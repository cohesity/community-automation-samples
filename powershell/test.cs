public static void GetBSRData()
        {
            DateTime endDate = DateTime.Now.Date.Add(new TimeSpan(17, 00, 00));
            //endDate = endDate.Date.Add(new TimeSpan(17,00,00));
            TimeSpan date = new TimeSpan(0, 17, 0, 0);
            //endDate = endDate.Add(date);

            DateTime startDate = DateTime.Now.Date.AddDays(-1);
            startDate = startDate.Add(date);

            long unixStartTime = ((DateTimeOffset)startDate).ToUnixTimeMilliseconds() * 1000;
            long unixEndTime = ((DateTimeOffset)endDate).ToUnixTimeMilliseconds() * 1000;
            //unixStartTime = 1658872800000000;
            //unixEndTime = 1658959200000000;
            Console.WriteLine(unixStartTime + " - " + unixEndTime);
            // Console.WriteLine(startDate + " - " + endDate);

            string serverNames = ConfigurationManager.AppSettings["CohesityServers"];
            //serverNames = "XF00ASEPODLPC2";

            List<BACKUPSTATUS> bsrList = new List<BACKUPSTATUS>();
            List<string> hosts = new List<string>();

            int i = 0;

            List<PolicyDetails> policies = new List<PolicyDetails>();

            string drpath = @"\\gslbp4s" + (ConfigurationManager.AppSettings["EnvName"].ToLower() == "prod" ? "tc" : "qa") + "p4s01gf" + (ConfigurationManager.AppSettings["EnvName"].ToLower() == "prod" ? "" : ".qa") + @".bnymellon.net\p4sshare\BaaS_Portal\COHESITY\Logs\BSR_Logs_" + DateTime.Now.Date.ToString("yyyy-MM-dd") + ".txt";
            foreach (string clusterName in serverNames.Split(','))
            {
                HttpWebResponse responseGet = null;
                string AuthCode = string.Empty;
                StreamReader reader = null;
                Console.WriteLine(clusterName);

                try
                {
                    responseGet = GetCohesityData(clusterName, "accessTokens", "");
                    if (responseGet != null)
                    {
                        reader = new StreamReader(responseGet.GetResponseStream());
                        string responseFromServer = reader.ReadToEnd();

                        dynamic resp = JObject.Parse(responseFromServer);
                        AuthCode = resp["accessToken"].Value;

                        if (AuthCode != string.Empty)
                        {
                            responseGet = GetCohesityData(clusterName, "protectionJobs", AuthCode);
                            if (responseGet != null)
                            {
                                reader = new StreamReader(responseGet.GetResponseStream());
                                responseFromServer = reader.ReadToEnd();

                                var result = JsonConvert.DeserializeObject<List<JobRoot>>(responseFromServer);
                                foreach (var item in result)
                                {
                                    if (item.isDeleted != true)
                                    {
                                        responseGet = GetCohesityData(clusterName, "protectionRuns?jobId=" + item.id + "&numRuns=500000&startTimeUsecs=" + unixStartTime + "&endTimeUsecs=" + unixEndTime, AuthCode);
                                        if (responseGet != null)
                                        {
                                            reader = new StreamReader(responseGet.GetResponseStream());
                                            responseFromServer = reader.ReadToEnd();
                                            var runResult = JsonConvert.DeserializeObject<List<PRJRoot>>(responseFromServer);
                                            if (item.name != "")
                                            {
                                                //if (runResult.Count > 0)
                                                //{
                                                var responseGetJob = GetCohesityData(clusterName, "protectionJobs/" + item.id, AuthCode);
                                                var responseFromServerJob = "";
                                                if (responseGetJob != null)
                                                {
                                                    reader = new StreamReader(responseGetJob.GetResponseStream());
                                                    responseFromServerJob = reader.ReadToEnd();
                                                }
                                                foreach (var run in runResult)
                                                {
                                                    if (run.backupRun.sourceBackupStatus != null)
                                                    {
                                                        Console.WriteLine(item.name + " - " + run.backupRun.sourceBackupStatus.Count);
                                                        foreach (var sourceItem in run.backupRun.sourceBackupStatus)
                                                        {
                                                            BACKUPSTATUS bsrData = new BACKUPSTATUS();
                                                            string status = sourceItem.status.Remove(0, 1);
                                                            if (status.ToLower() == "success" || status.ToLower() == "warning" || status.ToLower() == "failure")
                                                            {
                                                                bsrData.HostName = (sourceItem.source.name.Contains(".bnymellon.net") ? sourceItem.source.name.Substring(0, sourceItem.source.name.IndexOf(".")) : sourceItem.source.name).ToUpper();
                                                                if (status == "Success" || status == "Warning")
                                                                    bsrData.Status = "Completed";
                                                                if (status.ToLower() == "failure")
                                                                {
                                                                    bsrData.Status = "Failed";
                                                                    bsrData.ErrorCode = run.backupRun.error;
                                                                }
                                                                if (string.IsNullOrEmpty(status))
                                                                    bsrData.Status = "";

                                                                bsrData.NodeName = item.name;
                                                                bsrData.Server = clusterName;
                                                                bsrData.Domain = sourceItem.source.environment.Remove(0, 1);
                                                                bsrData.Scheduled = "Y";
                                                                bsrData.Product = "COHESITY";

                                                                if (status.ToLower() == "failure" && sourceItem.stats.startTimeUsecs != null && sourceItem.stats.admittedTimeUsecs == null)
                                                                {
                                                                    long startTimeUsecs = ((long)sourceItem.stats.startTimeUsecs) / 1000;
                                                                    bsrData.StartTime = DateTimeOffset.FromUnixTimeMilliseconds(startTimeUsecs).LocalDateTime;
                                                                }

                                                                if (sourceItem.stats.admittedTimeUsecs != null)
                                                                {
                                                                    long startTimeUsecs = ((long)sourceItem.stats.admittedTimeUsecs) / 1000;
                                                                    bsrData.StartTime = DateTimeOffset.FromUnixTimeMilliseconds(startTimeUsecs).LocalDateTime;
                                                                }

                                                                if (sourceItem.stats.endTimeUsecs != null)
                                                                {
                                                                    long endTimeUsecs = ((long)sourceItem.stats.endTimeUsecs) / 1000;
                                                                    bsrData.EndTime = DateTimeOffset.FromUnixTimeMilliseconds(endTimeUsecs).LocalDateTime;
                                                                }

                                                                if (sourceItem.stats.totalPhysicalBackupSizeBytes != null)
                                                                {
                                                                    long bytesProcessed = (long)sourceItem.stats.totalPhysicalBackupSizeBytes;
                                                                    bsrData.BackupSize = (double)bytesProcessed;
                                                                }

                                                                if (responseFromServerJob != "")
                                                                {
                                                                    var pjResult = JsonConvert.DeserializeObject<PJRoot>(responseFromServerJob);
                                                                    dynamic results = JsonConvert.DeserializeObject<dynamic>(responseFromServerJob);

                                                                    if (results != null)
                                                                    {
                                                                        if (results.isActive == null)
                                                                        {
                                                                            try
                                                                            {
                                                                                var pol = policies.Where(w => w.ClusterName == clusterName && w.PolicyId == pjResult.policyId && w.NodeName == bsrData.NodeName).FirstOrDefault();
                                                                                if (pol == null)
                                                                                {
                                                                                    responseGet = GetCohesityData(clusterName, "protectionPolicies/" + results.policyId, AuthCode);
                                                                                    if (responseGet != null)
                                                                                    {
                                                                                        reader = new StreamReader(responseGet.GetResponseStream());
                                                                                        responseFromServer = reader.ReadToEnd();
                                                                                        var policyResult = JsonConvert.DeserializeObject<PPRoot>(responseFromServer);
                                                                                        //File.AppendAllText(@"D:\Web\Jobs\protectionpolicies.txt", responseFromServer);

                                                                                        bsrData.Schedule = policyResult.incrementalSchedulingPolicy.periodicity.Remove(0, 1);
                                                                                        if ((bsrData.Schedule != null && bsrData.Schedule == "Continuous") || bsrData.NodeName.Contains("ESP") || bsrData.NodeName.Contains("_MS"))
                                                                                        {
                                                                                            bsrData.Schedule = "MANUAL";
                                                                                            bsrData.Scheduled = "N";
                                                                                        }

                                                                                        PolicyDetails pd = new PolicyDetails();
                                                                                        pd.ClusterName = clusterName;
                                                                                        pd.PolicyId = pjResult.policyId;
                                                                                        pd.Schedule = bsrData.Schedule;
                                                                                        pd.Scheduled = bsrData.Scheduled;
                                                                                        pd.NodeName = bsrData.NodeName;
                                                                                        policies.Add(pd);
                                                                                    }
                                                                                }

                                                                                else
                                                                                {
                                                                                    bsrData.Schedule = pol.Schedule;
                                                                                    bsrData.Scheduled = pol.Scheduled;
                                                                                }
                                                                            }
                                                                            catch (Exception ex)
                                                                            {
                                                                                Console.WriteLine(ex.Message);
                                                                            }
                                                                            finally
                                                                            {

                                                                                if (bsrData.Schedule == null)
                                                                                    bsrData.Schedule = "";
                                                                                if (responseGetJob != null)
                                                                                {
                                                                                    bsrList.Add(bsrData);
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        if (run.copyRun != null)
                                                        {
                                                            foreach (var cr in run.copyRun)
                                                            {
                                                                if (cr.target.replicationTarget != null)
                                                                {
                                                                    if (cr.copySnapshotTasks != null)
                                                                    {
                                                                        foreach (var task in cr.copySnapshotTasks)
                                                                        {
                                                                            if (task.status.Remove(0, 1).ToLower() == "success")
                                                                            {
                                                                                string hostName = (task.source.name.Contains(".bnymellon.net") ? task.source.name.Substring(0, task.source.name.IndexOf(".")) : task.source.name).ToUpper();

                                                                                foreach (var li in bsrList.Where(m => m.HostName.ToUpper().Contains(hostName.ToUpper())))
                                                                                {
                                                                                    if (hostName.ToUpper() == li.HostName.ToUpper())
                                                                                        li.ReplicationStatus = task.status.Remove(0, 1).ToUpper();
                                                                                    else
                                                                                        li.ReplicationStatus = "";
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }

                                                    }
                                                }
                                            }
                                        }
                                        //}
                                    }
                                }
                            }
                        }
                    }
                    string csvRow = clusterName + " - completed @ " + DateTime.Now.ToString() + "\r\n";
                    File.AppendAllText(drpath, csvRow);
                }
                catch (Exception ex)
                {
                    Utility.LogError(ex, clusterName + " - BACKUP STATUS - " + ex.Message, "COHESITY");
                }
                finally
                {
                    if (responseGet != null)
                        responseGet.Close();
                    if (reader != null)
                        reader.Close();
                }
            }

            if (bsrList.Count > 0)
            {
                Console.WriteLine(bsrList.Count + " -BSRData");
                SQLHelper.SaveBackupStatus(bsrList);
            }

        }
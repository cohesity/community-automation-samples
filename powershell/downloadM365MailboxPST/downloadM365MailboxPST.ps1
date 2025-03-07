# process commandline arguments
[CmdletBinding()]
param (
    [Parameter()][string]$vip = 'helios.cohesity.com',
    [Parameter()][string]$username = 'helios',
    [Parameter()][string]$domain = 'local',
    [Parameter()][string]$tenant = $null,
    [Parameter()][switch]$useApiKey,
    [Parameter()][string]$password = $null,
    [Parameter()][switch]$noPrompt,
    [Parameter()][switch]$mcm,
    [Parameter()][string]$mfaCode = $null,
    [Parameter()][string]$clusterName = $null,
    [Parameter()][array]$sourceUserName,
    [Parameter()][string]$sourceUserList,
    [Parameter()][string]$pstPassword = '',
    [Parameter()][switch]$promptForPSTPassword,
    [Parameter()][string]$fileName = '.\pst.zip',
    [Parameter()][datetime]$recoverDate,
    [Parameter()][switch]$continueOnError,
    [Parameter()][int]$sleepTimeSeconds = 30
)

# source the cohesity-api helper code
. $(Join-Path -Path $PSScriptRoot -ChildPath cohesity-api.ps1)

# authentication =============================================
# demand clusterName for Helios/MCM
if(($vip -eq 'helios.cohesity.com' -or $mcm) -and ! $clusterName){
    Write-Host "-clusterName required when connecting to Helios/MCM" -ForegroundColor Yellow
    exit 1
}

# authenticate
apiauth -vip $vip -username $username -domain $domain -passwd $password -apiKeyAuthentication $useApiKey -mfaCode $mfaCode -heliosAuthentication $mcm -tenant $tenant -noPromptForPassword $noPrompt

# exit on failed authentication
if(!$cohesity_api.authorized){
    Write-Host "Not authenticated" -ForegroundColor Yellow
    exit 1
}

# select helios/mcm managed cluster
if($USING_HELIOS){
    $thisCluster = heliosCluster $clusterName
    if(! $thisCluster){
        exit 1
    }
}
# end authentication =========================================


if($promptForPSTPassword){
    while($True){
        $secureNewPassword = Read-Host -Prompt "  Enter PST password" -AsSecureString
        $secureConfirmPassword = Read-Host -Prompt "Confirm PST password" -AsSecureString
        $pstPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $secureNewPassword ))
        $confirmPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $secureConfirmPassword ))
        if($pstPassword -cne $confirmPassword){
            Write-Host "Passwords do not match" -ForegroundColor Yellow
        }else{
            break
        }
    }
}


# gather list from command line params and file
function gatherList($Param=$null, $FilePath=$null, $Required=$True, $Name='items'){
    $items = @()
    if($Param){
        $Param | ForEach-Object {$items += $_}
    }
    if($FilePath){
        if(Test-Path -Path $FilePath -PathType Leaf){
            Get-Content $FilePath | ForEach-Object {$items += [string]$_}
        }else{
            Write-Host "*** Text file $FilePath not found! ***" -ForegroundColor Yellow
            exit 1
        }
    }
    if($Required -eq $True -and $items.Count -eq 0){
        Write-Host "*** No $Name specified ***" -ForegroundColor Yellow
        exit 1
    }
    return ($items | Sort-Object -Unique)
}

$sourceUserNames = @(gatherList -Param $sourceUserName -FilePath $sourceUserList -Name 'sourceUserName' -Required $True)

$cluster = api get cluster

$taskName = "Recover_Mailboxes_$(get-date -UFormat '%b_%d_%Y_%H-%M%p')"

$recoveryParams = @{
    "name" = $taskName;
    "snapshotEnvironment" = "kO365";
    "office365Params" = @{
        "recoveryAction" = "ConvertToPst";
        "recoverMailboxParams" = @{
            "continueOnError" = $true;
            "skipRecoverArchiveMailbox" = $true;
            "skipRecoverRecoverableItems" = $true;
            "skipRecoverArchiveRecoverableItems" = $true;
            "objects" = @();
            "pstParams" = @{
                "password" = $pstPassword
            }
        }
    }
}

foreach($sourceUser in $sourceUserNames){
    $userSearch = api get -v2 "data-protect/search/protected-objects?snapshotActions=RecoverMailbox&searchString=$sourceUser&environments=kO365"
    $userObjs = $userSearch.objects | Where-Object {$_.name -eq $sourceUser}
    if(!$userObjs){
        foreach($userObj in $userSearch.objects){
            $userSource = api get protectionSources/objects/$($userObj.id)
            if($userSource -and $userSource.office365ProtectionSource.primarySMTPAddress -eq $sourceUser){
                $userObjs = @($userObj)
            }
        }
    }
    if(!$userObjs){
        Write-Host "*** Mailbox User $sourceUser not found ***" -ForegroundColor Yellow
        if($continueOnError){
            continue
        }else{
            exit 1
        }
    }

    foreach($userObj in $userObjs){
        $protectionGroupId = $userObj.latestSnapshotsInfo[0].protectionGroupId
        $snapshotId = $userObj.latestSnapshotsInfo[0].localSnapshotInfo.snapshotId
    
        if($recoverDate){
            $recoverDateUsecs = dateToUsecs ($recoverDate.AddMinutes(1))
        
            $snapshots = api get -v2 "data-protect/objects/$($userObj.id)/snapshots?protectionGroupIds=$($protectionGroupId)"
            $snapshots = $snapshots.snapshots | Sort-Object -Property runStartTimeUsecs -Descending | Where-Object runStartTimeUsecs -lt $recoverDateUsecs
            if($snapshots -and $snapshots.Count -gt 0){
                $snapshot = $snapshots[0]
                $snapshotId = $snapshot.id
            }else{
                Write-Host "*** No snapshots available for $sourceUser from specified date ***"
                if($continueOnError){
                    continue
                }else{
                    exit 1
                }
            }
        }
    
        Write-Host "==> Processing $sourceUser"
        $recoveryParams.office365Params.recoverMailboxParams.objects = @($recoveryParams.office365Params.recoverMailboxParams.objects + @{
            "mailboxParams" = @{
                "recoverFolders" = $null;
                "recoverEntireMailbox" = $true
            };
            "ownerInfo" = @{
                "snapshotId" = $snapshotId
            }
        })
    }
}

if($recoveryParams.office365Params.recoverMailboxParams.objects.Count -eq 0){
    Write-Host "*** No objects found ***" -ForegroundColor Yellow
    exit 1
}

$recovery = api post -v2 data-protect/recoveries $recoveryParams

"==> Waiting for PST conversion to complete..."
$finishedStates = @('Canceled', 'Succeeded', 'Failed')
$pass = 0
do{
    Start-Sleep $sleepTimeSeconds
    $recoveryTask = api get -v2 data-protect/recoveries/$($recovery.id)?includeTenants=true
    $status = $recoveryTask.status

} until ($status -in $finishedStates)

$downloadURL = "https://$vip/v2/data-protect/recoveries/$($recovery.id)/downloadFiles?clusterId=$($cluster.id)&includeTenants=true"
if($status -eq 'Succeeded'){
    Write-Host "==> PST conversion finished with status: $status"
    Write-Host "==> Downloading zip file to $fileName"
    fileDownload -uri $downloadURL -filename $fileName
}else{
    Write-Host "*** PST conversion finished with status: $status ***"
}

# Copy the agent signing CA (private key and CA chain) from one Cohesity cluster to another
# so that physical agents can be registered to multiple clusters.
#
# Direct cluster authentication (original behavior):
#   .\copyCerts.ps1 -sourceCluster cluster1 -targetCluster cluster2 -targetUser admin [-useApiKeys]
#
# Helios authentication (uses the stored Helios API key, cluster names are the Helios cluster names):
#   .\copyCerts.ps1 -helios -sourceCluster cluster1 -targetCluster cluster2
#
# Restore the original target CA from the local backup file:
#   .\copyCerts.ps1 -restore -targetCluster cluster2 -targetUser admin
#   .\copyCerts.ps1 -helios -restore -targetCluster cluster2

# process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$targetCluster,
    [Parameter()][string]$targetUser,
    [Parameter()][string]$targetDomain = 'local',
    [Parameter()][string]$sourceCluster,
    [Parameter()][string]$sourceUser = $targetUser,
    [Parameter()][string]$sourceDomain = $targetDomain,
    [Parameter()][switch]$useApiKeys,
    [Parameter()][switch]$promptForMfaCode,
    [Parameter()][switch]$helios,
    [Parameter()][switch]$restore
)

# targetUser is only optional when connecting through Helios
if($helios){
    if(! $targetUser){
        $targetUser = 'helios'
    }
    $sourceUser = $targetUser
    $sourceDomain = $targetDomain
}else{
    if(! $targetUser){
        Write-Host "Please specify -targetUser (or use -helios)" -ForegroundColor Yellow
        exit
    }
}

if(! $restore -and (! $sourceCluster -or ! $sourceUser)){
    Write-Host "Please specify -restore, or -sourceCluster and -sourceUser" -ForegroundColor Yellow
    exit
}

# source the cohesity-api helper code
. $(Join-Path -Path $PSScriptRoot -ChildPath cohesity-api.ps1)

$heliosVip = 'helios.cohesity.com'
$heliosAuthenticated = $false

# functions -----------------------------------------------------
function connectToCluster($clusterName, $user, $dom){
    if($helios){
        # authenticate to Helios once, then switch between clusters
        if(! $script:heliosAuthenticated){
            $mfaCode = $null
            if($promptForMfaCode){
                $mfaCode = Read-Host -Prompt 'Please Enter MFA Code'
            }
            apiauth -vip $heliosVip -username $user -domain $dom -apiKeyAuthentication $True -mfaCode $mfaCode -quiet
            $script:heliosAuthenticated = $true
        }
        $null = heliosCluster $clusterName
    }else{
        $mfaCode = $null
        if($promptForMfaCode){
            $mfaCode = Read-Host -Prompt 'Please Enter MFA Code'
        }
        apiauth -vip $clusterName -username $user -domain $dom -apiKeyAuthentication $useApiKeys -mfaCode $mfaCode -quiet
    }

    $thisCluster = api get cluster

    # confirm we are talking to the requested cluster
    if($helios -and $thisCluster.name -ne $clusterName){
        Write-Host "Unable to connect to cluster $clusterName through Helios" -ForegroundColor Yellow
        exit 1
    }
    return $thisCluster
}

function checkClusterVersion(){
    if($cluster.clusterSoftwareVersion -lt '6.8.1_u5'){
        Write-Host "This script requires Cohesity version 6.8.1_u5 or later" -ForegroundColor Yellow
        exit 1
    }
}

function setGflag($vip, $servicename='kMagneto', $flagname='magneto_skip_cert_upgrade_for_multi_cluster_registration', $flagvalue='false', $reason='Enable agent certificate update'){

    $gflagAlreadySet = $false
    $gflags = api get /clusters/gflag

    foreach($service in $gflags){
        $svcName = $service.serviceName
        if($svcName -eq $servicename){
            $serviceGflags = $service.gflags
            foreach($serviceGflag in $serviceGflags){
                if($serviceGflag.name -eq $flagname -and $serviceGflag.value -eq $flagvalue){
                    Write-Host "Gflag already set"
                    $gflagAlreadySet = $True
                }
            }
        }
    }

    if(! $gflagAlreadySet){
        write-host "Setting gflag  $($servicename):  $flagname = $flagvalue"
        $gflagReq = @{
            'gflags' = @(
                @{
                    'name' = $flagname;
                    'reason' = $reason;
                    'value' = $flagvalue
                }
            );
            'serviceName' = $servicename;
            'effectiveNow' = $True
        }
        $null = api put '/clusters/gflag' $gflagReq
    }
}

function copyCerts($certs){
    $params = @{
        "privateKey" = $certs.privateKey;
        "caChain" = $certs.caChain
    }
    $result = api post -v2 cert-manager/bootstrap-ca $params
    $newCaChain = ''
    while($certs.caChain -ne $newCaChain){
        Start-Sleep 10
        $newCerts = api get -v2 cert-manager/ca-status
        $newCaChain = $newCerts.caCertChain
    }
}

# main ----------------------------------------------------------
if(! $restore){
    $cacheFile = "$($sourceCluster)-Certs.json"
    if(Test-Path -Path $cacheFile -PathType Leaf){
        "`nUsing cached keys from source cluster $sourceCluster..."
        $certs = Get-Content -Path $cacheFile | ConvertFrom-Json
    }else{
        "`nConnecting to source cluster $sourceCluster..."
        $cluster = connectToCluster $sourceCluster $sourceUser $sourceDomain

        # check cluster version
        checkClusterVersion

        # get certs
        Write-Host "Getting certs"
        $certs = api get -v2 cert-manager/ca-keys
        $certs | toJson | Out-File -FilePath $cacheFile
        setGflag -vip $sourceCluster
    }
}

"`nConnecting to target cluster $targetCluster..."
$cluster = connectToCluster $targetCluster $targetUser $targetDomain

# check cluster version
checkClusterVersion

$cacheFile = "$($cluster.name)-Certs.json"

# restore original certs
if($restore){
    if(Test-Path -Path $cacheFile -PathType Leaf){
        Write-Host "Restoring original certs"
        $certs = Get-Content -Path $cacheFile | ConvertFrom-Json
        copyCerts $certs
        Write-Host "Restore completed`n"
        exit
    }else{
        Write-Host "No backup found for $($cluster.name)`n" -ForegroundColor Yellow
        exit
    }
}

# backup original certs
$origCerts = api get -v2 cert-manager/ca-keys
if(! (Test-Path -Path $cacheFile -PathType Leaf)){
    $origCerts | toJson | Out-File -FilePath $cacheFile
}

# copy new certs
Write-Host "Copying certs"
copyCerts $certs

# set gflag
setGflag -vip $targetCluster
Write-Host "`nProcess finished`n"

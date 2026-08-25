# Set Legal Hold on FortKnox Vault Copies using PowerShell

Warning: this code is provided on a best effort basis and is not officially
supported or sanctioned by Cohesity. Review the selected runs and vaults before
changing legal hold.

This script adds, removes, or reports Data Protect legal hold on existing
FortKnox cloud-vault copies. It is intended for runs whose local snapshot may
already have expired while the FortKnox copy remains available.

Unlike `legalHold.ps1`, this script:

* does not exclude runs whose local snapshot was garbage collected;
* selects only archival targets whose ownership context is FortKnox/RPaaS;
* uses the v2 protection-group run API; and
* sends a legal-hold-only update without local snapshot or retention changes.

The account must have the Data Security privilege and permission to modify the
protection run. A custom role should include both `DATA_SECURITY` and
`PROTECTION_MODIFY`.

## Components

Place these files together in the same directory:

* `fortKnoxLegalHold.ps1`
* `cohesity-api.ps1` from
  [`powershell/cohesity-api`](../cohesity-api/cohesity-api.ps1)

## List FortKnox vaulted copies

```powershell
./fortKnoxLegalHold.ps1 -vip mycluster `
                        -username datasec `
                        -jobName 'my protection group' `
                        -listRuns
```

When connecting through Helios or MCM, also specify `-clusterName`.

The output includes the v2 `RunId`, FortKnox vault ID/name, current legal-hold
state, and expiry date. Use the displayed `RunId` for updates.

## Add legal hold

```powershell
./fortKnoxLegalHold.ps1 -vip mycluster `
                        -username datasec `
                        -jobName 'my protection group' `
                        -runId '12345:1609459200000000' `
                        -vaultName 'my-fortknox-vault' `
                        -addHold
```

## Remove legal hold

```powershell
./fortKnoxLegalHold.ps1 -vip mycluster `
                        -username datasec `
                        -jobName 'my protection group' `
                        -runId '12345:1609459200000000' `
                        -vaultName 'my-fortknox-vault' `
                        -removeHold
```

Removing legal hold after the original retention expiry may make the vaulted
copy immediately eligible for expiration.

## Other selectors

Use one run selector at a time:

* `-latest`
* `-runId '<jobId>:<runStartTimeUsecs>'`
* `-startDate '<date>' -endDate '<date>'`

Use `-vaultId` or `-vaultName` to limit the operation to a particular FortKnox
vault. If neither is supplied, the operation applies to every FortKnox target
on each selected run.

`-numRuns` controls how many recent runs are retrieved and defaults to 1000.

## Important limitations

* This changes Data Protect legal-hold metadata; it does not extend the cloud
  provider Object Lock expiration.
* Do not add retention, delete, resync, or DataLock fields to the request.
  FortKnox permits only a legal-hold-only update through this API.
* Legal hold cannot be added after the vaulted copy itself has expired.

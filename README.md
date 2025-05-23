# AlphaQuickSight 0.1.0

## Setup

### Access
- QuickSight is setup in AWS Dublin (Old QuickSight Version in London)
  - https://eu-west-1.quicksight.aws.amazon.com
  - `alpha-rock`

### Datasets
- All Datasets refer to a table or view with the same name in the Postgres cluster
- All Datasets are setup in a Shared Folder
  - `Lukas Märkl` and `Marco Scholz` have Owner permission to the Datasets

### Postgres Cluster
- Cluster URL: `quant.cluster-cm3hezyaasbb.eu-west-2.rds.amazonaws.com`
  - No issue with changing IPs !!!
- QuickSight has a separate Usernames for the PostgresCluster
  - `quicksight_admin` to generate data within the `quicksight`schema
  - `quicksight_connect` to only read data
  - Separate users allow to better control permissions and usage

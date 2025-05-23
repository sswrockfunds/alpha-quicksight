# AlphaQuickSight

## Setup

### Access
- QuickSight is setup in AWS Dublin (Old QuickSight Version in London)
  - https://eu-west-1.quicksight.aws.amazon.com
  - `alpha-rock`

### Datasets
- All Datasets refer to a table or view with the same name in the Postgres cluster
- All Datasets are setup in a Shared Folder
  - Lukas Märkl and Marco Scholz have Owner permission to the Datasets

### Postgres Cluster
- QuickSight has a separate Username for the PostgresCluster
- Permissions
  - Read all tables
  - Only write within Schema `quicksight.*`

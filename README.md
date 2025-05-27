# AlphaQuickSight 0.1.0

## Schedule

|                          | Interval | Type               | Scope            | Script Runtime |
|--------------------------|----------|--------------------|------------------|----------------|
| tradingdata              | 1min     | Table Delta Update | Account, Minute  | 1 sec          |
| tradingdata (full day)   | hourly   | Table Delta Update | Account, Minute  | 5 sec          |
| exposure                 | 5min     | Table Delta Update | Account, Minute  | 10 sec         |
| avg7d                    | daily    | Materialized View  | Account, Minute  | 150 sec        |
| current_day              | 5min     | Materialized View  | Account, Minute  | 50 sec         |
| ---                      |          |                    |                  |                |
| intraday Overall         | 5min     | Materialized View  | Minute           | 4 sec          |
| intraday Exchange        | 5min     | Materialized View  | Exchange, Minute | 4 sec          |
| intraday Account         | 5min     | Materialized View  | Account, Minute  | 17 sec         |
| intraday Top Instruments | 5min     | Materialized View  | Instrument       | 1 sec          |
| ---                      |          |                    |                  |                |
| clean tradingdata        | daily    |                    |                  |                |
| clean exposure           | daily    |                    |                  |                |

## ToDos

- Pnl daily
- transfers

## Provided Data

_exposure
_tradedata
public_stats
account_map
account_transfer
instrument_data

### Intraday

#### metrics

- tpl1, tpl60, tpl300
- turnover_usd
- pnl

#### dimensions

- exchange
- account
- time (7day avg, hour)

#### views

- `quicksight.intraday`
- `quicksight.intraday_by_exchange`
- `quicksight.intraday_by_account`
- `quicksight.intraday_current_hour`
- `quicksight.intraday_top_instruments`

- daily
- daily_by_exchange
- daily_by_account
- weekly
- weekly_by_exchange
- weekly_by_account
- monthly
- monthly_by_exchange
- monthly_by_account

## Dependencies

The QuickSight data depends heavily on other scripts and processes to gather and prepare data.
A full documentation of dependencies should guarantee maintainability and stability.

### CryptoStruct Schema

#### Tables

- `cryptostruct.instruments`
- cryptostruct.instruments_stats_daily

#### Process

- `monkey-bi` InstrumentImport
  `exposure.underlying_positions`
  `account.transfer`

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

# AlphaQuickSight 1.0.0

## Open
- No Transfers before 2023
- Missing Account Mappings
  - 1002 - 1009
  - 11003 - 11050
  - 12001 - 12041
  - 13000 - 13020
  - 18000 - 18025
  - 19000 - 19020
  - 20100
- No Trade data before 2023 (difficult)
- Delete Mappings without Exposure & Trades ??
````sql
   SELECT h.trading_day, h.account_id, q.exposure_usd, q.trade_count
     FROM account.history h
LEFT JOIN quicksight._history q ON h.account_id=q.account_id AND h.trading_day=q.trading_day
WHERE q.trade_count IS NULL AND (q.exposure_usd IS null OR q.exposure_usd = 0)
````

## Schedule

|                          | Interval | Type               | Scope            | Script Runtime |
|--------------------------|----------|--------------------|------------------|----------------|
| tradingdata              | 1min     | Table Delta Update | Account, Minute  | 1 sec          |
| tradingdata (full day)   | hourly   | Table Delta Update | Account, Minute  | 5 sec          |
| exposure                 | 2min     | Table Delta Update | Account, Minute  | 10 sec         |
| avg7d                    | hourly   | Materialized View  | Account, Minute  | 150 sec        |
| current_day              | 2min     | Materialized View  | Account, Minute  | 50 sec         |
| ---                      |          |                    |                  |                |
| intraday Overall         | 2min     | Materialized View  | Minute           | 4 sec          |
| intraday Exchange        | 2min     | Materialized View  | Exchange, Minute | 4 sec          |
| intraday Account         | 2min     | Materialized View  | Account, Minute  | 17 sec         |
| intraday Top Instruments | 2min     | Materialized View  | Instrument       | 1 sec          |
| ---                      |          |                    |                  |                |
| clean tradingdata        | daily    |                    |                  |                |
| clean exposure           | daily    |                    |                  |                |
| ---                      |          |                    |                  |                |
| daily                    | daily    | Table Delta Update | Account, Day     | 15 sec         |

## Dependencies

The QuickSight data depends heavily on other scripts and processes to gather and prepare data.
A full documentation of dependencies should guarantee maintainability and stability.

### Tables
- public data
    - `cryptostruct.instruments`
    - `cryptostruct.fx_minute`
    - `cryptostruct.fx_daily`
- privata data
    - `account.current`
    - `account.history`
    - `account.transfer`
    - `alpha.trades`
- private data from CryptoStruct Backend
    - `positions__underlyings` (implemented in core repo)

#### Process
- `monkey-bi`
    - InstrumentImport
    - SyncFx daily
    - TradeImport
- `alpha-ui`
    - Account Sync

## Daily
- Exposure
    - from CryptoStruct Backends `positions__underlyings` with `cryptostruct.fx_daily`
    - Transfers from `account.transfer`
    - TPL60 / Turnover from `alpha.trades`

## Intraday
- Trade Data from `alpha.trades`
- Exposure from CryptoStruct Backends `positions__underlyings` with `cryptostruct.fx_minute`
- All other views are `MATERIALIZED VIEWS` that are generated on this base data
  - `_avg7d` only needs to be generated once a day
  - `intraday_top_instruments` view is only based on the `alpha.trades` table

## Important Note on Old Data
- Before `2024-01-01` the old database must be used
- Before `2022-11-16` the underlying positions where archived in `positions__underlyings_archive`
  - And they have another column schema (no wallet, no cash balance or available balance)


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

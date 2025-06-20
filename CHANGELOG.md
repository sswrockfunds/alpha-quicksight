## [Unreleased]
### Added
- Added view `quicksight.summary` with the latest state of the current day
### Changed
### Fixed
### Removed
### -


## [1.0.2] - 2025-06-20 11:51 UTC
### Changed
- Updated dependencies
### Fixed
- Fixed missing `market` column to intraday_by_exchange
- Fixed select top instruments by `tpl60` instead of turnover
- Fixed issue of duplication caused of updated_ts
### Removed
### -


## [1.0.2] - 2025-06-20 09:51 UTC

## [1.0.1] - 2025-06-12 12:35 UTC
### Added
- Added sql for monthly and weekly views
- Added debug and account mapping scripts
### Fixed
- Fixed Duplicate issue in Materialized Views
  - `quicksight.intraday`
  - `quicksight.intraday_by_exchange`
  - `quicksight.intraday_by_account`

## [1.0.0] - 2025-06-11 20:34 UTC
### Added
- Added Daily Import
  - Exposure
  - PnL
  - Trade Data (Turnover, TPL, Trade count)
  - Transfers
  - Account mapping
### Changed
- Moved Balance Import classes from to repo

## [0.2.0] - 2025-05-27 16:12 UTC
### Added
- Added intraday views and tables
  - `quicksight.intraday`
  - `quicksight.intraday_by_exchange`
  - `quicksight.intraday_by_account`
  - `quicksight.intraday_top_instruments`
- Added deploy script to deploy to monkey-bi server
  - `composer deploy`
  - `composer dev`
- Added user scripts to `database/user`
  - scripts
    - `create_users.sql`
    - `change_passwords.sql`
  - users
    - `quicksight_admin` can write within the quicksight schema
    - `quicksight_connect` can only read and should be used for setting up the Datasets within QuickSight
- Added `database/permission.sql` that defines all permissions
- Added generic SQL-Script-Runner
### Changed
- Need `sswrockfunds/core 0.15.0` as min dependency

## [0.1.0] - 2025-05-23 09:45 UTC
### Added
- Release Workflow
- Initial folder Structure
- `composer.json`
- `CHANGELOG.md`
- `.gitignore`
- `.gitattributes`
- `.editorconfig`
### -

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

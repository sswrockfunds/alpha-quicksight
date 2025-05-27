## [Unreleased]
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
### Fixed
### Removed
### -


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

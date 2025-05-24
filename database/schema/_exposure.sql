DROP TABLE quicksight._exposure;

CREATE TABLE quicksight._exposure
(
    trading_month  VARCHAR(8),
    trading_week   VARCHAR(8),
    trading_day    DATE,
    trading_hour   TIMESTAMP,
    trading_minute TIMESTAMP,
    time_of_day    TIME(0),
    exchange_id    int,
    account_id     int,
    balance_usd    NUMERIC(20, 2),
    fiat_usd       NUMERIC(20, 2),
    stable_usd     NUMERIC(20, 2),
    crypto_usd     NUMERIC(20, 2),
    PRIMARY KEY (trading_minute, account_id)
);

CREATE INDEX exposure_day_time_idx ON quicksight._exposure (time_of_day, trading_day, account_id);
CREATE INDEX exposure_hour_idx ON quicksight._exposure (trading_hour, account_id);
CREATE INDEX exposure_week_idx ON quicksight._exposure (trading_week, account_id);
CREATE INDEX exposure_month_idx ON quicksight._exposure (trading_month, account_id);

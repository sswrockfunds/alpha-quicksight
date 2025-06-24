CREATE TABLE performance.minute_tradingdata
(
    trading_month  VARCHAR(8),
    trading_week   VARCHAR(8),
    trading_day    DATE,
    trading_hour   TIMESTAMP,
    trading_minute TIMESTAMP,
    time_of_day    TIME(0),
    exchange_id    int,
    account_id     int,
    turnover_usd   NUMERIC(20, 2),
    tpl1_usd       NUMERIC(20, 2),
    tpl10_usd      NUMERIC(20, 2),
    tpl30_usd      NUMERIC(20, 2),
    tpl60_usd      NUMERIC(20, 2),
    tpl300_usd     NUMERIC(20, 2),
    tpl900_usd     NUMERIC(20, 2),
    trade_count    INTEGER,
    updated_ts     TIMESTAMP,
    PRIMARY KEY (trading_minute, account_id)
);

CREATE INDEX minute_tradingdata_day_time_idx ON performance.minute_tradingdata (time_of_day, trading_day, account_id);
CREATE INDEX minute_tradingdata_hour_idx ON performance.minute_tradingdata (trading_hour, account_id);
CREATE INDEX minute_tradingdata_week_idx ON performance.minute_tradingdata (trading_week, account_id);
CREATE INDEX minute_tradingdata_month_idx ON performance.minute_tradingdata (trading_month, account_id);

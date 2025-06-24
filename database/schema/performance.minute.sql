DROP TABLE performance.minute;
CREATE TABLE performance.minute
(
    trading_month  VARCHAR(8),
    trading_week   VARCHAR(8),
    trading_day    DATE,
    trading_hour   TIMESTAMP(0),
    trading_minute TIMESTAMP(0),
    time_of_day    TIME(0),

    exchange_id        int,
    account_id         int,

    turnover           numeric(20, 2),
    tpl1               numeric(20, 2),
    tpl60              numeric(20, 2),
    tpl300             numeric(20, 2),
    pnl                numeric(20, 2),

    turnover_cum       numeric(20, 2),
    tpl1_cum           numeric(20, 2),
    tpl60_cum          numeric(20, 2),
    tpl300_cum         numeric(20, 2),
    pnl_cum            numeric(20, 2),

    turnover_avg7d     numeric(20, 2),
    tpl1_avg7d         numeric(20, 2),
    tpl60_avg7d        numeric(20, 2),
    tpl300_avg7d       numeric(20, 2),
    pnl_avg7d          numeric(20, 2),

    turnover_avg7d_cum numeric(20, 2),
    tpl1_avg7d_cum     numeric(20, 2),
    tpl60_avg7d_cum    numeric(20, 2),
    tpl300_avg7d_cum   numeric(20, 2),
    pnl_avg7d_cum      numeric(20, 2),

    updated_ts         timestamp(3),
    PRIMARY KEY (trading_day, trading_minute, account_id)
);

CREATE INDEX minute_by_account_idx ON performance.minute (trading_minute, account_id);
CREATE INDEX minute_by_exchange_idx ON performance.minute (trading_minute, exchange_id);

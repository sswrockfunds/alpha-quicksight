-- DROP TABLE IF EXISTS performance.minute_avg7d;

CREATE TABLE performance.minute
(
    trading_month  VARCHAR(8),
    trading_week   VARCHAR(8),
    trading_day    DATE,
    trading_hour   TIMESTAMP,
    trading_minute TIMESTAMP,
    time_of_day    TIME(0),

    exchange_id        text,
    account_id         text,

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
    PRIMARY KEY (trading_day_min, account_id)
);

CREATE INDEX minute_by_account_idx ON performance.minute_avg7d (trading_day_min, account_id);
CREATE INDEX minute__by_exchange_idx ON performance.minute_avg7d (trading_day_min, exchange_id);

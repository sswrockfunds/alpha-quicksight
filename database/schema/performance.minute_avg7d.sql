
DROP TABLE IF EXISTS performance.minute_avg7d;

CREATE TABLE performance.minute_avg7d
(
    trading_month  VARCHAR(8),
    trading_week   VARCHAR(8),
    trading_day    DATE,
    trading_hour   TIMESTAMP(0),
    trading_minute TIMESTAMP(0),
    time_of_day    TIME(0),

    trading_day_min    date,
    trading_day_max    date,
    trading_day_count  integer,
    datasets           integer,
    exchange_id        integer,
    account_id         integer,
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
    PRIMARY KEY (trading_minute, account_id)
);

CREATE INDEX minute_avg7d_by_account_idx ON performance.minute_avg7d (trading_day, account_id, time_of_day);
CREATE INDEX minute_avg7d_by_exchange_idx ON performance.minute_avg7d (trading_day, exchange_id, time_of_day);




CREATE TABLE performance.intraday_by_exchange
(
    trading_ts         TIMESTAMP(0),
    trading_day        DATE,
    time_of_day        TIME(0),

    exchange_id        int,
    market             VARCHAR(64),
    updated_ts         TIMESTAMP(3),

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

    turnover_avg7d_cum numeric(20, 2),
    tpl1_avg7d_cum     numeric(20, 2),
    tpl60_avg7d_cum    numeric(20, 2),
    tpl300_avg7d_cum   numeric(20, 2),
    pnl_avg7d_cum      numeric(20, 2),

    PRIMARY KEY (exchange_id, trading_ts)
);

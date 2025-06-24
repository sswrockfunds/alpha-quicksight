WITH
    script_input as ( {script_input} ),


    tradingdata as (
SELECT t.*
FROM performance.minute_tradingdata t
    JOIN script_input p ON t.trading_minute >= p.start_ts AND t.trading_minute < p.end_ts
    ),

    exposure as (
SELECT e.*
FROM performance.minute_exposure e
    JOIN script_input p ON e.trading_minute >= p.start_ts AND e.trading_minute < p.end_ts
    ),


    base AS (
SELECT coalesce(t.time_of_day,e.time_of_day) as time_of_day,
    coalesce(t.trading_day,e.trading_day) as trading_day,
    coalesce(t.trading_hour,e.trading_hour) as trading_hour,
    coalesce(t.trading_minute,e.trading_minute) as trading_minute,

    coalesce(t.exchange_id,e.exchange_id) as exchange_id,
    coalesce(t.account_id,e.account_id) as account_id,

    sum(coalesce(t.turnover_usd,0)) as turnover,
    sum(coalesce(t.tpl1_usd,0))     as tpl1,
    sum(coalesce(t.tpl60_usd,0))    as tpl60,
    sum(coalesce(t.tpl300_usd,0))   as tpl300,
    sum(coalesce(e.pnl_usd,0))      as pnl
FROM tradingdata t
    FULL OUTER JOIN exposure e ON t.trading_minute=e.trading_minute AND t.account_id=e.account_id
GROUP BY coalesce(t.time_of_day,e.time_of_day),
    coalesce(t.trading_day,e.trading_day),
    coalesce(t.trading_hour,e.trading_hour),
    coalesce(t.trading_minute,e.trading_minute),
    coalesce(t.exchange_id,e.exchange_id),
    coalesce(t.account_id,e.account_id)
    ),

    daily as (
SELECT time_of_day,
    trading_day,
    trading_hour,
    trading_minute,
    exchange_id,
    account_id,
    turnover,
    tpl1,
    tpl60,
    tpl300,
    pnl,
    SUM(turnover) OVER (PARTITION BY account_id ORDER BY time_of_day) AS turnover_cum,
    SUM(tpl1)     OVER (PARTITION BY account_id ORDER BY time_of_day) AS tpl1_cum,
    SUM(tpl60)    OVER (PARTITION BY account_id ORDER BY time_of_day) AS tpl60_cum,
    SUM(tpl300)   OVER (PARTITION BY account_id ORDER BY time_of_day) AS tpl300_cum,
    SUM(pnl)      OVER (PARTITION BY account_id ORDER BY time_of_day) AS pnl_cum,
    CURRENT_TIMESTAMP::timestamp(3) as updated_ts
FROM base
    )


INSERT INTO performance.minute(
    time_of_day,
    trading_day,
    trading_hour,
    trading_minute,
    exchange_id,
    account_id,
    turnover,
    tpl1,
    tpl60,
    tpl300,
    pnl,
    turnover_cum,
    tpl1_cum,
    tpl60_cum,
    tpl300_cum,
    pnl_cum,
    turnover_avg7d_cum,
    tpl1_avg7d_cum,
    tpl60_avg7d_cum,
    tpl300_avg7d_cum,
    pnl_avg7d_cum,
    updated_ts
)
SELECT d.time_of_day,
       d.trading_day,
       d.trading_hour,
       d.trading_minute,
       d.exchange_id,
       d.account_id,
       d.turnover,
       d.tpl1,
       d.tpl60,
       d.tpl300,
       d.pnl,
       d.turnover_cum,
       d.tpl1_cum,
       d.tpl60_cum,
       d.tpl300_cum,
       d.pnl_cum,
       a.turnover_avg7d_cum,
       a.tpl1_avg7d_cum,
       a.tpl60_avg7d_cum,
       a.tpl300_avg7d_cum,
       a.pnl_avg7d_cum,
       CURRENT_TIMESTAMP::timestamp(3) as updated_ts
FROM daily d
LEFT JOIN performance.minute_avg7d a ON d.trading_minute=a.ref_trading_minute AND d.account_id=a.account_id

    ON CONFLICT (trading_day, trading_minute, account_id)
DO UPDATE SET
    exchange_id        = EXCLUDED.exchange_id,
    turnover         = EXCLUDED.turnover,
       tpl1             = EXCLUDED.tpl1,
       tpl60            = EXCLUDED.tpl60,
       tpl300           = EXCLUDED.tpl300,
       pnl              = EXCLUDED.pnl,
       turnover_cum     = EXCLUDED.turnover_cum,
       tpl1_cum         = EXCLUDED.tpl1_cum,
       tpl60_cum        = EXCLUDED.tpl60_cum,
       tpl300_cum       = EXCLUDED.tpl300_cum,
       pnl_cum          = EXCLUDED.pnl_cum,
       turnover_avg7d_cum = EXCLUDED.turnover_avg7d_cum,
       tpl1_avg7d_cum     = EXCLUDED.tpl1_avg7d_cum,
       tpl60_avg7d_cum    = EXCLUDED.tpl60_avg7d_cum,
       tpl300_avg7d_cum   = EXCLUDED.tpl300_avg7d_cum,
       pnl_avg7d_cum      = EXCLUDED.pnl_avg7d_cum,
       updated_ts         = EXCLUDED.updated_ts;

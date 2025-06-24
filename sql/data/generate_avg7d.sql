WITH
    script_input as ( {script_input} ),

    base AS (
        SELECT
            coalesce(t.time_of_day,e.time_of_day) as time_of_day,
            coalesce(t.trading_day,e.trading_day) as trading_day,
            coalesce(t.exchange_id,e.exchange_id) as exchange_id,
            coalesce(t.account_id,e.account_id) as account_id,
            coalesce(t.trading_minute,e.trading_minute) as trading_minute,
            sum(coalesce(t.turnover_usd,0)) as turnover_usd,
            sum(coalesce(t.tpl1_usd,0))     as tpl1_usd,
            sum(coalesce(t.tpl60_usd,0))    as tpl60_usd,
            sum(coalesce(t.tpl300_usd,0))   as tpl300_usd,
            sum(coalesce(e.pnl_usd,0))    as pnl_usd
        FROM performance.minute_tradingdata t
        FULL OUTER JOIN performance.minute_exposure e ON t.account_id=e.account_id AND t.trading_minute=e.trading_minute
        WHERE coalesce(t.trading_day,e.trading_day) >= (SELECT ref_day - INTERVAL '7 days' FROM script_input)
    AND coalesce(t.trading_day,e.trading_day) < (SELECT ref_day FROM script_input)
    AND coalesce(t.trading_day,e.trading_day) < CURRENT_DATE
GROUP BY coalesce(t.time_of_day,e.time_of_day),
    coalesce(t.trading_day,e.trading_day),
    coalesce(t.exchange_id,e.exchange_id),
    coalesce(t.account_id,e.account_id),
    coalesce(t.trading_minute,e.trading_minute)
    ),

    avg7d AS (
SELECT
    p.ref_day,
    b.time_of_day,
    MIN(b.trading_day) as trading_day_min,
    MAX(b.trading_day) as trading_day_max,
    COUNT(DISTINCT b.trading_day) as trading_day_count,
    COUNT(b.*) as datasets,
    b.exchange_id,
    b.account_id,
    ROUND(AVG(b.turnover_usd), 2) AS turnover,
    ROUND(AVG(b.tpl1_usd), 2)     AS tpl1,
    ROUND(AVG(b.tpl60_usd), 2)    AS tpl60,
    ROUND(AVG(b.tpl300_usd), 2)   AS tpl300,
    ROUND(AVG(b.pnl_usd), 2)      AS pnl
FROM base b
    CROSS JOIN script_input p
GROUP BY p.ref_day, b.time_of_day, b.exchange_id, b.account_id
ORDER BY b.exchange_id, b.account_id, b.time_of_day asc
    )

INSERT INTO performance.minute_avg7d (
    ref_day,
    time_of_day,
    trading_day_min,
    trading_day_max,
    trading_day_count,
    datasets,
    exchange_id,
    account_id,
    turnover_avg7d,
    tpl1_avg7d,
    tpl60_avg7d,
    tpl300_avg7d,
    pnl_avg7d,
    turnover_avg7d_cum,
    tpl1_avg7d_cum,
    tpl60_avg7d_cum,
    tpl300_avg7d_cum,
    pnl_avg7d_cum,
    updated_ts
)
SELECT
    ref_day,
    time_of_day,
    trading_day_min,
    trading_day_max,
    trading_day_count,
    datasets,
    exchange_id,
    account_id,
    turnover AS turnover_avg7d,
    tpl1     AS tpl1_avg7d,
    tpl60    AS tpl60_avg7d,
    tpl300   AS tpl300_avg7d,
    pnl      AS pnl_avg7d,
    SUM(turnover) OVER (PARTITION BY account_id ORDER BY time_of_day) AS turnover_avg7d_cum,
    SUM(tpl1)     OVER (PARTITION BY account_id ORDER BY time_of_day) AS tpl1_avg7d_cum,
    SUM(tpl60)    OVER (PARTITION BY account_id ORDER BY time_of_day) AS tpl60_avg7d_cum,
    SUM(tpl300)   OVER (PARTITION BY account_id ORDER BY time_of_day) AS tpl300_avg7d_cum,
    SUM(pnl)      OVER (PARTITION BY account_id ORDER BY time_of_day) AS pnl_avg7d_cum,
        CURRENT_TIMESTAMP::timestamp(3) as updated_ts
FROM avg7d
    ON CONFLICT (ref_day, account_id, time_of_day)
DO UPDATE SET
    turnover_avg7d     = EXCLUDED.turnover_avg7d,
           tpl1_avg7d         = EXCLUDED.tpl1_avg7d,
           tpl60_avg7d        = EXCLUDED.tpl60_avg7d,
           tpl300_avg7d       = EXCLUDED.tpl300_avg7d,
           pnl_avg7d          = EXCLUDED.pnl_avg7d,
           turnover_avg7d_cum = EXCLUDED.turnover_avg7d_cum,
           tpl1_avg7d_cum     = EXCLUDED.tpl1_avg7d_cum,
           tpl60_avg7d_cum    = EXCLUDED.tpl60_avg7d_cum,
           tpl300_avg7d_cum   = EXCLUDED.tpl300_avg7d_cum,
           pnl_avg7d_cum      = EXCLUDED.pnl_avg7d_cum,
           updated_ts         = EXCLUDED.updated_ts;

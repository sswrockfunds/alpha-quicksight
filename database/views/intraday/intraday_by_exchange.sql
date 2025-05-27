--DROP MATERIALIZED VIEW IF EXISTS quicksight.intraday_by_account;

--CREATE MATERIALIZED VIEW quicksight.intraday_by_account AS
WITH base AS (
    SELECT
        coalesce(t.time_of_day,e.time_of_day) as time_of_day,
        coalesce(t.trading_day,e.trading_day) as trading_day,
        --  coalesce(t.account_id,e.account_id) as account_id,
        coalesce(t.exchange_id,e.exchange_id) as exchange_id,
        coalesce(t.trading_minute,e.trading_minute) as trading_minute,
        sum(t.turnover_usd) as turnover_usd,
        sum(t.tpl1_usd)     as tpl1_usd,
        sum(t.tpl60_usd)    as tpl60_usd,
        sum(t.tpl300_usd)   as tpl300_usd,
        sum(e.pnl_usd)      as pnl_usd
    FROM quicksight._tradingdata t
             FULL OUTER JOIN quicksight._exposure e ON t.account_id=e.account_id AND t.trading_minute=e.trading_minute
    WHERE (t.trading_day >= CURRENT_DATE - INTERVAL '7 days') OR (e.trading_day >= CURRENT_DATE - INTERVAL '7 days')
    GROUP BY coalesce(t.time_of_day,e.time_of_day),
             coalesce(t.trading_day,e.trading_day),
             --    coalesce(t.account_id,e.account_id),
             coalesce(t.exchange_id,e.exchange_id),
             coalesce(t.trading_minute,e.trading_minute)
),

     current_day AS (
         SELECT
             time_of_day,
             exchange_id,
             turnover_usd as turnover_current_day,
             tpl1_usd as tpl1_current_day,
             tpl60_usd as tpl60_current_day,
             tpl300_usd as tpl300_current_day,
             pnl_usd as pnl_current_day
         FROM base
         WHERE trading_day = CURRENT_DATE
     ),

     avg7d AS (
         SELECT
             time_of_day,
             exchange_id,
             ROUND(AVG(turnover_usd), 2) AS avg7d_turnover,
             ROUND(AVG(tpl1_usd), 2)     AS avg7d_tpl1,
             ROUND(AVG(tpl60_usd), 2)    AS avg7d_tpl60,
             ROUND(AVG(tpl300_usd), 2)   AS avg7d_tpl300,
             ROUND(AVG(pnl_usd), 2)   AS avg7d_pnl
         FROM base
         WHERE trading_day < CURRENT_DATE
         GROUP BY time_of_day, exchange_id
     ),

     combined AS (
         SELECT
             COALESCE(c.time_of_day, a.time_of_day) AS time_of_day,
             COALESCE(c.exchange_id, a.exchange_id) AS exchange_id,
             c.turnover_current_day,
             c.tpl1_current_day,
             c.tpl60_current_day,
             c.tpl300_current_day,
             c.pnl_current_day,
             a.avg7d_turnover,
             a.avg7d_tpl1,
             a.avg7d_tpl60,
             a.avg7d_tpl300,
             a.avg7d_pnl
         FROM avg7d a
                  FULL OUTER JOIN current_day c
                                  ON c.time_of_day = a.time_of_day AND c.exchange_id = a.exchange_id
     ),

     final_data AS (
         SELECT
             co.exchange_id,
             co.time_of_day,
             co.turnover_current_day,
             SUM(co.turnover_current_day) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS turnover_current_day_cum,
             SUM(COALESCE(co.tpl1_current_day, 0)) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS tpl1_current_cum,
             SUM(COALESCE(co.tpl60_current_day, 0)) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS tpl60_current_cum,
             SUM(COALESCE(co.tpl300_current_day, 0)) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS tpl300_current_cum,
             co.avg7d_turnover,
             SUM(co.avg7d_turnover) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS avg7d_turnover_cum,
             co.avg7d_tpl1,
             SUM(co.avg7d_tpl1) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS avg7d_tpl1_cum,
             co.avg7d_tpl60,
             SUM(co.avg7d_tpl60) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS avg7d_tpl60_cum,
             co.avg7d_tpl300,
             SUM(co.avg7d_tpl300) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS avg7d_tpl300_cum,
             co.pnl_current_day,
             SUM(COALESCE(co.pnl_current_day, 0)) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS pnl_usd_cum
         FROM combined co
     )

SELECT * FROM final_data
ORDER BY exchange_id, time_of_day;

--CREATE UNIQUE INDEX intraday_by_account_time_idx ON quicksight.intraday_by_account (account_id, exchange_id, time_of_day);

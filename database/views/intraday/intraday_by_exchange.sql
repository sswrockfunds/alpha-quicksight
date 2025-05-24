DROP MATERIALIZED VIEW IF EXISTS quicksight.intraday_by_exchange;

CREATE MATERIALIZED VIEW quicksight.intraday_by_exchange AS
WITH base AS (
    SELECT
        time_of_day,
        trading_day,
        exchange_id,
        SUM(turnover_usd) AS turnover_usd,
        SUM(tpl1_usd)     AS tpl1_usd,
        SUM(tpl60_usd)    AS tpl60_usd,
        SUM(tpl300_usd)   AS tpl300_usd
    FROM quicksight._tradingdata
    WHERE trading_day >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY trading_day, time_of_day, exchange_id
),

current_day AS (
    SELECT
        time_of_day,
        exchange_id,
        SUM(turnover_usd) AS turnover_current_day,
        SUM(tpl1_usd)     AS tpl1_current_day,
        SUM(tpl60_usd)    AS tpl60_current_day,
        SUM(tpl300_usd)   AS tpl300_current_day
    FROM base
    WHERE trading_day = CURRENT_DATE
    GROUP BY time_of_day, exchange_id
),

avg7d AS (
    SELECT
        time_of_day,
        exchange_id,
        ROUND(AVG(turnover_usd), 2) AS avg7d_turnover,
        ROUND(AVG(tpl1_usd), 2)     AS avg7d_tpl1,
        ROUND(AVG(tpl60_usd), 2)    AS avg7d_tpl60,
        ROUND(AVG(tpl300_usd), 2)   AS avg7d_tpl300
    FROM base
    GROUP BY time_of_day, exchange_id
),

combined AS (
    SELECT
        COALESCE(co.time_of_day, a.time_of_day) AS time_of_day,
        COALESCE(co.exchange_id, a.exchange_id) AS exchange_id,
        co.turnover_current_day,
        co.tpl1_current_day,
        co.tpl60_current_day,
        co.tpl300_current_day,
        a.avg7d_turnover,
        a.avg7d_tpl1,
        a.avg7d_tpl60,
        a.avg7d_tpl300
    FROM avg7d a
    FULL OUTER JOIN current_day co
      ON co.time_of_day = a.time_of_day AND co.exchange_id = a.exchange_id
),

final_data AS (
    SELECT
        co.exchange_id,
        m.market,
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
        SUM(co.avg7d_tpl300) OVER (PARTITION BY co.exchange_id ORDER BY co.time_of_day) AS avg7d_tpl300_cum
    FROM combined co
    JOIN cryptostruct.markets m ON co.exchange_id = m.exchange_id
)


SELECT * FROM final_data
ORDER BY exchange_id, market, time_of_day;

CREATE UNIQUE INDEX intraday_by_exchange_time_idx ON quicksight.intraday_by_exchange (exchange_id, market, time_of_day);

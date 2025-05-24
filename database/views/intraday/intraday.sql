DROP MATERIALIZED VIEW quicksight.intraday;
CREATE MATERIALIZED VIEW quicksight.intraday AS

WITH base AS (
    SELECT
        time_of_day,
        trading_day,
        SUM(turnover_usd) AS turnover_usd,
        SUM(tpl1_usd)     AS tpl1_usd,
        SUM(tpl60_usd)    AS tpl60_usd,
        SUM(tpl300_usd)   AS tpl300_usd
    FROM quicksight._tradingdata
    WHERE trading_day >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY trading_day, time_of_day
    ),

-- current day only
    current_day AS (
SELECT
    time_of_day,
    SUM(turnover_usd) AS turnover_current_day,
    SUM(tpl1_usd)     AS tpl1_current_day,
    SUM(tpl60_usd)    AS tpl60_current_day,
    SUM(tpl300_usd)   AS tpl300_current_day
FROM base
WHERE trading_day = CURRENT_DATE
GROUP BY time_of_day
    ),

-- 7-day average
    avg7d AS (
SELECT
    time_of_day,
    ROUND(AVG(turnover_usd), 2) AS avg7d_turnover,
    ROUND(AVG(tpl1_usd), 2)     AS avg7d_tpl1,
    ROUND(AVG(tpl60_usd), 2)    AS avg7d_tpl60,
    ROUND(AVG(tpl300_usd), 2)   AS avg7d_tpl300
FROM base
GROUP BY time_of_day
    ),

-- combine
    combined AS (
SELECT
    coalesce(co.time_of_day, a.time_of_day) as time_of_day,
    co.turnover_current_day,
    co.tpl1_current_day,
    co.tpl60_current_day,
    co.tpl300_current_day,
    a.avg7d_turnover,
    a.avg7d_tpl1,
    a.avg7d_tpl60,
    a.avg7d_tpl300
FROM avg7d a
    FULL OUTER JOIN current_day co ON co.time_of_day = a.time_of_day
    )

-- final with cumulative
SELECT
    time_of_day,
    turnover_current_day,
    SUM(turnover_current_day) OVER (ORDER BY time_of_day) AS turnover_current_day_cum,
    SUM(coalesce(co.tpl1_current_day, 0)) OVER (ORDER BY time_of_day) AS tpl1_current_cum,
    SUM(coalesce(co.tpl60_current_day, 0)) OVER (ORDER BY time_of_day) AS tpl60_current_cum,
    SUM(coalesce(co.tpl300_current_day, 0)) OVER (ORDER BY time_of_day) AS tpl300_current_cum,

    avg7d_turnover,
    SUM(avg7d_turnover) OVER (ORDER BY time_of_day) AS avg7d_turnover_cum,
    SUM(avg7d_tpl1) OVER (ORDER BY time_of_day) AS avg7d_tpl1_cum,
    SUM(avg7d_tpl60) OVER (ORDER BY time_of_day) AS avg7d_tpl60_cum,
    SUM(avg7d_tpl300) OVER (ORDER BY time_of_day) AS avg7d_tpl300_cum

FROM combined co
ORDER BY time_of_day;

CREATE UNIQUE INDEX intraday_time_idx ON quicksight.intraday (time_of_day);

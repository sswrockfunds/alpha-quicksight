DROP MATERIALIZED VIEW IF EXISTS quicksight.intraday_by_account;

CREATE MATERIALIZED VIEW quicksight.intraday_by_account AS
WITH base AS (
    SELECT
        time_of_day,
        trading_day,
        account_id,
        SUM(turnover_usd) AS turnover_usd,
        SUM(tpl1_usd)     AS tpl1_usd,
        SUM(tpl60_usd)    AS tpl60_usd,
        SUM(tpl300_usd)   AS tpl300_usd
    FROM quicksight.tradingdata_by_minute
    WHERE trading_day >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY trading_day, time_of_day, account_id
),

current_day AS (
    SELECT
        time_of_day,
        account_id,
        SUM(turnover_usd) AS turnover_current_day,
        SUM(tpl1_usd)     AS tpl1_current_day,
        SUM(tpl60_usd)    AS tpl60_current_day,
        SUM(tpl300_usd)   AS tpl300_current_day
    FROM base
    WHERE trading_day = CURRENT_DATE
    GROUP BY time_of_day, account_id
),

avg7d AS (
    SELECT
        time_of_day,
        account_id,
        ROUND(AVG(turnover_usd), 2) AS avg7d_turnover,
        ROUND(AVG(tpl1_usd), 2)     AS avg7d_tpl1,
        ROUND(AVG(tpl60_usd), 2)    AS avg7d_tpl60,
        ROUND(AVG(tpl300_usd), 2)   AS avg7d_tpl300
    FROM base
    GROUP BY time_of_day, account_id
),

combined AS (
    SELECT
        COALESCE(co.time_of_day, a.time_of_day) AS time_of_day,
        COALESCE(co.account_id, a.account_id) AS account_id,
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
      ON co.time_of_day = a.time_of_day AND co.account_id = a.account_id
),

final_data AS (
    SELECT
        co.account_id,
        a.exchange_id,
        a.account_name,
        co.time_of_day,
        co.turnover_current_day,
        SUM(co.turnover_current_day) OVER (PARTITION BY co.account_id ORDER BY co.time_of_day) AS turnover_current_day_cum,
        SUM(COALESCE(co.tpl1_current_day, 0)) OVER (PARTITION BY co.account_id ORDER BY co.time_of_day) AS tpl1_current_cum,
        SUM(COALESCE(co.tpl60_current_day, 0)) OVER (PARTITION BY co.account_id ORDER BY co.time_of_day) AS tpl60_current_cum,
        SUM(COALESCE(co.tpl300_current_day, 0)) OVER (PARTITION BY co.account_id ORDER BY co.time_of_day) AS tpl300_current_cum,
        co.avg7d_turnover,
        SUM(co.avg7d_turnover) OVER (PARTITION BY co.account_id ORDER BY co.time_of_day) AS avg7d_turnover_cum,
        co.avg7d_tpl1,
        SUM(co.avg7d_tpl1) OVER (PARTITION BY co.account_id ORDER BY co.time_of_day) AS avg7d_tpl1_cum,
        co.avg7d_tpl60,
        SUM(co.avg7d_tpl60) OVER (PARTITION BY co.account_id ORDER BY co.time_of_day) AS avg7d_tpl60_cum,
        co.avg7d_tpl300,
        SUM(co.avg7d_tpl300) OVER (PARTITION BY co.account_id ORDER BY co.time_of_day) AS avg7d_tpl300_cum
    FROM combined co
    JOIN account.current a ON co.account_id=a.account_id
)


SELECT * FROM final_data
ORDER BY account_id, exchange_id, market, time_of_day;

CREATE UNIQUE INDEX intraday_by_account_time_idx ON quicksight.intraday_by_account (account_id, exchange_id, market, time_of_day);

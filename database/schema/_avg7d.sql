DROP MATERIALIZED VIEW IF EXISTS quicksight._avg7d;

CREATE MATERIALIZED VIEW quicksight._avg7d AS

WITH base AS (
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
  		  sum(coalesce(e.pnl_usd,0))      as pnl_usd
    FROM quicksight._tradingdata t
    FULL OUTER JOIN quicksight._exposure e ON t.account_id=e.account_id AND t.trading_minute=e.trading_minute
    WHERE coalesce(t.trading_day,e.trading_day) >= CURRENT_DATE - INTERVAL '7 days'
      AND coalesce(t.trading_day,e.trading_day) < CURRENT_DATE
  GROUP BY coalesce(t.time_of_day,e.time_of_day),
           coalesce(t.trading_day,e.trading_day),
  				 coalesce(t.exchange_id,e.exchange_id),
           coalesce(t.account_id,e.account_id),
           coalesce(t.trading_minute,e.trading_minute)
),

avg7d AS (
    SELECT
        time_of_day,
  			MIN(trading_day) as trading_day_min,
  			MAX(trading_day) as trading_day_max,
  		  COUNT(DISTINCT trading_day) as trading_day_count,
  		  COUNT(*) as datasets,
        exchange_id,
  			account_id,
        ROUND(AVG(turnover_usd), 2) AS turnover,
        ROUND(AVG(tpl1_usd), 2)     AS tpl1,
        ROUND(AVG(tpl60_usd), 2)    AS tpl60,
        ROUND(AVG(tpl300_usd), 2)   AS tpl300,
  		  ROUND(AVG(pnl_usd), 2)   AS pnl
    FROM base
    WHERE trading_day < CURRENT_DATE
    GROUP BY time_of_day, exchange_id, account_id
  ORDER BY exchange_id, account_id, time_of_day asc
)

SELECT time_of_day,
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
FROM avg7d;

CREATE UNIQUE INDEX avg7d_idx ON quicksight._avg7d (account_id, exchange_id, time_of_day);
CREATE INDEX avg7d_by_account_idx ON quicksight._avg7d (account_id, time_of_day);
CREATE INDEX avg7d_by_exchange_idx ON quicksight._avg7d (exchange_id, time_of_day);

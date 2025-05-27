DROP MATERIALIZED VIEW IF EXISTS quicksight._current_day;

CREATE MATERIALIZED VIEW quicksight._current_day AS

WITH base AS (
    SELECT
        coalesce(t.time_of_day,e.time_of_day) as time_of_day,
        coalesce(t.trading_day,e.trading_day) as trading_day,
 				coalesce(t.exchange_id,e.exchange_id) as exchange_id,
        coalesce(t.account_id,e.account_id) as account_id,
  			coalesce(t.trading_minute,e.trading_minute) as trading_minute,
        sum(coalesce(t.turnover_usd,0)) as turnover,
        sum(coalesce(t.tpl1_usd,0))     as tpl1,
        sum(coalesce(t.tpl60_usd,0))    as tpl60,
        sum(coalesce(t.tpl300_usd,0))   as tpl300,
  		  sum(coalesce(e.pnl_usd,0))      as pnl
    FROM quicksight._tradingdata t
    FULL OUTER JOIN quicksight._exposure e ON t.account_id=e.account_id AND t.trading_minute=e.trading_minute
    WHERE coalesce(t.trading_day,e.trading_day) = CURRENT_DATE
  GROUP BY coalesce(t.time_of_day,e.time_of_day),
           coalesce(t.trading_day,e.trading_day),
  				 coalesce(t.exchange_id,e.exchange_id),
           coalesce(t.account_id,e.account_id),
           coalesce(t.trading_minute,e.trading_minute)
)

SELECT time_of_day,
       trading_day,
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
FROM base;

CREATE UNIQUE INDEX current_day_idx ON quicksight._current_day (account_id, exchange_id, time_of_day);
CREATE INDEX current_day_by_account_idx ON quicksight._current_day (account_id, time_of_day);
CREATE INDEX current_day_by_exchange_idx ON quicksight._current_day (exchange_id, time_of_day);

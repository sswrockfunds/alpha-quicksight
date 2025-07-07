DROP MATERIALIZED VIEW IF EXISTS quicksight.intraday_by_account;
CREATE MATERIALIZED VIEW quicksight.intraday_by_account AS

SELECT trading_minute AS trading_ts,
       trading_day,
       time_of_day,
       account_id,
       exchange_id,
       updated_ts,
       -- current_day
       turnover,
       tpl1,
       tpl300,
       tpl60,
       pnl,
       -- current_day cummulated
       turnover_cum,
       tpl1_cum,
       tpl60_cum,
       tpl300_cum,
       pnl_cum,
       -- avg7d cummulated
       turnover_avg7d_cum,
       tpl1_avg7d_cum,
       tpl60_avg7d_cum,
       tpl300_avg7d_cum,
       pnl_avg7d_cum
FROM performance.minute
WHERE trading_day=CURRENT_DATE;


CREATE UNIQUE INDEX intraday_by_account_idx ON quicksight.intraday_by_account (account_id, trading_ts);

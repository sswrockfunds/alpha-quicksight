DROP MATERIALIZED VIEW IF EXISTS quicksight.intraday_by_account;
CREATE MATERIALIZED VIEW quicksight.intraday_by_account AS

SELECT trading_minute AS trading_ts,
       trading_day,
       time_of_day,
       account_id,
       exchange_id,
       max(updated_ts) as updated_ts,
       -- current_day
       sum(turnover) as turnover,
       sum(tpl1)     as tpl1,
       sum(tpl60)    as tpl30,
       sum(tpl300)   as tpl60,
       sum(pnl)      as pnl,
       -- current_day cummulated
       sum(turnover_cum) as turnover_cum,
       sum(tpl1_cum)     as tpl1_cum,
       sum(tpl60_cum)    as tpl60_cum,
       sum(tpl300_cum)   as tpl300_cum,
       sum(pnl_cum)      as pnl_cum,
       -- avg7d cummulated
       sum(turnover_avg7d_cum) as turnover_avg7d_cum,
       sum(tpl1_avg7d_cum)     as tpl1_avg7d_cum,
       sum(tpl60_avg7d_cum)    as tpl60_avg7d_cum,
       sum(tpl300_avg7d_cum)   as tpl300_avg7d_cum,
       sum(pnl_avg7d_cum)      as pnl_avg7d_cum
FROM performance.minute
WHERE trading_day=CURRENT_DATE
GROUP BY trading_minute, trading_day, time_of_day, account_id, exchange_id;


CREATE UNIQUE INDEX intraday_by_account_idx ON quicksight.intraday_by_account (account_id, trading_ts);

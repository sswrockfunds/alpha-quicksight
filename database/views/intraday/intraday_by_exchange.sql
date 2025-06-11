DROP MATERIALIZED VIEW IF EXISTS quicksight.intraday_by_exchange;
CREATE MATERIALIZED VIEW quicksight.intraday_by_exchange AS

SELECT concat(CURRENT_DATE, ' ', coalesce(c.time_of_day, a.time_of_day))::timestamp AS trading_ts,
       coalesce(c.trading_day, CURRENT_DATE) as trading_day,
       coalesce(c.time_of_day, a.time_of_day) as time_of_day,
       coalesce(c.exchange_id, a.exchange_id) as exchange_id,
       c.updated_ts,
       -- current_day
       sum(c.turnover) as turnover,
       sum(c.tpl1)     as tpl1,
       sum(c.tpl60)    as tpl30,
       sum(c.tpl300)   as tpl60,
       sum(c.pnl)      as pnl,
       -- current_day cummulated
       sum(c.turnover_cum) as turnover_cum,
       sum(c.tpl1_cum)     as tpl1_cum,
       sum(c.tpl60_cum)    as tpl60_cum,
       sum(c.tpl300_cum)   as tpl300_cum,
       sum(c.pnl_cum)      as pnl_cum,
       -- avg7d cummulated
       sum(a.turnover_avg7d_cum) as turnover_avg7d_cum,
       sum(a.tpl1_avg7d_cum)     as tpl1_avg7d_cum,
       sum(a.tpl60_avg7d_cum)    as tpl60_avg7d_cum,
       sum(a.tpl300_avg7d_cum)   as tpl300_avg7d_cum,
       sum(a.pnl_avg7d_cum)      as pnl_avg7d_cum
FROM quicksight._current_day c
FULL OUTER JOIN quicksight._avg7d a ON c.time_of_day=a.time_of_day AND c.account_id=a.account_id
GROUP BY c.trading_day,
         c.time_of_day, a.time_of_day,
         c.exchange_id, a.exchange_id,
         c.updated_ts;

CREATE UNIQUE INDEX intraday_by_exchange_idx ON quicksight.intraday_by_exchange ( exchange_id, trading_ts, time_of_day);

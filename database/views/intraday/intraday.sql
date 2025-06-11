DROP MATERIALIZED VIEW IF EXISTS  quicksight.intraday;
CREATE MATERIALIZED VIEW quicksight.intraday AS

SELECT concat(coalesce(c.trading_day, a.trading_day), ' ', coalesce(c.time_of_day, a.time_of_day))::timestamp AS trading_ts,
       coalesce(c.trading_day, a.trading_day) as trading_day,
       coalesce(c.time_of_day, a.time_of_day) as time_of_day,
       coalesce(c.updated_ts, CURRENT_TIMESTAMP::timestamp(3)) as updated_ts,
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
         FULL OUTER JOIN (
    SELECT CURRENT_DATE as trading_day, * FROM quicksight._avg7d
) a ON c.trading_day=a.trading_day AND c.time_of_day=a.time_of_day AND c.account_id=a.account_id
GROUP BY coalesce(c.trading_day, a.trading_day),
         coalesce(c.time_of_day, a.time_of_day),
         coalesce(c.updated_ts, CURRENT_TIMESTAMP::timestamp(3));

--SELECT trading_ts, time_of_day, count(*)
--FROM quicksight.intraday
--GROUP BY 1,2
--HAVING count(*) > 1;

--SELECT * FROM quicksight.intraday WHERE trading_ts='2025-06-11 21:07:00'

CREATE UNIQUE INDEX intraday_time_idx ON quicksight.intraday (trading_ts, time_of_day);

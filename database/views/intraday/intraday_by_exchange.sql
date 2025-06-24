DROP MATERIALIZED VIEW IF EXISTS quicksight.intraday_by_exchange;
CREATE MATERIALIZED VIEW quicksight.intraday_by_exchange AS

SELECT p.trading_minute AS trading_ts,
       p.trading_day,
       p.time_of_day,
       p.exchange_id,
       m.market,
       max(p.updated_ts) as updated_ts,
       -- current_day
       sum(p.turnover) as turnover,
       sum(p.tpl1)     as tpl1,
       sum(p.tpl60)    as tpl30,
       sum(p.tpl300)   as tpl60,
       sum(p.pnl)      as pnl,
       -- current_day cummulated
       sum(p.turnover_cum) as turnover_cum,
       sum(p.tpl1_cum)     as tpl1_cum,
       sum(p.tpl60_cum)    as tpl60_cum,
       sum(p.tpl300_cum)   as tpl300_cum,
       sum(p.pnl_cum)      as pnl_cum,
       -- avg7d cummulated
       sum(p.turnover_avg7d_cum) as turnover_avg7d_cum,
       sum(p.tpl1_avg7d_cum)     as tpl1_avg7d_cum,
       sum(p.tpl60_avg7d_cum)    as tpl60_avg7d_cum,
       sum(p.tpl300_avg7d_cum)   as tpl300_avg7d_cum,
       sum(p.pnl_avg7d_cum)      as pnl_avg7d_cum
FROM performance.minute p
LEFT JOIN cryptostruct.markets m ON m.exchange_id=p.exchange_id
WHERE p.trading_day=CURRENT_DATE
GROUP BY p.trading_minute, p.exchange_id, m.market, p.trading_day, p.time_of_day;

CREATE UNIQUE INDEX intraday_by_exchange_idx ON quicksight.intraday_by_exchange ( exchange_id, trading_ts);

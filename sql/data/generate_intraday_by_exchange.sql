with

script_input as (
    {script_input}
-- SELECT CURRENT_DATE as ref_day
),

insert_data as (

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
     JOIN script_input pp ON  p.trading_day=pp.ref_day
    GROUP BY p.trading_minute, p.exchange_id, m.market, p.trading_day, p.time_of_day

)

INSERT INTO performance.intraday_by_exchange as i (
    trading_ts,
    trading_day,
    time_of_day,
    exchange_id,
    market,
    updated_ts,
    turnover,
    tpl1,
    tpl60,
    tpl300,
    pnl,
    turnover_cum,
    tpl1_cum,
    tpl60_cum,
    tpl300_cum,
    pnl_cum,
    turnover_avg7d_cum,
    tpl1_avg7d_cum,
    tpl60_avg7d_cum,
    tpl300_avg7d_cum,
    pnl_avg7d_cum
)

SELECT * FROM insert_data

ON CONFLICT (exchange_id, trading_ts) DO UPDATE SET
     updated_ts = EXCLUDED.updated_ts,
     turnover = EXCLUDED.turnover,
     tpl1 = EXCLUDED.tpl1,
     tpl60 = EXCLUDED.tpl60,
     tpl300 = EXCLUDED.tpl300,
     pnl = EXCLUDED.pnl,
     turnover_cum = EXCLUDED.turnover_cum,
     tpl1_cum = EXCLUDED.tpl1_cum,
     tpl60_cum = EXCLUDED.tpl60_cum,
     tpl300_cum = EXCLUDED.tpl300_cum,
     pnl_cum = EXCLUDED.pnl_cum,
     turnover_avg7d_cum = EXCLUDED.turnover_avg7d_cum,
     tpl1_avg7d_cum = EXCLUDED.tpl1_avg7d_cum,
     tpl60_avg7d_cum = EXCLUDED.tpl60_avg7d_cum,
     tpl300_avg7d_cum = EXCLUDED.tpl300_avg7d_cum,
     pnl_avg7d_cum = EXCLUDED.pnl_avg7d_cum
WHERE i.turnover_cum != EXCLUDED.turnover_cum OR i.turnover_avg7d_cum IS NULL;

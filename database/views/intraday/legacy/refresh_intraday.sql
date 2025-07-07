with insert_data as (

    SELECT trading_minute AS trading_ts,
           trading_day,
           time_of_day,
           max(updated_ts) as updated_ts,
           -- current_day
           sum(turnover) as turnover,
           sum(tpl1)     as tpl1,
           sum(tpl60)    as tpl60,
           sum(tpl300)   as tpl300,
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
    GROUP BY trading_minute, trading_day, time_of_day

)

INSERT INTO performance.intraday as i(
    trading_ts,
    trading_day,
    time_of_day,
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

ON CONFLICT (trading_ts) DO UPDATE SET
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
WHERE i.turnover_cum != EXCLUDED.turnover_cum;

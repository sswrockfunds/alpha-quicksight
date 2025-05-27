-- tradingdata_by_minute


with script_input as(
   {script_input}
),

     trades_by_minute as(
         SELECT trade_date as trading_day,
                date_trunc('minute', trade_ts) as trading_minute,
                date_trunc('minute', trade_ts)::TIME as time_of_day,
             i.exchange_id,
                t.*,
                p.now
         FROM alpha.trades t
                  JOIN cryptostruct.instruments i ON t.instrument_id=i.instrument_id
                  JOIN script_input p ON t.trade_ts>=p.start
                                     AND t.trade_ts<p.end
     ),
     insert_data as(

         SELECT to_char(trading_minute, 'YYYY-MM') AS trading_month,   -- trading_month: YYYY-MM string
                to_char(trading_minute, 'IYYY-"W"IW') AS trading_week, -- trading_week: ISO week (e.g., 2025-W17)
                trading_day,
                date_trunc('hour', trading_minute) AS trading_hour,    -- trading_hour: timestamp rounded to the hour
                trading_minute,
                time_of_day,
                exchange_id,
                account_id,
                round(-sum(coalesce(fees_usd,0)) + sum(coalesce(turnover_usd,0)), 2) as turnover_usd,
                round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl1_usd,0)), 2) as tpl1_usd,
                round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl10_usd,0)), 2) as tpl10_usd,
                round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl30_usd,0)), 2) as tpl30_usd,
                round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl60_usd,0)), 2) as tpl60_usd,
                round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl300_usd,0)), 2) as tpl300_usd,
                round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl900_usd,0)), 2) as tpl900_usd,
                count(*) as trade_count,
                now as updated_ts
         FROM trades_by_minute t
         GROUP BY trading_day, trading_minute, time_of_day, exchange_id, account_id, now
     )


INSERT INTO quicksight._tradingdata
        SELECT * FROM insert_data
ON CONFLICT (trading_minute, account_id)
DO UPDATE SET
    turnover_usd = EXCLUDED.turnover_usd,
    tpl1_usd = EXCLUDED.tpl1_usd,
    tpl10_usd = EXCLUDED.tpl10_usd,
    tpl30_usd = EXCLUDED.tpl30_usd,
    tpl60_usd = EXCLUDED.tpl60_usd,
    tpl300_usd = EXCLUDED.tpl300_usd,
    tpl900_usd = EXCLUDED.tpl900_usd,
    trade_count = EXCLUDED.trade_count,
    updated_ts = EXCLUDED.updated_ts
;

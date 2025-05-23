-- tradingdata_by_minute


with script_input as(
    SELECT '2025-05-23'::timestamp as "day",
        '2025-05-20'::timestamp as "start",
        '2025-05-21'::timestamp as "end",
            CURRENT_TIMESTAMP::timestamp as "now"
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
                  JOIN script_input p ON t.trade_ts>=p.day AND t.trade_ts<(p.day + Interval '1 day')
     ),
     insert_data as(

         SELECT trading_day,
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


INSERT INTO quicksight.tradingdata_by_minute
SELECT * FROM insert_data
    ON CONFLICT (trading_minute, account_id) DO NOTHING;

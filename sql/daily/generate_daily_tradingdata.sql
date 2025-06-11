-- tradingdata_by_minute


with

    script_input as ( {script_input} ),

    trades_by_day as (
        SELECT trade_date as trading_day,
               to_char(trade_date, 'YYYY-MM')    as trading_month,   -- trading_month: YYYY-MM string
               to_char(trade_date, 'IYYY-"W"IW') as trading_week,    -- trading_week: ISO week (e.g., 2025-W17)
               t.*
        FROM alpha.trades t
                 JOIN cryptostruct.instruments i ON t.instrument_id=i.instrument_id
                 JOIN script_input p ON t.trade_ts>=p.start
                                    AND t.trade_ts<p.end
                                    AND t.trade_ts<p.cut_off
    ),

    insert_data as (
        SELECT trading_month,   -- trading_month: YYYY-MM string
               trading_week, -- trading_week: ISO week (e.g., 2025-W17)
               trading_day,
               DATE_PART('year',  trading_day) as year_num,
               DATE_PART('month', trading_day) as month_num,
               DATE_PART('day',   trading_day) as day_num,
               account_id,
               round(-sum(coalesce(fees_usd,0)) + sum(coalesce(turnover_usd,0)), 2) as turnover_usd,
               round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl1_usd,0)), 2)     as tpl1_usd,
               round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl10_usd,0)), 2)    as tpl10_usd,
               round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl30_usd,0)), 2)    as tpl30_usd,
               round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl60_usd,0)), 2)    as tpl60_usd,
               round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl300_usd,0)), 2)   as tpl300_usd,
               round(-sum(coalesce(fees_usd,0)) + sum(coalesce(tpl900_usd,0)), 2)   as tpl900_usd,
               count(*) as trade_count,
               CURRENT_TIMESTAMP::timestamp(0) as updated_ts
        FROM trades_by_day t
        GROUP BY trading_month, trading_week, trading_day,
                 account_id, updated_ts
    )

INSERT INTO quicksight._history(
  							trading_month, trading_week, trading_day,
  						  year_num, month_num, day_num,
  							account_id,
  							turnover_usd, tpl1_usd, tpl10_usd, tpl30_usd, tpl60_usd, tpl300_usd, tpl900_usd,
  							trade_count,
  							updated_ts
						)
SELECT * FROM insert_data
    ON CONFLICT (trading_day, account_id)
DO UPDATE SET
    turnover_usd = EXCLUDED.turnover_usd,
           tpl1_usd = EXCLUDED.tpl1_usd,
           tpl10_usd = EXCLUDED.tpl10_usd,
           tpl30_usd = EXCLUDED.tpl30_usd,
           tpl60_usd = EXCLUDED.tpl60_usd,
           tpl300_usd = EXCLUDED.tpl300_usd,
           tpl900_usd = EXCLUDED.tpl900_usd,
           trade_count = EXCLUDED.trade_count,
           updated_ts = EXCLUDED.updated_ts;



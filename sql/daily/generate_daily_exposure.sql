WITH

    script_input as ( {script_input} ),

    insert_data as (
        SELECT to_char(e.trading_date, 'YYYY-MM')    as trading_month,   -- trading_month: YYYY-MM string
               to_char(e.trading_date, 'IYYY-"W"IW') as trading_week,    -- trading_week: ISO week (e.g., 2025-W17)
               e.trading_date as trading_day,
               DATE_PART('year',  e.trading_date) as year_num,
               DATE_PART('month', e.trading_date) as month_num,
               DATE_PART('day',   e.trading_date) as day_num,
               e.account_id,
               round(sum(e.backend_balance_usd), 2) as exposure_usd,
               coalesce(round(sum(e.backend_balance_usd) FILTER (WHERE e.underlying_type NOT IN ('fiat','stable_coin')), 2), 0.00) as exposure_usd,
               CURRENT_TIMESTAMP::timestamp(3) as updated_ts
        FROM exposure.underlying_positions e
                 JOIN script_input p ON e.trading_date>=p.start AND e.trading_date<=p.end
        GROUP BY to_char(trading_date, 'YYYY-MM'),
                 to_char(trading_date, 'IYYY-"W"IW'),
                 trading_date,
                 account_id
    )


INSERT INTO quicksight._history(
  							trading_month, trading_week, trading_day,
  						  year_num, month_num, day_num,
  							account_id,
  							exposure_usd,
  						  crypto_exposure_usd,
  							updated_ts
						)
SELECT * FROM insert_data
    ON CONFLICT (trading_day, account_id)
DO UPDATE SET
    exposure_usd = EXCLUDED.exposure_usd,
           crypto_exposure_usd = EXCLUDED.crypto_exposure_usd,
           updated_ts = EXCLUDED.updated_ts;


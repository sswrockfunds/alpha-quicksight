WITH

script_input as ( {script_input} ),

    exposure_start_of_day AS (
SELECT e.account_id,
    e.trading_day::date as prey_day,
    (e.trading_day + INTERVAL '1 day')::date AS trading_day,
    e.exposure_usd AS exposure_usd_sod
FROM performance.daily e
    JOIN script_input p ON e.trading_day >= (p.start - Interval '1 day')
    AND e.trading_day < p.end
    ),

    pnl as (
SELECT c.trading_day,
    c.account_id,
    coalesce(e.exposure_usd_sod, 0)  as sod_exposure,
    coalesce(c.exposure_usd, 0)      as eod_exposure,
    ABS(COALESCE(c.deposit_usd, 0))  as deposit,
    ABS(COALESCE(c.withdraw_usd, 0)) as withdraw
FROM performance.daily c
    JOIN script_input p ON c.trading_day >= p.start::date AND c.trading_day <= p.end::date
    LEFT JOIN exposure_start_of_day e ON c.trading_day=e.trading_day AND c.account_id=e.account_id
    )

-- Update the pnl using the exposure of the previous day as start of day exposure
UPDATE performance.daily h
SET pnl_usd = ROUND(eod_exposure - sod_exposure + withdraw - deposit, 2)
    FROM pnl p
WHERE h.account_id = p.account_id
  AND h.trading_day = p.trading_day;

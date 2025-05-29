WITH
    script_input as (
        SELECT '2025-05-01'::date as "start",
               '2025-05-29'::date as "end"
    ),

    transfer_data AS (
        SELECT t.transfer_ts::date                  as trading_day,
            t.from_account_id,
               t.to_account_id,
               t.underlying_id,
               t.amount,
               t.usd_value,
               t.fees_usd
        FROM account.transfer t
                 JOIN script_input p ON t.transfer_ts::date>=p.start AND t.transfer_ts::date<=p.end
    ),

    deposit_data AS (
SELECT trading_day,
    to_account_id  as account_id,
    sum(usd_value) as deposit_usd
FROM transfer_data
GROUP BY trading_day, to_account_id
    ),

    withdraw_data AS (
SELECT trading_day,
    from_account_id AS account_id,
    sum(usd_value) AS withdraw_usd,
    sum(fees_usd) AS fees_usd
FROM transfer_data
GROUP BY trading_day, from_account_id
    ),

    cashflow AS (
SELECT coalesce(d.trading_day, w.trading_day) as trading_day,
    coalesce(d.account_id, w.account_id) as account_id,
    d.deposit_usd,
    w.withdraw_usd + w.fees_usd as withdraw_usd
FROM deposit_data d
    FULL OUTER JOIN withdraw_data w ON d.trading_day=w.trading_day
    AND d.account_id=w.account_id
    )

SELECT * FROM cashflow

UPDATE quicksight._history h
SET deposit_usd = c.deposit_usd,
    withdraw_usd = c.withdraw_usd
    FROM cashflow c
WHERE h.trading_day = c.trading_day
  AND h.account_id = c.account_id;

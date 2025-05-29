with
script_input as ( {script_input} ),
account_data as (
    SELECT *
    FROM account.history a
    JOIN script_input p ON a.trading_day >= p.start AND a.trading_day <= p.end
)

UPDATE quicksight._history h
SET exchange_id = a.exchange_id,
    account_id = a.account_id,
    account_type = a.account_type,
    counter_underlying = a.counter_underlying,
    strategy = a.strategy,
    instrument_type = a.instrument_type,
    custody = a.custody,
    owner = a.owner
    FROM account_data a
WHERE h.trading_day = a.trading_day
  AND h.account_id = a.account_id;

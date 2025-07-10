DROP MATERIALIZED VIEW IF EXISTS  performance.account_summary;
CREATE MATERIALIZED VIEW performance.account_summary AS


with
    script_input as (
        --SELECT '2025-06-25'::date as ref_date
        SELECT CURRENT_DATE as ref_date,
               CURRENT_DATE - INTERVAL '1 day' as pref_date
    ),

-- Trading Performance
    trading as (
SELECT trading_day,
    account_id,
    exchange_id,
    sum(turnover_usd) as turnover,
    sum(tpl1_usd) as tpl1,
    sum(tpl10_usd) as tpl10,
    sum(tpl30_usd) as tpl30,
    sum(tpl60_usd) as tpl60,
    sum(tpl300_usd) as tpl300,
    sum(tpl900_usd) as tpl900,
    sum(trade_count) as trade_count
FROM performance.minute_tradingdata
WHERE trading_day=(SELECT ref_date FROM script_input)
GROUP BY trading_day, account_id, exchange_id
    ),

    exposure_ts as (
SELECT p.ref_date as trading_day,
    e.account_id,
    max(e.trading_minute) FILTER (WHERE trading_day = p.pref_date) as min_ts,
    max(e.trading_minute) FILTER (WHERE trading_day = p.ref_date) as max_ts
FROM performance.minute_exposure e
    JOIN script_input p ON e.trading_day IN (p.ref_date, p.pref_date)
GROUP BY p.ref_date, e.account_id
    ),

    exposure as (
SELECT e.trading_day,
    e.account_id,
    e.exchange_id,
       max(t.max_ts) as exposure_ts,
    max(t.balance_open) as balance_open,
    max(t.balance_close) as balance_close,
    min(e.balance_usd) as balance_low,
    max(e.balance_usd) as balance_high
FROM performance.minute_exposure e
    JOIN (
    SELECT et.*, o.balance_usd as balance_open, c.balance_usd as balance_close, c.crypto_usd as crypto_exposure
    FROM exposure_ts et
    LEFT JOIN performance.minute_exposure o ON o.trading_minute=et.min_ts AND o.account_id=et.account_id
    LEFT JOIN performance.minute_exposure c ON c.trading_minute=et.max_ts AND c.account_id=et.account_id
    ) t ON t.trading_day=e.trading_day AND t.account_id=e.account_id
--   WHERE trading_day=(SELECT ref_date FROM script_input)
GROUP BY e.trading_day, e.account_id, e.exchange_id
    ),

-- Transfers
    transfer_in as (
SELECT transfer_ts::date as trading_day,
    to_account_id as account_id,
    sum(usd_value) as deposit
FROM account.transfer
WHERE transfer_ts::date=(SELECT ref_date FROM script_input)
GROUP BY transfer_ts::date, to_account_id
    ),
    transfer_out as (
SELECT transfer_ts::date as trading_day,
    from_account_id as account_id,
    sum(usd_value) as withdraw
FROM account.transfer
WHERE transfer_ts::date=(SELECT ref_date FROM script_input)
GROUP BY transfer_ts::date, from_account_id
    ),
    net_transfer as (
SELECT coalesce(i.account_id, o.account_id) as account_id,
    i.deposit as deposit,
    -o.withdraw as withdraw,
    round(coalesce(i.deposit,0) - coalesce(o.withdraw,0),2) as transfer_net
FROM transfer_in i
    FULL OUTER JOIN transfer_out o ON i.account_id=o.account_id AND i.trading_day=o.trading_day
    ),

    current_instances as (
SELECT account_id,
    count(*) FILTER (WHERE state = 'RUNNING') as running,
    count(*) FILTER (WHERE state = 'CONFIGURED') as configured,
    count(*) FILTER (WHERE state NOT IN ('RUNNING','CONFIGURED')) as stopped
FROM live.strategy_instances WHERE request_ts > (select max(request_ts) - Interval '3 minute' FROM live.strategy_instances)
GROUP BY account_id
    )

-- Combine everything
SELECT e.trading_day, e.account_id, e.exchange_id,
       (e.balance_close - e.balance_open - coalesce(t.transfer_net,0)) as pnl,
       e.balance_low, e.balance_high, e.balance_open, e.balance_close, e.exposure_ts,
       t.deposit, t.withdraw, t.transfer_net,
       p.turnover, p.tpl1,p.tpl10,p.tpl30,p.tpl60,p.tpl300,p.tpl900,p.trade_count,
       ci.running, ci.configured, ci.stopped,
       a.account_name, a.account_type, a.instrument_type, a.counter_underlying, a.server, a.strategy
FROM exposure e
         LEFT JOIN trading p ON e.account_id=p.account_id AND e.trading_day=p.trading_day
         LEFT JOIN net_transfer t ON t.account_id=e.account_id
         LEFT JOIN account.history a ON e.account_id=a.account_id AND e.trading_day=a.trading_day
         LEFT JOIN current_instances ci ON e.account_id=ci.account_id;


CREATE UNIQUE INDEX account_summary_idx ON performance.account_summary (account_id);

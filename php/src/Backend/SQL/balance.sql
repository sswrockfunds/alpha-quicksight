WITH latest as
         (
             SELECT account_id, underlying_id, wallet, exposure, MAX(ts) AS ts
             FROM positions__underlyings
             WHERE ts <= '{cutOffTimestamp}'
             GROUP BY account_id, underlying_id, wallet, exposure
         )

SELECT '{cutOffTimestamp}' as ts,
       pu.last_seen_ts,
       pu.account_id,
       a.exchange_id,
       pu.underlying_id,
       pu.margin_balance,
       pu.wallet
FROM latest l
JOIN positions__underlyings pu USING (account_id, underlying_id, wallet, exposure, ts)
JOIN accounts a ON pu.account_id=a.account_id
WHERE abs(pu.margin_balance) > 0
  AND underlying_id > 0

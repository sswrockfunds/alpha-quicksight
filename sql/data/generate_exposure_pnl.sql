UPDATE quicksight._exposure e
SET pnl_usd = sub.pnl_usd
FROM (
  SELECT
    ctid,
    balance_usd - LAG(balance_usd) OVER (
      PARTITION BY exchange_id, account_id
      ORDER BY trading_minute
    ) AS pnl_usd
  FROM quicksight._exposure
) sub
WHERE e.pnl_usd is null AND e.ctid = sub.ctid;


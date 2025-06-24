-- Update the exchange data in daily performance stats
UPDATE performance.daily h
SET exchange_id = a.exchange_id
    FROM (
        SELECT account_id, exchange_id
          FROM account.history
      GROUP BY account_id, exchange_id
    ) as a
WHERE h.exchange_id IS NULL AND h.account_id = a.account_id;

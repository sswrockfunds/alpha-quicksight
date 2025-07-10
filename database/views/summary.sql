DROP VIEW quicksight.summary;
CREATE VIEW quicksight.summary as

WITH
    latest_data as (
        SELECT exchange_id,
               max(trading_ts) as trading_ts
        FROM quicksight.intraday_by_exchange
        WHERE pnl is NOT NULL
        GROUP BY exchange_id
    ),
    latest_exposure as (
        SELECT e.exchange_id,
               sum(e.balance_usd) as exposure_usd,
               sum(e.crypto_usd) as crypto_exposure_usd
        FROM performance.minute_exposure e
                 JOIN latest_data l ON e.exchange_id=l.exchange_id AND e.trading_minute=l.trading_ts
        GROUP BY e.exchange_id
    )

SELECT i.trading_ts,
       i.exchange_id,
       i.market,
       m.vendor,

       le.exposure_usd,
       le.crypto_exposure_usd,

       i.pnl_cum as pnl,
       i.turnover_cum as turnover,
       i.tpl1_cum as tpl1,
       i.tpl60_cum as tpl60,
       i.tpl300_cum as tpl300,

       i.pnl_avg7d_cum as pnl_avg7d,
       i.turnover_avg7d_cum as turnover_avg7d,
       i.tpl1_avg7d_cum as tpl1_avg7d,
       i.tpl60_avg7d_cum as tpl60_avg7d,
       i.tpl300_avg7d_cum as tpl300_avg7d,

       i.updated_ts
FROM quicksight.intraday_by_exchange i
         JOIN latest_data l ON i.exchange_id=l.exchange_id AND i.trading_ts=l.trading_ts
         LEFT JOIN latest_exposure le ON le.exchange_id=i.exchange_id
         LEFT JOIN cryptostruct.markets m ON i.exchange_id=m.exchange_id
WHERE le.exposure_usd > 1000 or i.turnover_cum > 0
ORDER BY le.exposure_usd DESC


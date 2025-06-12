CREATE OR REPLACE VIEW
  "quicksight"."weekly_by_exchange" AS

WITH last_days AS (
    SELECT
        trading_week,
        max(trading_day) AS last_trading_day
    FROM quicksight._history
    GROUP BY trading_week
)
SELECT
    h.trading_week,
    h.exchange_id,
    m.market,
    sum(CASE WHEN h.trading_day = ld.last_trading_day THEN h.exposure_usd END) AS exposure_usd,
    sum(CASE WHEN h.trading_day = ld.last_trading_day THEN h.crypto_exposure_usd END) AS crypto_exposure_usd,

    sum(h.deposit_usd) AS deposit_usd,
    sum(h.withdraw_usd) AS withdraw_usd,
    sum(h.pnl_usd) AS pnl_usd,
    sum(h.turnover_usd) AS turnover_usd,
    sum(h.tpl1_usd) AS tpl1_usd,
    sum(h.tpl10_usd) AS tpl10_usd,
    sum(h.tpl30_usd) AS tpl30_usd,
    sum(h.tpl60_usd) AS tpl60_usd,
    sum(h.tpl300_usd) AS tpl300_usd,
    sum(h.tpl900_usd) AS tpl900_usd,
    sum(h.trade_count) AS trade_count
FROM quicksight._history h
         LEFT JOIN cryptostruct.markets m ON h.exchange_id = m.exchange_id
         JOIN last_days ld ON h.trading_week = ld.trading_week
GROUP BY
    h.trading_week,
    h.exchange_id,
    m.market;

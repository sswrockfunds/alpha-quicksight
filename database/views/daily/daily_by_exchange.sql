CREATE OR REPLACE VIEW
  "quicksight"."daily_by_exchange" AS
SELECT
    h.trading_month,
    h.trading_week,
    h.trading_day,
    h.year_num,
    h.month_num,
    h.day_num,
    h.exchange_id,
    m.market,
    sum(h.exposure_usd) AS exposure_usd,
    sum(h.crypto_exposure_usd) AS crypto_exposure_usd,
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
FROM
    performance.daily h
    LEFT JOIN cryptostruct.markets m ON h.exchange_id = m.exchange_id
GROUP BY
    h.trading_month,
    h.trading_week,
    h.trading_day,
    h.year_num,
    h.month_num,
    h.day_num,
    h.exchange_id,
    m.market;

DROP MATERIALIZED VIEW quicksight.intraday_top_instruments;
CREATE MATERIALIZED VIEW quicksight.intraday_top_instruments AS

WITH
-- Directly on trades // if necessary, switch to already aggregated data
top20_instruments as (
    SELECT CURRENT_DATE as trading_day,
           instrument_id,
           round(sum(coalesce(turnover_usd,0)), 2) as turnover_usd,
           round(sum(coalesce(tpl1_usd,0)), 2) as tpl1_usd,
           round(sum(coalesce(tpl60_usd,0)), 2) as tpl60_usd,
           round(sum(coalesce(tpl300_usd,0)), 2) as tpl300_usd,
           round(sum(coalesce(fees_usd,0)), 2) as fees_usd,
           count(*) as trade_count
    FROM alpha.trades
    WHERE trade_ts>=CURRENT_DATE
    GROUP BY instrument_id
    ORDER BY sum(turnover_usd) DESC
    LIMIT 100
)

SELECT t.trading_day,
       i.instrument_id, i.symbol, i.type,
       i.market, i.exchange_id,
       t.turnover_usd,
       t.trade_count,
       t.tpl1_usd - t.fees_usd as tpl1_usd,
       t.tpl60_usd - t.fees_usd as tpl60_usd,
       t.tpl300_usd - t.fees_usd as tpl300_usd,
       s.turnover_value_usd as public_turnover_usd,
       s.trades_count as public_trade_count,
       CASE
           WHEN s.turnover_value_usd IS NULL OR s.turnover_value_usd = 0 THEN NULL
           ELSE round(t.turnover_usd / s.turnover_value_usd * 100, 3)
       END as marketshare_pct,
       CURRENT_TIMESTAMP as updated_ts
  FROM top20_instruments t
  JOIN cryptostruct.instruments i ON t.instrument_id=i.instrument_id
  LEFT JOIN cryptostruct.instruments_stats_daily s ON t.trading_day=s.day AND t.instrument_id=s.instrument_id
ORDER BY s.turnover_value_usd desc;

CREATE UNIQUE INDEX ON quicksight.intraday_top_instruments (instrument_id);

DELETE FROM performance.intraday_by_exchange WHERE trading_day<CURRENT_DATE - Interval '7 day'

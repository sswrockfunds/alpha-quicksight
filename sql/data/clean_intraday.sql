DELETE FROM performance.intraday WHERE trading_day<CURRENT_DATE - Interval '7 day'

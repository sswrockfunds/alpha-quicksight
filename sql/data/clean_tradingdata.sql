DELETE FROM performance.minute_tradingdata WHERE trading_minute<CURRENT_DATE - Interval '15 day'

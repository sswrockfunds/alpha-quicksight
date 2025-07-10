DELETE FROM performance.minute_exposure WHERE trading_minute<CURRENT_DATE - Interval '15 day'

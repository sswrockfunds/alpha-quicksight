--todo
--
DELETE FROM performance.minute_exposure WHERE trading_minute<CURRENT_DATE - Interval '8 day'


CREATE TABLE quicksight._history
(
    -- TIME DIMENSIONS
    trading_month       VARCHAR(8),  -- 2025-05
    trading_week        VARCHAR(8),  -- 2025-W22
    trading_day         DATE,        -- 2025-05-29
    year_num            int,         -- 2025
    month_num           int,         -- 5
    day_num             int,         -- 29
    -- ACCOUNT DIMENSIONS
    exchange_id         int,
    account_id          int,
    account_type        VARCHAR(16), -- Main / Production / IEO
    counter_underlying  VARCHAR(16), -- USDT / USD / EUR
    strategy            VARCHAR(32), -- AlphaFlexx / Sonic / Hedge
    instrument_type     VARCHAR(8),  -- spot / derivate / multi
    custody             BOOL,        -- True/false
    owner               VARCHAR(32), -- AlphaRock / Timo
    -- BALANCE METRICS
    exposure_usd        NUMERIC(20, 2),
    crypto_exposure_usd NUMERIC(20, 2),
    deposit_usd         NUMERIC(20, 2),
    withdraw_usd        NUMERIC(20, 2),
    pnl_usd             NUMERIC(20, 2),
    --- TRADING METRICS
    turnover_usd        NUMERIC(20, 2),
    tpl1_usd            NUMERIC(20, 2),
    tpl10_usd           NUMERIC(20, 2),
    tpl30_usd           NUMERIC(20, 2),
    tpl60_usd           NUMERIC(20, 2),
    tpl300_usd          NUMERIC(20, 2),
    tpl900_usd          NUMERIC(20, 2),
    trade_count         INTEGER,
    updated_ts          TIMESTAMP,
    PRIMARY KEY (trading_day, account_id)
);

CREATE INDEX performance_history_month_idx ON quicksight._history (trading_month, account_id);
CREATE INDEX performance_history_week_idx ON quicksight._history (trading_week, account_id);
CREATE INDEX performance_history_num_idx ON quicksight._history (year_num, month_num, day_num, account_id);

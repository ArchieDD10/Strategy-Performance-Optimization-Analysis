-- ============================================================================
-- Trading Performance Analytics - Data Loading Script
-- ============================================================================
-- Purpose: Load trade data from CSV into database
-- ============================================================================

-- Note: Adjust file path based on your environment
-- For MySQL/MariaDB:
LOAD DATA INFILE '../data/raw/trade_log.csv'
INTO TABLE trades
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(trade_id, @trade_date, @trade_time, instrument, setup_type, session, 
 risk_reward_ratio, risk_amount, win_loss, pnl, balance, peak_balance, 
 drawdown_pct, day_of_week, month_name, year, quarter, hour)
SET 
    trade_date = STR_TO_DATE(@trade_date, '%Y-%m-%d'),
    trade_time = STR_TO_DATE(@trade_time, '%H:%i');

-- For PostgreSQL:
/*
COPY trades(trade_id, trade_date, trade_time, instrument, setup_type, session, 
            risk_reward_ratio, risk_amount, win_loss, pnl, balance, peak_balance, 
            drawdown_pct, day_of_week, month_name, year, quarter, hour)
FROM '../data/raw/trade_log.csv'
DELIMITER ','
CSV HEADER;
*/

-- For SQL Server (BULK INSERT):
/*
BULK INSERT trades
FROM '../data/raw/trade_log.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);
*/

-- Verify data load
SELECT 
    COUNT(*) as total_records,
    MIN(trade_date) as earliest_trade,
    MAX(trade_date) as latest_trade,
    SUM(pnl) as total_pnl
FROM trades;

PRINT 'Data loaded successfully!';

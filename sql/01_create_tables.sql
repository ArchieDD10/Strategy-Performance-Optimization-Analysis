-- ============================================================================
-- Trading Performance Analytics - Table Creation Script
-- ============================================================================
-- Purpose: Create database schema for trading performance analysis
-- Author: Analytics Team
-- Date: 2025
-- ============================================================================

-- Drop tables if they exist (for clean re-runs)
DROP TABLE IF EXISTS trade_performance_metrics;
DROP TABLE IF EXISTS trades;

-- ============================================================================
-- Main Trades Table
-- ============================================================================

CREATE TABLE trades (
    trade_id INT PRIMARY KEY,
    trade_date DATE NOT NULL,
    trade_time TIME,
    instrument VARCHAR(20) NOT NULL,
    setup_type VARCHAR(50) NOT NULL,
    session VARCHAR(50) NOT NULL,
    risk_reward_ratio DECIMAL(5,2),
    risk_amount DECIMAL(10,2),
    win_loss VARCHAR(10),
    pnl DECIMAL(10,2),
    balance DECIMAL(15,2),
    peak_balance DECIMAL(15,2),
    drawdown_pct DECIMAL(5,2),
    day_of_week VARCHAR(20),
    month_name VARCHAR(20),
    year INT,
    quarter INT,
    hour INT,
    
    -- Indexes for performance
    INDEX idx_date (trade_date),
    INDEX idx_setup (setup_type),
    INDEX idx_session (session),
    INDEX idx_instrument (instrument),
    INDEX idx_win_loss (win_loss)
);

-- ============================================================================
-- Performance Metrics Table (for aggregated results)
-- ============================================================================

CREATE TABLE trade_performance_metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    metric_date DATE,
    metric_period VARCHAR(20), -- 'daily', 'weekly', 'monthly'
    dimension_type VARCHAR(50), -- 'overall', 'setup', 'session', 'instrument'
    dimension_value VARCHAR(50),
    
    -- Volume metrics
    total_trades INT,
    winning_trades INT,
    losing_trades INT,
    
    -- Performance metrics
    win_rate DECIMAL(5,2),
    total_pnl DECIMAL(15,2),
    avg_pnl DECIMAL(10,2),
    avg_win DECIMAL(10,2),
    avg_loss DECIMAL(10,2),
    profit_factor DECIMAL(10,2),
    
    -- Risk metrics
    max_drawdown DECIMAL(5,2),
    avg_risk_reward DECIMAL(5,2),
    sharpe_ratio DECIMAL(10,4),
    
    -- Behavioral metrics
    avg_trades_per_day DECIMAL(5,2),
    longest_win_streak INT,
    longest_loss_streak INT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_metric_date (metric_date),
    INDEX idx_dimension (dimension_type, dimension_value)
);

-- ============================================================================
-- Create a view for easy access to common metrics
-- ============================================================================

CREATE OR REPLACE VIEW v_trade_summary AS
SELECT 
    trade_date,
    session,
    setup_type,
    instrument,
    COUNT(*) as num_trades,
    SUM(CASE WHEN win_loss = 'Win' THEN 1 ELSE 0 END) as wins,
    SUM(CASE WHEN win_loss = 'Loss' THEN 1 ELSE 0 END) as losses,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate_pct,
    ROUND(SUM(pnl), 2) as total_pnl,
    ROUND(AVG(pnl), 2) as avg_pnl,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN pnl END), 2) as avg_win,
    ROUND(AVG(CASE WHEN win_loss = 'Loss' THEN pnl END), 2) as avg_loss,
    ROUND(AVG(risk_reward_ratio), 2) as avg_rr
FROM trades
GROUP BY trade_date, session, setup_type, instrument;

PRINT 'Tables and views created successfully!';

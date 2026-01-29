-- ============================================================================
-- Rolling Win Rate Analysis
-- ============================================================================
-- Purpose: Calculate win rates over different rolling windows
-- Business Question: How consistent is trading performance over time?
-- ============================================================================

-- ============================================================================
-- 10-Trade Rolling Win Rate
-- ============================================================================
SELECT 
    trade_id,
    trade_date,
    setup_type,
    win_loss,
    pnl,
    -- Rolling 10-trade win rate
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) 
          OVER (ORDER BY trade_id ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) * 100, 2) 
        AS rolling_10_win_rate,
    -- Rolling 10-trade P&L
    ROUND(SUM(pnl) 
          OVER (ORDER BY trade_id ROWS BETWEEN 9 PRECEDING AND CURRENT ROW), 2) 
        AS rolling_10_pnl,
    -- Rolling 20-trade win rate
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) 
          OVER (ORDER BY trade_id ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) * 100, 2) 
        AS rolling_20_win_rate,
    -- Rolling 50-trade win rate
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) 
          OVER (ORDER BY trade_id ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) * 100, 2) 
        AS rolling_50_win_rate
FROM trades
ORDER BY trade_id;

-- ============================================================================
-- Rolling Win Rate by Setup Type
-- ============================================================================
SELECT 
    trade_id,
    trade_date,
    setup_type,
    win_loss,
    -- Setup-specific rolling 20-trade win rate
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) 
          OVER (PARTITION BY setup_type ORDER BY trade_id ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) * 100, 2) 
        AS setup_rolling_20_wr,
    -- Setup-specific rolling P&L
    ROUND(SUM(pnl) 
          OVER (PARTITION BY setup_type ORDER BY trade_id ROWS BETWEEN 19 PRECEDING AND CURRENT ROW), 2) 
        AS setup_rolling_20_pnl
FROM trades
ORDER BY setup_type, trade_id;

-- ============================================================================
-- Monthly Rolling Performance
-- ============================================================================
WITH monthly_performance AS (
    SELECT 
        DATE_TRUNC('month', trade_date) as trade_month,
        COUNT(*) as trades,
        SUM(CASE WHEN win_loss = 'Win' THEN 1 ELSE 0 END) as wins,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
        ROUND(SUM(pnl), 2) as monthly_pnl
    FROM trades
    GROUP BY DATE_TRUNC('month', trade_date)
)
SELECT 
    trade_month,
    trades,
    wins,
    win_rate,
    monthly_pnl,
    -- 3-month rolling average win rate
    ROUND(AVG(win_rate) 
          OVER (ORDER BY trade_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) 
        AS rolling_3mo_wr,
    -- 3-month rolling P&L
    ROUND(SUM(monthly_pnl) 
          OVER (ORDER BY trade_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) 
        AS rolling_3mo_pnl
FROM monthly_performance
ORDER BY trade_month;

-- ============================================================================
-- Win Rate Volatility Analysis
-- ============================================================================
WITH rolling_stats AS (
    SELECT 
        trade_id,
        trade_date,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) 
              OVER (ORDER BY trade_id ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) * 100, 2) 
            AS rolling_30_wr
    FROM trades
)
SELECT 
    ROUND(AVG(rolling_30_wr), 2) as avg_win_rate,
    ROUND(STDDEV(rolling_30_wr), 2) as win_rate_volatility,
    ROUND(MIN(rolling_30_wr), 2) as min_win_rate,
    ROUND(MAX(rolling_30_wr), 2) as max_win_rate,
    ROUND(MAX(rolling_30_wr) - MIN(rolling_30_wr), 2) as win_rate_range
FROM rolling_stats
WHERE trade_id >= 30;  -- Only include records with full 30-trade window

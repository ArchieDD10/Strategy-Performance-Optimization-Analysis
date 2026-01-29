-- ============================================================================
-- Session-Based Performance Analysis
-- ============================================================================
-- Purpose: Analyze trading performance across different market sessions
-- Business Question: When do I perform best?
-- ============================================================================

-- ============================================================================
-- Session Performance Overview
-- ============================================================================
SELECT 
    session,
    COUNT(*) as total_trades,
    SUM(CASE WHEN win_loss = 'Win' THEN 1 ELSE 0 END) as wins,
    SUM(CASE WHEN win_loss = 'Loss' THEN 1 ELSE 0 END) as losses,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate_pct,
    ROUND(SUM(pnl), 2) as total_pnl,
    ROUND(AVG(pnl), 2) as avg_pnl_per_trade,
    ROUND(SUM(CASE WHEN win_loss = 'Win' THEN pnl END) / 
          SUM(CASE WHEN win_loss = 'Win' THEN 1 END), 2) as avg_win,
    ROUND(SUM(CASE WHEN win_loss = 'Loss' THEN pnl END) / 
          SUM(CASE WHEN win_loss = 'Loss' THEN 1 END), 2) as avg_loss,
    -- Profit Factor
    ROUND(ABS(SUM(CASE WHEN win_loss = 'Win' THEN pnl END) / 
          NULLIF(SUM(CASE WHEN win_loss = 'Loss' THEN pnl END), 0)), 2) as profit_factor,
    -- Expectancy
    ROUND(AVG(pnl), 2) as expectancy,
    ROUND(AVG(risk_reward_ratio), 2) as avg_rr_ratio
FROM trades
GROUP BY session
ORDER BY total_pnl DESC;

-- ============================================================================
-- Session Performance by Setup Type
-- ============================================================================
SELECT 
    session,
    setup_type,
    COUNT(*) as trades,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
    ROUND(SUM(pnl), 2) as total_pnl,
    ROUND(AVG(pnl), 2) as avg_pnl,
    ROUND(AVG(risk_reward_ratio), 2) as avg_rr
FROM trades
GROUP BY session, setup_type
HAVING COUNT(*) >= 10  -- Only show combinations with at least 10 trades
ORDER BY session, total_pnl DESC;

-- ============================================================================
-- Session Performance Trends Over Time
-- ============================================================================
WITH monthly_session_perf AS (
    SELECT 
        DATE_TRUNC('month', trade_date) as month,
        session,
        COUNT(*) as trades,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
        ROUND(SUM(pnl), 2) as monthly_pnl
    FROM trades
    GROUP BY DATE_TRUNC('month', trade_date), session
)
SELECT 
    month,
    session,
    trades,
    win_rate,
    monthly_pnl,
    -- 3-month moving average
    ROUND(AVG(monthly_pnl) 
          OVER (PARTITION BY session ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) 
        as ma_3mo_pnl
FROM monthly_session_perf
ORDER BY session, month;

-- ============================================================================
-- Best and Worst Sessions by Time Period
-- ============================================================================
WITH session_rankings AS (
    SELECT 
        year,
        quarter,
        session,
        COUNT(*) as trades,
        ROUND(SUM(pnl), 2) as pnl,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
        ROW_NUMBER() OVER (PARTITION BY year, quarter ORDER BY SUM(pnl) DESC) as rank_best,
        ROW_NUMBER() OVER (PARTITION BY year, quarter ORDER BY SUM(pnl) ASC) as rank_worst
    FROM trades
    GROUP BY year, quarter, session
)
SELECT 
    year,
    quarter,
    session,
    trades,
    pnl,
    win_rate,
    CASE 
        WHEN rank_best = 1 THEN 'Best Session'
        WHEN rank_worst = 1 THEN 'Worst Session'
    END as performance_tier
FROM session_rankings
WHERE rank_best = 1 OR rank_worst = 1
ORDER BY year, quarter, rank_best;

-- ============================================================================
-- Session Trading Volume and Profitability Correlation
-- ============================================================================
WITH daily_session_stats AS (
    SELECT 
        trade_date,
        session,
        COUNT(*) as daily_trades,
        ROUND(SUM(pnl), 2) as daily_pnl
    FROM trades
    GROUP BY trade_date, session
)
SELECT 
    session,
    ROUND(AVG(daily_trades), 2) as avg_daily_volume,
    ROUND(STDDEV(daily_trades), 2) as volume_stddev,
    ROUND(AVG(daily_pnl), 2) as avg_daily_pnl,
    ROUND(STDDEV(daily_pnl), 2) as pnl_stddev,
    -- Coefficient of variation (risk per unit of return)
    ROUND(STDDEV(daily_pnl) / NULLIF(AVG(daily_pnl), 0), 2) as cv_ratio
FROM daily_session_stats
GROUP BY session
ORDER BY avg_daily_pnl DESC;

-- ============================================================================
-- Time of Day Performance (Hourly Breakdown)
-- ============================================================================
SELECT 
    hour,
    COUNT(*) as trades,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
    ROUND(SUM(pnl), 2) as total_pnl,
    ROUND(AVG(pnl), 2) as avg_pnl,
    -- Identify primary session for each hour
    MODE() WITHIN GROUP (ORDER BY session) as primary_session
FROM trades
GROUP BY hour
ORDER BY hour;

-- ============================================================================
-- Session Consistency Score
-- ============================================================================
-- Measures how consistently profitable each session is
WITH session_daily_pnl AS (
    SELECT 
        session,
        trade_date,
        SUM(pnl) as daily_pnl
    FROM trades
    GROUP BY session, trade_date
)
SELECT 
    session,
    COUNT(*) as trading_days,
    SUM(CASE WHEN daily_pnl > 0 THEN 1 ELSE 0 END) as profitable_days,
    ROUND(SUM(CASE WHEN daily_pnl > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as profitable_day_pct,
    ROUND(AVG(daily_pnl), 2) as avg_daily_pnl,
    ROUND(STDDEV(daily_pnl), 2) as daily_pnl_volatility,
    -- Sharpe-like ratio (return per unit of volatility)
    ROUND(AVG(daily_pnl) / NULLIF(STDDEV(daily_pnl), 0), 3) as consistency_score
FROM session_daily_pnl
GROUP BY session
ORDER BY consistency_score DESC;

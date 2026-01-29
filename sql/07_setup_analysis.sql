-- ============================================================================
-- Setup Type Performance Analysis
-- ============================================================================
-- Purpose: Analyze which trading setups are performing well or poorly
-- Business Question: What setups are statistically dragging performance?
-- ============================================================================

-- ============================================================================
-- Overall Setup Performance
-- ============================================================================
SELECT 
    setup_type,
    COUNT(*) as total_trades,
    SUM(CASE WHEN win_loss = 'Win' THEN 1 ELSE 0 END) as wins,
    SUM(CASE WHEN win_loss = 'Loss' THEN 1 ELSE 0 END) as losses,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate_pct,
    ROUND(SUM(pnl), 2) as total_pnl,
    ROUND(AVG(pnl), 2) as avg_pnl,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN pnl END), 2) as avg_win,
    ROUND(AVG(CASE WHEN win_loss = 'Loss' THEN pnl END), 2) as avg_loss,
    ROUND(ABS(SUM(CASE WHEN win_loss = 'Win' THEN pnl END) / 
          NULLIF(SUM(CASE WHEN win_loss = 'Loss' THEN pnl END), 0)), 2) as profit_factor,
    ROUND(AVG(risk_reward_ratio), 2) as avg_rr_ratio,
    -- Expectancy per trade
    ROUND(AVG(pnl), 2) as expectancy,
    -- Setup contribution to total P&L
    ROUND(SUM(pnl) * 100.0 / (SELECT SUM(pnl) FROM trades), 2) as pnl_contribution_pct
FROM trades
GROUP BY setup_type
ORDER BY total_pnl DESC;

-- ============================================================================
-- Statistical Significance Test for Setup Performance
-- ============================================================================
-- Identifies setups with statistically significant underperformance
WITH setup_stats AS (
    SELECT 
        setup_type,
        COUNT(*) as n_trades,
        AVG(pnl) as mean_pnl,
        STDDEV(pnl) as stddev_pnl
    FROM trades
    GROUP BY setup_type
),
overall_stats AS (
    SELECT 
        AVG(pnl) as overall_mean_pnl,
        STDDEV(pnl) as overall_stddev_pnl
    FROM trades
)
SELECT 
    s.setup_type,
    s.n_trades,
    ROUND(s.mean_pnl, 2) as setup_avg_pnl,
    ROUND(o.overall_mean_pnl, 2) as overall_avg_pnl,
    -- Z-score (measures how many standard deviations from mean)
    ROUND((s.mean_pnl - o.overall_mean_pnl) / NULLIF(s.stddev_pnl / SQRT(s.n_trades), 0), 2) as z_score,
    CASE 
        WHEN (s.mean_pnl - o.overall_mean_pnl) / NULLIF(s.stddev_pnl / SQRT(s.n_trades), 0) < -1.96 
            THEN 'Significantly Underperforming'
        WHEN (s.mean_pnl - o.overall_mean_pnl) / NULLIF(s.stddev_pnl / SQRT(s.n_trades), 0) > 1.96 
            THEN 'Significantly Outperforming'
        ELSE 'Within Normal Range'
    END as performance_classification
FROM setup_stats s
CROSS JOIN overall_stats o
WHERE s.n_trades >= 20  -- Minimum sample size
ORDER BY z_score ASC;

-- ============================================================================
-- Setup Performance Trends Over Time
-- ============================================================================
WITH monthly_setup_perf AS (
    SELECT 
        DATE_TRUNC('month', trade_date) as month,
        setup_type,
        COUNT(*) as trades,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
        ROUND(SUM(pnl), 2) as monthly_pnl,
        ROUND(AVG(pnl), 2) as avg_pnl
    FROM trades
    GROUP BY DATE_TRUNC('month', trade_date), setup_type
)
SELECT 
    month,
    setup_type,
    trades,
    win_rate,
    monthly_pnl,
    avg_pnl,
    -- 3-month trend
    ROUND(AVG(monthly_pnl) 
          OVER (PARTITION BY setup_type ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) 
        as ma_3mo_pnl,
    -- Performance trend indicator
    CASE 
        WHEN monthly_pnl > AVG(monthly_pnl) OVER (PARTITION BY setup_type) THEN 'Above Average'
        ELSE 'Below Average'
    END as trend_status
FROM monthly_setup_perf
ORDER BY setup_type, month;

-- ============================================================================
-- Setup Win Rate Consistency
-- ============================================================================
WITH setup_daily_stats AS (
    SELECT 
        setup_type,
        trade_date,
        COUNT(*) as daily_trades,
        SUM(CASE WHEN win_loss = 'Win' THEN 1 ELSE 0 END) as daily_wins,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as daily_win_rate
    FROM trades
    GROUP BY setup_type, trade_date
    HAVING COUNT(*) >= 2  -- Days with at least 2 trades
)
SELECT 
    setup_type,
    COUNT(DISTINCT trade_date) as active_days,
    ROUND(AVG(daily_win_rate), 2) as avg_daily_wr,
    ROUND(STDDEV(daily_win_rate), 2) as wr_volatility,
    ROUND(MIN(daily_win_rate), 2) as worst_day_wr,
    ROUND(MAX(daily_win_rate), 2) as best_day_wr,
    -- Coefficient of variation for consistency
    ROUND(STDDEV(daily_win_rate) / NULLIF(AVG(daily_win_rate), 0), 2) as consistency_index
FROM setup_daily_stats
GROUP BY setup_type
ORDER BY consistency_index ASC;  -- Lower is more consistent

-- ============================================================================
-- Setup Performance by Instrument
-- ============================================================================
SELECT 
    setup_type,
    instrument,
    COUNT(*) as trades,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
    ROUND(SUM(pnl), 2) as total_pnl,
    ROUND(AVG(pnl), 2) as avg_pnl,
    ROUND(AVG(risk_reward_ratio), 2) as avg_rr
FROM trades
GROUP BY setup_type, instrument
HAVING COUNT(*) >= 5  -- Minimum 5 trades
ORDER BY setup_type, total_pnl DESC;

-- ============================================================================
-- Underperforming Setups - Deep Dive
-- ============================================================================
-- Focus on setups with negative expectancy
WITH setup_metrics AS (
    SELECT 
        setup_type,
        COUNT(*) as total_trades,
        ROUND(AVG(pnl), 2) as expectancy,
        ROUND(SUM(pnl), 2) as total_pnl,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate
    FROM trades
    GROUP BY setup_type
    HAVING AVG(pnl) < 0  -- Negative expectancy
)
SELECT 
    sm.setup_type,
    sm.total_trades,
    sm.expectancy,
    sm.total_pnl,
    sm.win_rate,
    -- What would total P&L be without this setup?
    (SELECT SUM(pnl) FROM trades) - sm.total_pnl as pnl_without_setup,
    ROUND(sm.total_pnl * 100.0 / (SELECT SUM(pnl) FROM trades), 2) as pnl_drag_pct
FROM setup_metrics sm
ORDER BY sm.total_pnl ASC;

-- ============================================================================
-- Setup Abandonment Recommendation
-- ============================================================================
-- Identify setups that should potentially be stopped
WITH setup_performance AS (
    SELECT 
        setup_type,
        COUNT(*) as trades,
        ROUND(AVG(pnl), 2) as avg_pnl,
        ROUND(SUM(pnl), 2) as total_pnl,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
        ROUND(ABS(SUM(CASE WHEN win_loss = 'Win' THEN pnl END) / 
              NULLIF(SUM(CASE WHEN win_loss = 'Loss' THEN pnl END), 0)), 2) as profit_factor
    FROM trades
    GROUP BY setup_type
)
SELECT 
    setup_type,
    trades,
    avg_pnl,
    total_pnl,
    win_rate,
    profit_factor,
    CASE 
        WHEN avg_pnl < 0 AND trades >= 30 THEN 'STOP - Proven Loser'
        WHEN avg_pnl < 0 AND trades < 30 THEN 'CAUTION - Needs More Data'
        WHEN profit_factor < 1.0 THEN 'REVIEW - Poor Risk/Reward'
        WHEN win_rate < 40 AND profit_factor < 1.5 THEN 'REVIEW - Low Win Rate & PF'
        ELSE 'CONTINUE'
    END as recommendation,
    -- Impact if setup is stopped
    ROUND(-1 * total_pnl, 2) as potential_recovery
FROM setup_performance
ORDER BY 
    CASE 
        WHEN avg_pnl < 0 AND trades >= 30 THEN 1
        WHEN avg_pnl < 0 AND trades < 30 THEN 2
        WHEN profit_factor < 1.0 THEN 3
        WHEN win_rate < 40 AND profit_factor < 1.5 THEN 4
        ELSE 5
    END,
    avg_pnl ASC;

-- ============================================================================
-- Best Setup Combinations (Multi-variate Analysis)
-- ============================================================================
SELECT 
    setup_type,
    session,
    day_of_week,
    COUNT(*) as trades,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
    ROUND(SUM(pnl), 2) as total_pnl,
    ROUND(AVG(pnl), 2) as avg_pnl
FROM trades
GROUP BY setup_type, session, day_of_week
HAVING COUNT(*) >= 5
ORDER BY avg_pnl DESC
LIMIT 20;

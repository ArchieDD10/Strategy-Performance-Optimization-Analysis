-- ============================================================================
-- Trade Frequency vs Profitability Analysis
-- ============================================================================
-- Purpose: Analyze relationship between trading frequency and performance
-- Business Question: Is higher frequency actually improving returns?
-- ============================================================================

-- ============================================================================
-- Daily Trading Frequency Analysis
-- ============================================================================
WITH daily_stats AS (
    SELECT 
        trade_date,
        COUNT(*) as trades_per_day,
        ROUND(SUM(pnl), 2) as daily_pnl,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as daily_win_rate
    FROM trades
    GROUP BY trade_date
)
SELECT 
    -- Frequency buckets
    CASE 
        WHEN trades_per_day = 1 THEN '1 trade'
        WHEN trades_per_day BETWEEN 2 AND 3 THEN '2-3 trades'
        WHEN trades_per_day BETWEEN 4 AND 5 THEN '4-5 trades'
        WHEN trades_per_day BETWEEN 6 AND 10 THEN '6-10 trades'
        ELSE '10+ trades'
    END as frequency_bucket,
    COUNT(*) as num_days,
    ROUND(AVG(trades_per_day), 2) as avg_trades,
    ROUND(AVG(daily_pnl), 2) as avg_daily_pnl,
    ROUND(SUM(daily_pnl), 2) as total_pnl,
    ROUND(AVG(daily_win_rate), 2) as avg_win_rate,
    -- PnL per trade
    ROUND(AVG(daily_pnl / trades_per_day), 2) as avg_pnl_per_trade,
    -- Consistency metrics
    ROUND(STDDEV(daily_pnl), 2) as pnl_volatility,
    SUM(CASE WHEN daily_pnl > 0 THEN 1 ELSE 0 END) as profitable_days,
    ROUND(SUM(CASE WHEN daily_pnl > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as profitable_day_pct
FROM daily_stats
GROUP BY 
    CASE 
        WHEN trades_per_day = 1 THEN '1 trade'
        WHEN trades_per_day BETWEEN 2 AND 3 THEN '2-3 trades'
        WHEN trades_per_day BETWEEN 4 AND 5 THEN '4-5 trades'
        WHEN trades_per_day BETWEEN 6 AND 10 THEN '6-10 trades'
        ELSE '10+ trades'
    END
ORDER BY avg_trades;

-- ============================================================================
-- Weekly Frequency vs Performance
-- ============================================================================
WITH weekly_stats AS (
    SELECT 
        DATE_TRUNC('week', trade_date) as week_start,
        COUNT(*) as trades_per_week,
        ROUND(SUM(pnl), 2) as weekly_pnl,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as weekly_win_rate,
        MAX(drawdown_pct) as max_weekly_dd
    FROM trades
    GROUP BY DATE_TRUNC('week', trade_date)
)
SELECT 
    CASE 
        WHEN trades_per_week < 5 THEN 'Low (<5)'
        WHEN trades_per_week BETWEEN 5 AND 10 THEN 'Medium (5-10)'
        WHEN trades_per_week BETWEEN 11 AND 20 THEN 'High (11-20)'
        ELSE 'Very High (20+)'
    END as frequency_tier,
    COUNT(*) as num_weeks,
    ROUND(AVG(trades_per_week), 2) as avg_weekly_trades,
    ROUND(AVG(weekly_pnl), 2) as avg_weekly_pnl,
    ROUND(SUM(weekly_pnl), 2) as total_pnl,
    ROUND(AVG(weekly_win_rate), 2) as avg_win_rate,
    ROUND(AVG(max_weekly_dd), 2) as avg_max_drawdown,
    -- Risk-adjusted return
    ROUND(AVG(weekly_pnl) / NULLIF(STDDEV(weekly_pnl), 0), 3) as sharpe_ratio
FROM weekly_stats
GROUP BY 
    CASE 
        WHEN trades_per_week < 5 THEN 'Low (<5)'
        WHEN trades_per_week BETWEEN 5 AND 10 THEN 'Medium (5-10)'
        WHEN trades_per_week BETWEEN 11 AND 20 THEN 'High (11-20)'
        ELSE 'Very High (20+)'
    END
ORDER BY avg_weekly_trades;

-- ============================================================================
-- Overtrading Detection
-- ============================================================================
-- Identify days with high frequency and poor performance
WITH daily_performance AS (
    SELECT 
        trade_date,
        day_of_week,
        COUNT(*) as num_trades,
        ROUND(SUM(pnl), 2) as daily_pnl,
        ROUND(AVG(pnl), 2) as avg_pnl_per_trade,
        ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate
    FROM trades
    GROUP BY trade_date, day_of_week
),
frequency_percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY num_trades) as p75_trades
    FROM daily_performance
)
SELECT 
    dp.trade_date,
    dp.day_of_week,
    dp.num_trades,
    dp.daily_pnl,
    dp.avg_pnl_per_trade,
    dp.win_rate,
    CASE 
        WHEN dp.num_trades > fp.p75_trades AND dp.daily_pnl < 0 THEN 'Potential Overtrading'
        WHEN dp.num_trades > fp.p75_trades AND dp.daily_pnl > 0 THEN 'High Frequency - Profitable'
        ELSE 'Normal'
    END as trading_pattern
FROM daily_performance dp
CROSS JOIN frequency_percentiles fp
WHERE dp.num_trades > fp.p75_trades
ORDER BY dp.daily_pnl ASC;

-- ============================================================================
-- Frequency by Setup Type
-- ============================================================================
WITH setup_frequency AS (
    SELECT 
        setup_type,
        trade_date,
        COUNT(*) as daily_setup_trades,
        ROUND(SUM(pnl), 2) as daily_setup_pnl
    FROM trades
    GROUP BY setup_type, trade_date
)
SELECT 
    setup_type,
    COUNT(DISTINCT trade_date) as days_traded,
    ROUND(AVG(daily_setup_trades), 2) as avg_trades_per_day,
    ROUND(MAX(daily_setup_trades), 0) as max_trades_per_day,
    ROUND(AVG(daily_setup_pnl), 2) as avg_daily_pnl,
    ROUND(STDDEV(daily_setup_pnl), 2) as daily_pnl_volatility,
    -- Optimal frequency indicator (high return, low volatility)
    ROUND(AVG(daily_setup_pnl) / NULLIF(STDDEV(daily_setup_pnl), 0), 3) as return_volatility_ratio
FROM setup_frequency
GROUP BY setup_type
ORDER BY return_volatility_ratio DESC;

-- ============================================================================
-- Time Between Trades Analysis
-- ============================================================================
WITH trade_intervals AS (
    SELECT 
        trade_id,
        trade_date,
        trade_time,
        pnl,
        win_loss,
        TIMESTAMPDIFF(MINUTE, 
            LAG(CONCAT(trade_date, ' ', trade_time)) OVER (ORDER BY trade_id),
            CONCAT(trade_date, ' ', trade_time)
        ) as minutes_since_last_trade
    FROM trades
)
SELECT 
    CASE 
        WHEN minutes_since_last_trade < 30 THEN '< 30 min'
        WHEN minutes_since_last_trade BETWEEN 30 AND 60 THEN '30-60 min'
        WHEN minutes_since_last_trade BETWEEN 61 AND 120 THEN '1-2 hours'
        WHEN minutes_since_last_trade BETWEEN 121 AND 240 THEN '2-4 hours'
        WHEN minutes_since_last_trade BETWEEN 241 AND 480 THEN '4-8 hours'
        ELSE '8+ hours'
    END as time_gap,
    COUNT(*) as num_trades,
    ROUND(AVG(CASE WHEN win_loss = 'Win' THEN 1.0 ELSE 0.0 END) * 100, 2) as win_rate,
    ROUND(AVG(pnl), 2) as avg_pnl,
    ROUND(SUM(pnl), 2) as total_pnl
FROM trade_intervals
WHERE minutes_since_last_trade IS NOT NULL
GROUP BY 
    CASE 
        WHEN minutes_since_last_trade < 30 THEN '< 30 min'
        WHEN minutes_since_last_trade BETWEEN 30 AND 60 THEN '30-60 min'
        WHEN minutes_since_last_trade BETWEEN 61 AND 120 THEN '1-2 hours'
        WHEN minutes_since_last_trade BETWEEN 121 AND 240 THEN '2-4 hours'
        WHEN minutes_since_last_trade BETWEEN 241 AND 480 THEN '4-8 hours'
        ELSE '8+ hours'
    END
ORDER BY 
    CASE time_gap
        WHEN '< 30 min' THEN 1
        WHEN '30-60 min' THEN 2
        WHEN '1-2 hours' THEN 3
        WHEN '2-4 hours' THEN 4
        WHEN '4-8 hours' THEN 5
        ELSE 6
    END;

-- ============================================================================
-- Correlation: Frequency vs Returns
-- ============================================================================
WITH daily_metrics AS (
    SELECT 
        trade_date,
        COUNT(*) as num_trades,
        ROUND(SUM(pnl), 2) as daily_pnl
    FROM trades
    GROUP BY trade_date
)
SELECT 
    COUNT(*) as total_days,
    ROUND(AVG(num_trades), 2) as avg_trades_per_day,
    ROUND(AVG(daily_pnl), 2) as avg_daily_pnl,
    -- Correlation coefficient between frequency and profitability
    ROUND(
        (COUNT(*) * SUM(num_trades * daily_pnl) - SUM(num_trades) * SUM(daily_pnl)) /
        NULLIF(SQRT(
            (COUNT(*) * SUM(num_trades * num_trades) - SUM(num_trades) * SUM(num_trades)) *
            (COUNT(*) * SUM(daily_pnl * daily_pnl) - SUM(daily_pnl) * SUM(daily_pnl))
        ), 0),
    4) as frequency_profitability_correlation
FROM daily_metrics;

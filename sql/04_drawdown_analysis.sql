-- ============================================================================
-- Drawdown Analysis
-- ============================================================================
-- Purpose: Analyze portfolio drawdowns and recovery patterns
-- Business Question: What are the risk characteristics of the strategy?
-- ============================================================================

-- ============================================================================
-- Maximum Drawdown Calculation
-- ============================================================================
WITH equity_curve AS (
    SELECT 
        trade_id,
        trade_date,
        balance,
        MAX(balance) OVER (ORDER BY trade_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as peak_equity,
        pnl
    FROM trades
)
SELECT 
    trade_id,
    trade_date,
    balance,
    peak_equity,
    -- Current drawdown
    ROUND(((peak_equity - balance) / peak_equity) * 100, 2) as current_drawdown_pct,
    ROUND(peak_equity - balance, 2) as current_drawdown_dollar,
    -- Time in drawdown
    CASE 
        WHEN balance < peak_equity THEN 1 
        ELSE 0 
    END as in_drawdown
FROM equity_curve
ORDER BY trade_id;

-- ============================================================================
-- Drawdown Periods Analysis
-- ============================================================================
WITH drawdown_flags AS (
    SELECT 
        trade_id,
        trade_date,
        balance,
        MAX(balance) OVER (ORDER BY trade_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as peak,
        CASE 
            WHEN balance < MAX(balance) OVER (ORDER BY trade_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
            THEN 1 ELSE 0 
        END as in_dd
    FROM trades
),
drawdown_groups AS (
    SELECT 
        *,
        SUM(CASE WHEN in_dd = 0 THEN 1 ELSE 0 END) 
            OVER (ORDER BY trade_id) as dd_group
    FROM drawdown_flags
)
SELECT 
    dd_group,
    MIN(trade_date) as dd_start,
    MAX(trade_date) as dd_end,
    DATEDIFF(day, MIN(trade_date), MAX(trade_date)) as dd_duration_days,
    COUNT(*) as trades_in_dd,
    ROUND(MAX((peak - balance) / peak * 100), 2) as max_dd_pct,
    ROUND(MAX(peak - balance), 2) as max_dd_dollar,
    ROUND(MIN(balance), 2) as trough_balance
FROM drawdown_groups
WHERE in_dd = 1
GROUP BY dd_group
HAVING COUNT(*) > 1
ORDER BY max_dd_pct DESC
LIMIT 10;

-- ============================================================================
-- Drawdown by Setup Type
-- ============================================================================
WITH setup_equity AS (
    SELECT 
        setup_type,
        trade_id,
        trade_date,
        SUM(pnl) OVER (PARTITION BY setup_type ORDER BY trade_id) as setup_cumulative_pnl,
        MAX(SUM(pnl) OVER (PARTITION BY setup_type ORDER BY trade_id)) 
            OVER (PARTITION BY setup_type ORDER BY trade_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
            as setup_peak_pnl
    FROM trades
)
SELECT 
    setup_type,
    ROUND(MAX(setup_peak_pnl - setup_cumulative_pnl), 2) as max_setup_drawdown,
    ROUND(AVG(setup_peak_pnl - setup_cumulative_pnl), 2) as avg_setup_drawdown,
    COUNT(DISTINCT CASE WHEN setup_peak_pnl > setup_cumulative_pnl THEN trade_id END) as trades_in_drawdown,
    COUNT(*) as total_trades,
    ROUND(COUNT(DISTINCT CASE WHEN setup_peak_pnl > setup_cumulative_pnl THEN trade_id END) * 100.0 / COUNT(*), 2) 
        as pct_time_in_dd
FROM setup_equity
GROUP BY setup_type
ORDER BY max_setup_drawdown DESC;

-- ============================================================================
-- Drawdown Recovery Analysis
-- ============================================================================
WITH recovery_analysis AS (
    SELECT 
        trade_id,
        trade_date,
        balance,
        MAX(balance) OVER (ORDER BY trade_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as peak,
        CASE 
            WHEN balance >= MAX(balance) OVER (ORDER BY trade_id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) 
            THEN 1 ELSE 0 
        END as new_high
    FROM trades
)
SELECT 
    COUNT(*) as total_new_highs,
    ROUND(AVG(DATEDIFF(day, LAG(trade_date) OVER (ORDER BY trade_id), trade_date)), 1) as avg_days_between_highs,
    ROUND(MAX(DATEDIFF(day, LAG(trade_date) OVER (ORDER BY trade_id), trade_date)), 0) as max_days_between_highs,
    ROUND(MIN(DATEDIFF(day, LAG(trade_date) OVER (ORDER BY trade_id), trade_date)), 0) as min_days_between_highs
FROM recovery_analysis
WHERE new_high = 1 AND trade_id > 1;

-- ============================================================================
-- Risk-Adjusted Returns (Calmar Ratio)
-- ============================================================================
WITH performance_metrics AS (
    SELECT 
        SUM(pnl) as total_return,
        MAX(drawdown_pct) as max_drawdown_pct,
        DATEDIFF(year, MIN(trade_date), MAX(trade_date)) as years_trading
    FROM trades
)
SELECT 
    ROUND(total_return, 2) as total_return,
    ROUND(max_drawdown_pct, 2) as max_drawdown_pct,
    years_trading,
    ROUND((total_return / years_trading), 2) as annualized_return,
    -- Calmar Ratio = Annualized Return / Max Drawdown
    ROUND((total_return / years_trading) / NULLIF(max_drawdown_pct, 0), 4) as calmar_ratio
FROM performance_metrics;

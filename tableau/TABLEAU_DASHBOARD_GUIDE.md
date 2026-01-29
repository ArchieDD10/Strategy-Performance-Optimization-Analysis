# Trading Performance Analytics - Tableau Dashboard Guide

## Dashboard Components

This guide outlines the key visualizations to create in Tableau for comprehensive trading performance analysis.

---

## 1. EXECUTIVE DASHBOARD (Main Overview)

### Top KPIs (Big Numbers)
- **Total P&L**: `SUM([PnL])` with color coding (green if positive, red if negative)
- **Win Rate**: `SUM(IF [Win_Loss] = "Win" THEN 1 ELSE 0 END) / COUNT([Trade_ID]) * 100`
- **Total Trades**: `COUNT([Trade_ID])`
- **Profit Factor**: `ABS(SUM(IF [Win_Loss] = "Win" THEN [PnL] END) / SUM(IF [Win_Loss] = "Loss" THEN [PnL] END))`
- **Max Drawdown**: `MAX([Drawdown_Pct])`

### Equity Curve (Line Chart)
- **X-Axis**: `Date`
- **Y-Axis**: `RUNNING_SUM(SUM([PnL]))` (Cumulative P&L)
- **Reference Line**: Starting balance ($10,000)
- **Dual Axis**: Drawdown percentage (shaded area)

### Monthly Performance (Bar Chart)
- **X-Axis**: `MONTH([Date])`
- **Y-Axis**: `SUM([PnL])`
- **Color**: Positive (green) / Negative (red)
- **Sort**: By month chronologically

---

## 2. RISK ANALYTICS DASHBOARD

### Drawdown Analysis (Area Chart)
- **X-Axis**: `Date`
- **Y-Axis**: `[Drawdown_Pct]`
- **Color**: Gradient (yellow to red based on severity)
- **Annotations**: Mark maximum drawdown points

### Returns Distribution (Histogram)
- **Bins**: `[PnL]` (bin size: $25)
- **Count**: Number of trades per bin
- **Overlay**: Normal distribution curve

### Risk-Adjusted Returns (Bullet Chart)
- **Metrics**:
  - Sharpe Ratio: `AVG([PnL]) / STDEV([PnL]) * SQRT(252)`
  - Sortino Ratio (custom calculation)
  - Calmar Ratio

### Value at Risk (VaR)
- **Table Calculation**: `PERCENTILE([PnL], 0.05)` for 95% VaR
- **Visual**: Gauge showing VaR relative to average trade

---

## 3. SESSION PERFORMANCE DASHBOARD

### Performance by Session (Bar Chart)
- **Rows**: `[Session]`
- **Columns**: 
  - `SUM([PnL])` - Total P&L
  - `COUNT([Trade_ID])` - Number of trades
  - Win Rate (calculated field)
- **Sort**: By total P&L descending

### Session Heatmap (Time of Day vs Day of Week)
- **Columns**: `[Hour]`
- **Rows**: `[Day_of_Week]`
- **Color**: `AVG([PnL])` (gradient: red to green)
- **Size**: `COUNT([Trade_ID])` (larger bubbles = more trades)

### Session Profitability Treemap
- **Hierarchy**: Session → Instrument → Setup Type
- **Size**: Number of trades
- **Color**: Win Rate %

---

## 4. SETUP ANALYSIS DASHBOARD

### Setup Performance Comparison (Combo Chart)
- **Rows**: `[Setup_Type]`
- **Bars**: `SUM([PnL])` per setup
- **Line**: Win Rate % (dual axis)
- **Color**: Setup type
- **Sort**: By total P&L

### Setup Profitability Matrix (Scatter Plot)
- **X-Axis**: Win Rate %
- **Y-Axis**: Average P&L per trade
- **Size**: Total number of trades
- **Color**: `[Setup_Type]`
- **Quadrants**: Add reference lines at median win rate and median P&L

### Setup Trends Over Time (Line Chart)
- **X-Axis**: `MONTH([Date])`
- **Y-Axis**: Rolling 20-trade P&L (table calculation)
- **Color**: `[Setup_Type]`
- **Filter**: Allow selection of specific setups

### Setup Recommendation Table
- **Columns**:
  - Setup Type
  - Total Trades
  - Win Rate %
  - Total P&L
  - Avg P&L
  - Profit Factor
  - **Recommendation** (calculated): 
    ```
    IF AVG([PnL]) < 0 AND COUNT([Trade_ID]) > 30 THEN "STOP"
    ELSEIF [Profit Factor] < 1 THEN "REVIEW"
    ELSE "CONTINUE"
    END
    ```

---

## 5. BEHAVIORAL ANALYSIS DASHBOARD

### Trading Frequency Analysis (Line + Bar)
- **X-Axis**: `Date`
- **Bars**: Trades per day
- **Line**: 20-day moving average of trades per day
- **Reference Line**: 95th percentile (overtrading threshold)

### Revenge Trading Detection (Table)
- **Filter**: Trades where:
  - Previous trade was a loss
  - Time since last trade < 1 hour
- **Columns**: Date, Time, Setup, P&L, Risk Amount
- **Highlight**: Negative P&L in red

### Risk Escalation Tracker (Scatter Plot)
- **X-Axis**: Trade number (sequence)
- **Y-Axis**: `[Risk_Amount]`
- **Color**: `[Win_Loss]` (previous trade)
- **Trend Line**: Show if risk is increasing over time

### Performance by Trading Frequency (Box Plot)
- **Dimension**: Trades per day buckets (1, 2-3, 4-5, 6-10, 10+)
- **Measure**: `[PnL]` distribution
- **Show**: Median, quartiles, outliers

---

## 6. TEMPORAL PATTERNS DASHBOARD

### Day of Week Performance (Stacked Bar)
- **Columns**: `[Day_of_Week]`
- **Stacked Bars**: Wins (green) and Losses (red)
- **Sort**: Monday to Friday

### Monthly Seasonality (Heatmap)
- **Columns**: `[Month]`
- **Rows**: `[Year]`
- **Color**: `SUM([PnL])` (red to green gradient)

### Hourly Performance Distribution (Radial/Polar Chart)
- **Angle**: `[Hour]` (0-23)
- **Radius**: `AVG([PnL])`
- **Color**: Win Rate %

### Quarter-over-Quarter Trends (Line Chart)
- **X-Axis**: `QUARTER([Date])` + `[Year]`
- **Y-Axis**: 
  - Total P&L (line)
  - Number of trades (bars)
- **Table**: Show % change QoQ

---

## 7. INSTRUMENT ANALYSIS DASHBOARD

### Performance by Instrument (Treemap)
- **Size**: `SUM([PnL])`
- **Color**: Win Rate %
- **Label**: Instrument name + Total P&L

### Instrument Comparison Table
- **Rows**: `[Instrument]`
- **Columns**:
  - Total Trades
  - Win Rate %
  - Total P&L
  - Avg P&L per trade
  - Sharpe Ratio (calculated)
- **Conditional Formatting**: Top 3 green, Bottom 3 red

### Instrument vs Setup Matrix (Heatmap)
- **Rows**: `[Instrument]`
- **Columns**: `[Setup_Type]`
- **Color**: `AVG([PnL])`
- **Filter**: Minimum 5 trades per cell

---

## 8. DRILL-DOWN DETAIL DASHBOARD

### Trade Log Table (Interactive)
- **Columns**: All key fields (Trade ID, Date, Time, Instrument, Setup, Session, Win/Loss, P&L, Balance, Drawdown %)
- **Actions**: Click to see individual trade details
- **Highlighting**: Color code wins (green) and losses (red)
- **Filters**: Date range, Session, Setup, Instrument, Win/Loss

### Individual Trade Analysis (Details Panel)
- Activated when clicking on a trade in main table
- Shows:
  - Trade context (what happened before/after)
  - Running balance at that point
  - Time since last trade
  - Current streak
  - Drawdown status

---

## Calculated Fields Reference

### Essential Calculated Fields

```tableau
// Cumulative P&L
RUNNING_SUM(SUM([PnL]))

// Win Rate %
SUM(IF [Win_Loss] = "Win" THEN 1 ELSE 0 END) / COUNT([Trade_ID]) * 100

// Profit Factor
ABS(SUM(IF [Win_Loss] = "Win" THEN [PnL] END) / 
    SUM(IF [Win_Loss] = "Loss" THEN [PnL] END))

// Average Win
AVG(IF [Win_Loss] = "Win" THEN [PnL] END)

// Average Loss
AVG(IF [Win_Loss] = "Loss" THEN [PnL] END)

// Sharpe Ratio (approximate)
AVG([PnL]) / STDEV([PnL]) * SQRT(252)

// Expectancy
([Win Rate %] / 100 * [Average Win]) + ((1 - [Win Rate %] / 100) * [Average Loss])

// Rolling Win Rate (20 trades)
WINDOW_AVG(SUM(IF [Win_Loss] = "Win" THEN 1.0 ELSE 0.0 END), -19, 0)

// Performance Rank
RANK(SUM([PnL]), 'desc')

// Is New High
[Balance] >= RUNNING_MAX([Balance])
```

---

## Dashboard Best Practices

1. **Color Consistency**:
   - Green: Profitable/Wins
   - Red: Losses/Negative
   - Blue: Neutral metrics
   - Yellow/Orange: Warnings

2. **Interactivity**:
   - Add date range filters to all dashboards
   - Enable setup/session/instrument filters
   - Use actions to link related views

3. **Performance**:
   - Use data extracts for large datasets
   - Limit dashboard to key visualizations (8-10 per dashboard max)
   - Use aggregated views where possible

4. **Annotations**:
   - Mark significant events (max drawdown, new highs)
   - Add context to outliers
   - Include reference lines for benchmarks

---

## SQL Database Connection (Alternative to CSV)

If using SQL database instead of CSV:

1. **Connection**: 
   - Server: `localhost` or your database server
   - Database: `trading_performance`
   - Table: `trades`

2. **Custom SQL**:
```sql
SELECT 
    t.*,
    RUNNING_SUM(t.pnl) OVER (ORDER BY t.trade_id) as cumulative_pnl
FROM trades t
WHERE t.trade_date >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
```

3. **Live Connection vs Extract**:
   - Live: Real-time data, slower performance
   - Extract: Faster, scheduled refreshes (daily recommended)

---

## Publishing & Sharing

1. **Tableau Public**: Free option for public dashboards
2. **Tableau Server**: Enterprise solution
3. **Tableau Online**: Cloud-hosted option
4. **Export Options**: 
   - PDF for reports
   - PNG for presentations
   - PowerPoint integration

---

## Next Steps

1. Load the data source (trade_log.csv or database)
2. Create calculated fields
3. Build individual visualizations
4. Combine into dashboards
5. Apply filters and actions
6. Publish and share

**Pro Tip**: Start with the Executive Dashboard first to get familiar with the data, then build specialized dashboards.

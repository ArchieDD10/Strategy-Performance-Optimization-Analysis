# How to Import Your Own Trading Data

## 📥 Quick Guide to Analyzing Your Own Trades

This guide shows you how to replace the sample data with your actual trading records.

---

## Step 1: Prepare Your Excel File

### Required Columns

Your Excel file needs these columns (in any order):

| Column Name | Type | Description | Example |
|------------|------|-------------|---------|
| **Date** | Date | Trade date | 2024-01-15 |
| **Time** | Time/Text | Trade time | 14:30 or 14:30:00 |
| **Instrument** | Text | What you traded | EUR/USD, AAPL, NAS100 |
| **Setup_Type** | Text | Your setup/strategy | Breakout, Reversal, Trend Following |
| **Session** | Text | Market session | London, New York, Tokyo |
| **Risk_Reward_Ratio** | Number | Your R:R target | 2.0, 1.5, 3.0 |
| **Risk_Amount** | Number | $ risked per trade | 100, 150, 200 |
| **Win_Loss** | Text | Outcome | Win or Loss |
| **PnL** | Number | Profit/Loss in $ | 250.50, -100.00 |

### Optional Columns (will be calculated if missing)

- **Balance** - Will be calculated from starting balance + cumulative P&L
- **Peak_Balance** - Calculated automatically
- **Drawdown_Pct** - Calculated automatically
- **Day_of_Week** - Extracted from Date
- **Month** - Extracted from Date
- **Year** - Extracted from Date
- **Quarter** - Extracted from Date
- **Hour** - Extracted from Time

---

## Step 2: Format Your Data

### Example Excel Layout

```
Date       | Time  | Instrument | Setup_Type      | Session | R:R | Risk | Win_Loss | PnL
-----------|-------|------------|-----------------|---------|-----|------|----------|-------
2024-01-15 | 09:30 | EUR/USD    | Breakout        | London  | 2.0 | 100  | Win      | 200
2024-01-15 | 14:00 | GBP/USD    | Trend Following | NY      | 1.5 | 100  | Loss     | -100
2024-01-16 | 10:15 | AAPL       | Reversal        | NY      | 3.0 | 150  | Win      | 450
```

### Important Rules

✅ **Dates**: Use format YYYY-MM-DD (e.g., 2024-01-15) or Excel date format  
✅ **Times**: Use HH:MM or HH:MM:SS format (24-hour)  
✅ **Win_Loss**: Must be exactly "Win" or "Loss" (case-sensitive)  
✅ **PnL**: Positive for wins, negative for losses  
✅ **No blank rows**: Remove any empty rows between data  

---

## Step 3: Save Your File

1. **Save as CSV** (recommended):
   - File → Save As
   - Choose "CSV (Comma delimited) (*.csv)"
   - Save as: `my_trades.csv`

2. **OR keep as Excel**:
   - Save as: `my_trades.xlsx`
   - Make sure data is on first sheet

---

## Step 4: Import Using Python Script

### Option A: Automatic Import (Easiest)

Create this Python script as `import_my_data.py` in the `python` folder:

```python
import pandas as pd
import numpy as np
from datetime import datetime

# ============================================================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================================================

# Path to your Excel/CSV file
YOUR_DATA_FILE = "C:/path/to/your/my_trades.xlsx"  # Change this!

# Your starting account balance
STARTING_BALANCE = 10000  # Change this!

# ============================================================================

def import_and_process_data(file_path, starting_balance):
    """Import your trading data and calculate derived fields"""
    
    print(f"Reading data from: {file_path}")
    
    # Read your file
    if file_path.endswith('.csv'):
        df = pd.read_csv(file_path)
    else:
        df = pd.read_excel(file_path)
    
    print(f"✓ Loaded {len(df)} trades")
    
    # Ensure required columns exist
    required_cols = ['Date', 'Instrument', 'Setup_Type', 'Session', 
                     'Risk_Reward_Ratio', 'Risk_Amount', 'Win_Loss', 'PnL']
    
    missing_cols = [col for col in required_cols if col not in df.columns]
    if missing_cols:
        print(f"✗ Missing required columns: {missing_cols}")
        return None
    
    # Standardize column names
    df.columns = [col.replace(' ', '_') for col in df.columns]
    
    # Add Trade_ID if not present
    if 'Trade_ID' not in df.columns:
        df['Trade_ID'] = range(1, len(df) + 1)
    
    # Convert dates
    df['Date'] = pd.to_datetime(df['Date'])
    
    # Add Time if missing
    if 'Time' not in df.columns:
        df['Time'] = '12:00'
    
    # Calculate Balance if not present
    if 'Balance' not in df.columns:
        df['Balance'] = starting_balance + df['PnL'].cumsum()
    
    # Calculate Peak Balance
    df['Peak_Balance'] = df['Balance'].cummax()
    
    # Calculate Drawdown
    df['Drawdown_Pct'] = ((df['Peak_Balance'] - df['Balance']) / df['Peak_Balance']) * 100
    
    # Add date components
    df['Day_of_Week'] = df['Date'].dt.day_name()
    df['Month'] = df['Date'].dt.month_name()
    df['Year'] = df['Date'].dt.year
    df['Quarter'] = df['Date'].dt.quarter
    
    # Extract hour from time
    if df['Time'].dtype == 'object':
        df['Hour'] = pd.to_datetime(df['Time'], format='%H:%M', errors='coerce').dt.hour
    else:
        df['Hour'] = pd.to_datetime(df['Time']).dt.hour
    
    # Sort by date
    df = df.sort_values(['Date', 'Time']).reset_index(drop=True)
    
    return df

def save_and_summarize(df):
    """Save processed data and show summary"""
    
    # Save CSV
    output_csv = '../data/raw/trade_log.csv'
    df.to_csv(output_csv, index=False)
    print(f"✓ Saved to {output_csv}")
    
    # Save Excel with summaries
    output_excel = '../data/raw/trade_log.xlsx'
    with pd.ExcelWriter(output_excel, engine='openpyxl') as writer:
        df.to_excel(writer, sheet_name='Trade_Log', index=False)
        
        # Setup summary
        setup_stats = df.groupby('Setup_Type').agg({
            'Win_Loss': lambda x: (x == 'Win').sum() / len(x) * 100,
            'PnL': ['sum', 'mean', 'count']
        }).round(2)
        setup_stats.columns = ['Win_Rate_%', 'Total_PnL', 'Avg_PnL', 'Trades']
        setup_stats.to_excel(writer, sheet_name='Setup_Analysis')
        
        # Session summary
        session_stats = df.groupby('Session').agg({
            'Win_Loss': lambda x: (x == 'Win').sum() / len(x) * 100,
            'PnL': ['sum', 'mean', 'count']
        }).round(2)
        session_stats.columns = ['Win_Rate_%', 'Total_PnL', 'Avg_PnL', 'Trades']
        session_stats.to_excel(writer, sheet_name='Session_Analysis')
    
    print(f"✓ Saved to {output_excel}")
    
    # Print summary
    print("\n" + "="*60)
    print("YOUR TRADING PERFORMANCE SUMMARY")
    print("="*60)
    
    total_trades = len(df)
    wins = len(df[df['Win_Loss'] == 'Win'])
    losses = len(df[df['Win_Loss'] == 'Loss'])
    win_rate = (wins / total_trades) * 100
    
    total_pnl = df['PnL'].sum()
    avg_win = df[df['Win_Loss'] == 'Win']['PnL'].mean()
    avg_loss = abs(df[df['Win_Loss'] == 'Loss']['PnL'].mean())
    
    print(f"Total Trades: {total_trades}")
    print(f"Wins: {wins} | Losses: {losses}")
    print(f"Win Rate: {win_rate:.2f}%")
    print(f"Total P&L: ${total_pnl:,.2f}")
    print(f"Average Win: ${avg_win:.2f}")
    print(f"Average Loss: ${avg_loss:.2f}")
    print(f"Profit Factor: {(wins * avg_win) / (losses * avg_loss):.2f}")
    print(f"Final Balance: ${df['Balance'].iloc[-1]:,.2f}")
    print(f"Max Drawdown: {df['Drawdown_Pct'].max():.2f}%")
    print("="*60)

# Main execution
if __name__ == "__main__":
    print("="*60)
    print("IMPORTING YOUR TRADING DATA")
    print("="*60)
    print()
    
    # Import and process
    df = import_and_process_data(YOUR_DATA_FILE, STARTING_BALANCE)
    
    if df is not None:
        # Save and summarize
        save_and_summarize(df)
        
        print("\n✓ Import complete! Your data is ready for analysis.")
        print("\nNext steps:")
        print("  1. Run: python feature_engineering.py")
        print("  2. Run: python outlier_detection.py")
        print("  3. Run: python statistical_analysis.py")
        print("  4. Open Tableau and analyze!")
    else:
        print("\n✗ Import failed. Please check your data format.")
```

### Run the Import Script

```powershell
# 1. Edit import_my_data.py and update YOUR_DATA_FILE path
# 2. Update STARTING_BALANCE to your actual starting balance
# 3. Run the script

cd python
python import_my_data.py
```

---

## Step 5: Run the Analysis

Once your data is imported, run the complete analysis:

```powershell
# Run all analytics
python feature_engineering.py
python outlier_detection.py
python statistical_analysis.py
```

Or use the automation script:

```powershell
# Windows
.\run_pipeline.ps1

# Mac/Linux
./run_pipeline.sh
```

---

## Option B: Manual Import (Using Excel)

### If you prefer working in Excel:

1. **Open the template**: `data/raw/trade_log.xlsx`
2. **Go to "Trade_Log" sheet**
3. **Delete sample data** (rows 2 and below)
4. **Copy your data** from your Excel file
5. **Paste into Trade_Log sheet**
6. **Verify columns match** the template
7. **Save the file**
8. **Export to CSV**: Save As → CSV → `trade_log.csv`

---

## Option C: Direct CSV Replacement

### Simplest method if you have clean data:

1. **Prepare your CSV** with the required columns
2. **Replace the file**: Copy your CSV to `data/raw/trade_log.csv`
3. **Run the pipeline**:
   ```powershell
   cd python
   python feature_engineering.py
   python statistical_analysis.py
   ```

---

## Troubleshooting

### "Missing required columns"
- Check column names match exactly (case-sensitive)
- Use underscores instead of spaces: `Risk_Amount` not `Risk Amount`

### "Date parsing error"
- Ensure dates are in YYYY-MM-DD format or Excel date format
- Check for blank date cells

### "Win_Loss must be Win or Loss"
- Verify values are exactly "Win" or "Loss" (capital W and L)
- Check for extra spaces or typos

### "Negative balance calculated"
- Verify your starting balance is correct
- Check that losses are negative numbers in PnL column

### "Python module not found"
- Install dependencies: `pip install -r requirements.txt`

---

## Example: Complete Workflow

```powershell
# 1. Create import script (copy code above)
New-Item -Path python/import_my_data.py -ItemType File

# 2. Edit the file and set YOUR_DATA_FILE path

# 3. Run import
cd python
python import_my_data.py

# 4. Run analysis pipeline
python feature_engineering.py
python outlier_detection.py
python statistical_analysis.py

# 5. Open Tableau
# Connect to data/raw/trade_log.csv
# Build your dashboards!
```

---

## What You'll Get

After importing your data, you'll have:

✅ **data/raw/trade_log.csv** - Your cleaned trading data  
✅ **data/raw/trade_log.xlsx** - Excel with summary sheets  
✅ **data/processed/trade_features.csv** - 80+ engineered features  
✅ **data/processed/outlier_report.csv** - Detected anomalies  
✅ **docs/performance_metrics.txt** - Statistical analysis  
✅ **docs/outlier_analysis.png** - Visualizations  

Plus all SQL and Tableau analytics on **your actual data**!

---

## Tips for Best Results

### Data Quality
- **Be honest**: Include all trades (wins and losses)
- **Be complete**: Don't skip trades
- **Be consistent**: Use same naming for setups/sessions
- **Be accurate**: Double-check P&L values

### Minimum Recommended Data
- **At least 50 trades** for meaningful statistics
- **100+ trades** for reliable patterns
- **200+ trades** for robust analysis
- **500+ trades** for excellent insights

### Common Setups to Use
- Breakout
- Reversal
- Trend Following
- Range Trading
- Scalping
- Swing Trading
- News Trading

### Common Sessions
- London
- New York
- Tokyo
- Sydney
- Overlap-EU-US
- Overlap-Asia-EU

---

## Need Help?

If you run into issues:

1. Check the example data in `trade_log.csv` for reference
2. Verify your column names match exactly
3. Ensure dates and times are properly formatted
4. Check that Win/Loss values are correct
5. Review the error messages carefully

---

**You're ready to analyze your own trading performance!** 📊

Once your data is imported, all the SQL queries, Python analytics, and Tableau dashboards will work with your actual trades.

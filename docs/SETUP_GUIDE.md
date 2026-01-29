# Quick Setup Guide

## 🚀 Getting Started in 5 Steps

### Step 1: Environment Setup (5 minutes)

**Install Python dependencies:**
```powershell
cd python
pip install -r requirements.txt
```

**Verify installation:**
```powershell
python -c "import pandas, numpy, scipy; print('All packages installed successfully!')"
```

### Step 2: Generate Sample Data (2 minutes)

```powershell
python generate_sample_data.py
```

**Expected output:**
- `data/raw/trade_log.csv` (500 trades)
- `data/raw/trade_log.xlsx` (with summary sheets)
- Console output showing performance summary

### Step 3: Database Setup (10 minutes)

**Option A: MySQL**
```sql
-- Create database
CREATE DATABASE trading_performance;
USE trading_performance;

-- Run setup scripts
SOURCE sql/01_create_tables.sql;
SOURCE sql/02_load_data.sql;

-- Verify
SELECT COUNT(*) as total_trades FROM trades;
```

**Option B: PostgreSQL**
```sql
-- Create database
CREATE DATABASE trading_performance;
\c trading_performance

-- Run setup scripts
\i sql/01_create_tables.sql
\i sql/02_load_data.sql

-- Verify
SELECT COUNT(*) as total_trades FROM trades;
```

**Option C: Skip SQL (use CSV directly in Tableau)**
- You can skip database setup and connect Tableau directly to the CSV files
- This is the fastest option for testing

### Step 4: Run Python Analytics (5 minutes)

```powershell
# Feature engineering
python feature_engineering.py

# Outlier detection
python outlier_detection.py

# Statistical analysis
python statistical_analysis.py
```

**Generated outputs:**
- `data/processed/trade_features.csv`
- `data/processed/outlier_report.csv`
- `docs/performance_metrics.txt`
- `docs/outlier_analysis.png`

### Step 5: Build Tableau Dashboard (20 minutes)

1. **Open Tableau Desktop**

2. **Connect to Data Source:**
   - File → Open → `tableau/trade_performance.tds`
   - OR manually connect to `data/raw/trade_log.csv`

3. **Create First Dashboard:**
   - Follow `tableau/TABLEAU_DASHBOARD_GUIDE.md`
   - Start with Executive Dashboard (easiest)
   - Add KPIs: Total P&L, Win Rate, Profit Factor, Max Drawdown

4. **Add Visualizations:**
   - Equity Curve (line chart)
   - Monthly Performance (bar chart)
   - Session Heatmap

5. **Publish or Save:**
   - Save as `.twbx` (packaged workbook)
   - OR publish to Tableau Public

---

## 📂 What You Should Have Now

```
✅ data/raw/trade_log.csv (500 trades)
✅ data/raw/trade_log.xlsx
✅ data/processed/trade_features.csv (with 80+ features)
✅ data/processed/outlier_report.csv
✅ docs/performance_metrics.txt
✅ docs/outlier_analysis.png
✅ SQL database loaded (optional)
✅ Tableau dashboard started
```

---

## 🔧 Common Issues & Solutions

### Issue 1: Python Package Installation Errors

**Problem:** `pip install` fails with permission errors

**Solution:**
```powershell
# Use --user flag
pip install --user -r requirements.txt

# OR create virtual environment (recommended)
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Issue 2: SQL Data Loading Fails

**Problem:** `LOAD DATA INFILE` permission denied

**Solution:**
```sql
-- For MySQL, check secure_file_priv
SHOW VARIABLES LIKE 'secure_file_priv';

-- Move CSV to allowed directory OR use Python to load
-- See alternative in sql/02_load_data.sql comments
```

**Alternative: Use Python to load SQL:**
```python
import pandas as pd
from sqlalchemy import create_engine

# Read CSV
df = pd.read_csv('../data/raw/trade_log.csv')

# Create connection
engine = create_engine('mysql+pymysql://user:password@localhost/trading_performance')

# Load to database
df.to_sql('trades', engine, if_exists='append', index=False)
```

### Issue 3: Tableau Can't Find Data

**Problem:** Tableau shows "File not found" error

**Solution:**
- Use absolute path instead of relative path
- OR copy CSV files to Tableau's default data directory
- OR connect directly without using .tds file

### Issue 4: Missing Python Libraries

**Problem:** `ModuleNotFoundError: No module named 'sklearn'`

**Solution:**
```powershell
# Install scikit-learn specifically
pip install scikit-learn

# OR install all requirements again
pip install -r requirements.txt --upgrade
```

---

## 🎯 Quick Wins (What to Show First)

### For Your Portfolio:

1. **Equity Curve** → Shows growth over time
2. **Session Performance Heatmap** → Visually impressive
3. **Setup Recommendation Table** → Shows business value
4. **Feature Engineering Script** → Shows technical skill

### For Interviews:

**Be ready to explain:**
- Why you chose certain metrics (Sharpe ratio, profit factor, etc.)
- How you handled outliers
- The business value of identifying underperforming setups
- How this project demonstrates end-to-end BI skills

---

## 📊 Sample Dashboard Preview

Once complete, your main dashboard should show:

**Top Row (KPIs):**
```
┌─────────────┬──────────────┬─────────────┬────────────────┐
│  Total P&L  │  Win Rate %  │ Profit Factor│ Max Drawdown % │
│   $12,450   │    52.4%     │     1.85     │     15.2%      │
└─────────────┴──────────────┴─────────────┴────────────────┘
```

**Middle Row:**
```
┌────────────────────────────────────────────────────────────┐
│                    Equity Curve                            │
│  (Line chart showing account balance over time)            │
└────────────────────────────────────────────────────────────┘
```

**Bottom Row:**
```
┌─────────────────────────┬──────────────────────────────────┐
│  Monthly Performance    │   Session Performance Heatmap    │
│  (Bar chart)            │   (Hour vs Day of Week)          │
└─────────────────────────┴──────────────────────────────────┘
```

---

## 🎓 Next Steps

### Level Up Your Project:

1. **Add More Data:**
   - Increase to 1000+ trades
   - Add more instruments
   - Include fundamental data (news events)

2. **Advanced Analytics:**
   - Build ML model to predict trade success
   - Add Monte Carlo simulations
   - Implement walk-forward optimization

3. **Automation:**
   - Schedule daily data refresh
   - Automated report generation
   - Email alerts for anomalies

4. **Web Dashboard:**
   - Convert to Plotly Dash or Streamlit
   - Add real-time streaming
   - Enable mobile access

5. **Share Your Work:**
   - Publish Tableau dashboard to Tableau Public
   - Write blog post about insights
   - Create YouTube walkthrough
   - Add to LinkedIn portfolio

---

## 📚 Additional Resources

### Learning Resources:

- **SQL Window Functions**: [Mode Analytics SQL Tutorial](https://mode.com/sql-tutorial/)
- **Tableau Dashboards**: [Tableau Public Gallery](https://public.tableau.com/gallery/)
- **Python for Finance**: [Python for Finance Book](https://www.oreilly.com/library/view/python-for-finance/9781492024323/)
- **Trading Analytics**: [QuantConnect Documentation](https://www.quantconnect.com/docs)

### Tools Documentation:

- **pandas**: https://pandas.pydata.org/docs/
- **SQL**: https://dev.mysql.com/doc/
- **Tableau**: https://help.tableau.com/
- **scikit-learn**: https://scikit-learn.org/

---

## ✅ Checklist Before Sharing

- [ ] All Python scripts run without errors
- [ ] SQL queries execute successfully
- [ ] Tableau dashboard opens and displays data
- [ ] README.md has your contact info updated
- [ ] Screenshots added to docs/ folder
- [ ] GitHub repository is public
- [ ] Code is commented and clean
- [ ] Sample data generates correctly
- [ ] All file paths are relative (no hard-coded paths)
- [ ] Requirements.txt is complete

---

## 🚀 You're Ready!

Your flagship BI project is complete! This demonstrates:

✅ **Data Engineering** - ETL pipeline  
✅ **SQL** - Complex analytics queries  
✅ **Python** - Feature engineering & statistics  
✅ **Tableau** - Interactive dashboards  
✅ **Business Acumen** - Actionable insights  

**Perfect for BI Analyst interviews!**

---

## 💡 Pro Tips

1. **Practice your walkthrough**: Can you explain the entire project in 5 minutes?
2. **Know your numbers**: Memorize key metrics (win rate, profit factor, etc.)
3. **Be ready for deep dives**: Interviewers may ask about specific SQL queries or Python code
4. **Customize for companies**: Research the company and emphasize relevant aspects
5. **Have it live**: Host Tableau dashboard online for easy sharing

---

## 📞 Need Help?

If you run into issues:

1. Check the error message carefully
2. Review the relevant section in this guide
3. Check Python/SQL/Tableau documentation
4. Search Stack Overflow
5. Verify your Python version (3.8+) and package versions

---

Good luck with your BI Analyst interviews! 🎉

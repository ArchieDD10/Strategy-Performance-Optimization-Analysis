# Getting Started with Tableau - Step-by-Step Guide

## 📊 Complete Beginner's Guide to Building Your Trading Dashboard

This guide walks you through using Tableau with your trading data, from installation to creating your first dashboard.

---

## Step 1: Install Tableau (If Needed)

### Option A: Tableau Public (Free)
1. Go to [https://public.tableau.com/](https://public.tableau.com/)
2. Click "Download Tableau Public"
3. Install and create a free account
4. **Note**: Dashboards will be public (good for portfolio!)

### Option B: Tableau Desktop (Paid/Trial)
1. Go to [https://www.tableau.com/products/desktop](https://www.tableau.com/products/desktop)
2. Start 14-day free trial
3. Download and install
4. **Note**: Can save private workbooks

---

## Step 2: Open Tableau and Connect to Data

### Connect to Your Trading Data

1. **Launch Tableau Desktop/Public**

2. **Connect to Data**:
   - On the start screen, under "Connect" → "To a File"
   - Click **"Text file"** (for CSV) or **"Microsoft Excel"** (for .xlsx)

3. **Browse to your data**:
   ```
   C:\Projects\Performance-Optimization-Analysis\
   Strategy-Performance-Optimization-Analysis\data\raw\trade_log.csv
   ```

4. **Preview your data**:
   - You should see all your trades in the preview pane
   - Verify columns look correct
   - Check data types (Date should be Date, PnL should be Number)

5. **Click "Sheet 1"** at the bottom to start building

---

## Step 3: Understanding the Tableau Interface

### Key Areas

```
┌─────────────────────────────────────────────────────────────┐
│  [File] [Data] [Worksheet] [Dashboard] [Story] [Analysis]  │ ← Menus
├─────────────────────────────────────────────────────────────┤
│ Data Pane          │         Canvas                         │
│ ┌─────────────┐   │   [Drop sheets here]                   │
│ │ Tables      │   │                                         │
│ │  trade_log  │   │   Your visualization appears here      │
│ │             │   │                                         │
│ │ Dimensions  │   │                                         │
│ │  • Date     │   │                                         │
│ │  • Session  │   │                                         │
│ │  • Setup    │   │                                         │
│ │             │   │                                         │
│ │ Measures    │   │                                         │
│ │  • PnL      │   │                                         │
│ │  • Balance  │   │                                         │
│ └─────────────┘   │                                         │
│                    │                                         │
│  Marks Card        │                                         │
│  ┌──────────┐     │                                         │
│  │ Color    │     │                                         │
│  │ Size     │     │                                         │
│  │ Label    │     │                                         │
│  └──────────┘     │                                         │
└─────────────────────────────────────────────────────────────┘
  ← Rows            ← Columns →
```

### Key Concepts

- **Dimensions** (Blue pills): Categories (Date, Setup, Session, Instrument)
- **Measures** (Green pills): Numbers (PnL, Balance, Risk Amount)
- **Columns/Rows**: Where you drag fields to create visualizations
- **Marks Card**: Controls colors, sizes, labels, tooltips

---

## Step 4: Create Your First Visualization - Equity Curve

### Let's Build a Simple Line Chart Showing Account Growth

**Step-by-step:**

1. **Drag "Date"** from Dimensions to **Columns** (top)
   - Tableau may aggregate by year - click the dropdown and select "Day"

2. **Drag "Balance"** from Measures to **Rows** (left side)

3. **Change to Line Chart**:
   - On Marks card, click dropdown (default is "Automatic")
   - Select **"Line"**

4. **Format the chart**:
   - Right-click Y-axis → "Format"
   - Under "Numbers" → select "Currency (Custom)" → "$"
   - Click "Color" on Marks card → choose a nice green

5. **Add title**:
   - Double-click the title at top
   - Type: "Equity Curve - Account Growth Over Time"

**🎉 You just created your first visualization!**

---

## Step 5: Create Key Visualizations

### Visualization #1: Total P&L (Big Number KPI)

1. **Create new sheet**: Click icon next to "Sheet 1" tab
2. **Drag "PnL"** to the canvas (center)
3. **Change to text**:
   - Marks card → select "Text"
4. **Format**:
   - Right-click on the number → "Format"
   - Numbers → Currency → "$"
5. **Make it bigger**:
   - Click "Text" on Marks card → Click "..." button
   - Increase font size to 48
6. **Add color**:
   - Click "Color" on Marks card
   - Choose green for positive, red for negative
7. **Rename sheet**: Right-click tab → "Rename" → "Total P&L"

### Visualization #2: Win Rate %

1. **Create new sheet**
2. **Create calculated field**:
   - Right-click in Data pane → "Create Calculated Field"
   - Name: `Win Rate %`
   - Formula: 
     ```
     SUM(IF [Win_Loss] = "Win" THEN 1 ELSE 0 END) / COUNT([Trade_ID]) * 100
     ```
   - Click OK

3. **Drag "Win Rate %"** to canvas
4. **Format as percentage**:
   - Right-click → Format → Number → Percentage → 1 decimal
5. **Make it big** (font size 48)
6. **Rename sheet**: "Win Rate"

### Visualization #3: Monthly Performance (Bar Chart)

1. **Create new sheet**
2. **Drag "Date"** to Columns
   - Click dropdown → select "Month"
3. **Drag "PnL"** to Rows
4. **Change to Bar**:
   - Marks card → "Bar"
5. **Add color by positive/negative**:
   - Drag "PnL" to Color on Marks card
   - Click Color → Edit Colors → choose diverging palette (red to green)
6. **Sort by date**:
   - Click sort icon on toolbar
7. **Rename sheet**: "Monthly Performance"

### Visualization #4: Performance by Session (Bar Chart)

1. **Create new sheet**
2. **Drag "Session"** to Rows
3. **Drag "PnL"** to Columns
4. **Sort descending**:
   - Click descending sort icon
5. **Add win rate as dual axis**:
   - Drag "Win Rate %" to Columns (next to PnL)
   - Right-click the "Win Rate %" pill → "Dual Axis"
   - Right-click right Y-axis → "Synchronize Axis"
6. **Format**:
   - Click "Color" → Choose different colors for each
7. **Rename sheet**: "Session Performance"

### Visualization #5: Session Heatmap (Time of Day Analysis)

1. **Create new sheet**
2. **Drag "Hour"** to Columns
3. **Drag "Day_of_Week"** to Rows
4. **Drag "PnL"** to Color
5. **Change mark type**:
   - Marks card → "Square"
6. **Format colors**:
   - Click Color → Edit Colors → Choose "Red-Green Diverging"
7. **Add labels**:
   - Drag "PnL" to Label on Marks card
   - Format → "$"
8. **Rename sheet**: "Session Heatmap"

---

## Step 6: Create a Dashboard

### Combine Your Visualizations into One Dashboard

1. **Create Dashboard**:
   - Click Dashboard menu → "New Dashboard"
   - OR click dashboard icon at bottom

2. **Set size**:
   - Left sidebar → Size → "Automatic" or "Desktop (1200 x 800)"

3. **Add sheets**:
   - From left sidebar, drag sheets onto canvas:
     - **Top row**: Total P&L, Win Rate, Profit Factor (side by side)
     - **Middle**: Equity Curve (full width)
     - **Bottom left**: Monthly Performance
     - **Bottom right**: Session Performance

4. **Arrange layout**:
   - Drag sheets to position
   - Resize by dragging edges
   - Use "Tiled" or "Floating" layouts

5. **Add title**:
   - Drag "Text" object from Objects panel
   - Type: "Trading Performance Dashboard"
   - Format → Font size 24, Bold

6. **Add filters**:
   - Click any sheet in dashboard
   - Click filter icon (funnel) → "Add Filter"
   - Select "Date" → "Range of Dates"
   - Repeat for "Setup_Type", "Session", "Instrument"

7. **Make interactive**:
   - Click a sheet → Click funnel icon → "Use as Filter"
   - Now clicking on that sheet filters other sheets

---

## Step 7: Create Calculated Fields (Important Metrics)

### Essential Calculated Fields for Trading

Click "Analysis" → "Create Calculated Field" and add these:

**1. Profit Factor**
```tableau
ABS(SUM(IF [Win_Loss] = "Win" THEN [PnL] END) / 
    SUM(IF [Win_Loss] = "Loss" THEN [PnL] END))
```

**2. Average Win**
```tableau
AVG(IF [Win_Loss] = "Win" THEN [PnL] END)
```

**3. Average Loss**
```tableau
AVG(IF [Win_Loss] = "Loss" THEN [PnL] END)
```

**4. Cumulative P&L**
```tableau
RUNNING_SUM(SUM([PnL]))
```

**5. Win Rate %** (already created above)
```tableau
SUM(IF [Win_Loss] = "Win" THEN 1 ELSE 0 END) / COUNT([Trade_ID]) * 100
```

**6. Expectancy**
```tableau
AVG([PnL])
```

**7. Risk-Adjusted Return (Sharpe-like)**
```tableau
AVG([PnL]) / STDEV([PnL])
```

---

## Step 8: Build the Complete Executive Dashboard

### Follow This Layout

```
┌─────────────────────────────────────────────────────────────┐
│        TRADING PERFORMANCE DASHBOARD                        │
├──────────────┬──────────────┬──────────────┬───────────────┤
│  Total P&L   │  Win Rate %  │ Profit Factor│ Max Drawdown  │
│  $26,847     │    50.6%     │     2.09     │    4.16%      │
├──────────────────────────────────────────────────────────────┤
│                    Equity Curve                              │
│  [Line chart showing balance over time]                      │
├────────────────────────────┬─────────────────────────────────┤
│  Monthly Performance       │   Session Performance           │
│  [Bar chart by month]      │   [Bar chart by session]        │
└────────────────────────────┴─────────────────────────────────┘
```

### Steps:

1. Create 4 KPI sheets (P&L, Win Rate, Profit Factor, Max Drawdown)
2. Create Equity Curve (Line chart of Balance over Date)
3. Create Monthly Performance (Bar chart)
4. Create Session Performance (Bar chart)
5. Create new Dashboard
6. Arrange sheets as shown above
7. Add filters for Date, Setup, Session
8. Make it interactive

---

## Step 9: Save and Share

### Save Your Work

**Tableau Public:**
```
File → Save to Tableau Public
- Login to your account
- Enter workbook name
- Click "Save"
- Your dashboard is now online!
```

**Tableau Desktop:**
```
File → Save As
- Choose location
- Save as .twb (linked to data) or .twbx (packaged with data)
```

### Share Your Dashboard

**Tableau Public:**
- Copy the URL from Tableau Public
- Share on LinkedIn, portfolio, resume
- Perfect for showing employers!

**Tableau Desktop:**
- File → Export → Image (for presentations)
- File → Export → PDF (for reports)
- Publish to Tableau Server (if available)

---

## Quick Tips for Better Dashboards

### Design Best Practices

✅ **Color Coding**:
- Green = Profit, Wins
- Red = Loss, Negative
- Blue = Neutral metrics

✅ **KPIs at Top**:
- Most important metrics first
- Big numbers, easy to read

✅ **Consistent Fonts**:
- Title: 20-24pt
- Headers: 14-16pt
- Body: 10-12pt

✅ **White Space**:
- Don't overcrowd
- Let visualizations breathe

✅ **Interactivity**:
- Add filters for exploration
- Use tooltips for details
- Enable drill-down

### Common Mistakes to Avoid

❌ Too many colors  
❌ Cluttered layouts  
❌ Missing titles/labels  
❌ Wrong chart types  
❌ No filters  
❌ Unformatted numbers  

---

## Troubleshooting

### "Can't connect to file"
- Check file path is correct
- Ensure file isn't open in Excel
- Try absolute path instead of relative

### "Date field showing as text"
- Click field → Change Data Type → Date
- Or right-click in Data pane → "Change Data Type"

### "Numbers not showing currency format"
- Right-click axis/number → Format
- Numbers → Currency → Custom → "$"

### "Can't create calculated field"
- Check formula syntax
- Ensure field names match exactly
- Look for missing brackets or quotes

### "Dashboard looks messy"
- Use containers (horizontal/vertical)
- Set consistent padding (5-10px)
- Align sheets to grid

---

## Next Steps: Advanced Features

Once comfortable with basics, try:

1. **Parameters**: Create dynamic what-if scenarios
2. **Sets**: Define custom groups of trades
3. **Table Calculations**: Running totals, percent of total
4. **Actions**: Click to filter, highlight related data
5. **Animations**: Show changes over time
6. **Mobile Layouts**: Optimize for phones/tablets

---

## Learning Resources

### Official Tableau Resources
- **Tableau Public Gallery**: [public.tableau.com/gallery](https://public.tableau.com/gallery)
- **Tableau Training**: [help.tableau.com/current/pro/desktop/en-us/getstarted_overview.htm](https://help.tableau.com/current/pro/desktop/en-us/getstarted_overview.htm)
- **Tableau Community**: [community.tableau.com](https://community.tableau.com)

### YouTube Tutorials
- Search: "Tableau beginner tutorial"
- Search: "Tableau dashboard design"
- Search: "Tableau financial dashboard"

### Practice Datasets
- Use your actual trading data!
- More trades = better insights

---

## Your Complete Dashboard Checklist

- [ ] Connect to trade_log.csv
- [ ] Create Total P&L visualization
- [ ] Create Win Rate % visualization
- [ ] Create Profit Factor visualization
- [ ] Create Equity Curve (line chart)
- [ ] Create Monthly Performance (bar chart)
- [ ] Create Session Performance (bar chart)
- [ ] Create Session Heatmap
- [ ] Create Setup Performance table
- [ ] Build Executive Dashboard
- [ ] Add filters (Date, Setup, Session)
- [ ] Make sheets interactive
- [ ] Format numbers (currency, percentages)
- [ ] Add titles and labels
- [ ] Save workbook
- [ ] Export/publish for portfolio

---

## 🎯 Your First Goal

**In Your First Session, Create:**

1. ✅ Connect to data (5 min)
2. ✅ Equity curve line chart (10 min)
3. ✅ Total P&L KPI (5 min)
4. ✅ Win Rate KPI (10 min)
5. ✅ Simple dashboard combining them (10 min)

**Total time: 40 minutes**

You'll have a working dashboard to show!

---

## 🎉 You're Ready!

Tableau is powerful but intuitive. Start simple:
1. Connect to your data
2. Drag and drop fields
3. Choose chart types
4. Build dashboards
5. Share your work

**The best way to learn is by doing. Open Tableau now and follow along!**

For the complete dashboard blueprints, see: [tableau/TABLEAU_DASHBOARD_GUIDE.md](../tableau/TABLEAU_DASHBOARD_GUIDE.md)

Happy visualizing! 📊✨

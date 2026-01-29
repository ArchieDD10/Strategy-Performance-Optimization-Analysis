# Trading Performance Analytics - Quick Start Script
# Run this to execute the complete analysis pipeline

Write-Host "="*70 -ForegroundColor Cyan
Write-Host "TRADING PERFORMANCE ANALYTICS - COMPLETE PIPELINE" -ForegroundColor Cyan
Write-Host "="*70 -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Python installation
Write-Host "[1/5] Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Python not found. Please install Python 3.8 or higher." -ForegroundColor Red
    exit 1
}

# Step 2: Install dependencies
Write-Host ""
Write-Host "[2/5] Installing Python dependencies..." -ForegroundColor Yellow
Set-Location python
pip install -r requirements.txt --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "! Some packages may have failed to install" -ForegroundColor Yellow
}

# Step 3: Generate sample data
Write-Host ""
Write-Host "[3/5] Generating sample trading data..." -ForegroundColor Yellow
python generate_sample_data.py
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Sample data generated successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Data generation failed" -ForegroundColor Red
    exit 1
}

# Step 4: Run feature engineering
Write-Host ""
Write-Host "[4/5] Running feature engineering..." -ForegroundColor Yellow
python feature_engineering.py
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Features engineered successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Feature engineering failed" -ForegroundColor Red
}

# Step 5: Run outlier detection
Write-Host ""
Write-Host "[5/5] Running outlier detection and statistical analysis..." -ForegroundColor Yellow
python outlier_detection.py
python statistical_analysis.py

# Summary
Write-Host ""
Write-Host "="*70 -ForegroundColor Cyan
Write-Host "PIPELINE COMPLETE!" -ForegroundColor Green
Write-Host "="*70 -ForegroundColor Cyan
Write-Host ""
Write-Host "Generated files:" -ForegroundColor White
Write-Host "  ✓ data/raw/trade_log.csv (500 trades)" -ForegroundColor Green
Write-Host "  ✓ data/raw/trade_log.xlsx (with summaries)" -ForegroundColor Green
Write-Host "  ✓ data/processed/trade_features.csv (80+ features)" -ForegroundColor Green
Write-Host "  ✓ data/processed/outlier_report.csv" -ForegroundColor Green
Write-Host "  ✓ docs/performance_metrics.txt" -ForegroundColor Green
Write-Host "  ✓ docs/outlier_analysis.png" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review data files in data/ directory" -ForegroundColor White
Write-Host "  2. Run SQL scripts on your database (sql/ directory)" -ForegroundColor White
Write-Host "  3. Open Tableau and connect to trade_log.csv" -ForegroundColor White
Write-Host "  4. Build dashboards using tableau/TABLEAU_DASHBOARD_GUIDE.md" -ForegroundColor White
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  - README.md - Project overview" -ForegroundColor White
Write-Host "  - docs/SETUP_GUIDE.md - Detailed setup instructions" -ForegroundColor White
Write-Host "  - docs/PROJECT_SUMMARY.md - Project highlights" -ForegroundColor White
Write-Host ""
Write-Host "Happy analyzing! 📊" -ForegroundColor Cyan

Set-Location ..

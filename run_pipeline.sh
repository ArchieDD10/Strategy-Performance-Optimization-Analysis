# Trading Performance Analytics - Quick Start (Bash)
# Run this to execute the complete analysis pipeline on Unix/Linux/Mac

echo "======================================================================"
echo "TRADING PERFORMANCE ANALYTICS - COMPLETE PIPELINE"
echo "======================================================================"
echo ""

# Step 1: Check Python installation
echo "[1/5] Checking Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✓ $PYTHON_VERSION"
    PYTHON_CMD=python3
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version)
    echo "✓ $PYTHON_VERSION"
    PYTHON_CMD=python
else
    echo "✗ Python not found. Please install Python 3.8 or higher."
    exit 1
fi

# Step 2: Install dependencies
echo ""
echo "[2/5] Installing Python dependencies..."
cd python
$PYTHON_CMD -m pip install -r requirements.txt --quiet
if [ $? -eq 0 ]; then
    echo "✓ Dependencies installed successfully"
else
    echo "! Some packages may have failed to install"
fi

# Step 3: Generate sample data
echo ""
echo "[3/5] Generating sample trading data..."
$PYTHON_CMD generate_sample_data.py
if [ $? -eq 0 ]; then
    echo "✓ Sample data generated successfully"
else
    echo "✗ Data generation failed"
    exit 1
fi

# Step 4: Run feature engineering
echo ""
echo "[4/5] Running feature engineering..."
$PYTHON_CMD feature_engineering.py
if [ $? -eq 0 ]; then
    echo "✓ Features engineered successfully"
else
    echo "✗ Feature engineering failed"
fi

# Step 5: Run outlier detection
echo ""
echo "[5/5] Running outlier detection and statistical analysis..."
$PYTHON_CMD outlier_detection.py
$PYTHON_CMD statistical_analysis.py

# Summary
echo ""
echo "======================================================================"
echo "PIPELINE COMPLETE!"
echo "======================================================================"
echo ""
echo "Generated files:"
echo "  ✓ data/raw/trade_log.csv (500 trades)"
echo "  ✓ data/raw/trade_log.xlsx (with summaries)"
echo "  ✓ data/processed/trade_features.csv (80+ features)"
echo "  ✓ data/processed/outlier_report.csv"
echo "  ✓ docs/performance_metrics.txt"
echo "  ✓ docs/outlier_analysis.png"
echo ""
echo "Next steps:"
echo "  1. Review data files in data/ directory"
echo "  2. Run SQL scripts on your database (sql/ directory)"
echo "  3. Open Tableau and connect to trade_log.csv"
echo "  4. Build dashboards using tableau/TABLEAU_DASHBOARD_GUIDE.md"
echo ""
echo "Documentation:"
echo "  - README.md - Project overview"
echo "  - docs/SETUP_GUIDE.md - Detailed setup instructions"
echo "  - docs/PROJECT_SUMMARY.md - Project highlights"
echo ""
echo "Happy analyzing! 📊"

cd ..

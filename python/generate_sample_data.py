"""
Generate Sample Trading Data for Performance Analytics Dashboard
Creates realistic trading data with various patterns and scenarios
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Set seed for reproducibility
np.random.seed(42)
random.seed(42)

# Configuration
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2025, 12, 31)
NUM_TRADES = 500

# Trading parameters
INSTRUMENTS = ['EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'NZD/USD', 'USD/CAD', 'EUR/GBP', 'XAU/USD', 'NAS100', 'SPX500']
SESSIONS = ['Sydney', 'Tokyo', 'London', 'New York', 'Overlap-EU-US', 'Overlap-Asia-EU']
SETUP_TYPES = ['Breakout', 'Reversal', 'Trend Following', 'Range Trading', 'News Trading', 'Scalping', 'Swing']

# Risk parameters
BASE_RISK = 100  # Base risk per trade in dollars
WIN_RATE_BASE = 0.52  # Base win rate (slightly profitable)

def generate_trades(num_trades):
    """Generate realistic trading data with patterns"""
    trades = []
    
    # Running balance
    balance = 10000
    peak_balance = balance
    
    for i in range(num_trades):
        # Generate date (business days only)
        days_offset = i * (365 * 3 / num_trades)
        trade_date = START_DATE + timedelta(days=int(days_offset))
        
        # Skip weekends
        while trade_date.weekday() >= 5:
            trade_date += timedelta(days=1)
        
        # Select session based on time of day (realistic distribution)
        hour = random.randint(0, 23)
        if 22 <= hour or hour < 6:
            session = 'Sydney'
        elif 6 <= hour < 9:
            session = 'Tokyo'
        elif 9 <= hour < 13:
            session = 'Overlap-Asia-EU'
        elif 13 <= hour < 16:
            session = 'London'
        elif 16 <= hour < 18:
            session = 'Overlap-EU-US'
        else:
            session = 'New York'
        
        # Setup type with varying win rates
        setup = random.choice(SETUP_TYPES)
        
        # Instrument
        instrument = random.choice(INSTRUMENTS)
        
        # Risk:Reward ratio (common values in trading)
        rr_ratio = random.choice([1.0, 1.5, 2.0, 2.5, 3.0])
        
        # Risk amount (varies slightly)
        risk_amount = BASE_RISK * random.uniform(0.8, 1.2)
        
        # Determine win/loss based on setup-specific win rate
        setup_win_rates = {
            'Breakout': 0.48,
            'Reversal': 0.45,
            'Trend Following': 0.58,
            'Range Trading': 0.52,
            'News Trading': 0.40,
            'Scalping': 0.55,
            'Swing': 0.50
        }
        
        # Session-based performance adjustments
        session_multipliers = {
            'Sydney': 0.92,
            'Tokyo': 0.95,
            'London': 1.08,
            'New York': 1.05,
            'Overlap-EU-US': 1.12,
            'Overlap-Asia-EU': 1.03
        }
        
        # Calculate adjusted win probability
        base_win_prob = setup_win_rates.get(setup, WIN_RATE_BASE)
        session_mult = session_multipliers.get(session, 1.0)
        adjusted_win_prob = min(0.75, base_win_prob * session_mult)
        
        # Add some variance based on recent performance (streaks)
        if i > 10:
            recent_trades = trades[-10:]
            recent_wins = sum(1 for t in recent_trades if t['Win_Loss'] == 'Win')
            # Mean reversion tendency
            if recent_wins > 7:
                adjusted_win_prob *= 0.85
            elif recent_wins < 3:
                adjusted_win_prob *= 1.15
        
        # Determine outcome
        is_win = random.random() < adjusted_win_prob
        
        # Calculate P&L
        if is_win:
            pnl = risk_amount * rr_ratio
            win_loss = 'Win'
        else:
            pnl = -risk_amount
            win_loss = 'Loss'
        
        # Update balance
        balance += pnl
        peak_balance = max(peak_balance, balance)
        
        # Calculate drawdown
        drawdown_pct = ((peak_balance - balance) / peak_balance) * 100 if peak_balance > 0 else 0
        
        # Store trade
        trade = {
            'Trade_ID': i + 1,
            'Date': trade_date.strftime('%Y-%m-%d'),
            'Time': f"{hour:02d}:{random.randint(0, 59):02d}",
            'Instrument': instrument,
            'Setup_Type': setup,
            'Session': session,
            'Risk_Reward_Ratio': round(rr_ratio, 1),
            'Risk_Amount': round(risk_amount, 2),
            'Win_Loss': win_loss,
            'PnL': round(pnl, 2),
            'Balance': round(balance, 2),
            'Peak_Balance': round(peak_balance, 2),
            'Drawdown_Pct': round(drawdown_pct, 2)
        }
        
        trades.append(trade)
    
    return pd.DataFrame(trades)

def add_derived_metrics(df):
    """Add additional metrics for analysis"""
    
    # Cumulative statistics
    df['Cumulative_PnL'] = df['PnL'].cumsum()
    df['Trade_Number'] = range(1, len(df) + 1)
    
    # Win streaks
    df['Win_Binary'] = (df['Win_Loss'] == 'Win').astype(int)
    
    # Day of week
    df['Day_of_Week'] = pd.to_datetime(df['Date']).dt.day_name()
    
    # Month
    df['Month'] = pd.to_datetime(df['Date']).dt.month_name()
    df['Year'] = pd.to_datetime(df['Date']).dt.year
    df['Quarter'] = pd.to_datetime(df['Date']).dt.quarter
    
    # Hour of day
    df['Hour'] = pd.to_datetime(df['Time'], format='%H:%M').dt.hour
    
    return df

def main():
    """Generate and save trading data"""
    print("Generating trading data...")
    
    # Generate trades
    df = generate_trades(NUM_TRADES)
    
    # Add derived metrics
    df = add_derived_metrics(df)
    
    # Save to CSV
    output_file = '../data/raw/trade_log.csv'
    df.to_csv(output_file, index=False)
    print(f"✓ Saved {len(df)} trades to {output_file}")
    
    # Print summary statistics
    print("\n" + "="*60)
    print("TRADING PERFORMANCE SUMMARY")
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
    
    print("\n" + "="*60)
    print("PERFORMANCE BY SETUP TYPE")
    print("="*60)
    
    setup_stats = df.groupby('Setup_Type').agg({
        'Win_Loss': lambda x: (x == 'Win').sum() / len(x) * 100,
        'PnL': ['sum', 'mean', 'count']
    }).round(2)
    
    setup_stats.columns = ['Win_Rate_%', 'Total_PnL', 'Avg_PnL', 'Trades']
    print(setup_stats.sort_values('Total_PnL', ascending=False))
    
    print("\n" + "="*60)
    print("PERFORMANCE BY SESSION")
    print("="*60)
    
    session_stats = df.groupby('Session').agg({
        'Win_Loss': lambda x: (x == 'Win').sum() / len(x) * 100,
        'PnL': ['sum', 'mean', 'count']
    }).round(2)
    
    session_stats.columns = ['Win_Rate_%', 'Total_PnL', 'Avg_PnL', 'Trades']
    print(session_stats.sort_values('Total_PnL', ascending=False))
    
    # Save Excel version for easy viewing
    excel_file = '../data/raw/trade_log.xlsx'
    with pd.ExcelWriter(excel_file, engine='openpyxl') as writer:
        df.to_excel(writer, sheet_name='Trade_Log', index=False)
        setup_stats.to_excel(writer, sheet_name='Setup_Analysis')
        session_stats.to_excel(writer, sheet_name='Session_Analysis')
    
    print(f"\n✓ Saved Excel version to {excel_file}")
    print("\nData generation complete! Ready for SQL analysis.")

if __name__ == "__main__":
    main()

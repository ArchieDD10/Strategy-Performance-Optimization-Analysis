"""
Statistical Analysis and Performance Metrics
Comprehensive statistical analysis of trading performance
"""

import pandas as pd
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
import seaborn as sns


class TradingStatistics:
    """Calculate advanced trading statistics and performance metrics"""
    
    def __init__(self, df):
        """Initialize with trading dataframe"""
        self.df = df.copy()
        self.df['Date'] = pd.to_datetime(self.df['Date'])
        self.metrics = {}
    
    def calculate_all_metrics(self):
        """Calculate comprehensive performance metrics"""
        print("Calculating performance metrics...")
        
        self.calculate_basic_metrics()
        self.calculate_risk_metrics()
        self.calculate_consistency_metrics()
        self.calculate_efficiency_metrics()
        self.calculate_behavioral_metrics()
        
        return self.metrics
    
    def calculate_basic_metrics(self):
        """Core performance metrics"""
        print("  → Basic performance metrics...")
        
        total_trades = len(self.df)
        wins = len(self.df[self.df['Win_Loss'] == 'Win'])
        losses = len(self.df[self.df['Win_Loss'] == 'Loss'])
        
        win_rate = (wins / total_trades) * 100 if total_trades > 0 else 0
        
        total_pnl = self.df['PnL'].sum()
        avg_pnl = self.df['PnL'].mean()
        
        avg_win = self.df[self.df['Win_Loss'] == 'Win']['PnL'].mean()
        avg_loss = self.df[self.df['Win_Loss'] == 'Loss']['PnL'].mean()
        
        profit_factor = abs((wins * avg_win) / (losses * avg_loss)) if losses > 0 else np.inf
        
        expectancy = (win_rate/100 * avg_win) + ((1 - win_rate/100) * avg_loss)
        
        self.metrics['basic'] = {
            'Total Trades': total_trades,
            'Wins': wins,
            'Losses': losses,
            'Win Rate (%)': round(win_rate, 2),
            'Total P&L ($)': round(total_pnl, 2),
            'Average P&L ($)': round(avg_pnl, 2),
            'Average Win ($)': round(avg_win, 2),
            'Average Loss ($)': round(avg_loss, 2),
            'Profit Factor': round(profit_factor, 2),
            'Expectancy ($)': round(expectancy, 2)
        }
    
    def calculate_risk_metrics(self):
        """Risk and drawdown metrics"""
        print("  → Risk metrics...")
        
        # Drawdown
        max_dd_pct = self.df['Drawdown_Pct'].max()
        avg_dd_pct = self.df[self.df['Drawdown_Pct'] > 0]['Drawdown_Pct'].mean()
        
        # Volatility
        pnl_std = self.df['PnL'].std()
        daily_returns = self.df.groupby('Date')['PnL'].sum()
        daily_std = daily_returns.std()
        
        # Sharpe Ratio (assuming 0% risk-free rate)
        avg_daily_return = daily_returns.mean()
        sharpe = (avg_daily_return / daily_std) * np.sqrt(252) if daily_std > 0 else 0
        
        # Sortino Ratio (downside deviation)
        negative_returns = daily_returns[daily_returns < 0]
        downside_std = negative_returns.std()
        sortino = (avg_daily_return / downside_std) * np.sqrt(252) if downside_std > 0 else 0
        
        # Calmar Ratio
        days_trading = (self.df['Date'].max() - self.df['Date'].min()).days
        annualized_return = (total_pnl / 10000) * (365 / days_trading) if days_trading > 0 else 0
        calmar = (annualized_return / max_dd_pct) if max_dd_pct > 0 else 0
        
        # Value at Risk (95%)
        var_95 = np.percentile(self.df['PnL'], 5)
        
        # Max consecutive losses
        loss_streaks = []
        current_streak = 0
        for result in self.df['Win_Loss']:
            if result == 'Loss':
                current_streak += 1
            else:
                if current_streak > 0:
                    loss_streaks.append(current_streak)
                current_streak = 0
        max_loss_streak = max(loss_streaks) if loss_streaks else 0
        
        self.metrics['risk'] = {
            'Max Drawdown (%)': round(max_dd_pct, 2),
            'Average Drawdown (%)': round(avg_dd_pct, 2),
            'P&L Std Dev ($)': round(pnl_std, 2),
            'Daily Returns Std Dev ($)': round(daily_std, 2),
            'Sharpe Ratio': round(sharpe, 2),
            'Sortino Ratio': round(sortino, 2),
            'Calmar Ratio': round(calmar, 2),
            'Value at Risk 95% ($)': round(var_95, 2),
            'Max Consecutive Losses': max_loss_streak
        }
    
    def calculate_consistency_metrics(self):
        """Consistency and reliability metrics"""
        print("  → Consistency metrics...")
        
        # Daily performance
        daily_pnl = self.df.groupby('Date')['PnL'].sum()
        profitable_days = (daily_pnl > 0).sum()
        total_days = len(daily_pnl)
        profitable_day_pct = (profitable_days / total_days) * 100
        
        # Monthly performance
        self.df['YearMonth'] = self.df['Date'].dt.to_period('M')
        monthly_pnl = self.df.groupby('YearMonth')['PnL'].sum()
        profitable_months = (monthly_pnl > 0).sum()
        total_months = len(monthly_pnl)
        profitable_month_pct = (profitable_months / total_months) * 100
        
        # Consistency score (% of days beating average)
        avg_daily_pnl = daily_pnl.mean()
        days_above_avg = (daily_pnl > avg_daily_pnl).sum()
        consistency_score = (days_above_avg / total_days) * 100
        
        # Coefficient of variation
        cv = (daily_pnl.std() / abs(daily_pnl.mean())) if daily_pnl.mean() != 0 else np.inf
        
        # Win/Loss clustering (measures randomness)
        runs = 1
        for i in range(1, len(self.df)):
            if self.df.iloc[i]['Win_Loss'] != self.df.iloc[i-1]['Win_Loss']:
                runs += 1
        
        expected_runs = (2 * wins * losses) / total_trades + 1
        z_runs = (runs - expected_runs) / np.sqrt((2 * wins * losses * (2 * wins * losses - total_trades)) / 
                                                   (total_trades ** 2 * (total_trades - 1)))
        
        wins = self.metrics['basic']['Wins']
        losses = self.metrics['basic']['Losses']
        total_trades = self.metrics['basic']['Total Trades']
        
        self.metrics['consistency'] = {
            'Profitable Days': profitable_days,
            'Total Trading Days': total_days,
            'Profitable Day %': round(profitable_day_pct, 2),
            'Profitable Months': profitable_months,
            'Total Months': total_months,
            'Profitable Month %': round(profitable_month_pct, 2),
            'Consistency Score %': round(consistency_score, 2),
            'Coefficient of Variation': round(cv, 2),
            'Runs Test Z-Score': round(z_runs, 2)
        }
    
    def calculate_efficiency_metrics(self):
        """Trading efficiency metrics"""
        print("  → Efficiency metrics...")
        
        # Average holding period (for intraday, use hours)
        # Since we don't have exit times, we'll use trade frequency as proxy
        total_days = (self.df['Date'].max() - self.df['Date'].min()).days
        avg_trades_per_day = len(self.df) / total_days if total_days > 0 else 0
        
        # Win/Loss ratio
        avg_win = self.metrics['basic']['Average Win ($)']
        avg_loss = abs(self.metrics['basic']['Average Loss ($)'])
        win_loss_ratio = avg_win / avg_loss if avg_loss > 0 else np.inf
        
        # Average R:R achieved
        avg_rr_actual = self.df['Risk_Reward_Ratio'].mean()
        avg_rr_winners = self.df[self.df['Win_Loss'] == 'Win']['Risk_Reward_Ratio'].mean()
        
        # Edge calculation
        win_rate = self.metrics['basic']['Win Rate (%)'] / 100
        edge = (win_rate * avg_win) + ((1 - win_rate) * avg_loss)
        edge_pct = (edge / abs(avg_loss)) * 100 if avg_loss != 0 else 0
        
        # Payoff ratio
        payoff_ratio = win_loss_ratio
        
        # Kelly Criterion (optimal position size)
        kelly = (win_rate * win_loss_ratio - (1 - win_rate)) / win_loss_ratio
        
        # System Quality Number (SQN)
        expectancy = self.metrics['basic']['Expectancy ($)']
        std_pnl = self.df['PnL'].std()
        sqn = (expectancy / std_pnl) * np.sqrt(len(self.df)) if std_pnl > 0 else 0
        
        self.metrics['efficiency'] = {
            'Avg Trades Per Day': round(avg_trades_per_day, 2),
            'Win/Loss Ratio': round(win_loss_ratio, 2),
            'Avg R:R Ratio': round(avg_rr_actual, 2),
            'Avg R:R on Winners': round(avg_rr_winners, 2),
            'Edge ($)': round(edge, 2),
            'Edge (%)': round(edge_pct, 2),
            'Payoff Ratio': round(payoff_ratio, 2),
            'Kelly Criterion (%)': round(kelly * 100, 2),
            'System Quality Number': round(sqn, 2)
        }
    
    def calculate_behavioral_metrics(self):
        """Behavioral and psychological metrics"""
        print("  → Behavioral metrics...")
        
        # Time between trades
        self.df['DateTime'] = pd.to_datetime(self.df['Date'].astype(str) + ' ' + self.df['Time'])
        time_diffs = self.df['DateTime'].diff().dt.total_seconds() / 3600  # hours
        avg_time_between = time_diffs.mean()
        
        # Revenge trading detection (quick trade after loss)
        self.df['Prev_Result'] = self.df['Win_Loss'].shift(1)
        self.df['Hours_Since_Last'] = time_diffs
        revenge_trades = len(self.df[
            (self.df['Prev_Result'] == 'Loss') & 
            (self.df['Hours_Since_Last'] < 1)
        ])
        revenge_pct = (revenge_trades / len(self.df)) * 100
        
        # Risk escalation after losses
        self.df['Risk_Change'] = self.df['Risk_Amount'].pct_change()
        escalation_trades = len(self.df[
            (self.df['Prev_Result'] == 'Loss') &
            (self.df['Risk_Change'] > 0.2)  # >20% increase
        ])
        escalation_pct = (escalation_trades / len(self.df)) * 100
        
        # Setup consistency (how often changing setups)
        setup_changes = (self.df['Setup_Type'] != self.df['Setup_Type'].shift(1)).sum()
        setup_change_rate = (setup_changes / len(self.df)) * 100
        
        # Session consistency
        session_changes = (self.df['Session'] != self.df['Session'].shift(1)).sum()
        
        # Overtrading days (days with >95th percentile trades)
        daily_trades = self.df.groupby('Date').size()
        overtrade_threshold = daily_trades.quantile(0.95)
        overtrade_days = (daily_trades > overtrade_threshold).sum()
        
        self.metrics['behavioral'] = {
            'Avg Hours Between Trades': round(avg_time_between, 2),
            'Potential Revenge Trades': revenge_trades,
            'Revenge Trading Rate (%)': round(revenge_pct, 2),
            'Risk Escalation Events': escalation_trades,
            'Risk Escalation Rate (%)': round(escalation_pct, 2),
            'Setup Changes': setup_changes,
            'Setup Change Rate (%)': round(setup_change_rate, 2),
            'Overtrading Days': overtrade_days
        }
    
    def generate_report(self, output_path='../docs/performance_metrics.txt'):
        """Generate comprehensive metrics report"""
        print("\nGenerating performance report...")
        
        with open(output_path, 'w') as f:
            f.write("="*70 + "\n")
            f.write("TRADING PERFORMANCE ANALYSIS REPORT\n")
            f.write("="*70 + "\n\n")
            
            for category, metrics in self.metrics.items():
                f.write(f"\n{category.upper()} METRICS\n")
                f.write("-" * 70 + "\n")
                for metric, value in metrics.items():
                    f.write(f"{metric:.<50} {value:>15}\n")
                f.write("\n")
        
        print(f"✓ Saved report to {output_path}")
    
    def display_summary(self):
        """Display key metrics summary"""
        print("\n" + "="*70)
        print("KEY PERFORMANCE INDICATORS")
        print("="*70)
        
        key_metrics = {
            'Total P&L': self.metrics['basic']['Total P&L ($)'],
            'Win Rate': f"{self.metrics['basic']['Win Rate (%)']}%",
            'Profit Factor': self.metrics['basic']['Profit Factor'],
            'Expectancy': f"${self.metrics['basic']['Expectancy ($)']}",
            'Sharpe Ratio': self.metrics['risk']['Sharpe Ratio'],
            'Max Drawdown': f"{self.metrics['risk']['Max Drawdown (%)']}%",
            'Profitable Days': f"{self.metrics['consistency']['Profitable Day %']}%",
            'System Quality Number': self.metrics['efficiency']['System Quality Number']
        }
        
        for metric, value in key_metrics.items():
            print(f"{metric:.<40} {value:>25}")


def main():
    """Run statistical analysis"""
    print("="*70)
    print("TRADING STATISTICAL ANALYSIS")
    print("="*70)
    
    # Load data
    df = pd.read_csv('../data/raw/trade_log.csv')
    print(f"\nLoaded {len(df)} trades")
    
    # Calculate metrics
    stats_analyzer = TradingStatistics(df)
    metrics = stats_analyzer.calculate_all_metrics()
    
    # Display summary
    stats_analyzer.display_summary()
    
    # Generate full report
    stats_analyzer.generate_report()
    
    print("\n✓ Statistical analysis complete!")


if __name__ == "__main__":
    main()

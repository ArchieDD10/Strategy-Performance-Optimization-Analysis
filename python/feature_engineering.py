"""
Feature Engineering for Trading Performance Analysis
Generates advanced features for predictive modeling and pattern detection
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta


class TradingFeatureEngineer:
    """Creates advanced features from raw trading data"""
    
    def __init__(self, df):
        """Initialize with trading dataframe"""
        self.df = df.copy()
        self.df['Date'] = pd.to_datetime(self.df['Date'])
        self.df = self.df.sort_values('Trade_ID').reset_index(drop=True)
    
    def create_all_features(self):
        """Generate all feature sets"""
        print("Creating trading features...")
        
        self.create_streak_features()
        self.create_momentum_features()
        self.create_volatility_features()
        self.create_behavioral_features()
        self.create_temporal_features()
        self.create_performance_metrics()
        
        print(f"✓ Created {len(self.df.columns)} total features")
        return self.df
    
    def create_streak_features(self):
        """Win/loss streaks and related features"""
        print("  → Creating streak features...")
        
        # Current streak
        self.df['Win_Binary'] = (self.df['Win_Loss'] == 'Win').astype(int)
        
        # Calculate win/loss streaks
        self.df['Streak'] = self._calculate_streak(self.df['Win_Binary'])
        
        # Longest win/loss streaks (rolling)
        self.df['Longest_Win_Streak_20'] = self._rolling_max_streak(self.df['Win_Binary'], 20)
        self.df['Longest_Loss_Streak_20'] = self._rolling_max_streak(1 - self.df['Win_Binary'], 20)
        
        # Streak momentum
        self.df['Streak_Momentum'] = self.df['Streak'] * self.df['PnL']
        
        # Days since last win/loss
        self.df['Trades_Since_Last_Win'] = self._trades_since_event(self.df['Win_Binary'])
        self.df['Trades_Since_Last_Loss'] = self._trades_since_event(1 - self.df['Win_Binary'])
    
    def create_momentum_features(self):
        """P&L momentum and trend features"""
        print("  → Creating momentum features...")
        
        # Moving averages of P&L
        for window in [5, 10, 20, 50]:
            self.df[f'MA_PnL_{window}'] = self.df['PnL'].rolling(window=window, min_periods=1).mean()
            self.df[f'MA_Balance_{window}'] = self.df['Balance'].rolling(window=window, min_periods=1).mean()
        
        # P&L velocity (rate of change)
        self.df['PnL_Velocity_5'] = self.df['PnL'].rolling(window=5, min_periods=2).apply(
            lambda x: (x.iloc[-1] - x.iloc[0]) / len(x) if len(x) > 1 else 0
        )
        
        # Balance momentum
        self.df['Balance_Momentum_10'] = self.df['Balance'].pct_change(periods=10) * 100
        
        # Cumulative P&L acceleration
        self.df['Cumulative_PnL'] = self.df['PnL'].cumsum()
        self.df['PnL_Acceleration'] = self.df['Cumulative_PnL'].diff().diff()
    
    def create_volatility_features(self):
        """Risk and volatility metrics"""
        print("  → Creating volatility features...")
        
        # Rolling standard deviation of P&L
        for window in [10, 20, 50]:
            self.df[f'PnL_Volatility_{window}'] = self.df['PnL'].rolling(
                window=window, min_periods=2
            ).std()
        
        # Coefficient of variation (risk per unit of return)
        self.df['CV_20'] = (
            self.df['PnL'].rolling(window=20, min_periods=5).std() / 
            self.df['PnL'].rolling(window=20, min_periods=5).mean().abs()
        )
        
        # Drawdown features
        self.df['Drawdown_Dollar'] = self.df['Peak_Balance'] - self.df['Balance']
        self.df['Recovery_Rate'] = np.where(
            self.df['Drawdown_Dollar'] > 0,
            self.df['PnL'] / self.df['Drawdown_Dollar'],
            0
        )
        
        # Maximum adverse excursion proxy
        self.df['MAE_Proxy'] = np.where(
            self.df['Win_Loss'] == 'Win',
            abs(self.df['Risk_Amount']),  # Winners had risk
            abs(self.df['PnL'])  # Losers show actual loss
        )
        
        # Risk-adjusted return (Sharpe-like)
        self.df['Risk_Adjusted_Return_20'] = (
            self.df['PnL'].rolling(window=20, min_periods=5).mean() /
            self.df['PnL'].rolling(window=20, min_periods=5).std()
        )
    
    def create_behavioral_features(self):
        """Trading behavior patterns"""
        print("  → Creating behavioral features...")
        
        # Trading frequency
        self.df['Trades_Per_Day'] = self.df.groupby('Date')['Trade_ID'].transform('count')
        
        # Time since last trade (in hours)
        self.df['DateTime'] = pd.to_datetime(self.df['Date'].astype(str) + ' ' + self.df['Time'])
        self.df['Hours_Since_Last_Trade'] = self.df['DateTime'].diff().dt.total_seconds() / 3600
        
        # Revenge trading indicator (quick trade after loss)
        self.df['Potential_Revenge_Trade'] = (
            (self.df['Win_Loss'].shift(1) == 'Loss') & 
            (self.df['Hours_Since_Last_Trade'] < 1)
        ).astype(int)
        
        # Risk escalation (increasing risk after losses)
        self.df['Risk_Change_Pct'] = self.df['Risk_Amount'].pct_change() * 100
        self.df['Risk_Escalation'] = (
            (self.df['Win_Loss'].shift(1) == 'Loss') & 
            (self.df['Risk_Change_Pct'] > 20)
        ).astype(int)
        
        # Session consistency
        self.df['Same_Session_As_Prev'] = (
            self.df['Session'] == self.df['Session'].shift(1)
        ).astype(int)
        
        # Setup rotation (changing setups frequently)
        self.df['Setup_Changes_10'] = (
            self.df['Setup_Type'] != self.df['Setup_Type'].shift(1)
        ).rolling(window=10, min_periods=1).sum()
    
    def create_temporal_features(self):
        """Time-based features"""
        print("  → Creating temporal features...")
        
        # Cyclical encoding of hour (sine/cosine)
        self.df['Hour_Sin'] = np.sin(2 * np.pi * self.df['Hour'] / 24)
        self.df['Hour_Cos'] = np.cos(2 * np.pi * self.df['Hour'] / 24)
        
        # Day of week encoding
        self.df['DayOfWeek_Num'] = pd.to_datetime(self.df['Date']).dt.dayofweek
        self.df['DayOfWeek_Sin'] = np.sin(2 * np.pi * self.df['DayOfWeek_Num'] / 7)
        self.df['DayOfWeek_Cos'] = np.cos(2 * np.pi * self.df['DayOfWeek_Num'] / 7)
        
        # Month encoding
        self.df['Month_Num'] = pd.to_datetime(self.df['Date']).dt.month
        self.df['Month_Sin'] = np.sin(2 * np.pi * self.df['Month_Num'] / 12)
        self.df['Month_Cos'] = np.cos(2 * np.pi * self.df['Month_Num'] / 12)
        
        # Weekend proximity
        self.df['Is_Monday'] = (self.df['DayOfWeek_Num'] == 0).astype(int)
        self.df['Is_Friday'] = (self.df['DayOfWeek_Num'] == 4).astype(int)
        
        # End/start of month
        self.df['Days_In_Month'] = pd.to_datetime(self.df['Date']).dt.days_in_month
        self.df['Day_Of_Month'] = pd.to_datetime(self.df['Date']).dt.day
        self.df['Is_Month_End'] = (self.df['Day_Of_Month'] >= self.df['Days_In_Month'] - 2).astype(int)
        self.df['Is_Month_Start'] = (self.df['Day_Of_Month'] <= 3).astype(int)
    
    def create_performance_metrics(self):
        """Aggregated performance features"""
        print("  → Creating performance metrics...")
        
        # Win rate (rolling)
        for window in [10, 20, 50]:
            self.df[f'Win_Rate_{window}'] = (
                self.df['Win_Binary'].rolling(window=window, min_periods=1).mean() * 100
            )
        
        # Profit factor (rolling)
        for window in [20, 50]:
            wins_sum = (self.df['PnL'] * self.df['Win_Binary']).rolling(
                window=window, min_periods=1
            ).sum()
            losses_sum = abs((self.df['PnL'] * (1 - self.df['Win_Binary'])).rolling(
                window=window, min_periods=1
            ).sum())
            self.df[f'Profit_Factor_{window}'] = wins_sum / losses_sum.replace(0, np.nan)
        
        # Average win/loss ratio
        for window in [20]:
            avg_win = (self.df['PnL'] * self.df['Win_Binary']).rolling(
                window=window, min_periods=1
            ).sum() / self.df['Win_Binary'].rolling(window=window, min_periods=1).sum()
            
            avg_loss = abs((self.df['PnL'] * (1 - self.df['Win_Binary'])).rolling(
                window=window, min_periods=1
            ).sum() / (1 - self.df['Win_Binary']).rolling(window=window, min_periods=1).sum())
            
            self.df[f'Avg_Win_Loss_Ratio_{window}'] = avg_win / avg_loss.replace(0, np.nan)
        
        # Expectancy (rolling)
        self.df['Expectancy_20'] = self.df['PnL'].rolling(window=20, min_periods=1).mean()
        
        # Performance rank (percentile)
        self.df['Performance_Percentile'] = self.df['PnL'].rank(pct=True) * 100
    
    # Helper methods
    def _calculate_streak(self, series):
        """Calculate current win/loss streak"""
        streak = []
        current_streak = 0
        
        for i, val in enumerate(series):
            if i == 0:
                current_streak = 1 if val == 1 else -1
            else:
                if val == series.iloc[i-1]:
                    if val == 1:
                        current_streak += 1
                    else:
                        current_streak -= 1
                else:
                    current_streak = 1 if val == 1 else -1
            streak.append(current_streak)
        
        return streak
    
    def _rolling_max_streak(self, series, window):
        """Calculate longest streak in rolling window"""
        result = []
        for i in range(len(series)):
            start_idx = max(0, i - window + 1)
            window_data = series.iloc[start_idx:i+1]
            
            max_streak = 0
            current_streak = 0
            
            for val in window_data:
                if val == 1:
                    current_streak += 1
                    max_streak = max(max_streak, current_streak)
                else:
                    current_streak = 0
            
            result.append(max_streak)
        
        return result
    
    def _trades_since_event(self, event_series):
        """Calculate number of trades since last event (1 in series)"""
        result = []
        trades_since = 0
        
        for val in event_series:
            if val == 1:
                trades_since = 0
            else:
                trades_since += 1
            result.append(trades_since)
        
        return result


def main():
    """Load data and create features"""
    print("="*60)
    print("TRADING FEATURE ENGINEERING")
    print("="*60)
    
    # Load data
    df = pd.read_csv('../data/raw/trade_log.csv')
    print(f"\nLoaded {len(df)} trades")
    
    # Create features
    engineer = TradingFeatureEngineer(df)
    df_features = engineer.create_all_features()
    
    # Save engineered features
    output_file = '../data/processed/trade_features.csv'
    df_features.to_csv(output_file, index=False)
    print(f"\n✓ Saved features to {output_file}")
    
    # Display sample
    print("\n" + "="*60)
    print("SAMPLE FEATURES (Last 5 Trades)")
    print("="*60)
    
    feature_cols = [
        'Trade_ID', 'Date', 'PnL', 'Win_Loss', 'Streak', 
        'Win_Rate_20', 'Profit_Factor_20', 'PnL_Volatility_20',
        'Trades_Per_Day', 'Potential_Revenge_Trade'
    ]
    print(df_features[feature_cols].tail())
    
    # Feature importance preview
    print("\n" + "="*60)
    print("FEATURE SUMMARY")
    print("="*60)
    
    feature_groups = {
        'Streak Features': [c for c in df_features.columns if 'Streak' in c or 'Since' in c],
        'Momentum Features': [c for c in df_features.columns if 'MA_' in c or 'Momentum' in c],
        'Volatility Features': [c for c in df_features.columns if 'Volatility' in c or 'CV_' in c],
        'Behavioral Features': [c for c in df_features.columns if 'Revenge' in c or 'Escalation' in c],
        'Performance Metrics': [c for c in df_features.columns if 'Win_Rate' in c or 'Profit_Factor' in c]
    }
    
    for group, features in feature_groups.items():
        print(f"\n{group}: {len(features)} features")
        for f in features[:5]:  # Show first 5
            print(f"  - {f}")
        if len(features) > 5:
            print(f"  ... and {len(features) - 5} more")
    
    print(f"\n✓ Feature engineering complete!")
    print(f"Total features: {len(df_features.columns)}")


if __name__ == "__main__":
    main()

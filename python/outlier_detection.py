"""
Outlier Detection and Analysis for Trading Performance
Identifies anomalous trades and patterns that require attention
"""

import pandas as pd
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
import seaborn as sns


class TradingOutlierDetector:
    """Detect outliers and anomalies in trading data"""
    
    def __init__(self, df):
        """Initialize with trading dataframe"""
        self.df = df.copy()
        self.outliers = {}
    
    def detect_all_outliers(self):
        """Run all outlier detection methods"""
        print("Detecting outliers...")
        
        self.detect_pnl_outliers()
        self.detect_risk_outliers()
        self.detect_behavioral_outliers()
        self.detect_temporal_outliers()
        self.detect_statistical_outliers()
        
        return self.outliers
    
    def detect_pnl_outliers(self):
        """Detect unusual P&L values"""
        print("  → Detecting P&L outliers...")
        
        # Z-score method
        z_scores = np.abs(stats.zscore(self.df['PnL'].fillna(0)))
        pnl_outliers = self.df[z_scores > 3].copy()
        
        # IQR method
        Q1 = self.df['PnL'].quantile(0.25)
        Q3 = self.df['PnL'].quantile(0.75)
        IQR = Q3 - Q1
        iqr_outliers = self.df[
            (self.df['PnL'] < (Q1 - 1.5 * IQR)) | 
            (self.df['PnL'] > (Q3 + 1.5 * IQR))
        ].copy()
        
        self.outliers['pnl_zscore'] = pnl_outliers
        self.outliers['pnl_iqr'] = iqr_outliers
        
        print(f"    Found {len(pnl_outliers)} P&L outliers (Z-score)")
        print(f"    Found {len(iqr_outliers)} P&L outliers (IQR)")
    
    def detect_risk_outliers(self):
        """Detect unusual risk-taking behavior"""
        print("  → Detecting risk outliers...")
        
        # Risk amount outliers
        risk_zscore = np.abs(stats.zscore(self.df['Risk_Amount'].fillna(0)))
        risk_outliers = self.df[risk_zscore > 2.5].copy()
        
        # R:R ratio outliers (very high or very low)
        rr_outliers = self.df[
            (self.df['Risk_Reward_Ratio'] > self.df['Risk_Reward_Ratio'].quantile(0.95)) |
            (self.df['Risk_Reward_Ratio'] < self.df['Risk_Reward_Ratio'].quantile(0.05))
        ].copy()
        
        # Risk escalation (sudden increases)
        self.df['Risk_Pct_Change'] = self.df['Risk_Amount'].pct_change() * 100
        risk_escalation = self.df[self.df['Risk_Pct_Change'] > 50].copy()
        
        self.outliers['risk_amount'] = risk_outliers
        self.outliers['risk_reward'] = rr_outliers
        self.outliers['risk_escalation'] = risk_escalation
        
        print(f"    Found {len(risk_outliers)} risk amount outliers")
        print(f"    Found {len(rr_outliers)} R:R ratio outliers")
        print(f"    Found {len(risk_escalation)} risk escalation events")
    
    def detect_behavioral_outliers(self):
        """Detect anomalous trading behavior"""
        print("  → Detecting behavioral outliers...")
        
        # High-frequency trading days
        trades_per_day = self.df.groupby('Date').size()
        high_freq_days = trades_per_day[
            trades_per_day > trades_per_day.quantile(0.95)
        ]
        high_freq_trades = self.df[self.df['Date'].isin(high_freq_days.index)].copy()
        
        # Rapid-fire trades (< 30 minutes apart)
        self.df['DateTime'] = pd.to_datetime(self.df['Date'].astype(str) + ' ' + self.df['Time'])
        self.df['Minutes_Since_Last'] = self.df['DateTime'].diff().dt.total_seconds() / 60
        rapid_trades = self.df[self.df['Minutes_Since_Last'] < 30].copy()
        
        # Revenge trading (quick trade after loss)
        revenge_trades = self.df[
            (self.df['Win_Loss'].shift(1) == 'Loss') & 
            (self.df['Minutes_Since_Last'] < 60)
        ].copy()
        
        # Same setup repeatedly
        self.df['Same_Setup_Count'] = self.df.groupby(
            (self.df['Setup_Type'] != self.df['Setup_Type'].shift()).cumsum()
        ).cumcount() + 1
        repetitive_setup = self.df[self.df['Same_Setup_Count'] >= 5].copy()
        
        self.outliers['high_frequency_days'] = high_freq_trades
        self.outliers['rapid_fire_trades'] = rapid_trades
        self.outliers['revenge_trading'] = revenge_trades
        self.outliers['repetitive_setups'] = repetitive_setup
        
        print(f"    Found {len(high_freq_trades)} trades on high-frequency days")
        print(f"    Found {len(rapid_trades)} rapid-fire trades")
        print(f"    Found {len(revenge_trades)} potential revenge trades")
        print(f"    Found {len(repetitive_setup)} repetitive setup instances")
    
    def detect_temporal_outliers(self):
        """Detect unusual trading times"""
        print("  → Detecting temporal outliers...")
        
        # Unusual trading hours
        hour_counts = self.df['Hour'].value_counts()
        rare_hours = hour_counts[hour_counts < hour_counts.quantile(0.25)]
        unusual_time_trades = self.df[self.df['Hour'].isin(rare_hours.index)].copy()
        
        # Weekend trading (should be minimal)
        self.df['DayOfWeek'] = pd.to_datetime(self.df['Date']).dt.dayofweek
        weekend_trades = self.df[self.df['DayOfWeek'].isin([5, 6])].copy()
        
        # Trades outside normal sessions
        normal_sessions = ['London', 'New York', 'Overlap-EU-US']
        unusual_session_trades = self.df[~self.df['Session'].isin(normal_sessions)].copy()
        
        self.outliers['unusual_hours'] = unusual_time_trades
        self.outliers['weekend_trading'] = weekend_trades
        self.outliers['unusual_sessions'] = unusual_session_trades
        
        print(f"    Found {len(unusual_time_trades)} trades at unusual hours")
        print(f"    Found {len(weekend_trades)} weekend trades")
        print(f"    Found {len(unusual_session_trades)} trades in unusual sessions")
    
    def detect_statistical_outliers(self):
        """Statistical anomaly detection"""
        print("  → Detecting statistical anomalies...")
        
        # Isolation Forest for multivariate outliers
        from sklearn.ensemble import IsolationForest
        
        # Prepare features
        feature_cols = ['PnL', 'Risk_Amount', 'Risk_Reward_Ratio', 'Hour', 'DayOfWeek']
        X = self.df[feature_cols].fillna(0)
        
        # Fit Isolation Forest
        iso_forest = IsolationForest(contamination=0.05, random_state=42)
        outlier_labels = iso_forest.fit_predict(X)
        
        multivariate_outliers = self.df[outlier_labels == -1].copy()
        
        self.outliers['multivariate_anomalies'] = multivariate_outliers
        
        print(f"    Found {len(multivariate_outliers)} multivariate anomalies")
    
    def generate_outlier_report(self, output_path='../data/processed/outlier_report.csv'):
        """Generate comprehensive outlier report"""
        print("\nGenerating outlier report...")
        
        # Combine all outliers with labels
        all_outliers = []
        
        for outlier_type, outlier_df in self.outliers.items():
            if len(outlier_df) > 0:
                temp_df = outlier_df.copy()
                temp_df['Outlier_Type'] = outlier_type
                all_outliers.append(temp_df)
        
        if all_outliers:
            combined_outliers = pd.concat(all_outliers, ignore_index=True)
            
            # Remove duplicates, keep all outlier types
            report_cols = [
                'Trade_ID', 'Date', 'Time', 'Instrument', 'Setup_Type', 
                'Session', 'Win_Loss', 'PnL', 'Risk_Amount', 
                'Risk_Reward_Ratio', 'Outlier_Type'
            ]
            
            outlier_report = combined_outliers[
                [c for c in report_cols if c in combined_outliers.columns]
            ].drop_duplicates(subset=['Trade_ID', 'Outlier_Type'])
            
            outlier_report.to_csv(output_path, index=False)
            print(f"✓ Saved outlier report to {output_path}")
            
            return outlier_report
        else:
            print("No outliers detected")
            return pd.DataFrame()
    
    def plot_outliers(self, output_dir='../docs/'):
        """Create visualization of outliers"""
        print("\nCreating outlier visualizations...")
        
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        
        # 1. P&L Distribution with outliers
        ax1 = axes[0, 0]
        ax1.hist(self.df['PnL'], bins=50, alpha=0.7, color='skyblue', edgecolor='black')
        if len(self.outliers['pnl_zscore']) > 0:
            ax1.scatter(
                self.outliers['pnl_zscore']['PnL'], 
                [5] * len(self.outliers['pnl_zscore']), 
                color='red', s=100, label='Outliers', zorder=5
            )
        ax1.set_title('P&L Distribution with Outliers', fontsize=14, fontweight='bold')
        ax1.set_xlabel('P&L ($)')
        ax1.set_ylabel('Frequency')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # 2. Risk Amount Boxplot
        ax2 = axes[0, 1]
        box_data = [
            self.df[self.df['Setup_Type'] == setup]['Risk_Amount'].dropna() 
            for setup in self.df['Setup_Type'].unique()
        ]
        ax2.boxplot(box_data, labels=self.df['Setup_Type'].unique())
        ax2.set_title('Risk Amount by Setup (Outlier Detection)', fontsize=14, fontweight='bold')
        ax2.set_xlabel('Setup Type')
        ax2.set_ylabel('Risk Amount ($)')
        ax2.tick_params(axis='x', rotation=45)
        ax2.grid(True, alpha=0.3)
        
        # 3. Trading Frequency Timeline
        ax3 = axes[1, 0]
        daily_trades = self.df.groupby('Date').size()
        ax3.plot(pd.to_datetime(daily_trades.index), daily_trades.values, 
                linewidth=2, color='navy', alpha=0.7)
        threshold = daily_trades.quantile(0.95)
        ax3.axhline(y=threshold, color='red', linestyle='--', 
                   label=f'95th Percentile ({threshold:.0f} trades)')
        ax3.set_title('Daily Trading Frequency (Overtrading Detection)', 
                     fontsize=14, fontweight='bold')
        ax3.set_xlabel('Date')
        ax3.set_ylabel('Number of Trades')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
        plt.setp(ax3.xaxis.get_majorticklabels(), rotation=45)
        
        # 4. Scatter: Risk vs Return with outliers
        ax4 = axes[1, 1]
        scatter = ax4.scatter(
            self.df['Risk_Amount'], 
            self.df['PnL'], 
            c=self.df['Win_Loss'].map({'Win': 'green', 'Loss': 'red'}),
            alpha=0.6, s=50
        )
        
        # Mark multivariate outliers
        if len(self.outliers.get('multivariate_anomalies', [])) > 0:
            outlier_data = self.outliers['multivariate_anomalies']
            ax4.scatter(
                outlier_data['Risk_Amount'],
                outlier_data['PnL'],
                edgecolors='black', facecolors='none',
                s=200, linewidths=2, label='Anomalies'
            )
        
        ax4.set_title('Risk vs Return (Anomaly Detection)', fontsize=14, fontweight='bold')
        ax4.set_xlabel('Risk Amount ($)')
        ax4.set_ylabel('P&L ($)')
        ax4.legend(['Win', 'Loss', 'Anomaly'])
        ax4.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plot_path = f'{output_dir}outlier_analysis.png'
        plt.savefig(plot_path, dpi=300, bbox_inches='tight')
        print(f"✓ Saved outlier visualizations to {plot_path}")
        plt.close()


def main():
    """Run outlier detection analysis"""
    print("="*60)
    print("TRADING OUTLIER DETECTION")
    print("="*60)
    
    # Load data
    df = pd.read_csv('../data/raw/trade_log.csv')
    print(f"\nLoaded {len(df)} trades")
    
    # Detect outliers
    detector = TradingOutlierDetector(df)
    outliers = detector.detect_all_outliers()
    
    # Generate report
    print("\n" + "="*60)
    print("OUTLIER SUMMARY")
    print("="*60)
    
    report = detector.generate_outlier_report()
    
    if len(report) > 0:
        print(f"\nTotal outlier instances: {len(report)}")
        print(f"Unique trades flagged: {report['Trade_ID'].nunique()}")
        
        print("\nOutlier breakdown by type:")
        print(report['Outlier_Type'].value_counts())
        
        print("\nTop 10 outlier trades:")
        print(report.head(10)[
            ['Trade_ID', 'Date', 'Setup_Type', 'PnL', 'Outlier_Type']
        ])
    
    # Create visualizations
    detector.plot_outliers()
    
    print("\n✓ Outlier detection complete!")


if __name__ == "__main__":
    main()

class SMABacktester():
    
    def __init__(self, symbol, SMA_S, SMA_L, start_date, end_date):

        self.symbol = symbol
        self.SMA_S = SMA_S
        self.SMA_L = SMA_L
        self.start_date = start_date
        self.end_date = end_date
        self.results = None
        self.get_data()

    def get_data(self):
    
        df = yf.download(self.symbol, start = self.start_date, end = self.end_date, auto_adjust = False)
        data = df['Close'].copy()
        data.columns = ['Close']
        data['returns'] = np.log(data['Close'].div(data['Close'].shift(1)))
        data['SMA_S'] = data['Close'].rolling(self.SMA_S).mean()
        data['SMA_L'] = data['Close'].rolling(self.SMA_L).mean()
        data.dropna(inplace = True)
        self.data2 = data

        return data

    def test_results(self):
        
        data = self.data2.copy().dropna()
        data['position'] = np.where(data['SMA_S'] > data['SMA_L'], 1, -1)
        data['strategy'] = data['returns'] * data['position'].shift(1)
        data.dropna(inplace = True)
        data['returns_bh'] = data['returns'].cumsum().apply(np.exp)
        data['returns_strategy'] = data['strategy'].cumsum().apply(np.exp)
        performance = data['returns_strategy'].iloc[-1]
        outperformance = performance - data['returns_bh'].iloc[-1]
        self.results = data
        returns = np.exp(data['strategy'].sum())
        std = data['strategy'].std() * np.sqrt(252)
    
        print(f'Performance for {self.symbol}: {round(performance, 6)}'), 
        print(f'Outperformance Deviation for {self.symbol}: {round(outperformance, 6)}')

    def plot_results(self):

        if self.results is None:
            print('Run the test please')
        else:
            title = '{} | SMA_S = {} | SMA_L = {}'.format(self.symbol, self.SMA_S, self.SMA_L)
            fig, ax = plt.subplots(figsize = (10, 6))
            self.results[['returns_bh', 'returns_strategy']].plot(ax = ax)
            ax.set_title(title, fontweight = 'bold', fontsize = 12)
            ax.set_xlabel('Date', fontweight = 'bold', fontsize = 10)
            ax.set_ylabel('Returns', fontweight = 'bold', fontsize = 10)
            ax.legend(fontsize = 10)
            ax.tick_params(axis = 'both', labelsize = 10)
            ax.grid(True, linestyle = '--', alpha = 0.3)
            plt.show()
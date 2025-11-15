import { IStock } from '../db/models/TodayNews';

// Using Yahoo Finance API alternative - finnhub.io (free tier)
// For production, you'd want to use a proper API with authentication
export async function fetchStockData(): Promise<IStock[]> {
  const symbols = [
    { symbol: 'AAPL', name: 'Apple' },
    { symbol: 'AMZN', name: 'Amazon' },
    { symbol: 'META', name: 'Meta' },
    { symbol: 'NFLX', name: 'Netflix' },
    { symbol: 'GOOGL', name: 'Google' },
    { symbol: 'NVDA', name: 'NVIDIA' },
    { symbol: 'MSFT', name: 'Microsoft' },
  ];

  try {
    // Using a free API endpoint - you can replace with your preferred stock API
    const stockPromises = symbols.map(async (stock) => {
      try {
        // Using Yahoo Finance API via yfinance proxy
        const response = await fetch(
          `https://query1.finance.yahoo.com/v8/finance/chart/${stock.symbol}?interval=1d&range=1d`,
          {
            headers: {
              'User-Agent': 'Mozilla/5.0',
            },
          }
        );

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        const quote = data.chart.result[0];
        const meta = quote.meta;
        const currentPrice = meta.regularMarketPrice || 0;
        const previousClose = meta.chartPreviousClose || meta.previousClose || 0;
        const change = currentPrice - previousClose;
        const changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0;

        return {
          symbol: stock.symbol,
          name: stock.name,
          price: parseFloat(currentPrice.toFixed(2)),
          change: parseFloat(change.toFixed(2)),
          changePercent: parseFloat(changePercent.toFixed(2)),
        };
      } catch (error) {
        console.error(`Error fetching ${stock.symbol}:`, error);
        // Return mock data if API fails
        return {
          symbol: stock.symbol,
          name: stock.name,
          price: 0,
          change: 0,
          changePercent: 0,
        };
      }
    });

    const stocks = await Promise.all(stockPromises);
    return stocks;
  } catch (error) {
    console.error('Error fetching stock data:', error);
    return [];
  }
}

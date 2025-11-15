import { ICryptoPrice } from '../db/models/TodayNews';

// Using CoinGecko API (free, no API key required)
export async function fetchCryptoData(): Promise<ICryptoPrice[]> {
  try {
    const cryptoIds = ['bitcoin', 'ethereum', 'binancecoin'];

    const response = await fetch(
      `https://api.coingecko.com/api/v3/simple/price?ids=${cryptoIds.join(',')}&vs_currencies=usd&include_24hr_change=true`
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();

    const cryptoMap: { [key: string]: string } = {
      bitcoin: 'Bitcoin',
      ethereum: 'Ethereum',
      binancecoin: 'BNB',
    };

    const cryptoPrices: ICryptoPrice[] = cryptoIds.map((id) => ({
      symbol: id === 'bitcoin' ? 'BTC' : id === 'ethereum' ? 'ETH' : 'BNB',
      name: cryptoMap[id],
      price: data[id]?.usd || 0,
      change24h: parseFloat((data[id]?.usd_24h_change || 0).toFixed(2)),
    }));

    return cryptoPrices;
  } catch (error) {
    console.error('Error fetching crypto data:', error);
    return [
      {
        symbol: 'BTC',
        name: 'Bitcoin',
        price: 0,
        change24h: 0,
      },
      {
        symbol: 'ETH',
        name: 'Ethereum',
        price: 0,
        change24h: 0,
      },
      {
        symbol: 'BNB',
        name: 'BNB',
        price: 0,
        change24h: 0,
      },
    ];
  }
}

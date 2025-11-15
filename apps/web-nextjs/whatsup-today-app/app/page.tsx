'use client';

import { useEffect, useState } from 'react';
import createApolloClient from '@/lib/apollo-client';
import { GET_ALL_DATA } from '@/lib/graphql/queries';

interface Stock {
  symbol: string;
  name: string;
  price: number;
  change: number;
  changePercent: number;
}

interface HourlyTemp {
  hour: string;
  temperature: number;
}

interface Weather {
  city: string;
  temperature: number;
  condition: string;
  high: number;
  low: number;
  humidity: number;
  hourlyTemps?: HourlyTemp[];
}

interface NBAGame {
  homeTeam: string;
  awayTeam: string;
  homeScore: number;
  awayScore: number;
  date: string;
  status: string;
}

interface NewsHeadline {
  title: string;
  source: string;
  url: string;
  publishedAt: string;
}

interface CryptoPrice {
  symbol: string;
  name: string;
  price: number;
  change24h: number;
}

interface DashboardData {
  stocks: Stock[];
  weather: Weather;
  nbaGames: NBAGame[];
  newsHeadlines: NewsHeadline[];
  cryptoPrices: CryptoPrice[];
}

export default function Home() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedDate, setSelectedDate] = useState<string>('');
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = async (forceRefresh: boolean = false) => {
    try {
      if (forceRefresh) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }
      const client = createApolloClient();
      const { data } = await client.query<DashboardData>({
        query: GET_ALL_DATA,
        variables: selectedDate ? { date: selectedDate, refresh: forceRefresh } : { refresh: forceRefresh },
      });
      setData(data || null);
      setLoading(false);
      setRefreshing(false);
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Failed to load data');
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [selectedDate]);

  const handleRefresh = () => {
    if (!selectedDate || selectedDate === new Date().toISOString().split('T')[0]) {
      fetchData(true);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-amber-50 flex items-center justify-center">
        <div className="text-3xl font-serif text-gray-800">Loading today&apos;s news...</div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="min-h-screen bg-amber-50 flex items-center justify-center">
        <div className="text-2xl font-serif text-red-800">{error || 'No data available'}</div>
      </div>
    );
  }

  const displayDate = selectedDate
    ? new Date(selectedDate + 'T00:00:00').toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      })
    : new Date().toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });

  return (
    <div className="min-h-screen bg-amber-50 py-4 md:py-8 px-2 md:px-4">
      <div className="max-w-7xl mx-auto">
        {/* Newspaper Header */}
        <header className="border-b-4 border-black pb-4 mb-4 md:mb-8">
          <div className="text-center">
            <h1 className="text-4xl md:text-6xl font-serif font-bold text-gray-900 mb-2">
              What&apos;s Up Today
            </h1>
            <p className="text-lg md:text-xl font-serif italic text-gray-700">{displayDate}</p>
            <div className="mt-2 text-sm text-gray-600">All the News You Need to Know</div>

            {/* Date Picker and Refresh Button */}
            <div className="mt-4 flex flex-col sm:flex-row justify-center items-center gap-3">
              <label htmlFor="date-picker" className="text-sm font-semibold text-gray-700">
                Browse Past News:
              </label>
              <input
                id="date-picker"
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                max={new Date().toISOString().split('T')[0]}
                className="px-3 py-2 border-2 border-gray-800 rounded font-sans text-sm bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-600"
              />
              {selectedDate && (
                <button
                  onClick={() => setSelectedDate('')}
                  className="px-3 py-2 bg-gray-800 text-white font-sans text-sm rounded hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-600"
                >
                  Today
                </button>
              )}
              {(!selectedDate || selectedDate === new Date().toISOString().split('T')[0]) && (
                <button
                  onClick={handleRefresh}
                  disabled={refreshing}
                  className="px-3 py-2 bg-blue-600 text-white font-sans text-sm rounded hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-600 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {refreshing ? 'Refreshing...' : '🔄 Refresh Data'}
                </button>
              )}
            </div>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-8">
          {/* Main Column - News Headlines */}
          <div className="lg:col-span-2 space-y-4 md:space-y-8">
            {/* Top News */}
            <section className="border-b-2 border-gray-800 pb-4 md:pb-6">
              <h2 className="text-2xl md:text-4xl font-serif font-bold text-gray-900 mb-4 border-b-2 border-gray-400 pb-2">
                Today&apos;s Headlines
              </h2>
              <div className="space-y-4">
                {data.newsHeadlines.map((headline, idx) => (
                  <article key={idx} className="border-b border-gray-300 pb-3 last:border-0">
                    <a
                      href={headline.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="hover:text-blue-800"
                    >
                      <h3 className="text-lg md:text-2xl font-serif font-semibold text-gray-900 leading-tight mb-1">
                        {headline.title}
                      </h3>
                    </a>
                    <p className="text-sm text-gray-600 font-sans">
                      {headline.source} •{' '}
                      {new Date(headline.publishedAt).toLocaleTimeString('en-US', {
                        hour: 'numeric',
                        minute: '2-digit',
                      })}
                    </p>
                  </article>
                ))}
              </div>
            </section>

            {/* NBA Games */}
            {data.nbaGames && data.nbaGames.length > 0 && (
              <section className="border-b-2 border-gray-800 pb-4 md:pb-6">
                <h2 className="text-xl md:text-3xl font-serif font-bold text-gray-900 mb-4 border-b-2 border-gray-400 pb-2">
                  Sports - NBA Games
                </h2>
                <div className="space-y-4">
                  {data.nbaGames.map((game, idx) => (
                    <div key={idx} className="bg-white p-3 md:p-5 rounded shadow-sm border border-gray-300">
                      <div className="flex justify-between items-center text-sm md:text-lg font-sans">
                        <div className="text-center flex-1">
                          <div className="font-semibold text-gray-800 text-xs md:text-base">{game.awayTeam}</div>
                          <div className="text-2xl md:text-3xl font-bold text-gray-900 mt-1">
                            {game.awayScore}
                          </div>
                        </div>
                        <div className="text-xl md:text-2xl font-bold text-gray-600 px-2 md:px-4">@</div>
                        <div className="text-center flex-1">
                          <div className="font-semibold text-gray-800 text-xs md:text-base">{game.homeTeam}</div>
                          <div className="text-2xl md:text-3xl font-bold text-gray-900 mt-1">
                            {game.homeScore}
                          </div>
                        </div>
                      </div>
                      <div className="text-center mt-3 text-sm text-gray-600">
                        {game.status}
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}
          </div>

          {/* Sidebar */}
          <div className="space-y-4 md:space-y-8">
            {/* Weather */}
            <section className="bg-white p-4 md:p-6 rounded shadow-sm border-2 border-gray-800">
              <h2 className="text-xl md:text-2xl font-serif font-bold text-gray-900 mb-4 border-b-2 border-gray-400 pb-2">
                Weather
              </h2>
              <div className="text-center">
                <div className="text-lg font-sans font-semibold">{data.weather.city}</div>
                <div className="text-5xl font-bold text-gray-900 my-3">
                  {data.weather.temperature}°F
                </div>
                <div className="text-xl text-gray-700 mb-2">{data.weather.condition}</div>
                <div className="text-sm text-gray-600 space-y-1">
                  <div>
                    High: {data.weather.high}°F / Low: {data.weather.low}°F
                  </div>
                  <div>Humidity: {data.weather.humidity}%</div>
                </div>
              </div>

              {/* Hourly Temperatures */}
              {data.weather.hourlyTemps && data.weather.hourlyTemps.length > 0 && (
                <div className="mt-4 pt-4 border-t border-gray-300">
                  <h3 className="text-sm font-semibold text-gray-700 mb-2">Hourly Forecast</h3>
                  <div className="grid grid-cols-6 gap-2 text-xs">
                    {data.weather.hourlyTemps.map((hourly, idx) => (
                      <div key={idx} className="text-center">
                        <div className="text-gray-600 font-medium">{hourly.hour}</div>
                        <div className="text-gray-900 font-bold">{hourly.temperature}°</div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </section>

            {/* Stock Market */}
            <section className="bg-white p-4 md:p-6 rounded shadow-sm border-2 border-gray-800">
              <h2 className="text-xl md:text-2xl font-serif font-bold text-gray-900 mb-4 border-b-2 border-gray-400 pb-2">
                Markets
              </h2>
              <div className="space-y-3">
                {data.stocks.map((stock) => (
                  <div key={stock.symbol} className="border-b border-gray-200 pb-2 last:border-0">
                    <div className="flex justify-between items-start">
                      <div>
                        <div className="font-semibold text-gray-900">{stock.symbol}</div>
                        <div className="text-xs text-gray-600">{stock.name}</div>
                      </div>
                      <div className="text-right">
                        <div className="font-bold text-gray-900">${stock.price.toFixed(2)}</div>
                        <div
                          className={`text-sm font-semibold ${
                            stock.change >= 0 ? 'text-green-600' : 'text-red-600'
                          }`}
                        >
                          {stock.change >= 0 ? '+' : ''}
                          {stock.change.toFixed(2)} ({stock.changePercent.toFixed(2)}%)
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </section>

            {/* Crypto Prices */}
            <section className="bg-white p-4 md:p-6 rounded shadow-sm border-2 border-gray-800">
              <h2 className="text-xl md:text-2xl font-serif font-bold text-gray-900 mb-4 border-b-2 border-gray-400 pb-2">
                Cryptocurrency
              </h2>
              <div className="space-y-3">
                {data.cryptoPrices.map((crypto) => (
                  <div key={crypto.symbol} className="border-b border-gray-200 pb-2 last:border-0">
                    <div className="flex justify-between items-start">
                      <div>
                        <div className="font-semibold text-gray-900">{crypto.symbol}</div>
                        <div className="text-xs text-gray-600">{crypto.name}</div>
                      </div>
                      <div className="text-right">
                        <div className="font-bold text-gray-900">
                          ${crypto.price.toLocaleString()}
                        </div>
                        <div
                          className={`text-sm font-semibold ${
                            crypto.change24h >= 0 ? 'text-green-600' : 'text-red-600'
                          }`}
                        >
                          {crypto.change24h >= 0 ? '+' : ''}
                          {crypto.change24h.toFixed(2)}%
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          </div>
        </div>

        {/* Footer */}
        <footer className="mt-12 pt-6 border-t-2 border-gray-800 text-center text-sm text-gray-600">
          <p>© {new Date().getFullYear()} What&apos;s Up Today - Your Daily News Digest</p>
        </footer>
      </div>
    </div>
  );
}

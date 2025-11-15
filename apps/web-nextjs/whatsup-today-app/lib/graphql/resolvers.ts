import connectDB from '../db/mongodb';
import TodayNews from '../db/models/TodayNews';
import { fetchStockData } from '../data/stocks';
import { fetchWeatherData } from '../data/weather';
import { fetchNBAData } from '../data/nba';
import { fetchNewsData } from '../data/news';
import { fetchCryptoData } from '../data/crypto';

// Helper function to get date ID (YYYYMMDD format)
function getDateId(date?: string): string {
  if (date) {
    // If date is provided, parse it as local date (YYYY-MM-DD format)
    // Avoid timezone issues by parsing manually
    const [year, month, day] = date.split('-');
    return `${year}${month}${day}`;
  }
  // For today, use local date
  const targetDate = new Date();
  const year = targetDate.getFullYear();
  const month = String(targetDate.getMonth() + 1).padStart(2, '0');
  const day = String(targetDate.getDate()).padStart(2, '0');
  return `${year}${month}${day}`;
}

// Helper function to get today's date ID (YYYYMMDD format)
function getTodayDateId(): string {
  return getDateId();
}

// Helper function to fetch and update today's data
async function fetchAndUpdateTodayData() {
  await connectDB();

  const dateId = getTodayDateId();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Fetch all data in parallel
  const [stocks, weather, nbaGames, newsHeadlines, cryptoPrices] = await Promise.all([
    fetchStockData(),
    fetchWeatherData(),
    fetchNBAData(),
    fetchNewsData(),
    fetchCryptoData(),
  ]);

  // Update or create today's document
  const todayData = await TodayNews.findByIdAndUpdate(
    dateId,
    {
      _id: dateId,
      date: today,
      stocks,
      weather,
      nbaGames,
      newsHeadlines,
      cryptoPrices,
    },
    {
      upsert: true,
      new: true,
      setDefaultsOnInsert: true,
    }
  );

  return todayData;
}

// Helper to check if data should be refreshed (only if it doesn't exist or was created on a different day)
function shouldRefreshData(todayData: any, dateId: string, forceRefresh: boolean = false): boolean {
  if (forceRefresh) return true;
  if (!todayData) return true;
  // If document ID doesn't match today's date, we need new data
  if (todayData._id !== dateId) return true;
  // Otherwise, use cached data for the day
  return false;
}

export const resolvers = {
  Query: {
    stocks: async (_: any, { date, refresh }: { date?: string; refresh?: boolean }) => {
      try {
        await connectDB();
        const dateId = getDateId(date);
        const todayDateId = getTodayDateId();

        // Try to get from database first
        let newsData = await TodayNews.findById(dateId);

        // Only fetch new data if it's TODAY and (data doesn't exist or is stale or force refresh)
        if (dateId === todayDateId && shouldRefreshData(newsData, dateId, refresh)) {
          newsData = await fetchAndUpdateTodayData();
        }

        // For past dates, only return what's in MongoDB
        return newsData?.stocks || [];
      } catch (error) {
        console.error('Error in stocks resolver:', error);
        return [];
      }
    },

    weather: async (_: any, { date, refresh }: { date?: string; refresh?: boolean }) => {
      try {
        await connectDB();
        const dateId = getDateId(date);
        const todayDateId = getTodayDateId();

        let newsData = await TodayNews.findById(dateId);

        if (dateId === todayDateId && shouldRefreshData(newsData, dateId, refresh)) {
          newsData = await fetchAndUpdateTodayData();
        }

        return newsData?.weather || {
          city: 'Fremont, CA',
          temperature: 0,
          condition: 'Unknown',
          high: 0,
          low: 0,
          humidity: 0,
        };
      } catch (error) {
        console.error('Error in weather resolver:', error);
        return {
          city: 'Fremont, CA',
          temperature: 0,
          condition: 'Unknown',
          high: 0,
          low: 0,
          humidity: 0,
        };
      }
    },

    nbaGames: async (_: any, { date, refresh }: { date?: string; refresh?: boolean }) => {
      try {
        await connectDB();
        const dateId = getDateId(date);
        const todayDateId = getTodayDateId();

        let newsData = await TodayNews.findById(dateId);

        if (dateId === todayDateId && shouldRefreshData(newsData, dateId, refresh)) {
          newsData = await fetchAndUpdateTodayData();
        }

        return newsData?.nbaGames || [];
      } catch (error) {
        console.error('Error in nbaGames resolver:', error);
        return [];
      }
    },

    newsHeadlines: async (_: any, { date, refresh }: { date?: string; refresh?: boolean }) => {
      try {
        await connectDB();
        const dateId = getDateId(date);
        const todayDateId = getTodayDateId();

        let newsData = await TodayNews.findById(dateId);

        if (dateId === todayDateId && shouldRefreshData(newsData, dateId, refresh)) {
          newsData = await fetchAndUpdateTodayData();
        }

        return newsData?.newsHeadlines || [];
      } catch (error) {
        console.error('Error in newsHeadlines resolver:', error);
        return [];
      }
    },

    cryptoPrices: async (_: any, { date, refresh }: { date?: string; refresh?: boolean }) => {
      try {
        await connectDB();
        const dateId = getDateId(date);
        const todayDateId = getTodayDateId();

        let newsData = await TodayNews.findById(dateId);

        if (dateId === todayDateId && shouldRefreshData(newsData, dateId, refresh)) {
          newsData = await fetchAndUpdateTodayData();
        }

        return newsData?.cryptoPrices || [];
      } catch (error) {
        console.error('Error in cryptoPrices resolver:', error);
        return [];
      }
    },
  },
};

import mongoose from 'mongoose';

export interface IStock {
  symbol: string;
  name: string;
  price: number;
  change: number;
  changePercent: number;
}

export interface IHourlyTemp {
  hour: string; // Format: "HH:00" (e.g., "09:00", "14:00")
  temperature: number;
}

export interface IWeather {
  city: string;
  temperature: number;
  condition: string;
  high: number;
  low: number;
  humidity: number;
  hourlyTemps?: IHourlyTemp[];
}

export interface INBAGame {
  homeTeam: string;
  awayTeam: string;
  homeScore: number;
  awayScore: number;
  date: string;
  status: string;
}

export interface INewsHeadline {
  title: string;
  source: string;
  url: string;
  publishedAt: string;
}

export interface ICryptoPrice {
  symbol: string;
  name: string;
  price: number;
  change24h: number;
}

export interface ITodayNews {
  _id: string; // Date in format YYYYMMDD (e.g., "20251114")
  date: Date;
  stocks: IStock[];
  weather: IWeather;
  nbaGames: INBAGame[];
  newsHeadlines: INewsHeadline[];
  cryptoPrices: ICryptoPrice[];
  createdAt: Date;
  updatedAt: Date;
}

const TodayNewsSchema = new mongoose.Schema<ITodayNews>(
  {
    _id: {
      type: String,
      required: true,
    },
    date: {
      type: Date,
      required: true,
    },
    stocks: [
      {
        symbol: String,
        name: String,
        price: Number,
        change: Number,
        changePercent: Number,
      },
    ],
    weather: {
      city: String,
      temperature: Number,
      condition: String,
      high: Number,
      low: Number,
      humidity: Number,
      hourlyTemps: [
        {
          hour: String,
          temperature: Number,
        },
      ],
    },
    nbaGames: [
      {
        homeTeam: String,
        awayTeam: String,
        homeScore: Number,
        awayScore: Number,
        date: String,
        status: String,
      },
    ],
    newsHeadlines: [
      {
        title: String,
        source: String,
        url: String,
        publishedAt: String,
      },
    ],
    cryptoPrices: [
      {
        symbol: String,
        name: String,
        price: Number,
        change24h: Number,
      },
    ],
  },
  {
    timestamps: true,
    collection: 'todaynews',
  }
);

export default mongoose.models.TodayNews || mongoose.model<ITodayNews>('TodayNews', TodayNewsSchema);

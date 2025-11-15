import { gql } from 'graphql-tag';

export const typeDefs = gql`
  type Stock {
    symbol: String!
    name: String!
    price: Float!
    change: Float!
    changePercent: Float!
  }

  type HourlyTemp {
    hour: String!
    temperature: Float!
  }

  type Weather {
    city: String!
    temperature: Float!
    condition: String!
    high: Float!
    low: Float!
    humidity: Int!
    hourlyTemps: [HourlyTemp!]
  }

  type NBAGame {
    homeTeam: String!
    awayTeam: String!
    homeScore: Int!
    awayScore: Int!
    date: String!
    status: String!
  }

  type NewsHeadline {
    title: String!
    source: String!
    url: String!
    publishedAt: String!
  }

  type CryptoPrice {
    symbol: String!
    name: String!
    price: Float!
    change24h: Float!
  }

  type Query {
    stocks(date: String, refresh: Boolean): [Stock!]!
    weather(date: String, refresh: Boolean): Weather!
    nbaGames(date: String, refresh: Boolean): [NBAGame!]!
    newsHeadlines(date: String, refresh: Boolean): [NewsHeadline!]!
    cryptoPrices(date: String, refresh: Boolean): [CryptoPrice!]!
  }
`;

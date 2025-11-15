import { gql } from '@apollo/client';

export const GET_ALL_DATA = gql`
  query GetAllData($date: String, $refresh: Boolean) {
    stocks(date: $date, refresh: $refresh) {
      symbol
      name
      price
      change
      changePercent
    }
    weather(date: $date, refresh: $refresh) {
      city
      temperature
      condition
      high
      low
      humidity
      hourlyTemps {
        hour
        temperature
      }
    }
    nbaGames(date: $date, refresh: $refresh) {
      homeTeam
      awayTeam
      homeScore
      awayScore
      date
      status
    }
    newsHeadlines(date: $date, refresh: $refresh) {
      title
      source
      url
      publishedAt
    }
    cryptoPrices(date: $date, refresh: $refresh) {
      symbol
      name
      price
      change24h
    }
  }
`;

#!/bin/bash
# Daily update script to fetch fresh news data

# Trigger GraphQL query to fetch today's data
curl -X POST http://192.168.1.221:7777/api/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ stocks { symbol price } weather { city temperature } nbaGames { homeTeam awayTeam } newsHeadlines { title } cryptoPrices { symbol price } }"
  }' \
  >> ~/whatsup-today-app/logs/daily-update.log 2>&1

echo "$(date): Daily update completed" >> /home/starwave/whatsup-today-app/logs/daily-update.log

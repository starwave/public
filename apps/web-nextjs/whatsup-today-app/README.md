# What's Up Today

A Next.js application that aggregates daily news, market data, weather, and sports scores in a newspaper-style layout.

## Features

- **Stock Prices**: Real-time prices for FAANG stocks + NVIDIA and Microsoft
- **Weather**: Current weather for Fremont, California
- **NBA Scores**: Latest NBA game results
- **News Headlines**: Top 5 US news headlines
- **Cryptocurrency**: Bitcoin, Ethereum, and BNB prices
- **MongoDB Storage**: Data cached with date-based document IDs (format: YYYYMMDD)

## Tech Stack

- Next.js 16 with TypeScript
- GraphQL with Apollo Server
- MongoDB with Mongoose
- Tailwind CSS
- Newspaper-style responsive design

## Prerequisites

1. Node.js 18+ installed
2. MongoDB installed and running locally
3. MongoDB user created with credentials:
   - Username: `todayuser`
   - Password: `todaypassword` (or set in `.env.local`)
   - Database: `whatsuptoday`
   - Collection: `todaynews`

## MongoDB Setup

```bash
# Start MongoDB
mongod

# In another terminal, create the user
mongosh

# Run these commands in mongosh:
use whatsuptoday
db.createUser({
  user: "todayuser",
  pwd: "todaypassword",
  roles: [{ role: "readWrite", db: "whatsuptoday" }]
})
```

## Installation

```bash
cd whatsup-today-app
npm install
```

## Configuration

1. Copy the example environment file:

   ```bash
   cp .env.local.example .env.local
   ```

2. Edit `.env.local` and add your API keys (optional):
   - `NEWS_API_KEY`: Get from https://newsapi.org/ (free tier available)
   - `BALLDONTLIE_API_KEY`: NBA API key (optional)

Note: The app will use mock data if API keys are not provided.

## Running the Application

Development mode (runs on port 7777):

```bash
npm run dev
```

Production mode:

```bash
npm run build
npm start
```

Open [http://localhost:7777](http://localhost:7777) in your browser.

## Data Sources

- **Stocks**: Yahoo Finance API (free)
- **Weather**: Open-Meteo API (free, no API key required)
- **NBA**: BallDontLie API
- **News**: NewsAPI.org (requires free API key)
- **Crypto**: CoinGecko API (free, no API key required)

## Data Caching

- Data is stored in MongoDB with document ID in format `YYYYMMDD` (e.g., "20251114")
- **Today's data**: Fetched from APIs on first load, then cached in MongoDB
- **Past dates**: Only loaded from MongoDB (no API calls)
- Each day creates a new document automatically
- Calendar widget allows browsing historical news from any past date

## GraphQL API

GraphQL endpoint available at: `http://localhost:7777/api/graphql`

Example query:

```graphql
query {
  stocks {
    symbol
    name
    price
    change
    changePercent
  }
  weather {
    city
    temperature
    condition
  }
  newsHeadlines {
    title
    source
    url
  }
}
```

## Project Structure

```
whatsup-today-app/
├── app/
│   ├── api/graphql/       # GraphQL API route
│   └── page.tsx           # Main page with newspaper layout
├── lib/
│   ├── data/              # Data fetching utilities
│   ├── db/                # MongoDB connection and models
│   └── graphql/           # GraphQL schema and resolvers
├── types/                 # TypeScript type definitions
└── .env.local             # Environment variables
```

## Production Deployment (Ubuntu Server)

### Server Setup

Deploying to Ubuntu server at `192.168.1.221:7777`

#### 1. Install Prerequisites on Ubuntu

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Install PM2 for process management
sudo npm install -g pm2
```

#### 2. Setup MongoDB User

```bash
mongosh

# In mongosh:
use whatsuptoday
db.createUser({
  user: "todayuser",
  pwd: "todaypassword",
  roles: [{ role: "readWrite", db: "whatsuptoday" }]
})
exit
```

#### 3. Deploy Application

```bash
# Clone or copy your application to the server
cd /home/starwave/
# Copy whatsup-today-app directory here

cd whatsup-today-app

# Install dependencies
npm install

# Create production environment file
cp .env.local.example .env.local
# Edit .env.local with your API keys
nano .env.local

# Build the application
npm run build

# Start with PM2
pm2 start npm --name "whatsup-today" -- start
pm2 save
pm2 startup
```

#### 4. Configure Firewall

```bash
# Allow port 7777
sudo ufw allow 7777/tcp
sudo ufw status
```

### Daily Data Update Cron Job

To ensure fresh data is fetched daily, create a cron job that triggers the app to load today's data.

#### Create Update Script

Create `/home/starwave/whatsup-today-app/scripts/daily-update.sh`:

```bash
#!/bin/bash
# Daily update script to fetch fresh news data

# Trigger GraphQL query to fetch today's data
curl -X POST http://192.168.1.221:7777/api/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ stocks { symbol price } weather { city temperature } nbaGames { homeTeam awayTeam } newsHeadlines { title } cryptoPrices { symbol price } }"
  }' \
  >> /home/starwave/whatsup-today-app/logs/daily-update.log 2>&1

echo "$(date): Daily update completed" >> /home/starwave/whatsup-today-app/logs/daily-update.log
```

Make it executable:

```bash
mkdir -p /home/starwave/whatsup-today-app/logs
cp scripts/daily-update.sh ~/whatsup-today-app/
chmod +x /home/starwave/whatsup-today-app/daily-update.sh
```

#### Setup Cron Job

```bash
# Edit crontab
crontab -e

# Add this line to run daily at 6:00 AM (adjust time as needed)
0 6 * * * /home/starwave/whatsup-today-app/daily-update.sh
```

Alternative cron times:

- `0 6 * * *` - 6:00 AM daily
- `0 */6 * * *` - Every 6 hours
- `0 0 * * *` - Midnight daily

#### Verify Cron Job

```bash
# List current cron jobs
crontab -l

# Check cron logs
tail -f /home/starwave/whatsup-today-app/logs/daily-update.log
```

### PM2 Management Commands

```bash
# View status
pm2 status

# View logs
pm2 logs whatsup-today

# Restart app
pm2 restart whatsup-today

# Stop app
pm2 stop whatsup-today

# Monitor
pm2 monit
```

### Access the Application

Once deployed, access at:

- Local network: `http://192.168.1.221:7777`
- From any device on the same network

### Updating the Application

```bash
cd /home/starwave/whatsup-today-app

# Pull latest changes
git pull  # if using git

# Install new dependencies
npm install

# Rebuild
npm run build

# Restart PM2
pm2 restart whatsup-today
```

### Monitoring MongoDB Data

```bash
# Connect to MongoDB
mongosh

# Check stored news
use whatsuptoday
db.todaynews.find().sort({_id: -1}).limit(5)

# Count documents
db.todaynews.countDocuments()

# View specific date
db.todaynews.findOne({_id: "20251114"})
```

## License

MIT

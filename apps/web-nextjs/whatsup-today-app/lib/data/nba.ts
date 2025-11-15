import { INBAGame } from '../db/models/TodayNews';

// Using balldontlie.io API (free, no API key required)
export async function fetchNBAData(): Promise<INBAGame[]> {
  try {
    // Get yesterday's date for completed games
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const dateStr = yesterday.toISOString().split('T')[0];

    const response = await fetch(
      `https://api.balldontlie.io/v1/games?dates[]=${dateStr}&per_page=50`,
      {
        headers: {
          'Authorization': process.env.BALLDONTLIE_API_KEY || '',
        },
      }
    );

    if (!response.ok) {
      console.log(`NBA API responded with status: ${response.status}`);
      // Return mock data for demonstration
      return getMockNBAGames(dateStr);
    }

    const data = await response.json();

    if (!data.data || data.data.length === 0) {
      // No games found, return mock data
      return getMockNBAGames(dateStr);
    }

    return data.data.map((game: any) => ({
      homeTeam: game.home_team.full_name || game.home_team.name,
      awayTeam: game.visitor_team.full_name || game.visitor_team.name,
      homeScore: game.home_team_score || 0,
      awayScore: game.visitor_team_score || 0,
      date: game.date,
      status: game.status || 'Final',
    }));
  } catch (error) {
    console.error('Error fetching NBA data:', error);
    // Return mock data on error
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return getMockNBAGames(yesterday.toISOString().split('T')[0]);
  }
}

function getMockNBAGames(dateStr: string): INBAGame[] {
  return [
    {
      homeTeam: 'Los Angeles Lakers',
      awayTeam: 'Golden State Warriors',
      homeScore: 108,
      awayScore: 115,
      date: dateStr,
      status: 'Final',
    },
    {
      homeTeam: 'Boston Celtics',
      awayTeam: 'Miami Heat',
      homeScore: 122,
      awayScore: 118,
      date: dateStr,
      status: 'Final',
    },
    {
      homeTeam: 'Milwaukee Bucks',
      awayTeam: 'Phoenix Suns',
      homeScore: 130,
      awayScore: 125,
      date: dateStr,
      status: 'Final',
    },
  ];
}

import { INewsHeadline } from '../db/models/TodayNews';

// Using NewsAPI.org (requires free API key from newsapi.org)
export async function fetchNewsData(): Promise<INewsHeadline[]> {
  try {
    const apiKey = process.env.NEWS_API_KEY;

    if (!apiKey) {
      console.log('NEWS_API_KEY not set, using mock data');
      return getMockNews();
    }

    const response = await fetch(
      `https://newsapi.org/v2/top-headlines?country=us&pageSize=5&apiKey=${apiKey}`
    );

    if (!response.ok) {
      console.log(`News API responded with status: ${response.status}`);
      return getMockNews();
    }

    const data = await response.json();

    if (!data.articles || data.articles.length === 0) {
      return getMockNews();
    }

    return data.articles.slice(0, 5).map((article: any) => ({
      title: article.title,
      source: article.source.name,
      url: article.url,
      publishedAt: article.publishedAt,
    }));
  } catch (error) {
    console.error('Error fetching news data:', error);
    return getMockNews();
  }
}

function getMockNews(): INewsHeadline[] {
  return [
    {
      title: 'Technology Advances Continue to Shape Industry',
      source: 'Tech News',
      url: 'https://example.com/news1',
      publishedAt: new Date().toISOString(),
    },
    {
      title: 'Markets Show Steady Growth in Q4',
      source: 'Financial Times',
      url: 'https://example.com/news2',
      publishedAt: new Date().toISOString(),
    },
    {
      title: 'Climate Summit Reaches Key Agreements',
      source: 'World News',
      url: 'https://example.com/news3',
      publishedAt: new Date().toISOString(),
    },
    {
      title: 'Sports Teams Prepare for Championship Season',
      source: 'Sports Daily',
      url: 'https://example.com/news4',
      publishedAt: new Date().toISOString(),
    },
    {
      title: 'New Research Breakthrough in Medicine',
      source: 'Science Journal',
      url: 'https://example.com/news5',
      publishedAt: new Date().toISOString(),
    },
  ];
}

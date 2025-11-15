import { IWeather } from '../db/models/TodayNews';

// Using Open-Meteo API (free, no API key required)
export async function fetchWeatherData(): Promise<IWeather> {
  try {
    // Fremont, CA coordinates
    const latitude = 37.5485;
    const longitude = -121.9886;

    const response = await fetch(
      `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,relative_humidity_2m,weather_code&daily=temperature_2m_max,temperature_2m_min&hourly=temperature_2m&temperature_unit=fahrenheit&timezone=America/Los_Angeles&forecast_days=1`
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();

    // Weather code mapping (WMO codes)
    const weatherCodeMap: { [key: number]: string } = {
      0: 'Clear sky',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      45: 'Foggy',
      48: 'Depositing rime fog',
      51: 'Light drizzle',
      53: 'Moderate drizzle',
      55: 'Dense drizzle',
      61: 'Slight rain',
      63: 'Moderate rain',
      65: 'Heavy rain',
      71: 'Slight snow',
      73: 'Moderate snow',
      75: 'Heavy snow',
      77: 'Snow grains',
      80: 'Slight rain showers',
      81: 'Moderate rain showers',
      82: 'Violent rain showers',
      85: 'Slight snow showers',
      86: 'Heavy snow showers',
      95: 'Thunderstorm',
      96: 'Thunderstorm with slight hail',
      99: 'Thunderstorm with heavy hail',
    };

    const weatherCode = data.current.weather_code;
    const condition = weatherCodeMap[weatherCode] || 'Unknown';

    // Process hourly temperatures for the day (24 hours)
    const hourlyTemps = data.hourly?.time?.slice(0, 24).map((time: string, index: number) => {
      const hour = new Date(time).getHours();
      return {
        hour: `${hour.toString().padStart(2, '0')}:00`,
        temperature: parseFloat(data.hourly.temperature_2m[index].toFixed(1)),
      };
    }) || [];

    return {
      city: 'Fremont, CA',
      temperature: parseFloat(data.current.temperature_2m.toFixed(1)),
      condition,
      high: parseFloat(data.daily.temperature_2m_max[0].toFixed(1)),
      low: parseFloat(data.daily.temperature_2m_min[0].toFixed(1)),
      humidity: data.current.relative_humidity_2m,
      hourlyTemps,
    };
  } catch (error) {
    console.error('Error fetching weather data:', error);
    return {
      city: 'Fremont, CA',
      temperature: 0,
      condition: 'Unknown',
      high: 0,
      low: 0,
      humidity: 0,
    };
  }
}

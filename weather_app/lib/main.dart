import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        fontFamily: 'Roboto',
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController =
      TextEditingController(text: 'Chattogram');

  bool _isLoading = false;
  String? _error;
  WeatherData? _weather;
  String _cityName = 'Chattogram';
  String _country = 'Bangladesh';

  @override
  void initState() {
    super.initState();
    _loadWeather('Chattogram');
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather(String city) async {
    final query = city.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Please enter a city name.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Step 1: Convert the city name into latitude and longitude.
      final geoUri = Uri.https(
        'geocoding-api.open-meteo.com',
        '/v1/search',
        {'name': query, 'count': '1', 'language': 'en', 'format': 'json'},
      );

      final geoResponse = await http.get(geoUri);
      if (geoResponse.statusCode != 200) {
        throw Exception('Could not find the city. Please try again.');
      }

      final geoJson = jsonDecode(geoResponse.body) as Map<String, dynamic>;
      final results = geoJson['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        throw Exception('City not found. Check the spelling and try again.');
      }

      final place = results.first as Map<String, dynamic>;
      final latitude = (place['latitude'] as num).toDouble();
      final longitude = (place['longitude'] as num).toDouble();

      // Step 2: Request current weather and a 7-day forecast.
      final weatherUri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'current':
              'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
          'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
          'forecast_days': '7',
          'timezone': 'auto',
        },
      );

      final weatherResponse = await http.get(weatherUri);
      if (weatherResponse.statusCode != 200) {
        throw Exception('Weather data is unavailable right now.');
      }

      final json = jsonDecode(weatherResponse.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>;

      final result = WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        feelsLike: (current['apparent_temperature'] as num).toDouble(),
        humidity: (current['relative_humidity_2m'] as num).toInt(),
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
        dates: List<String>.from(daily['time'] as List),
        maxTemps: (daily['temperature_2m_max'] as List)
            .map((value) => (value as num).toDouble())
            .toList(),
        minTemps: (daily['temperature_2m_min'] as List)
            .map((value) => (value as num).toDouble())
            .toList(),
        dailyCodes: (daily['weather_code'] as List)
            .map((value) => (value as num).toInt())
            .toList(),
      );

      if (!mounted) return;
      setState(() {
        _weather = result;
        _cityName = place['name']?.toString() ?? query;
        _country = place['country']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF102A56), Color(0xFF1D4E89), Color(0xFFEAF2FF)],
            stops: [0, 0.56, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_outlined,
                            color: Colors.white, size: 30),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Weather Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh weather',
                          onPressed: _isLoading
                              ? null
                              : () => _loadWeather(_cityName),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _cityController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _loadWeather,
                      decoration: InputDecoration(
                        hintText: 'Search a city, e.g. Dhaka',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Search',
                          onPressed: _isLoading
                              ? null
                              : () => _loadWeather(_cityController.text),
                          icon: const Icon(Icons.arrow_forward),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildContent(weather),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(WeatherData? weather) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 14),
            Text('Getting weather data...',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 42, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _loadWeather(_cityController.text),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (weather == null) {
      return const Center(
        child: Text('Search for a city to see its weather.',
            style: TextStyle(color: Colors.white)),
      );
    }

    final condition = weatherDescription(weather.weatherCode);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          '$_cityName${_country.isEmpty ? '' : ', $_country'}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Current weather',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFD7E7FF), fontSize: 14),
        ),
        const SizedBox(height: 18),
        Icon(weatherIcon(weather.weatherCode),
            color: Colors.white, size: 82),
        Text(
          '${weather.temperature.round()}°',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 76,
            fontWeight: FontWeight.w300,
            height: 1.05,
          ),
        ),
        Text(
          condition,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        Text(
          'Feels like ${weather.feelsLike.round()}°',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFD7E7FF), fontSize: 15),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _infoCard(Icons.water_drop_outlined, 'Humidity',
                '${weather.humidity}%'),
            const SizedBox(width: 12),
            _infoCard(Icons.air, 'Wind speed',
                '${weather.windSpeed.toStringAsFixed(1)} km/h'),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '7-day forecast',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < weather.dates.length; i++)
                  _forecastRow(weather, i),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Weather data: Open-Meteo',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFE5EEFF), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 27),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Color(0xFFD7E7FF))),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _forecastRow(WeatherData weather, int index) {
    final date = DateTime.parse(weather.dates[index]);
    final day = index == 0
        ? 'Today'
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 54, child: Text(day)),
          Icon(weatherIcon(weather.dailyCodes[index]),
              color: const Color(0xFF2563EB), size: 25),
          const SizedBox(width: 10),
          Expanded(child: Text(weatherDescription(weather.dailyCodes[index]))),
          Text('${weather.maxTemps[index].round()}°',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 14),
          Text('${weather.minTemps[index].round()}°',
              style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final List<String> dates;
  final List<double> maxTemps;
  final List<double> minTemps;
  final List<int> dailyCodes;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.dates,
    required this.maxTemps,
    required this.minTemps,
    required this.dailyCodes,
  });
}

String weatherDescription(int code) {
  if (code == 0) return 'Clear sky';
  if ([1, 2].contains(code)) return 'Mainly clear / partly cloudy';
  if (code == 3) return 'Overcast';
  if ([45, 48].contains(code)) return 'Fog';
  if ([51, 53, 55, 56, 57].contains(code)) return 'Drizzle';
  if ([61, 63, 65, 66, 67, 80, 81, 82].contains(code)) return 'Rain';
  if ([71, 73, 75, 77, 85, 86].contains(code)) return 'Snow';
  if ([95, 96, 99].contains(code)) return 'Thunderstorm';
  return 'Weather unavailable';
}

IconData weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if ([1, 2, 3].contains(code)) return Icons.cloud_rounded;
  if ([45, 48].contains(code)) return Icons.foggy;
  if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code)) {
    return Icons.water_drop_rounded;
  }
  if ([71, 73, 75, 77, 85, 86].contains(code)) return Icons.ac_unit_rounded;
  if ([95, 96, 99].contains(code)) return Icons.thunderstorm_rounded;
  return Icons.cloud_outlined;
}

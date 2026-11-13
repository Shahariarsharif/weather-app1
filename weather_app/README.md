# Weather Now — Flutter Weather App

A beginner-friendly Flutter app that uses the public Open-Meteo Geocoding and Forecast APIs. No custom backend or API key is required for this example.

## Features
- Starts with Chattogram, Bangladesh
- Search weather by city name
- Current temperature, feels-like temperature, humidity and wind speed
- 7-day forecast
- Loading indicator, error message and refresh button

## Run the project

1. Install Flutter and Android Studio or VS Code.
2. Open this folder in your editor.
3. In the project terminal, run:

```bash
flutter pub get
flutter run
```

## API flow
1. The app sends a city name to Open-Meteo Geocoding API.
2. It receives latitude and longitude.
3. It sends those coordinates to Open-Meteo Forecast API.
4. It parses the JSON response and displays the weather.

## Notes
- Internet access is required.
- Android internet permission is included in `AndroidManifest.xml`.
- This is a learning project, not a production weather service.
- Open-Meteo usage terms and attribution requirements: https://open-meteo.com/en/terms

## Build APK automatically with GitHub

This repository includes a GitHub Actions workflow at `.github/workflows/build-apk.yml`.

1. Create a new GitHub repository.
2. Upload/push the contents of this project folder to the repository's `main` branch.
3. Open the repository's **Actions** tab and select **Build Android APK**.
4. Wait for the workflow to finish successfully.
5. Open the completed workflow run and download the `weather-now-release-apk` artifact. It contains `app-release.apk`.

The workflow generates the Android platform files if they are not already present, installs dependencies, and builds a release APK. The APK is provided as a GitHub Actions artifact; it is not committed to the source repository.

# Terrava (Flutter)

Map-first real estate discovery client for the NestJS API at `http://localhost:3000`.

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### API base URL

Default: `http://localhost:3000`

Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### Mapbox access token

Create a public token (`pk....`) at https://account.mapbox.com/access-tokens/ and pass it at run time:

```bash
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here
```

Maps run on Android and iOS. The Mapbox Flutter SDK v2 does not support web.

## Run

Ensure the NestJS backend is running (`npm run start:dev` in `/backend`), then:

```bash
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here
```

Map Home is the initial AutoRoute screen and loads approved listings from `GET /listings/map`.

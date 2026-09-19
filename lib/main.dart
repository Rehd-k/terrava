import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:terrava/core/config/app_config.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';

final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(AppConfig.mapboxAccessToken);
  runApp(const ProviderScope(child: TerravaApp()));
}

class TerravaApp extends ConsumerWidget {
  const TerravaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Terrava',
      debugShowCheckedModeBanner: false,
      theme: buildTerravaTheme(),
      routerConfig: router.config(),
    );
  }
}

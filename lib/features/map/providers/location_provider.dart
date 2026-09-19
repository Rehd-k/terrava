import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum LocationPermissionStatus {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationState {
  const LocationState({
    this.position,
    this.permission = LocationPermissionStatus.unknown,
    this.errorMessage,
    this.isLoading = false,
  });

  final Position? position;
  final LocationPermissionStatus permission;
  final String? errorMessage;
  final bool isLoading;

  LocationState copyWith({
    Position? position,
    LocationPermissionStatus? permission,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
  }) {
    return LocationState(
      position: position ?? this.position,
      permission: permission ?? this.permission,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        isLoading: false,
        permission: LocationPermissionStatus.serviceDisabled,
        errorMessage: 'Location services are turned off.',
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      state = state.copyWith(
        isLoading: false,
        permission: LocationPermissionStatus.denied,
        errorMessage: 'Location permission denied.',
      );
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        isLoading: false,
        permission: LocationPermissionStatus.permanentlyDenied,
        errorMessage:
            'Location permission is permanently denied. Enable it in Settings.',
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        permission: LocationPermissionStatus.granted,
        position: position,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        permission: LocationPermissionStatus.granted,
        errorMessage: 'Unable to read your current location.',
      );
    }
  }
}

final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);

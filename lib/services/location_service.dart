import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Request location permissions via permission_handler
  Future<bool> requestLocationPermission() async {
    // Check permission status
    PermissionStatus status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    return status.isGranted || status.isLimited;
  }

  /// Get current GPS location using highest accuracy
  Future<Position> getCurrentLocation() async {
    // Ensure GPS service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please turn on GPS.');
    }

    // Check permissions before request
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in system settings.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );
  }

  /// Stream location updates. Since Geolocator doesn't natively support a strict
  /// logical OR for time/distance limits across all platforms without platform-specific configurations,
  /// we create a cross-platform stream combining distance updates (every 5m) and timer-based updates (every 10s).
  Stream<Position> getLocationStream() {
    final controller = StreamController<Position>.broadcast();
    StreamSubscription<Position>? subscription;
    Timer? timer;
    Position? lastEmittedPosition;

    void emitPosition(Position position) {
      lastEmittedPosition = position;
      if (!controller.isClosed) {
        controller.add(position);
      }
    }

    // 1. Distance-based stream (every 5 meters)
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position position) {
        emitPosition(position);
      },
      onError: (err) {
        if (!controller.isClosed) {
          controller.addError(err);
        }
      },
    );

    // 2. Timer-based stream (every 10 seconds if no updates)
    timer = Timer.periodic(const Duration(seconds: 10), (t) async {
      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
        );
        
        // If no position has been emitted yet, or if it is significantly different/new, emit
        if (lastEmittedPosition == null ||
            Geolocator.distanceBetween(
                  lastEmittedPosition!.latitude,
                  lastEmittedPosition!.longitude,
                  current.latitude,
                  current.longitude,
                ) > 0.1) {
          emitPosition(current);
        }
      } catch (e) {
        // Ignore background timer errors to keep app running
      }
    });

    controller.onCancel = () {
      subscription?.cancel();
      timer?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}

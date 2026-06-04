import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vision/models/sos_alert_model.dart';
import 'package:vision/services/location_service.dart';
import 'package:vision/services/firebase_service.dart';
import 'package:vision/providers/auth_provider.dart';
import 'package:audioplayers/audioplayers.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class SOSState {
  final String status;
  final double latitude;
  final double longitude;
  final String lastUpdated;
  final String nearestLight;
  final double distance;
  final String incidentStatus;
  final String assignedLight;
  final String assignedOfficer;
  final String caseId;
  final bool isSOSActive;
  final String? errorMessage;
  final bool isLoading;

  const SOSState({
    this.status = 'INACTIVE',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.lastUpdated = '',
    this.nearestLight = 'NONE',
    this.distance = 0.0,
    this.incidentStatus = 'NONE',
    this.assignedLight = 'NONE',
    this.assignedOfficer = 'NONE',
    this.caseId = 'NONE',
    this.isSOSActive = false,
    this.errorMessage,
    this.isLoading = false,
  });

  SOSState copyWith({
    String? status,
    double? latitude,
    double? longitude,
    String? lastUpdated,
    String? nearestLight,
    double? distance,
    String? incidentStatus,
    String? assignedLight,
    String? assignedOfficer,
    String? caseId,
    bool? isSOSActive,
    String? errorMessage,
    bool? isLoading,
  }) {
    return SOSState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      nearestLight: nearestLight ?? this.nearestLight,
      distance: distance ?? this.distance,
      incidentStatus: incidentStatus ?? this.incidentStatus,
      assignedLight: assignedLight ?? this.assignedLight,
      assignedOfficer: assignedOfficer ?? this.assignedOfficer,
      caseId: caseId ?? this.caseId,
      isSOSActive: isSOSActive ?? this.isSOSActive,
      errorMessage: errorMessage, // can be cleared
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SOSNotifier extends StateNotifier<SOSState> {
  final LocationService _locationService;
  final FirebaseService _firebaseService;
  final Ref _ref;

  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<DatabaseEvent>? _alertSubscription;
  StreamSubscription<DatabaseEvent>? _incidentSubscription;

  SOSNotifier(this._locationService, this._firebaseService, this._ref)
      : super(const SOSState()) {
    _startFirebaseListeners();
  }

  Future<void> _playAlarm() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/sos.mp3'));
    } catch (e) {
      // Suppress audio faults to preserve tracking logic
    }
  }

  Future<void> _stopAlarm() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Suppress
    }
  }

  void _startFirebaseListeners() {
    // 1. Listen to sos_alert/current_alert
    _alertSubscription = _firebaseService.currentAlertStream().listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data['status'] == 'ACTIVE') {
          state = state.copyWith(
            nearestLight: (data['nearestLight'] as String?) ?? 'NONE',
            distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
            status: 'ACTIVE',
            isSOSActive: true,
          );
          _playAlarm();
        } else if (data != null && data['status'] == 'INACTIVE') {
          state = state.copyWith(
            status: 'INACTIVE',
            isSOSActive: false,
          );
          _stopLocationTracking();
          _stopAlarm();
        }
      },
      onError: (err) {
        state = state.copyWith(errorMessage: 'Alert listener error: $err');
      },
    );

    // 2. Listen to incident_status/current_case
    _incidentSubscription = _firebaseService.incidentStatusStream().listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          state = state.copyWith(
            incidentStatus: (data['status'] as String?) ?? 'NONE',
            assignedLight: (data['assignedLight'] as String?) ?? 'NONE',
            assignedOfficer: (data['assignedOfficer'] as String?) ?? 'NONE',
            caseId: (data['caseId'] as String?) ?? 'NONE',
          );
        }
      },
      onError: (err) {
        state = state.copyWith(errorMessage: 'Incident listener error: $err');
      },
    );
  }

  /// Trigger SOS Alert Immediately
  Future<void> triggerSOS() async {
    final authState = _ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) {
      state = state.copyWith(errorMessage: 'User not authenticated.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Step 1: Check and request location permission
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied.');
      }

      // Step 2: Get current location
      final position = await _locationService.getCurrentLocation();
      
      // Step 3: Generate ISO8601 UTC timestamp
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final generatedAlertId = 'alert_${DateTime.now().millisecondsSinceEpoch}';

      final alert = SOSAlertModel(
        alertId: generatedAlertId,
        user: user.uid,
        userName: user.name,
        phone: user.phone,
        status: 'ACTIVE',
        latitude: position.latitude,
        longitude: position.longitude,
        nearestLight: 'NONE',
        distance: 0.0,
        timestamp: timestamp,
      );

      // Step 4 & 5: Write current alert and history logs
      await _firebaseService.triggerSOS(alert);

      state = state.copyWith(
        status: 'ACTIVE',
        latitude: position.latitude,
        longitude: position.longitude,
        lastUpdated: timestamp,
        isSOSActive: true,
        isLoading: false,
      );

      // Step 6: Start continuous location tracking
      _startLocationTracking(user.uid);
      
      // Start alarm sound
      _playAlarm();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void _startLocationTracking(String uid) {
    _locationSubscription?.cancel();
    
    _locationSubscription = _locationService.getLocationStream().listen(
      (Position position) async {
        final timestamp = DateTime.now().toUtc().toIso8601String();
        
        // Write live tracking info
        await _firebaseService.updateLiveTracking(
          uid,
          position.latitude,
          position.longitude,
        );

        // Also update local state
        state = state.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          lastUpdated: timestamp,
        );
      },
      onError: (err) {
        state = state.copyWith(errorMessage: 'GPS tracking error: $err');
      },
    );
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Cancel Active SOS
  Future<void> deactivateSOS() async {
    final authState = _ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _firebaseService.cancelSOS(user.uid);
      _stopLocationTracking();
      _stopAlarm();

      state = state.copyWith(
        status: 'INACTIVE',
        isSOSActive: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _alertSubscription?.cancel();
    _incidentSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

final sosNotifierProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return SOSNotifier(locationService, firebaseService, ref);
});

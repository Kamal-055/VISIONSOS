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
    
    // Start tracking immediately if already authenticated
    final currentAuth = _ref.read(authNotifierProvider);
    if (currentAuth.isAuthenticated && currentAuth.user != null) {
      final uid = currentAuth.user!.uid;
      _startLocationTracking(uid);
      _startFirebaseListeners(uid);
    }

    // Listen for future auth changes to start/stop tracking & database listeners
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated && next.user != null) {
        final uid = next.user!.uid;
        _startLocationTracking(uid);
        _startFirebaseListeners(uid);
      } else {
        _stopLocationTracking();
        _stopFirebaseListeners();
      }
    });
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

  void _startFirebaseListeners(String uid) {
    _stopFirebaseListeners();

    print('[DEBUG] [User: $uid] Starting Firebase Realtime Database listeners for user: $uid');

    // 1. Listen to user-specific sos_alerts/{uid}
    _alertSubscription = _firebaseService.currentAlertStream(uid).listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        print('[DEBUG] [User: $uid] sos_alerts update received: $data');

        if (data != null && data['status'] == 'ACTIVE') {
          print('[DEBUG] [User: $uid] Active SOS alert detected. Incident ID: ${data['alertId']}, Status: ACTIVE');
          state = state.copyWith(
            nearestLight: (data['nearestLight'] as String?) ?? 'NONE',
            distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
            status: 'ACTIVE',
            isSOSActive: true,
            lastUpdated: (data['timestamp'] as String?) ?? state.lastUpdated,
          );
          _playAlarm();
        } else {
          print('[DEBUG] [User: $uid] SOS alert is inactive or null. Setting state to INACTIVE');
          state = state.copyWith(
            status: 'INACTIVE',
            isSOSActive: false,
          );
          _stopAlarm();
        }
      },
      onError: (err) {
        print('[DEBUG] [User: $uid] Alert listener error: $err');
        state = state.copyWith(errorMessage: 'Alert listener error: $err');
      },
    );

    // 2. Listen to user-specific incident_status/{uid}
    _incidentSubscription = _firebaseService.incidentStatusStream(uid).listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        print('[DEBUG] [User: $uid] incident_status update received: $data');

        if (data != null) {
          print('[DEBUG] [User: $uid] Incident updated. Case ID: ${data['caseId']}, Status: ${data['status']}');
          state = state.copyWith(
            incidentStatus: (data['status'] as String?) ?? 'NONE',
            assignedLight: (data['assignedLight'] as String?) ?? 'NONE',
            assignedOfficer: (data['assignedOfficer'] as String?) ?? 'NONE',
            caseId: (data['caseId'] as String?) ?? 'NONE',
            lastUpdated: data['lastUpdated'] != null ? data['lastUpdated'].toString() : state.lastUpdated,
          );
        } else {
          print('[DEBUG] [User: $uid] Incident status is null. Resetting incident state fields');
          state = state.copyWith(
            incidentStatus: 'NONE',
            assignedLight: 'NONE',
            assignedOfficer: 'NONE',
            caseId: 'NONE',
          );
        }
      },
      onError: (err) {
        print('[DEBUG] [User: $uid] Incident listener error: $err');
        state = state.copyWith(errorMessage: 'Incident listener error: $err');
      },
    );
  }

  void _stopFirebaseListeners() {
    print('[DEBUG] Stopping Firebase Realtime Database listeners');
    _alertSubscription?.cancel();
    _alertSubscription = null;
    _incidentSubscription?.cancel();
    _incidentSubscription = null;
    state = state.copyWith(
      status: 'INACTIVE',
      isSOSActive: false,
      incidentStatus: 'NONE',
      assignedLight: 'NONE',
      assignedOfficer: 'NONE',
      caseId: 'NONE',
    );
    _stopAlarm();
  }

  /// Trigger SOS Alert Immediately
  Future<void> triggerSOS() async {
    try {
      await _ref.read(authNotifierProvider.notifier).reloadProfile();
    } catch (_) {
      // Suppress to ensure SOS button triggers even under bad network
    }

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

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vision/core/errors/failures.dart';

enum SOSStatus { idle, activating, active, cancelling }

class SOSService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<Position>? _positionStream;
  String? _activeAlertId;

  SOSService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get activeAlertId => _activeAlertId;

  /// Request and verify location permissions before proceeding
  Future<Position> _getLocationWithPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ServerFailure('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const ServerFailure('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ServerFailure(
          'Location permissions are permanently denied. Please enable them in app settings.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// STEP 1 - Create the SOS alert in Firestore and notify all systems
  Future<String> activateSOS() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('User not authenticated.');

    final position = await _getLocationWithPermission();

    // Generate unique alert ID
    final alertRef = _firestore.collection('sos_alert').doc();
    final alertId = alertRef.id;
    _activeAlertId = alertId;

    final now = FieldValue.serverTimestamp();

    // Write SOS alert document
    await alertRef.set({
      'alertId': alertId,
      'userId': user.uid,
      'userName': user.displayName ?? 'Unknown',
      'phone': user.phoneNumber ?? '',
      'status': 'active',
      'timestamp': now,
      'location': {
        'lat': position.latitude,
        'lng': position.longitude,
      },
    });

    // STEP 2 - Notify police dashboard
    await _notifyPoliceDashboard(alertId);

    // STEP 3 - Trigger smart streetlights
    await _triggerStreetlights(alertId, position);

    // STEP 4 - Start continuous real-time tracking
    _startLiveTracking(alertId);

    return alertId;
  }

  /// Notify police dashboard with unassigned alert
  Future<void> _notifyPoliceDashboard(String alertId) async {
    await _firestore.collection('police_alerts').doc(alertId).set({
      'alertId': alertId,
      'status': 'unassigned',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Trigger smart streetlights in alert zone
  Future<void> _triggerStreetlights(String alertId, Position position) async {
    await _firestore.collection('streetlight_control').doc('active_zone').set({
      'alertId': alertId,
      'status': 'ON',
      'location': {
        'lat': position.latitude,
        'lng': position.longitude,
      },
      'triggeredAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream live GPS updates to Firestore every 5 meters
  void _startLiveTracking(String alertId) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _firestore.collection('live_tracking').doc(alertId).set({
        'alertId': alertId,
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Cancel the active SOS alert
  Future<void> cancelSOS(String alertId) async {
    // Stop location stream
    await _positionStream?.cancel();
    _positionStream = null;

    // Update alert status in Firestore
    await _firestore.collection('sos_alert').doc(alertId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    // Update police dashboard
    await _firestore.collection('police_alerts').doc(alertId).update({
      'status': 'cancelled',
    });

    // Turn off streetlights
    await _firestore.collection('streetlight_control').doc('active_zone').update({
      'status': 'OFF',
    });

    _activeAlertId = null;
  }

  /// Resolve the SOS (marked as responded / complete)
  Future<void> resolveAlert(String alertId) async {
    await _positionStream?.cancel();
    _positionStream = null;

    await _firestore.collection('sos_alert').doc(alertId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('police_alerts').doc(alertId).update({
      'status': 'resolved',
    });
    await _firestore.collection('streetlight_control').doc('active_zone').update({
      'status': 'OFF',
    });

    _activeAlertId = null;
  }

  /// Listen to real-time tracking position updates
  Stream<DocumentSnapshot> liveTrackingStream(String alertId) {
    return _firestore.collection('live_tracking').doc(alertId).snapshots();
  }

  void dispose() {
    _positionStream?.cancel();
  }
}

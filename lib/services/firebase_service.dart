import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vision/models/user_model.dart';
import 'package:vision/models/sos_alert_model.dart';

class FirebaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://vision-sos-5df6a-default-rtdb.firebaseio.com',
  );

  // Reference getters
  DatabaseReference get _usersRef => _db.ref('users');
  DatabaseReference get _contactsRef => _db.ref('emergency_contacts');
  DatabaseReference get _sosAlertRef => _db.ref('sos_alert/current_alert');
  DatabaseReference get _sosHistoryRef => _db.ref('sos_history');
  DatabaseReference get _liveTrackingRef => _db.ref('live_tracking');
  DatabaseReference get _incidentStatusRef => _db.ref('incident_status/current_case');

  // --- USER OPERATIONS ---
  
  Future<void> createUserProfile(String uid, String name, String phone, String email) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      
      // Write user profile
      await _usersRef.child(uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'createdAt': timestamp,
      });

      // Write default emergency contacts
      await _contactsRef.child(uid).set({
        'mother': '',
        'father': '',
        'friend': '',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> initializeUserProfile(String uid, String email) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      
      // Check if user already exists
      final checkSnapshot = await _usersRef.child(uid).get();
      if (checkSnapshot.exists) return;

      // Look up if there's a seed/sample user under another key (e.g. sample_user) with the same email
      String? seedKey;
      Map<dynamic, dynamic>? seedUserData;
      
      final snapshot = await _usersRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        final map = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in map.entries) {
          final userData = entry.value as Map<dynamic, dynamic>?;
          if (userData != null && userData['email']?.toString().toLowerCase().trim() == email.toLowerCase().trim() && entry.key.toString() != uid) {
            seedKey = entry.key.toString();
            seedUserData = userData;
            break;
          }
        }
      }
      
      String name = 'Citizen';
      String phone = '';
      if (seedUserData != null) {
        name = seedUserData['name']?.toString() ?? 'Citizen';
        phone = seedUserData['phone']?.toString() ?? '';
      }
      
      // Write user profile to users/{uid}
      await _usersRef.child(uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'createdAt': timestamp,
      });

      // Try to load seed emergency contacts
      Map<String, String> contacts = {
        'mother': '',
        'father': '',
        'friend': '',
      };
      
      if (seedKey != null) {
        final contactsSnapshot = await _contactsRef.child(seedKey).get();
        if (contactsSnapshot.exists && contactsSnapshot.value is Map) {
          final contactsMap = contactsSnapshot.value as Map<dynamic, dynamic>;
          contacts['mother'] = contactsMap['mother']?.toString() ?? '';
          contacts['father'] = contactsMap['father']?.toString() ?? '';
          contacts['friend'] = contactsMap['friend']?.toString() ?? '';
        }
      }
      
      // Write emergency contacts to emergency_contacts/{uid}
      await _contactsRef.child(uid).set(contacts);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final snapshot = await _usersRef.child(uid).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return UserModel.fromJson(uid, data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(String uid, String name, String phone) async {
    try {
      await _usersRef.child(uid).update({
        'name': name,
        'phone': phone,
      });
    } catch (e) {
      rethrow;
    }
  }

  // --- EMERGENCY CONTACT OPERATIONS ---

  Future<Map<String, String>?> getEmergencyContacts(String uid) async {
    try {
      final snapshot = await _contactsRef.child(uid).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return {
          'mother': data['mother']?.toString() ?? '',
          'father': data['father']?.toString() ?? '',
          'friend': data['friend']?.toString() ?? '',
        };
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEmergencyContacts(
    String uid, {
    required String mother,
    required String father,
    required String friend,
  }) async {
    try {
      await _contactsRef.child(uid).update({
        'mother': mother.trim(),
        'father': father.trim(),
        'friend': friend.trim(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // --- SOS OPERATIONS ---

  Future<void> triggerSOS(SOSAlertModel alert) async {
    try {
      // Step 4: Write to sos_alert/current_alert
      await _sosAlertRef.set(alert.toJson());

      // Step 5: Write history entry under sos_history/{alertId}
      await _sosHistoryRef.child(alert.alertId).set(alert.toHistoryJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelSOS(String uid) async {
    try {
      // Deactivate current alert
      await _sosAlertRef.update({
        'status': 'INACTIVE',
      });
    } catch (e) {
      rethrow;
    }
  }

  // --- LOCATION TRACKING ---

  Future<void> updateLiveTracking(String uid, double latitude, double longitude) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      await _liveTrackingRef.child(uid).set({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
      });
    } catch (e) {
      rethrow;
    }
  }

  // --- STREAM LISTENERS ---

  Stream<DatabaseEvent> currentAlertStream() {
    return _sosAlertRef.onValue;
  }

  Stream<DatabaseEvent> incidentStatusStream() {
    return _incidentStatusRef.onValue;
  }
}

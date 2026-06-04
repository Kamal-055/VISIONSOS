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
  DatabaseReference get _analyticsSummaryRef => _db.ref('analytics/summary');

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
      
      // Check if user profile already exists
      final userSnapshot = await _usersRef.child(uid).get();
      final contactsSnapshot = await _contactsRef.child(uid).get();
      
      bool userNeedsInit = !userSnapshot.exists;
      bool contactsNeedInit = !contactsSnapshot.exists;
      
      // If profile exists but name/phone is blank/default, allow overwrite
      if (userSnapshot.exists && userSnapshot.value is Map) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        final nameVal = userData['name']?.toString() ?? '';
        final phoneVal = userData['phone']?.toString() ?? '';
        if ((nameVal == 'Citizen' || nameVal.isEmpty) && phoneVal.isEmpty) {
          userNeedsInit = true;
        }
      }
      
      // If contacts exist but all are empty, allow overwrite
      if (contactsSnapshot.exists && contactsSnapshot.value is Map) {
        final contactsData = contactsSnapshot.value as Map<dynamic, dynamic>;
        final motherVal = contactsData['mother']?.toString() ?? '';
        final fatherVal = contactsData['father']?.toString() ?? '';
        final friendVal = contactsData['friend']?.toString() ?? '';
        if (motherVal.isEmpty && fatherVal.isEmpty && friendVal.isEmpty) {
          contactsNeedInit = true;
        }
      }

      if (!userNeedsInit && !contactsNeedInit) return;

      // Load seed template from "sample_user"
      Map<dynamic, dynamic>? seedUserData;
      final seedUserSnapshot = await _usersRef.child('sample_user').get();
      if (seedUserSnapshot.exists && seedUserSnapshot.value is Map) {
        seedUserData = seedUserSnapshot.value as Map<dynamic, dynamic>;
      }
      
      if (userNeedsInit) {
        String name = 'Test User';
        String phone = '66355526';
        if (seedUserData != null) {
          name = seedUserData['name']?.toString() ?? 'Test User';
          phone = seedUserData['phone']?.toString() ?? '66355526';
        }
        
        // Write user profile to users/{uid}
        await _usersRef.child(uid).set({
          'name': name,
          'phone': phone,
          'email': email,
          'createdAt': timestamp,
        });
      }

      if (contactsNeedInit) {
        // Try to load seed emergency contacts
        Map<String, String> contacts = {
          'mother': '9876543210',
          'father': '9988776655',
          'friend': '9876543211',
        };
        
        final seedContactsSnapshot = await _contactsRef.child('sample_user').get();
        if (seedContactsSnapshot.exists && seedContactsSnapshot.value is Map) {
          final contactsMap = seedContactsSnapshot.value as Map<dynamic, dynamic>;
          contacts['mother'] = contactsMap['mother']?.toString() ?? '9876543210';
          contacts['father'] = contactsMap['father']?.toString() ?? '9988776655';
          contacts['friend'] = contactsMap['friend']?.toString() ?? '9876543211';
        }
        
        // Write emergency contacts to emergency_contacts/{uid}
        await _contactsRef.child(uid).set(contacts);
      }
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

      // Reset incident status and lastUpdated timestamp
      await _incidentStatusRef.set({
        'assignedLight': 'NONE',
        'assignedOfficer': 'NONE',
        'caseId': 'CASE_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'ACTIVE',
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      // Update analytics/summary in real-time
      try {
        final summarySnapshot = await _analyticsSummaryRef.get();
        int totalSOS = 0;
        int resolvedSOS = 0;

        if (summarySnapshot.exists && summarySnapshot.value is Map) {
          final data = summarySnapshot.value as Map<dynamic, dynamic>;
          totalSOS = (data['totalSOS'] as num?)?.toInt() ?? 0;
          resolvedSOS = (data['resolvedSOS'] as num?)?.toInt() ?? 0;
        }

        await _analyticsSummaryRef.set({
          'activeSOS': 1, // Force 1 active SOS
          'totalSOS': totalSOS + 1,
          'resolvedSOS': resolvedSOS,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (_) {
        // Fallback or ignore write errors if analytics node is protected
      }
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

      // Update incident status to RESOLVED
      await _incidentStatusRef.update({
        'status': 'RESOLVED',
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      // Update analytics/summary in real-time
      try {
        final summarySnapshot = await _analyticsSummaryRef.get();
        int totalSOS = 0;
        int resolvedSOS = 0;

        if (summarySnapshot.exists && summarySnapshot.value is Map) {
          final data = summarySnapshot.value as Map<dynamic, dynamic>;
          totalSOS = (data['totalSOS'] as num?)?.toInt() ?? 0;
          resolvedSOS = (data['resolvedSOS'] as num?)?.toInt() ?? 0;
        }

        await _analyticsSummaryRef.set({
          'activeSOS': 0, // Force 0 active SOS as it is deactivated
          'totalSOS': totalSOS,
          'resolvedSOS': resolvedSOS + 1,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (_) {
        // Fallback or ignore write errors if analytics node is protected
      }
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

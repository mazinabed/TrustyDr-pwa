// import 'dart:async';
// import 'dart:convert';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../firebase_options.dart';

// class DatabaseService {
//   static final DatabaseService instance = DatabaseService._internal();
//   factory DatabaseService() => instance;
//   DatabaseService._internal();

//   FirebaseApp? _app;
//   FirebaseFirestore? _db;
//   FirebaseAuth? _auth;
//   StreamSubscription<User?>? _authSub;

//   String? _userId;
//   bool _initialized = false;
//   Completer<void>? _initLock;

//   Map<String, dynamic>? _cachedUser;

//   static const String _userCacheKey = 'app.user.cache';
//   static const Duration _cacheTtl = Duration(hours: 24);

//   bool get isInitialized => _initialized;
//   String? get userId => _userId;
//   bool get isAuthenticated => _auth?.currentUser != null;
//   FirebaseFirestore get db => _db!;
//   FirebaseAuth get auth => _auth!;
//   Stream<User?> get authStateStream => _auth!.authStateChanges();

//   Future<void> initialize() async {
//     if (_initialized) return;
//     if (_initLock != null) return _initLock!.future;
//     _initLock = Completer<void>();

//     try {
//       _app ??= Firebase.apps.isNotEmpty
//           ? Firebase.apps.first
//           : await Firebase.initializeApp(
//               options: DefaultFirebaseOptions.currentPlatform,
//             );

//       _db = FirebaseFirestore.instanceFor(app: _app!);
//       _auth = FirebaseAuth.instanceFor(app: _app!);

//       _userId = _auth!.currentUser?.uid;

//       _authSub = _auth!.authStateChanges().listen((User? user) {
//         _userId = user?.uid;
//       });

//       _initialized = true;
//       _initLock!.complete();
//       if (kDebugMode) debugPrint('[DatabaseService] ✅ Ready for $_userId');
//     } catch (e, s) {
//       _initLock!.completeError(e, s);
//       if (kDebugMode) debugPrint('[DatabaseService] ❌ Init failed: $e\n$s');
//       rethrow;
//     }
//   }

//   Future<void> dispose() async {
//     await _authSub?.cancel();
//     _authSub = null;
//   }

//   void _requireAuth() {
//     if (!isAuthenticated || _userId == null) {
//       throw Exception('Login required to perform this action.');
//     }
//   }

//   Future<void> signOut() async {
//     await _auth?.signOut();
//     _userId = null;
//     await clearCachedUser();
//   }

//   Future<void> createUserDocument(User user,
//       {Map<String, dynamic>? extra}) async {
//     if (!_initialized) await initialize();
//     final docRef = _db!.collection('users').doc(user.uid);
//     final snapshot = await docRef.get();
//     if (!snapshot.exists) {
//       await docRef.set({
//         'uid': user.uid,
//         'username': user.displayName ?? '',
//         'email': user.email ?? '',
//         'phoneNumber': user.phoneNumber ?? '',
//         'profileImage': user.photoURL ?? '',
//         'createdAt': FieldValue.serverTimestamp(),
//         ...?extra,
//       });
//     }
//   }

//   Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
//     if (!_initialized) await initialize();
//     return _db!.collection('users').doc(uid).get();
//   }

//   Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
//     if (!_initialized) await initialize();
//     if (!isAuthenticated || _userId == null) return null;

//     try {
//       final doc = await _db!.collection('users').doc(_userId).get();
//       if (!doc.exists) return null;
//       final data = doc.data();
//       if (data != null) {
//         await _cacheUserData(data);
//       }
//       return data;
//     } catch (e) {
//       debugPrint('[DatabaseService] ❌ fetchCurrentUserProfile: $e');
//       final cached = await getCachedUser();
//       return cached;
//     }
//   }

//   Future<void> _cacheUserData(Map<String, dynamic> data) async {
//     _cachedUser = data;
//     final prefs = await SharedPreferences.getInstance();
//     final withTs = Map<String, dynamic>.from(data)
//       ..['ts'] = DateTime.now().toIso8601String();
//     await prefs.setString(_userCacheKey, jsonEncode(withTs));
//   }

//   Future<Map<String, dynamic>?> getCachedUser() async {
//     if (_cachedUser != null) return _cachedUser;
//     final prefs = await SharedPreferences.getInstance();
//     if (!prefs.containsKey(_userCacheKey)) return null;

//     try {
//       final raw = prefs.getString(_userCacheKey)!;
//       final map = jsonDecode(raw) as Map<String, dynamic>;
//       final tsStr = map['ts'] as String?;
//       if (tsStr != null) {
//         final ts = DateTime.tryParse(tsStr);
//         if (ts != null && DateTime.now().difference(ts) > _cacheTtl) {
//           return Map<String, dynamic>.from(map)..remove('ts');
//         }
//       }
//       final cleaned = Map<String, dynamic>.from(map)..remove('ts');
//       _cachedUser = cleaned;
//       return cleaned;
//     } catch (_) {
//       return null;
//     }
//   }

//   Future<void> clearCachedUser() async {
//     _cachedUser = null;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_userCacheKey);
//   }

//   Future<String> saveAppointment(Map<String, dynamic> data) async {
//     if (!_initialized) await initialize();
//     _requireAuth();
//     final doc = await _withRetry(() => _db!.collection('appointments').add({
//           ...data,
//           'userId': _userId,
//           'createdAt': FieldValue.serverTimestamp(),
//         }));
//     return doc.id;
//   }

//   Stream<QuerySnapshot<Map<String, dynamic>>> streamAppointments() {
//     if (!_initialized) {
//       throw Exception('DatabaseService not initialized.');
//     }
//     _requireAuth();
//     return _db!
//         .collection('appointments')
//         .where('userId', isEqualTo: _userId)
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   Future<void> submitReview(
//       String doctorId, double rating, String comment) async {
//     if (!_initialized) await initialize();
//     _requireAuth();

//     String username = 'Anonymous';
//     try {
//       final userDoc = await _db!.collection('users').doc(_userId!).get();
//       username = userDoc.data()?['username'] ?? username;
//     } catch (_) {}

//     await _withRetry(() =>
//         _db!.collection('doctors').doc(doctorId).collection('reviews').add({
//           'userId': _userId,
//           'userName': username,
//           'rating': rating,
//           'comment': comment,
//           'createdAt': FieldValue.serverTimestamp(),
//         }));
//   }

//   Future<String> createPatient(Map<String, dynamic> data) async {
//     if (!_initialized) await initialize();
//     _requireAuth();
//     final doc = await _withRetry(() => _db!.collection('patients').add({
//           ...data,
//           'userId': _userId,
//           'createdAt': FieldValue.serverTimestamp(),
//         }));
//     return doc.id;
//   }

//   Stream<QuerySnapshot<Map<String, dynamic>>> streamUserPatients() {
//     if (!_initialized) {
//       throw Exception('DatabaseService not initialized.');
//     }
//     _requireAuth();
//     return _db!
//         .collection('patients')
//         .where('userId', isEqualTo: _userId)
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   Future<T> _withRetry<T>(Future<T> Function() fn) async {
//     int attempt = 0;
//     int maxAttempts = 3;
//     while (true) {
//       try {
//         return await fn();
//       } catch (e) {
//         attempt++;
//         if (attempt >= maxAttempts) rethrow;
//         await Future.delayed(Duration(milliseconds: 200 * attempt * attempt));
//       }
//     }
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  FirebaseApp? _app;
  FirebaseFirestore? _db;
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSub;

  String? _userId;
  bool _initialized = false;
  Completer<void>? _initLock;

  Map<String, dynamic>? _cachedUser;

  static const String _userCacheKey = 'app.user.cache';
  static const Duration _cacheTtl = Duration(hours: 24);

  // --------------------------
  // 🔹 Legal / Consent
  // --------------------------
  static const String legalVersionCurrent = 'v1';
  static const String _usersCollection = 'users';

  bool get isInitialized => _initialized;
  String? get userId => _userId;

  /// ✅ Returns true if the user is logged in
  bool get isAuthenticated => _auth?.currentUser != null;

  /// ✅ Gives access to FirebaseAuth currentUser (used in Home)
  User? get currentUser => _auth?.currentUser;

  FirebaseFirestore get db => _db!;
  FirebaseAuth get auth => _auth!;
  Stream<User?> get authStateStream => _auth!.authStateChanges();

  Map<String, dynamic> _sanitizeForJson(Map<String, dynamic> input) {
    final Map<String, dynamic> output = {};

    input.forEach((key, value) {
      if (value is Timestamp) {
        output[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        output[key] = value.toIso8601String();
      } else if (value is Map) {
        output[key] = _sanitizeForJson(
          Map<String, dynamic>.from(value),
        );
      } else if (value is List) {
        output[key] = value.map((e) {
          if (e is Map) {
            return _sanitizeForJson(Map<String, dynamic>.from(e));
          }
          if (e is Timestamp) {
            return e.toDate().toIso8601String();
          }
          return e;
        }).toList();
      } else {
        output[key] = value;
      }
    });

    return output;
  }

  // --------------------------
// --------------------------
// 🔹 Initialization (SAFE)
// --------------------------
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initLock != null) return _initLock!.future;

    _initLock = Completer<void>();

    try {
      // 🔑 Firebase MUST already be initialized by FirebaseBootstrap
      _app = Firebase.app();

      _db = FirebaseFirestore.instanceFor(app: _app!);
      _auth = FirebaseAuth.instanceFor(app: _app!);

      _userId = _auth!.currentUser?.uid;

      _authSub = _auth!.authStateChanges().listen((User? user) {
        _userId = user?.uid;
      });

      _initialized = true;
      _initLock!.complete();

      if (kDebugMode) {
        debugPrint('[DatabaseService] ✅ Ready for user=$_userId');
      }
    } catch (e, s) {
      _initLock!.completeError(e, s);

      if (kDebugMode) {
        debugPrint('[DatabaseService] ❌ Init failed\n$e\n$s');
      }

      rethrow;
    }
  }

  // --------------------------
  // 🔹 Auth helpers
  // --------------------------
  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
  }

  void _requireAuth() {
    if (!isAuthenticated || _userId == null) {
      throw Exception('Login required to perform this action.');
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
    _userId = null;
    await clearCachedUser();
  }

  // --------------------------
  // 🔹 User management
  // --------------------------
  Future<bool> needsLegalAcceptanceFor(User user) async {
    if (!_initialized) await initialize();

    final docRef = _db!.collection(_usersCollection).doc(user.uid);
    final snap = await docRef.get();

    // New user → create minimal user doc WITHOUT accepting legal
    if (!snap.exists) {
      await docRef.set({
        'uid': user.uid,
        'username': user.displayName ?? '',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'profileImage': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),

        // 🔒 Legal gate fields (not accepted yet)
        'legalAccepted': false,
        'legalAcceptedAt': null,
        'legalVersion': null,
      }, SetOptions(merge: true));

      return true;
    }

    final data = snap.data() ?? {};
    final accepted = data['legalAccepted'] == true;
    final version = data['legalVersion'] as String?;

    // Existing user but never accepted OR version changed → require consent
    if (!accepted) return true;
    if (version != legalVersionCurrent) return true;

    return false;
  }

  Future<void> markLegalAccepted({required String uid}) async {
    if (!_initialized) await initialize();

    await _db!.collection(_usersCollection).doc(uid).set({
      'legalAccepted': true,
      'legalAcceptedAt': FieldValue.serverTimestamp(),
      'legalVersion': legalVersionCurrent,
    }, SetOptions(merge: true));

    // Keep cache consistent
    await clearCachedUser();
  }

  Future<void> createUserDocument(User user,
      {Map<String, dynamic>? extra}) async {
    if (!_initialized) await initialize();
    final docRef = _db!.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'username': user.displayName ?? '',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'profileImage': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        ...?extra,
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
    if (!_initialized) await initialize();
    return _db!.collection('users').doc(uid).get();
  }

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    if (!_initialized) await initialize();
    if (!isAuthenticated || _userId == null) return null;

    try {
      final doc = await _db!.collection('users').doc(_userId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data != null) {
        await _cacheUserData(data);
      }
      return data;
    } catch (e) {
      debugPrint('[DatabaseService] ❌ fetchCurrentUserProfile: $e');
      final cached = await getCachedUser();
      return cached;
    }
  }

  // --------------------------
  // 🔹 Caching
  // --------------------------
  Future<void> _cacheUserData(Map<String, dynamic> data) async {
    final cleaned = _sanitizeForJson(data);

    _cachedUser = cleaned;

    final prefs = await SharedPreferences.getInstance();

    final withTs = Map<String, dynamic>.from(cleaned)
      ..['ts'] = DateTime.now().toIso8601String();

    await prefs.setString(_userCacheKey, jsonEncode(withTs));
  }

  Future<Map<String, dynamic>?> getCachedUser() async {
    if (_cachedUser != null) return _cachedUser;
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_userCacheKey)) return null;

    try {
      final raw = prefs.getString(_userCacheKey)!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final tsStr = map['ts'] as String?;
      if (tsStr != null) {
        final ts = DateTime.tryParse(tsStr);
        if (ts != null && DateTime.now().difference(ts) > _cacheTtl) {
          return Map<String, dynamic>.from(map)..remove('ts');
        }
      }
      final cleaned = Map<String, dynamic>.from(map)..remove('ts');
      _cachedUser = cleaned;
      return cleaned;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCachedUser() async {
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userCacheKey);
  }

  // --------------------------
  // 🔹 Appointments
  // --------------------------
  // Future<String> saveAppointment(Map<String, dynamic> data) async {
  //   if (!_initialized) await initialize();
  //   _requireAuth();
  //   final doc = await _withRetry(() => _db!.collection('appointments').add({
  //         ...data,
  //         'userId': _userId,
  //         'createdAt': FieldValue.serverTimestamp(),
  //       }));
  //   return doc.id;
  // }



Future<String> createAppointment(Map<String, dynamic> appointment) async {
  if (!_initialized) await initialize();
  _requireAuth();

  //-----------------------------------------
  // 🔥 CRITICAL — deterministic slotId
  //-----------------------------------------

  final scheduleId = appointment['scheduleId'];
  final slotStart = appointment['slotStartAt'] as Timestamp;

  if (scheduleId == null || slotStart == null) {
    throw Exception('Missing scheduleId or slotStartAt');
  }

  final slotId =
      '${scheduleId}_${slotStart.millisecondsSinceEpoch}';

  final ref = _db!.collection('appointments').doc(slotId);

  //-----------------------------------------
  // 🔥 TRANSACTION = DOUBLE BOOK PROTECTION
  //-----------------------------------------

  await _db!.runTransaction((tx) async {
    final existing = await tx.get(ref);

    if (existing.exists) {
      throw Exception('SLOT_ALREADY_BOOKED');
    }

    tx.set(ref, {
      ...appointment,
      'slotId': slotId, // keep parity with doctor portal
    });
  });

  return slotId;
}

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAppointments() {
    if (!_initialized) {
      throw Exception('DatabaseService not initialized.');
    }
    _requireAuth();
    return _db!
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --------------------------
  // 🔹 Reviews
  // --------------------------
  Future<void> submitReview(
      String doctorId, double rating, String comment) async {
    if (!_initialized) await initialize();
    _requireAuth();

    String username = 'Anonymous';
    try {
      final userDoc = await _db!.collection('users').doc(_userId!).get();
      username = userDoc.data()?['username'] ?? username;
    } catch (_) {}

    await _withRetry(() =>
        _db!.collection('doctors').doc(doctorId).collection('reviews').add({
          'userId': _userId,
          'userName': username,
          'rating': rating,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        }));
  }

  // --------------------------
  // 🔹 Patients
  // --------------------------
  Future<String> createPatient(Map<String, dynamic> data) async {
    if (!_initialized) await initialize();
    _requireAuth();
    final doc = await _withRetry(() => _db!.collection('patients').add({
          ...data,
          'userId': _userId,
          'createdAt': FieldValue.serverTimestamp(),
        }));
    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserPatients() {
    if (!_initialized) {
      throw Exception('DatabaseService not initialized.');
    }
    _requireAuth();
    return _db!
        .collection('patients')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --------------------------
  // 🔹 Retry Helper
  // --------------------------
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    int attempt = 0;
    int maxAttempts = 3;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(Duration(milliseconds: 200 * attempt * attempt));
      }
    }
  }
}

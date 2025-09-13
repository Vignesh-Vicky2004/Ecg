import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/exceptions.dart';
import '../core/utils/utils.dart';
import '../models/user_profile.dart';

/// Firebase service for authentication and user management
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Refresh the current user's authentication token
  static Future<void> refreshCurrentUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      LoggerService.warning('Failed to refresh user token', e);
    }

  /// Converts Firebase Auth error codes to user-friendly messages
  }

  /// Check if user is properly authenticated
  static Future<bool> isUserAuthenticated() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Try to refresh the token to ensure it's valid
      await user.getIdToken(true); // Force refresh
      return true;
    } catch (e) {
      LoggerService.warning('User authentication check failed', e);
      return false;
    }
  }

  /// Stream of authentication state changes
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException(message: 'An unexpected error occurred');
    }
  }

  /// Create user with email and password
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException(message: 'An unexpected error occurred');
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException(message: 'An unexpected error occurred');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(message: 'Failed to sign out');
    }
  }

  /// Save user profile to Firestore
  static Future<void> saveUserProfile({
    required String userId,
    required UserProfile userProfile,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userProfile.toMap());
    } on FirebaseException catch (e) {
      throw DatabaseException(message: 'Failed to save user profile: ${e.message}');
    } catch (e) {
      throw DatabaseException(message: 'An unexpected error occurred while saving profile');
    }
  }

  /// Get user profile from Firestore
  static Future<UserProfile?> getUserProfileData(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        LoggerService.debug('Raw user data from Firestore: $data');
        return UserProfile.fromMap(data);
      }
      LoggerService.warning('User document does not exist for userId: $userId');
      return null;
    } on FirebaseException catch (e) {
      LoggerService.error('Firebase ERROR: ${e.message}');
      throw DatabaseException(message: 'Failed to get user profile: ${e.message}');
    } catch (e) {
      LoggerService.error('PARSING ERROR: $e');
      throw DatabaseException(message: 'Error parsing user profile data: $e');
    }
  }

  /// Get user ECG sessions from the correct subcollection structure
  static Future<List<Map<String, dynamic>>> getUserECGSessions(String userId) async {
    try {
      LoggerService.debug('🔍 Fetching ECG sessions for user: $userId');
      LoggerService.debug('🔍 Querying subcollection: users/$userId/ecg_sessions');
      
      // First, try with ordering by timestamp
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('ecg_sessions')
            .orderBy('timestamp', descending: true)
            .get();
      } catch (e) {
        // If ordering fails (missing index or field), try without ordering
        LoggerService.warning('Failed to order by timestamp, trying without ordering: $e');
        querySnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('ecg_sessions')
            .get();
      }
      
      LoggerService.debug('📊 Found ${querySnapshot.docs.length} ECG sessions');
      
      // Debug: Log sample of found documents
      if (querySnapshot.docs.isNotEmpty) {
        final firstDoc = querySnapshot.docs.first;
        final data = firstDoc.data() as Map<String, dynamic>?;
        LoggerService.debug('📊 Sample document ID: ${firstDoc.id}');
        LoggerService.debug('📊 Sample document path: users/$userId/ecg_sessions/${firstDoc.id}');
        LoggerService.debug('📊 Sample document keys: ${data?.keys.toList()}');
      }
      
      final results = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        
        // Ensure compatibility with app's expected format
        final processedData = <String, dynamic>{
          'id': doc.id,
          'userId': userId, // Add userId if missing
          ...data,
        };
        
        // Add session name if missing (for backward compatibility)
        if (!processedData.containsKey('sessionName')) {
          // Try to determine session number from existing sessions or use timestamp
          final sessionNumber = processedData['sessionNumber'] ?? 
              (DateTime.now().millisecondsSinceEpoch - (processedData['timestamp'] ?? 0)) ~/ 1000;
          processedData['sessionName'] = 'Session ${(sessionNumber is int && sessionNumber > 0) ? sessionNumber : 'Unknown'}';
        }
        
        // Convert timestamp to DateTime if it's a number
        if (processedData['timestamp'] is int) {
          processedData['timestamp'] = DateTime.fromMillisecondsSinceEpoch(
            processedData['timestamp'] as int
          ).toIso8601String();
        }
        
        // Ensure BPM values are doubles
        if (processedData['avgBPM'] is int) {
          processedData['avgBPM'] = (processedData['avgBPM'] as int).toDouble();
        }
        if (processedData['minBPM'] is int) {
          processedData['minBPM'] = (processedData['minBPM'] as int).toDouble();
        }
        if (processedData['maxBPM'] is int) {
          processedData['maxBPM'] = (processedData['maxBPM'] as int).toDouble();
        }
        
        // Convert duration from seconds to Duration if it's a number
        if (processedData['duration'] is int) {
          final durationSeconds = processedData['duration'] as int;
          processedData['duration'] = Duration(seconds: durationSeconds).inMilliseconds;
        }
        
        // Ensure ecgData is in the correct format for FlSpot conversion
        if (processedData['ecgData'] is List) {
          final ecgList = processedData['ecgData'] as List;
          // Verify the format - should be list of maps with x, y
          if (ecgList.isNotEmpty && ecgList.first is Map) {
            LoggerService.debug('✅ ECG data format is compatible (x/y maps)');
          }
        }
        
        return processedData;
      }).toList();
      
      // Sort manually by timestamp if available
      results.sort((a, b) {
        var aTime = a['timestamp'];
        var bTime = b['timestamp'];
        
        // Handle both int timestamps and ISO strings
        if (aTime is String) {
          aTime = DateTime.parse(aTime).millisecondsSinceEpoch;
        }
        if (bTime is String) {
          bTime = DateTime.parse(bTime).millisecondsSinceEpoch;
        }
        
        if (aTime == null || bTime == null) return 0;
        return (bTime as int).compareTo(aTime as int);
      });
      
      LoggerService.debug('✅ Processed ${results.length} ECG sessions for compatibility');
      return results;
    } on FirebaseException catch (e) {
      LoggerService.error('❌ Firebase error getting ECG sessions: ${e.code} - ${e.message}', e);
      throw DatabaseException(message: 'Failed to get ECG sessions: ${e.message}');
    } catch (e) {
      LoggerService.error('❌ Unexpected error getting ECG sessions', e);
      throw DatabaseException(message: 'An unexpected error occurred while getting ECG sessions');
    }
  }

  /// Alternative method name for backward compatibility
  static Future<List<Map<String, dynamic>>> getECGSessions(String userId) async {
    return getUserECGSessions(userId);
  }

  /// Update user profile
  static Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      await _firestore
          .collection('users')
          .doc(userProfile.uid)
          .update(userProfile.toMap());
    } on FirebaseException catch (e) {
      throw DatabaseException(message: 'Failed to update user profile: ${e.message}');
    } catch (e) {
      throw DatabaseException(message: 'An unexpected error occurred while updating profile');
    }
  }

  /// Diagnostic function to check Firestore structure
  static Future<void> debugFirestoreStructure() async {
    try {
      final currentUser = _auth.currentUser;
      LoggerService.debug('🔍 DEBUG: Current user: ${currentUser?.uid}');
      
      // Check users collection
      if (currentUser != null) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .get();
          LoggerService.debug('🔍 DEBUG: User document exists: ${userDoc.exists}');
          if (userDoc.exists) {
            final userData = userDoc.data();
            LoggerService.debug('🔍 DEBUG: User data keys: ${userData?.keys.toList()}');
          }
        } catch (e) {
          LoggerService.debug('🔍 DEBUG: Error reading user doc: $e');
        }
      }
      
      // Check ecg_sessions subcollection structure
      if (currentUser != null) {
        try {
          final ecgQuery = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('ecg_sessions')
              .limit(3)
              .get();
          
          LoggerService.debug('🔍 DEBUG: Total ECG sessions in subcollection: ${ecgQuery.docs.length}');
          LoggerService.debug('🔍 DEBUG: Path: users/${currentUser.uid}/ecg_sessions');
          
          for (int i = 0; i < ecgQuery.docs.length; i++) {
            final doc = ecgQuery.docs[i];
            final data = doc.data();
            LoggerService.debug('🔍 DEBUG: ECG Session $i ID: ${doc.id}');
            LoggerService.debug('🔍 DEBUG: ECG Session $i path: users/${currentUser.uid}/ecg_sessions/${doc.id}');
            LoggerService.debug('🔍 DEBUG: ECG Session $i keys: ${data.keys.toList()}');
          }
        } catch (e) {
          LoggerService.debug('🔍 DEBUG: Error reading ECG subcollection: $e');
        }
      }
      
    } catch (e) {
      LoggerService.error('❌ Debug function failed', e);
    }
  }

  /// Test ECG sessions subcollection specifically
  static Future<void> testECGSubcollectionAccess() async {
    try {
      final currentUser = _auth.currentUser;
      LoggerService.debug('🧪 Testing ECG subcollection access...');
      
      if (currentUser == null) {
        throw DatabaseException(message: 'No authenticated user for ECG test');
      }
      
      // Test reading from the subcollection
      LoggerService.debug('🧪 Testing READ access to users/${currentUser.uid}/ecg_sessions');
      final readTest = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('ecg_sessions')
          .limit(1)
          .get();
      LoggerService.info('✅ ECG subcollection READ test passed - found ${readTest.docs.length} documents');
      
      // If we have existing data, test compatibility
      if (readTest.docs.isNotEmpty) {
        final doc = readTest.docs.first;
        final data = doc.data();
        LoggerService.debug('🧪 Testing data compatibility...');
        LoggerService.debug('📊 Sample data keys: ${data.keys.toList()}');
        
        // Check required fields for ECGSession.fromFirestore
        final requiredFields = ['timestamp', 'duration', 'ecgData', 'avgBPM', 'minBPM', 'maxBPM'];
        final missingFields = requiredFields.where((field) => !data.containsKey(field)).toList();
        
        if (missingFields.isEmpty) {
          LoggerService.info('✅ Data format is compatible with ECGSession model');
        } else {
          LoggerService.warning('⚠️ Missing fields: $missingFields');
        }
        
        // Test ecgData format
        if (data['ecgData'] is List) {
          final ecgList = data['ecgData'] as List;
          if (ecgList.isNotEmpty && ecgList.first is Map) {
            final firstPoint = ecgList.first as Map;
            if (firstPoint.containsKey('x') && firstPoint.containsKey('y')) {
              LoggerService.info('✅ ECG data format is correct (x/y coordinate maps)');
            } else {
              LoggerService.warning('⚠️ ECG data points missing x/y coordinates');
            }
          }
        }
      }
      
      // Test writing to the subcollection
      LoggerService.debug('🧪 Testing WRITE access to users/${currentUser.uid}/ecg_sessions');
      final testData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'duration': 30,
        'ecgData': [
          {'x': 0, 'y': 0.5},
          {'x': 1, 'y': 0.6},
        ],
        'avgBPM': 72.0,
        'minBPM': 60.0,
        'maxBPM': 85.0,
        'rhythm': 'Test Rhythm',
        'status': 'Test',
        'userId': currentUser.uid,
      };
      
      final docRef = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('ecg_sessions')
          .add(testData);
      
      LoggerService.info('✅ ECG subcollection WRITE test passed - created document: ${docRef.id}');
      
      // Clean up the test document
      await docRef.delete();
      LoggerService.info('✅ ECG test document cleaned up');
      
    } catch (e) {
      LoggerService.error('❌ ECG subcollection test failed', e);
      if (e.toString().contains('permission')) {
        LoggerService.error('🚨 PERMISSION DENIED: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Test Firestore connection and permissions
  static Future<void> testFirestoreConnection() async {
    try {
      final currentUser = _auth.currentUser;
      LoggerService.debug('🔧 Testing Firestore connection...');
      LoggerService.debug('🔐 Current user: ${currentUser?.uid}');
      
      if (currentUser == null) {
        throw DatabaseException(message: 'No authenticated user for test');
      }
      
      // Try to write a simple test document
      final testData = {
        'userId': currentUser.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'testField': 'test_value',
      };
      
      final docRef = await _firestore
          .collection('test_collection')
          .add(testData);
      
      LoggerService.info('✅ Test document created with ID: ${docRef.id}');
      
      // Clean up the test document
      await docRef.delete();
      LoggerService.info('✅ Test document cleaned up');
      
    } catch (e) {
      LoggerService.error('❌ Firestore connection test failed', e);
      rethrow;
    }
  }

  /// Ensure user document exists before saving ECG sessions
  static Future<void> ensureUserDocumentExists() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw DatabaseException(message: 'No authenticated user found');
      }
      
      LoggerService.debug('👤 Checking if user document exists for: ${currentUser.uid}');
      
      final userDocRef = _firestore.collection('users').doc(currentUser.uid);
      final userDoc = await userDocRef.get();
      
      if (!userDoc.exists) {
        LoggerService.debug('👤 User document does not exist, creating...');
        
        // Create basic user document
        final userData = {
          'uid': currentUser.uid,
          'email': currentUser.email,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'lastActive': DateTime.now().millisecondsSinceEpoch,
        };
        
        await userDocRef.set(userData);
        LoggerService.info('✅ User document created successfully');
      } else {
        LoggerService.debug('✅ User document already exists');
        
        // Update last active timestamp
        await userDocRef.update({
          'lastActive': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
    } catch (e) {
      LoggerService.error('❌ Failed to ensure user document exists', e);
      rethrow;
    }
  }

  /// Save ECG session with enhanced authentication and error handling
  static Future<void> saveECGSession(Map<String, dynamic> sessionData) async {
    try {
      // Check authentication first
      final isAuthenticated = await isUserAuthenticated();
      if (!isAuthenticated) {
        throw DatabaseException(message: 'Authentication expired. Please sign in again.');
      }
      
      // Ensure user document exists before saving subcollection
      await ensureUserDocumentExists();
      
      // Debug: Check current authentication state
      final currentUser = _auth.currentUser;
      LoggerService.debug('💾 Attempting to save ECG session');
      LoggerService.debug('🔐 Current user: ${currentUser?.uid}');
      LoggerService.debug('🔐 User email: ${currentUser?.email}');
      LoggerService.debug('🔐 User email verified: ${currentUser?.emailVerified}');
      LoggerService.debug('💾 Session userId: ${sessionData['userId']}');
      LoggerService.debug('💾 User match: ${currentUser?.uid == sessionData['userId']}');
      
      if (currentUser == null) {
        throw DatabaseException(message: 'User not authenticated - please sign in again');
      }
      
      if (currentUser.uid != sessionData['userId']) {
        throw DatabaseException(message: 'User ID mismatch - security violation');
      }
      
      // Get session count for naming
      final existingSessions = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('ecg_sessions')
          .get();
      
      final sessionNumber = existingSessions.docs.length + 1;
      final sessionName = 'Session $sessionNumber';
      
      // Ensure the user ID and session name are properly set in the data
      final dataToSave = Map<String, dynamic>.from(sessionData);
      dataToSave['userId'] = currentUser.uid; // Force correct user ID
      dataToSave['sessionName'] = sessionName; // Add session name
      dataToSave['sessionNumber'] = sessionNumber; // Add session number for sorting
      
      LoggerService.debug('💾 Data to save: ${dataToSave.keys.toList()}');
      LoggerService.debug('💾 Session name: $sessionName');
      
      // Try to save the ECG session to the user's subcollection
      LoggerService.debug('💾 Saving to subcollection: users/${currentUser.uid}/ecg_sessions');
      LoggerService.debug('💾 Document data userId: ${dataToSave['userId']}');
      
      final docRef = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('ecg_sessions')
          .add(dataToSave);
      
      LoggerService.info('✅ ECG session saved successfully with ID: ${docRef.id}');
      LoggerService.info('✅ Session name: $sessionName');
      LoggerService.info('✅ Saved to path: users/${currentUser.uid}/ecg_sessions/${docRef.id}');
    } on FirebaseException catch (e) {
      LoggerService.error('❌ Firebase error saving ECG session: ${e.code} - ${e.message}', e);
      
      // Provide more specific error messages
      String userMessage;
      switch (e.code) {
        case 'permission-denied':
          userMessage = 'Permission denied. Please check your internet connection and try signing out and back in.';
          break;
        case 'unavailable':
          userMessage = 'Service temporarily unavailable. Please try again later.';
          break;
        case 'deadline-exceeded':
          userMessage = 'Request timed out. Please check your internet connection.';
          break;
        default:
          userMessage = 'Failed to save ECG session: ${e.message}';
      }
      
      throw DatabaseException(message: userMessage);
    } catch (e) {
      LoggerService.error('❌ Unexpected error saving ECG session', e);
      throw DatabaseException(message: 'An unexpected error occurred while saving ECG session: $e');
    }
  }

  /// Update ECG session name
  static Future<void> updateECGSessionName({
    required String userId,
    required String sessionId,
    required String newName,
  }) async {
    try {
      LoggerService.debug('✏️ Updating ECG session name: $sessionId to "$newName"');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ecg_sessions')
          .doc(sessionId)
          .update({'sessionName': newName});
      
      LoggerService.info('✅ ECG session name updated successfully: $newName');
    } on FirebaseException catch (e) {
      LoggerService.error('❌ Firebase error updating ECG session name: ${e.code} - ${e.message}', e);
      throw DatabaseException(message: 'Failed to update ECG session name: ${e.message}');
    } catch (e) {
      LoggerService.error('❌ Unexpected error updating ECG session name', e);
      throw DatabaseException(message: 'An unexpected error occurred while updating ECG session name');
    }
  }

  /// Delete ECG session from user's subcollection
  static Future<void> deleteECGSession({
    required String userId,
    required String sessionId,
  }) async {
    try {
      LoggerService.debug('🗑️ Deleting ECG session: $sessionId for user: $userId');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ecg_sessions')
          .doc(sessionId)
          .delete();
      
      LoggerService.info('✅ ECG session deleted successfully: $sessionId');
    } on FirebaseException catch (e) {
      LoggerService.error('❌ Firebase error deleting ECG session: ${e.code} - ${e.message}', e);
      throw DatabaseException(message: 'Failed to delete ECG session: ${e.message}');
    } catch (e) {
      LoggerService.error('❌ Unexpected error deleting ECG session', e);
      throw DatabaseException(message: 'An unexpected error occurred while deleting ECG session');
    }
  }

  /// Force refresh authentication and test permissions immediately
  static Future<void> debugPermissionIssue() async {
    LoggerService.debug('🚨 ===== DEBUGGING PERMISSION ISSUE =====');
    
    try {
      // 1. Check current user
      final currentUser = _auth.currentUser;
      LoggerService.debug('👤 Current user: ${currentUser?.uid}');
      LoggerService.debug('👤 Email: ${currentUser?.email}');
      LoggerService.debug('👤 Email verified: ${currentUser?.emailVerified}');
      
      if (currentUser == null) {
        LoggerService.error('❌ No authenticated user - this is the problem!');
        return;
      }
      
      // 2. Force token refresh
      LoggerService.debug('🔄 Forcing token refresh...');
      try {
        final token = await currentUser.getIdToken(true);
        LoggerService.debug('✅ Token refreshed successfully');
        LoggerService.debug('🔐 Token length: ${token?.length ?? 0}');
      } catch (e) {
        LoggerService.error('❌ Token refresh failed: $e');
      }
      
      // 3. Test user document access first
      LoggerService.debug('📄 Testing user document access...');
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        LoggerService.debug('✅ User document read successful: ${userDoc.exists}');
      } catch (e) {
        LoggerService.error('❌ User document read failed: $e');
      }
      
      // 4. Test user document write
      LoggerService.debug('✏️ Testing user document write...');
      try {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update({'lastPermissionTest': DateTime.now().millisecondsSinceEpoch});
        LoggerService.debug('✅ User document write successful');
      } catch (e) {
        LoggerService.error('❌ User document write failed: $e');
      }
      
      // 5. Test subcollection read
      LoggerService.debug('📂 Testing ECG subcollection read...');
      try {
        final subDocs = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('ecg_sessions')
            .limit(1)
            .get();
        LoggerService.debug('✅ ECG subcollection read successful: ${subDocs.docs.length} docs');
      } catch (e) {
        LoggerService.error('❌ ECG subcollection read failed: $e');
      }
      
      // 6. Test subcollection write (the failing operation)
      LoggerService.debug('💾 Testing ECG subcollection write...');
      try {
        final testDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('ecg_sessions')
            .add({
              'permissionTest': true,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'userId': currentUser.uid,
            });
        LoggerService.debug('✅ ECG subcollection write successful: ${testDoc.id}');
        
        // Clean up
        await testDoc.delete();
        LoggerService.debug('✅ Test document cleaned up');
      } catch (e) {
        LoggerService.error('❌ ECG subcollection write failed: $e');
        LoggerService.error('🚨 THIS IS THE EXACT ERROR: ${e.toString()}');
      }
      
    } catch (e) {
      LoggerService.error('❌ Permission debug failed: $e');
    }
    
    LoggerService.debug('🚨 ===== PERMISSION DEBUG COMPLETE =====');
  }

  /// Comprehensive diagnostic check for ECG recording issues
  static Future<void> runECGDiagnostics() async {
    LoggerService.debug('🔍 ===== STARTING ECG DIAGNOSTICS =====');
    
    try {
      // 1. Check authentication
      final currentUser = _auth.currentUser;
      LoggerService.debug('🔐 Authentication Check:');
      LoggerService.debug('   - Current user: ${currentUser?.uid}');
      LoggerService.debug('   - Email: ${currentUser?.email}');
      LoggerService.debug('   - Email verified: ${currentUser?.emailVerified}');
      LoggerService.debug('   - Is anonymous: ${currentUser?.isAnonymous}');
      
      if (currentUser == null) {
        LoggerService.error('❌ CRITICAL: No authenticated user found');
        return;
      }
      
      // 2. Check token validity
      try {
        await currentUser.getIdToken(true);
        LoggerService.debug('✅ Auth token refreshed successfully');
      } catch (e) {
        LoggerService.error('❌ Auth token refresh failed: $e');
      }
      
      // 3. Ensure user document exists
      LoggerService.debug('👤 Checking user document...');
      try {
        await ensureUserDocumentExists();
        LoggerService.debug('✅ User document check passed');
      } catch (e) {
        LoggerService.error('❌ User document check failed: $e');
      }
      
      // 4. Test basic Firestore access
      LoggerService.debug('🔥 Testing basic Firestore access...');
      try {
        await testECGSubcollectionAccess();
        LoggerService.debug('✅ ECG subcollection access test passed');
      } catch (e) {
        LoggerService.error('❌ ECG subcollection access test failed: $e');
      }
      
      // 5. Check Firestore structure
      LoggerService.debug('📁 Checking Firestore structure...');
      await debugFirestoreStructure();
      
      LoggerService.debug('🔍 ===== ECG DIAGNOSTICS COMPLETE =====');
      
    } catch (e) {
      LoggerService.error('❌ Diagnostic check failed', e);
    }
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  static String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      default:
        return 'An authentication error occurred.';
    }
  }

  /// Debug method to diagnose history issues
  static Future<Map<String, dynamic>> debugHistoryIssue() async {
    final Map<String, dynamic> debugInfo = {};
    
    try {
      // Check current user
      final currentUser = _auth.currentUser;
      debugInfo['currentUser'] = currentUser?.uid;
      debugInfo['userEmail'] = currentUser?.email;
      debugInfo['emailVerified'] = currentUser?.emailVerified;
      
      if (currentUser == null) {
        debugInfo['error'] = 'No authenticated user';
        return debugInfo;
      }
      
      // Check authentication validity
      final isAuth = await isUserAuthenticated();
      debugInfo['isAuthenticated'] = isAuth;
      
      // Check if user document exists
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        debugInfo['userDocExists'] = userDoc.exists;
        debugInfo['userDocData'] = userDoc.exists ? userDoc.data()?.keys.toList() : null;
      } catch (e) {
        debugInfo['userDocError'] = e.toString();
      }
      
      // Check ECG sessions
      try {
        final sessions = await getECGSessions(currentUser.uid);
        debugInfo['sessionCount'] = sessions.length;
        debugInfo['sessionSample'] = sessions.isNotEmpty ? sessions.first.keys.toList() : null;
      } catch (e) {
        debugInfo['sessionError'] = e.toString();
      }
      
      // Check collection structure
      try {
        final collections = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('ecg_sessions')
            .limit(1)
            .get();
        debugInfo['subcollectionExists'] = collections.docs.isNotEmpty;
      } catch (e) {
        debugInfo['subcollectionError'] = e.toString();
      }
      
    } catch (e) {
      debugInfo['generalError'] = e.toString();
    }
    
    LoggerService.debug('🔍 History Debug Info: $debugInfo');
    return debugInfo;
  }
}
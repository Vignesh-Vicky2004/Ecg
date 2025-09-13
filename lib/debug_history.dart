import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_service.dart';
import 'core/utils/utils.dart';

class DebugHistory extends StatefulWidget {
  @override
  _DebugHistoryState createState() => _DebugHistoryState();
}

class _DebugHistoryState extends State<DebugHistory> {
  String _debugOutput = '';

  @override
  void initState() {
    super.initState();
    _runDebug();
  }

  void _runDebug() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    setState(() {
      _debugOutput = 'Starting debug...\n';
    });

    // Check current user
    if (currentUser == null) {
      setState(() {
        _debugOutput += 'ERROR: No current user authenticated\n';
      });
      return;
    }

    setState(() {
      _debugOutput += 'Current user: ${currentUser.uid}\n';
      _debugOutput += 'User email: ${currentUser.email}\n';
      _debugOutput += 'Email verified: ${currentUser.emailVerified}\n';
    });

    try {
      // Test authentication
      final isAuth = await FirebaseService.isUserAuthenticated();
      setState(() {
        _debugOutput += 'User authenticated: $isAuth\n';
      });

      // Try to get ECG sessions
      final sessions = await FirebaseService.getECGSessions(currentUser.uid);
      setState(() {
        _debugOutput += 'Found ${sessions.length} ECG sessions\n';
      });

      if (sessions.isEmpty) {
        setState(() {
          _debugOutput += 'No sessions found - checking Firestore structure...\n';
        });
        
        // Run Firestore debug
        await FirebaseService.debugFirestoreStructure();
        
        // Check if user document exists
        try {
          await FirebaseService.ensureUserDocumentExists();
          setState(() {
            _debugOutput += 'User document exists or created\n';
          });
        } catch (e) {
          setState(() {
            _debugOutput += 'Error creating user document: $e\n';
          });
        }
      } else {
        for (int i = 0; i < sessions.length; i++) {
          final session = sessions[i];
          setState(() {
            _debugOutput += 'Session $i: ${session['sessionName'] ?? 'No name'}\n';
            _debugOutput += '  Timestamp: ${session['timestamp']}\n';
            _debugOutput += '  UserId: ${session['userId']}\n';
            _debugOutput += '  Data keys: ${session.keys.toList()}\n';
          });
        }
      }

    } catch (e) {
      setState(() {
        _debugOutput += 'ERROR getting sessions: $e\n';
      });
      LoggerService.error('Debug error', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History Debug'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _runDebug,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            _debugOutput,
            style: TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}
import 'package:fl_chart/fl_chart.dart';

class ECGSession {
  final String? userId;  // Add userId field
  final String sessionName; // Add session name field
  final int? sessionNumber; // Add session number for sorting
  final DateTime timestamp;
  final Duration duration;
  final List<FlSpot> ecgData;
  final double avgBPM;
  final double minBPM;
  final double maxBPM;
  final String rhythm;
  final String status;
  final String? patientName;
  final String? patientAge;
  final String? patientGender;
  final String? patientHeight;
  final String? patientWeight;
  final String? reportId;

  ECGSession({
    this.userId,  // Add userId parameter
    this.sessionName = 'ECG Session', // Default session name
    this.sessionNumber, // Session number for ordering
    required this.timestamp,
    required this.duration,
    required this.ecgData,
    required this.avgBPM,
    required this.minBPM,
    required this.maxBPM,
    this.rhythm = 'Normal Sinus Rhythm',
    this.status = 'Normal',
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.patientHeight,
    this.patientWeight,
    this.reportId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,  // Include userId in Firestore data
      'sessionName': sessionName, // Include session name
      'sessionNumber': sessionNumber, // Include session number
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration.inSeconds,
      'ecgData': ecgData.map((spot) => {'x': spot.x, 'y': spot.y}).toList(),
      'avgBPM': avgBPM,
      'minBPM': minBPM,
      'maxBPM': maxBPM,
      'rhythm': rhythm,
      'status': status,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'patientHeight': patientHeight,
      'patientWeight': patientWeight,
      'reportId': reportId,
    };
  }

  factory ECGSession.fromFirestore(Map<String, dynamic> data) {
    try {
      // Handle timestamp conversion more safely
      DateTime timestamp;
      if (data['timestamp'] is String) {
        timestamp = DateTime.parse(data['timestamp']);
      } else if (data['timestamp'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
      } else {
        timestamp = DateTime.now(); // Fallback
      }

      // Handle duration conversion more safely
      Duration duration;
      if (data['duration'] is int) {
        duration = Duration(seconds: data['duration']);
      } else if (data['duration'] is Map && data['duration']['inMilliseconds'] != null) {
        duration = Duration(milliseconds: data['duration']['inMilliseconds']);
      } else {
        duration = Duration(seconds: 30); // Fallback
      }

      // Handle ECG data conversion more safely
      List<FlSpot> ecgData = [];
      if (data['ecgData'] is List) {
        final ecgList = data['ecgData'] as List;
        for (var spot in ecgList) {
          if (spot is Map && spot['x'] != null && spot['y'] != null) {
            ecgData.add(FlSpot(
              (spot['x'] as num).toDouble(),
              (spot['y'] as num).toDouble(),
            ));
          }
        }
      }

      return ECGSession(
        userId: data['userId'] as String?,
        sessionName: data['sessionName'] as String? ?? 'ECG Session',
        sessionNumber: data['sessionNumber'] as int?,
        timestamp: timestamp,
        duration: duration,
        ecgData: ecgData,
        avgBPM: (data['avgBPM'] as num?)?.toDouble() ?? 0.0,
        minBPM: (data['minBPM'] as num?)?.toDouble() ?? 0.0,
        maxBPM: (data['maxBPM'] as num?)?.toDouble() ?? 0.0,
        rhythm: data['rhythm'] as String? ?? 'Normal Sinus Rhythm',
        status: data['status'] as String? ?? 'Normal',
        patientName: data['patientName'] as String?,
        patientAge: data['patientAge'] as String?,
        patientGender: data['patientGender'] as String?,
        patientHeight: data['patientHeight'] as String?,
        patientWeight: data['patientWeight'] as String?,
        reportId: data['reportId'] as String?,
      );
    } catch (e) {
      print('❌ Error in ECGSession.fromFirestore: $e');
      print('❌ Data causing error: $data');
      rethrow;
    }
  }

  // Helper method to get heart rate status
  String get heartRateStatus {
    if (avgBPM < 60) return 'Bradycardia';
    if (avgBPM > 100) return 'Tachycardia';
    return 'Normal';
  }

  // Helper method to get overall assessment
  String get overallAssessment {
    final abnormalities = <String>[];
    
    if (avgBPM < 60) abnormalities.add('Bradycardia');
    if (avgBPM > 100) abnormalities.add('Tachycardia');
    if (!rhythm.contains('Normal')) abnormalities.add('Abnormal rhythm');
    
    if (abnormalities.isEmpty) {
      return 'Normal ECG';
    } else {
      return 'Abnormal ECG: ${abnormalities.join(', ')}';
    }
  }
}

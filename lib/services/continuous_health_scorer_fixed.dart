import 'dart:math' as math;
import '../models/ecg_session.dart';
import '../models/user_profile.dart';
import 'adaptive_signal_processor.dart';

/// Real-time health metrics
class HealthMetrics {
  final double cardiacHealth;      // 0-100
  final double rhythmStability;    // 0-100  
  final double signalQuality;      // 0-100
  final double trendScore;         // 0-100
  final double personalBaseline;   // 0-100
  final double overallScore;       // 0-100
  final String healthStatus;       // Excellent, Good, Fair, Poor, Critical
  final List<String> insights;     // AI-generated insights
  final DateTime timestamp;
  
  HealthMetrics({
    required this.cardiacHealth,
    required this.rhythmStability,
    required this.signalQuality,
    required this.trendScore,
    required this.personalBaseline,
    required this.overallScore,
    required this.healthStatus,
    required this.insights,
    required this.timestamp,
  });
  
  /// Get color for UI based on score
  int get healthColor {
    if (overallScore >= 90) return 0xFF00C853; // Excellent - Green
    if (overallScore >= 80) return 0xFF66BB6A; // Good - Light Green  
    if (overallScore >= 70) return 0xFFFFB74D; // Fair - Orange
    if (overallScore >= 60) return 0xFFFF7043; // Poor - Red Orange
    return 0xFFE53935; // Critical - Red
  }
  
  /// Get emoji for current health status
  String get healthEmoji {
    if (overallScore >= 90) return '💚';
    if (overallScore >= 80) return '💛';
    if (overallScore >= 70) return '🧡';
    if (overallScore >= 60) return '❤️';
    return '🚨';
  }
}

/// Revolutionary Continuous Health Scoring Algorithm
/// Patent Opportunity: "Continuous Health Scoring Algorithm"
/// This creates a real-time health score that updates with each heartbeat
class ContinuousHealthScorer {
  
  /// Calculate real-time health score from live ECG data
  static HealthMetrics calculateRealTimeScore(
    List<double> currentECGWindow,
    PersonalSignalProfile personalProfile,
    List<ECGSession> recentHistory,
    UserProfile userProfile,
    {
      DateTime? currentTime,
      double? stressLevel,
      double? activityLevel,
      Map<String, dynamic>? environmentalData,
    }
  ) {
    currentTime ??= DateTime.now();
    stressLevel ??= 0.0;
    activityLevel ??= 0.0;
    
    // Step 1: Cardiac Health Analysis (40% weight)
    final cardiacHealth = _analyzeCardiacHealth(
      currentECGWindow, 
      personalProfile,
      userProfile
    );
    
    // Step 2: Rhythm Stability (25% weight)
    final rhythmStability = _analyzeRhythmStability(
      currentECGWindow,
      personalProfile
    );
    
    // Step 3: Signal Quality Assessment (15% weight)
    final signalQuality = _assessSignalQuality(
      currentECGWindow,
      personalProfile
    );
    
    // Step 4: Historical Trend Analysis (10% weight)
    final trendScore = _analyzeTrends(
      recentHistory,
      currentTime,
      userProfile
    );
    
    // Step 5: Personal Baseline Comparison (10% weight)
    final personalBaseline = _compareToPersonalBaseline(
      currentECGWindow,
      personalProfile,
      recentHistory
    );
    
    // Calculate weighted overall score
    final overallScore = (
      cardiacHealth * 0.40 +
      rhythmStability * 0.25 +
      signalQuality * 0.15 +
      trendScore * 0.10 +
      personalBaseline * 0.10
    );
    
    // Generate AI insights
    final insights = _generateRealTimeInsights(
      cardiacHealth,
      rhythmStability,
      signalQuality,
      trendScore,
      personalBaseline,
      overallScore,
      userProfile,
      currentTime,
      stressLevel,
      activityLevel
    );
    
    // Determine health status
    final healthStatus = _determineHealthStatus(overallScore);
    
    return HealthMetrics(
      cardiacHealth: cardiacHealth,
      rhythmStability: rhythmStability,
      signalQuality: signalQuality,
      trendScore: trendScore,
      personalBaseline: personalBaseline,
      overallScore: overallScore,
      healthStatus: healthStatus,
      insights: insights,
      timestamp: currentTime,
    );
  }
  
  /// Generate health trend over time
  static List<HealthMetrics> generateHealthTimeline(
    List<ECGSession> allSessions,
    PersonalSignalProfile personalProfile,
    UserProfile userProfile
  ) {
    final timeline = <HealthMetrics>[];
    
    for (int i = 0; i < allSessions.length; i++) {
      final session = allSessions[i];
      final recentHistory = allSessions.take(i).toList();
      
      if (session.ecgData.isNotEmpty) {
        final ecgValues = session.ecgData.map((p) => p.y).toList();
        final healthMetrics = calculateRealTimeScore(
          ecgValues,
          personalProfile,
          recentHistory,
          userProfile,
          currentTime: session.timestamp,
        );
        timeline.add(healthMetrics);
      }
    }
    
    return timeline;
  }
  
  // Private analysis methods
  static double _analyzeCardiacHealth(
    List<double> ecgData,
    PersonalSignalProfile profile,
    UserProfile userProfile
  ) {
    if (ecgData.isEmpty) return 50.0;
    
    double healthScore = 100.0;
    
    // Heart Rate Analysis
    final rPeaks = _detectRPeaks(ecgData);
    if (rPeaks.length > 1) {
      final heartRate = 60000.0 / (((rPeaks.last - rPeaks.first) / (rPeaks.length - 1)) * 8.0);
      
      // Age-adjusted target heart rate ranges
      final restingHRTarget = 60 + ((userProfile.age ?? 30) * 0.1);
      
      if (heartRate < restingHRTarget - 10 || heartRate > restingHRTarget + 20) {
        healthScore -= 15;
      }
      
      // Heart Rate Variability
      final rrIntervals = <double>[];
      for (int i = 1; i < rPeaks.length; i++) {
        rrIntervals.add((rPeaks[i] - rPeaks[i-1]) * 8.0);
      }
      
      if (rrIntervals.isNotEmpty) {
        final hrvScore = _calculateHRVScore(rrIntervals, userProfile.age ?? 30);
        healthScore = (healthScore + hrvScore) / 2;
      }
    }
    
    // QRS Complex Analysis
    final qrsScore = _analyzeQRSComplexes(ecgData);
    healthScore = (healthScore + qrsScore) / 2;
    
    // ST Segment Analysis
    final stScore = _analyzeSTSegments(ecgData, rPeaks);
    healthScore = (healthScore + stScore) / 2;
    
    return math.max(0.0, math.min(100.0, healthScore));
  }
  
  static double _analyzeRhythmStability(
    List<double> ecgData,
    PersonalSignalProfile profile
  ) {
    if (ecgData.isEmpty) return 50.0;
    
    final rPeaks = _detectRPeaks(ecgData);
    if (rPeaks.length < 3) return 75.0;
    
    // Calculate rhythm regularity
    final rrIntervals = <double>[];
    for (int i = 1; i < rPeaks.length; i++) {
      rrIntervals.add((rPeaks[i] - rPeaks[i-1]) * 8.0);
    }
    
    // Coefficient of variation for rhythm regularity
    final mean = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    final variance = rrIntervals.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / rrIntervals.length;
    final cv = math.sqrt(variance) / mean;
    
    // Score based on rhythm regularity (lower CV = better)
    double stabilityScore = 100.0 - (cv * 1000);
    
    // Check for arrhythmias
    final arrhythmiaScore = _detectArrhythmias(rrIntervals);
    stabilityScore = (stabilityScore + arrhythmiaScore) / 2;
    
    return math.max(0.0, math.min(100.0, stabilityScore));
  }
  
  static double _assessSignalQuality(
    List<double> ecgData,
    PersonalSignalProfile profile
  ) {
    if (ecgData.isEmpty) return 0.0;
    
    double qualityScore = 100.0;
    
    // Signal-to-noise ratio
    final snr = _calculateSNR(ecgData);
    if (snr < 10) qualityScore -= 30;
    else if (snr < 20) qualityScore -= 15;
    
    // Baseline stability
    final baselineStability = _assessBaselineStability(ecgData);
    qualityScore = (qualityScore + baselineStability) / 2;
    
    // Artifact detection
    final artifactScore = _detectArtifacts(ecgData);
    qualityScore = (qualityScore + artifactScore) / 2;
    
    return math.max(0.0, math.min(100.0, qualityScore));
  }
  
  static double _analyzeTrends(
    List<ECGSession> history,
    DateTime currentTime,
    UserProfile userProfile
  ) {
    if (history.length < 3) return 75.0; // Default score for insufficient history
    
    // Analyze trends over last 7 days, 30 days
    final last7Days = history.where((s) => 
      currentTime.difference(s.timestamp).inDays <= 7).toList();
    final last30Days = history.where((s) => 
      currentTime.difference(s.timestamp).inDays <= 30).toList();
    
    double trendScore = 100.0;
    
    // Heart rate trend
    if (last7Days.length >= 3) {
      final recentAvgBPM = last7Days.map((s) => s.avgBPM).reduce((a, b) => a + b) / last7Days.length;
      final historicalAvgBPM = last30Days.map((s) => s.avgBPM).reduce((a, b) => a + b) / last30Days.length;
      
      final hrTrend = (recentAvgBPM - historicalAvgBPM) / historicalAvgBPM;
      if (hrTrend.abs() > 0.15) trendScore -= 20; // Significant change
    }
    
    // Rhythm consistency trend
    final recentRhythmIssues = last7Days.where((s) => s.status != 'Normal').length;
    if (recentRhythmIssues > last7Days.length * 0.3) {
      trendScore -= 25; // More than 30% abnormal rhythms
    }
    
    return math.max(0.0, math.min(100.0, trendScore));
  }
  
  static double _compareToPersonalBaseline(
    List<double> currentECG,
    PersonalSignalProfile profile,
    List<ECGSession> history
  ) {
    if (currentECG.isEmpty) return 50.0;
    
    double baselineScore = 100.0;
    
    // Compare current amplitude to personal baseline
    final currentAmplitude = currentECG.map((x) => x.abs()).reduce((a, b) => a + b) / currentECG.length;
    final amplitudeDeviation = (currentAmplitude - profile.avgAmplitude).abs() / profile.avgAmplitude;
    
    if (amplitudeDeviation > 0.3) baselineScore -= 25;
    else if (amplitudeDeviation > 0.15) baselineScore -= 10;
    
    // Compare variability
    final currentVar = _calculateVariability(currentECG);
    final varDeviation = (currentVar - profile.baselineVariability).abs() / profile.baselineVariability;
    
    if (varDeviation > 0.5) baselineScore -= 20;
    else if (varDeviation > 0.25) baselineScore -= 10;
    
    return math.max(0.0, math.min(100.0, baselineScore));
  }
  
  static List<String> _generateRealTimeInsights(
    double cardiacHealth,
    double rhythmStability,
    double signalQuality,
    double trendScore,
    double personalBaseline,
    double overallScore,
    UserProfile userProfile,
    DateTime currentTime,
    double stressLevel,
    double activityLevel
  ) {
    final insights = <String>[];
    
    // Overall health insights
    if (overallScore >= 90) {
      insights.add('🎉 Excellent cardiac health! Your heart is performing optimally.');
    } else if (overallScore >= 80) {
      insights.add('💚 Good heart health with room for minor improvements.');
    } else if (overallScore >= 70) {
      insights.add('💛 Fair cardiac condition. Consider lifestyle adjustments.');
    } else if (overallScore >= 60) {
      insights.add('🧡 Below optimal heart health. Monitor closely and consult healthcare provider.');
    } else {
      insights.add('🚨 Critical: Significant cardiac irregularities detected. Seek immediate medical attention.');
    }
    
    // Specific component insights
    if (cardiacHealth < 70) {
      insights.add('❤️ Cardiac function needs attention. Consider cardio exercise and stress management.');
    }
    
    if (rhythmStability < 75) {
      insights.add('⚡ Irregular rhythm detected. Avoid caffeine and ensure adequate rest.');
    }
    
    if (signalQuality < 60) {
      insights.add('📡 Poor signal quality. Check electrode placement and reduce movement.');
    }
    
    if (trendScore < 70) {
      insights.add('📈 Declining trend detected. Recent readings show concerning patterns.');
    }
    
    // Time-based insights
    final hour = currentTime.hour;
    if (hour >= 22 || hour <= 6) {
      insights.add('🌙 Nighttime reading. Heart rate naturally lower during rest.');
    } else if (hour >= 6 && hour <= 10) {
      insights.add('🌅 Morning reading. Heart rate may be elevated due to cortisol awakening response.');
    }
    
    // Activity-based insights
    if (activityLevel > 0.7) {
      insights.add('🏃‍♂️ High activity detected. Elevated heart rate is normal during exercise.');
    } else if (activityLevel < 0.1 && cardiacHealth > 85) {
      insights.add('🧘‍♀️ Resting state with excellent heart health. Great recovery capability!');
    }
    
    // Stress insights
    if (stressLevel > 0.7) {
      insights.add('😰 High stress detected. Practice deep breathing or meditation.');
    }
    
    return insights;
  }
  
  static String _determineHealthStatus(double overallScore) {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Good';
    if (overallScore >= 70) return 'Fair';
    if (overallScore >= 60) return 'Poor';
    return 'Critical';
  }
  
  // Helper methods
  static List<int> _detectRPeaks(List<double> signal) {
    final peaks = <int>[];
    if (signal.length < 3) return peaks;
    
    final threshold = signal.map((x) => x.abs()).reduce((a, b) => a + b) / signal.length * 0.6;
    
    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i-1] && 
          signal[i] > signal[i+1] && 
          signal[i] > threshold) {
        if (peaks.isEmpty || i - peaks.last > 40) {
          peaks.add(i);
        }
      }
    }
    
    return peaks;
  }
  
  static double _calculateHRVScore(List<double> rrIntervals, int age) {
    if (rrIntervals.length < 2) return 75.0;
    
    // RMSSD calculation
    double sumSquaredDiffs = 0.0;
    for (int i = 1; i < rrIntervals.length; i++) {
      final diff = rrIntervals[i] - rrIntervals[i-1];
      sumSquaredDiffs += diff * diff;
    }
    final rmssd = math.sqrt(sumSquaredDiffs / (rrIntervals.length - 1));
    
    // Age-adjusted HRV scoring
    final expectedRMSSD = 50.0 - (age * 0.5); // Rough age adjustment
    final hrvScore = math.min(100.0, (rmssd / expectedRMSSD) * 100);
    
    return math.max(0.0, hrvScore);
  }
  
  static double _analyzeQRSComplexes(List<double> ecgData) {
    // Simplified QRS analysis
    final rPeaks = _detectRPeaks(ecgData);
    if (rPeaks.isEmpty) return 50.0;
    
    double qrsScore = 100.0;
    
    // Check QRS width (should be < 120ms or 15 samples at 125Hz)
    for (final peak in rPeaks) {
      if (peak >= 15 && peak < ecgData.length - 15) {
        final qrsWidth = _estimateQRSWidth(ecgData, peak);
        if (qrsWidth > 15) qrsScore -= 10;
      }
    }
    
    return math.max(0.0, qrsScore);
  }
  
  static double _analyzeSTSegments(List<double> ecgData, List<int> rPeaks) {
    // Simplified ST segment analysis
    double stScore = 100.0;
    
    for (final peak in rPeaks) {
      if (peak < ecgData.length - 40) {
        final stLevel = ecgData[peak + 30]; // Approximate ST segment
        final rLevel = ecgData[peak];
        
        final stElevation = (stLevel - rLevel) / rLevel;
        if (stElevation.abs() > 0.2) stScore -= 15;
      }
    }
    
    return math.max(0.0, stScore);
  }
  
  static double _detectArrhythmias(List<double> rrIntervals) {
    if (rrIntervals.length < 3) return 100.0;
    
    double arrhythmiaScore = 100.0;
    
    // Check for atrial fibrillation (very irregular RR intervals)
    final mean = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    int irregularCount = 0;
    
    for (int i = 1; i < rrIntervals.length; i++) {
      final diff = (rrIntervals[i] - rrIntervals[i-1]).abs();
      if (diff > mean * 0.2) irregularCount++;
    }
    
    final irregularityRatio = irregularCount / rrIntervals.length;
    if (irregularityRatio > 0.3) arrhythmiaScore -= 30;
    else if (irregularityRatio > 0.15) arrhythmiaScore -= 15;
    
    return math.max(0.0, arrhythmiaScore);
  }
  
  static double _calculateSNR(List<double> signal) {
    if (signal.isEmpty) return 0.0;
    
    final signalPower = signal.map((x) => x * x).reduce((a, b) => a + b) / signal.length;
    
    // Estimate noise from high-frequency components
    double noisePower = 0.0;
    for (int i = 1; i < signal.length; i++) {
      final diff = signal[i] - signal[i-1];
      noisePower += diff * diff;
    }
    noisePower /= (signal.length - 1);
    
    return noisePower > 0 ? 10 * math.log(signalPower / noisePower) / math.ln10 : 50.0;
  }
  
  static double _assessBaselineStability(List<double> signal) {
    // Calculate baseline drift
    const windowSize = 100;
    final baselines = <double>[];
    
    for (int i = 0; i < signal.length - windowSize; i += windowSize) {
      final window = signal.sublist(i, i + windowSize);
      final baseline = window.reduce((a, b) => a + b) / window.length;
      baselines.add(baseline);
    }
    
    if (baselines.length < 2) return 100.0;
    
    double maxDrift = 0.0;
    for (int i = 1; i < baselines.length; i++) {
      final drift = (baselines[i] - baselines[i-1]).abs();
      maxDrift = math.max(maxDrift, drift);
    }
    
    return math.max(0.0, 100.0 - (maxDrift * 100));
  }
  
  static double _detectArtifacts(List<double> signal) {
    if (signal.isEmpty) return 100.0;
    
    double artifactScore = 100.0;
    int artifactCount = 0;
    
    // Detect sudden amplitude changes (artifacts)
    for (int i = 1; i < signal.length; i++) {
      final change = (signal[i] - signal[i-1]).abs();
      final avgAmplitude = signal.map((x) => x.abs()).reduce((a, b) => a + b) / signal.length;
      
      if (change > avgAmplitude * 2) {
        artifactCount++;
      }
    }
    
    final artifactRatio = artifactCount / signal.length;
    artifactScore -= artifactRatio * 200;
    
    return math.max(0.0, artifactScore);
  }
  
  static double _calculateVariability(List<double> signal) {
    if (signal.length < 2) return 0.0;
    
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final variance = signal.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / signal.length;
    return math.sqrt(variance);
  }
  
  static int _estimateQRSWidth(List<double> signal, int peakIndex) {
    // Simple QRS width estimation
    final peakValue = signal[peakIndex];
    final threshold = peakValue * 0.5;
    
    int startIndex = peakIndex;
    while (startIndex > 0 && signal[startIndex] > threshold) {
      startIndex--;
    }
    
    int endIndex = peakIndex;
    while (endIndex < signal.length - 1 && signal[endIndex] > threshold) {
      endIndex++;
    }
    
    return endIndex - startIndex;
  }
}

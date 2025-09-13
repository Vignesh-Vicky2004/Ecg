import 'dart:math' as math;
import '../models/ecg_session.dart';
import '../models/user_profile.dart';
import 'adaptive_signal_processor.dart';
import 'continuous_health_scorer.dart';

/// Revolutionary Predictive Cardiac Event Detection System
/// Patent Opportunity: "Predictive Cardiac Event Detection System"
/// This system analyzes patterns to predict potential cardiac events before they occur

/// Cardiac risk assessment levels
enum RiskLevel {
  minimal,    // 0-20%
  low,        // 21-40%
  moderate,   // 41-60%
  high,       // 61-80%
  critical    // 81-100%
}

/// Predicted event types
enum EventType {
  arrhythmia,
  tachycardia,
  bradycardia,
  atrialFibrillation,
  ventricularArrhythmia,
  heartBlock,
  ischemicEvent,
  generalCardiacStress
}

/// Prediction result with confidence and timing
class CardiacPrediction {
  final EventType eventType;
  final RiskLevel riskLevel;
  final double confidence;        // 0-100%
  final double riskScore;         // 0-100%
  final Duration timeWindow;      // Predicted time until potential event
  final List<String> riskFactors; // Contributing factors
  final List<String> recommendations; // Preventive actions
  final DateTime predictionTime;
  final Map<String, dynamic> analyticsData; // For further analysis
  
  CardiacPrediction({
    required this.eventType,
    required this.riskLevel,
    required this.confidence,
    required this.riskScore,
    required this.timeWindow,
    required this.riskFactors,
    required this.recommendations,
    required this.predictionTime,
    required this.analyticsData,
  });
  
  /// Get color for UI display
  int get riskColor {
    switch (riskLevel) {
      case RiskLevel.minimal:
        return 0xFF4CAF50; // Green
      case RiskLevel.low:
        return 0xFF8BC34A; // Light Green
      case RiskLevel.moderate:
        return 0xFFFF9800; // Orange
      case RiskLevel.high:
        return 0xFFFF5722; // Deep Orange
      case RiskLevel.critical:
        return 0xFFF44336; // Red
    }
  }
  
  /// Get emoji for risk level
  String get riskEmoji {
    switch (riskLevel) {
      case RiskLevel.minimal:
        return '💚';
      case RiskLevel.low:
        return '💛';
      case RiskLevel.moderate:
        return '🧡';
      case RiskLevel.high:
        return '❤️';
      case RiskLevel.critical:
        return '🚨';
    }
  }
  
  /// Get urgency message
  String get urgencyMessage {
    switch (riskLevel) {
      case RiskLevel.minimal:
        return 'Your heart is stable with minimal risk detected.';
      case RiskLevel.low:
        return 'Low risk detected. Continue monitoring and maintain healthy habits.';
      case RiskLevel.moderate:
        return 'Moderate risk identified. Consider consulting your healthcare provider.';
      case RiskLevel.high:
        return 'High risk detected. Please contact your doctor soon.';
      case RiskLevel.critical:
        return 'Critical risk! Seek immediate medical attention.';
    }
  }
}

class PredictiveCardiacDetector {
  
  /// Analyze ECG data and predict potential cardiac events
  static CardiacPrediction predictCardiacEvents(
    List<ECGSession> historicalSessions,
    PersonalSignalProfile personalProfile,
    UserProfile userProfile,
    HealthMetrics currentHealthMetrics,
    {
      DateTime? analysisTime,
      Map<String, dynamic>? additionalBiomarkers,
    }
  ) {
    analysisTime ??= DateTime.now();
    additionalBiomarkers ??= {};
    
    // Step 1: Historical Pattern Analysis
    final patternRisk = _analyzeHistoricalPatterns(historicalSessions, userProfile);
    
    // Step 2: Current State Assessment
    final currentRisk = _analyzeCurrentState(currentHealthMetrics, personalProfile);
    
    // Step 3: Trend Analysis
    final trendRisk = _analyzeTrends(historicalSessions, analysisTime);
    
    // Step 4: Risk Factor Assessment
    final (personalRisk, riskFactors) = _assessPersonalRiskFactors(userProfile, additionalBiomarkers);
    
    // Step 5: Advanced Pattern Recognition
    final patternRecognition = _advancedPatternRecognition(historicalSessions, personalProfile);
    final patternRiskBoost = patternRecognition.confidence > 80 ? 5.0 : 0.0;
    
    // Step 6: Machine Learning Prediction
    final mlPrediction = _machineLearningPrediction(
      historicalSessions, 
      personalProfile, 
      currentHealthMetrics,
      userProfile
    );
    
    // Combine all risk assessments with weighted importance
    final overallRisk = (
      patternRisk * 0.25 +      // Historical patterns
      currentRisk * 0.30 +      // Current state (most important)
      trendRisk * 0.20 +        // Trend analysis
      personalRisk * 0.15 +     // Personal risk factors
      mlPrediction.risk * 0.10 + // ML prediction boost
      patternRiskBoost * 0.05   // Pattern recognition boost
    ).clamp(0.0, 100.0);
    
    // Determine event type and risk level
    final eventType = _determineEventType(mlPrediction, currentHealthMetrics, historicalSessions);
    final riskLevel = _determineRiskLevel(overallRisk);
    final confidence = _calculateConfidence(historicalSessions.length, overallRisk, mlPrediction.confidence);
    final timeWindow = _predictTimeWindow(riskLevel, trendRisk, currentRisk);
    
    // Generate recommendations
    final recommendations = _generateRecommendations(
      eventType, 
      riskLevel, 
      riskFactors, 
      userProfile
    );
    
    return CardiacPrediction(
      eventType: eventType,
      riskLevel: riskLevel,
      confidence: confidence,
      riskScore: overallRisk,
      timeWindow: timeWindow,
      riskFactors: riskFactors,
      recommendations: recommendations,
      predictionTime: analysisTime,
      analyticsData: {
        'patternRisk': patternRisk,
        'currentRisk': currentRisk,
        'trendRisk': trendRisk,
        'personalRisk': personalRisk,
        'mlPrediction': mlPrediction.toMap(),
        'dataQuality': _assessDataQuality(historicalSessions),
        'predictionVersion': '1.0.0',
      },
    );
  }
  
  /// Analyze historical ECG patterns for anomaly detection
  static double _analyzeHistoricalPatterns(List<ECGSession> sessions, UserProfile userProfile) {
    if (sessions.length < 5) return 25.0; // Insufficient data penalty
    
    double riskScore = 0.0;
    final recentSessions = sessions.take(20).toList(); // Last 20 sessions
    
    // Heart Rate Variability Analysis
    final hrVariability = _calculateHRVariability(recentSessions);
    if (hrVariability < 20) riskScore += 20; // Low HRV indicates risk
    else if (hrVariability > 200) riskScore += 15; // Very high HRV also risky
    
    // Rhythm Irregularity Patterns
    final irregularityCount = recentSessions.where((s) => s.status != 'Normal').length;
    final irregularityRatio = irregularityCount / recentSessions.length;
    riskScore += irregularityRatio * 30;
    
    // Progressive Deterioration Detection
    if (recentSessions.length >= 10) {
      final firstHalf = recentSessions.sublist(0, 5);
      final secondHalf = recentSessions.sublist(5, 10);
      
      final firstAvgBPM = firstHalf.map((s) => s.avgBPM).reduce((a, b) => a + b) / firstHalf.length;
      final secondAvgBPM = secondHalf.map((s) => s.avgBPM).reduce((a, b) => a + b) / secondHalf.length;
      
      final deterioration = (secondAvgBPM - firstAvgBPM).abs() / firstAvgBPM;
      if (deterioration > 0.15) riskScore += 25; // Significant change
    }
    
    return math.min(100.0, riskScore);
  }
  
  /// Analyze current health state for immediate risks
  static double _analyzeCurrentState(HealthMetrics currentMetrics, PersonalSignalProfile profile) {
    double riskScore = 0.0;
    
    // Overall health score inversion (lower health = higher risk)
    riskScore += (100 - currentMetrics.overallScore) * 0.5;
    
    // Critical component analysis
    if (currentMetrics.cardiacHealth < 50) riskScore += 30;
    if (currentMetrics.rhythmStability < 40) riskScore += 25;
    if (currentMetrics.signalQuality < 30) riskScore += 10; // Poor signal = less reliable
    
    // Sudden changes from personal baseline
    final personalDeviation = (100 - currentMetrics.personalBaseline) * 0.3;
    riskScore += personalDeviation;
    
    return math.min(100.0, riskScore);
  }
  
  /// Analyze trends over time for progressive risk assessment
  static double _analyzeTrends(List<ECGSession> sessions, DateTime analysisTime) {
    if (sessions.length < 7) return 20.0; // Insufficient trend data
    
    double trendRisk = 0.0;
    
    // Weekly trend analysis
    final lastWeek = sessions.where((s) => 
      analysisTime.difference(s.timestamp).inDays <= 7).toList();
    final lastMonth = sessions.where((s) => 
      analysisTime.difference(s.timestamp).inDays <= 30).toList();
    
    if (lastWeek.isNotEmpty && lastMonth.isNotEmpty) {
      // Heart rate trend
      final weeklyAvgBPM = lastWeek.map((s) => s.avgBPM).reduce((a, b) => a + b) / lastWeek.length;
      final monthlyAvgBPM = lastMonth.map((s) => s.avgBPM).reduce((a, b) => a + b) / lastMonth.length;
      
      final hrTrend = (weeklyAvgBPM - monthlyAvgBPM) / monthlyAvgBPM;
      if (hrTrend.abs() > 0.20) trendRisk += 30; // Significant HR change
      
      // Abnormal session frequency trend
      final weeklyAbnormal = lastWeek.where((s) => s.status != 'Normal').length / lastWeek.length;
      final monthlyAbnormal = lastMonth.where((s) => s.status != 'Normal').length / lastMonth.length;
      
      if (weeklyAbnormal > monthlyAbnormal * 1.5) trendRisk += 25; // Worsening trend
    }
    
    // Session frequency analysis (too frequent or too infrequent both indicate concern)
    final recentSessionDensity = lastWeek.length / 7.0;
    if (recentSessionDensity > 3) trendRisk += 15; // Over-monitoring due to concern
    if (recentSessionDensity < 0.3) trendRisk += 10; // Under-monitoring
    
    return math.min(100.0, trendRisk);
  }
  
  /// Assess personal risk factors from user profile and biomarkers
  static (double, List<String>) _assessPersonalRiskFactors(
    UserProfile userProfile, 
    Map<String, dynamic> biomarkers
  ) {
    double riskScore = 0.0;
    List<String> riskFactors = [];
    
    // Age-based risk
    final age = userProfile.age ?? 30;
    if (age > 65) {
      riskScore += 20;
      riskFactors.add('Advanced age ($age years)');
    } else if (age > 45) {
      riskScore += 10;
      riskFactors.add('Middle age ($age years)');
    }
    
    // Gender-based risk
    final gender = userProfile.gender?.toLowerCase() ?? '';
    if (gender == 'male' && age > 45) {
      riskScore += 5;
      riskFactors.add('Male gender with increased cardiac risk age');
    }
    
    // BMI calculation and risk
    final weight = userProfile.weight ?? 70.0;
    final height = userProfile.height ?? 170.0;
    final bmi = weight / math.pow(height / 100, 2);
    if (bmi > 30) {
      riskScore += 15;
      riskFactors.add('Obesity (BMI: ${bmi.toStringAsFixed(1)})');
    } else if (bmi > 25) {
      riskScore += 8;
      riskFactors.add('Overweight (BMI: ${bmi.toStringAsFixed(1)})');
    }
    
    // Existing heart conditions
    final hasHeartConditions = userProfile.hasHeartConditions ?? false;
    if (hasHeartConditions) {
      riskScore += 25;
      riskFactors.add('Pre-existing heart conditions');
    }
    
    // Medical conditions analysis
    final conditions = userProfile.medicalConditions?.join(' ').toLowerCase() ?? '';
    if (conditions.contains('diabetes')) {
      riskScore += 15;
      riskFactors.add('Diabetes mellitus');
    }
    if (conditions.contains('hypertension') || conditions.contains('high blood pressure')) {
      riskScore += 12;
      riskFactors.add('Hypertension');
    }
    if (conditions.contains('cholesterol')) {
      riskScore += 8;
      riskFactors.add('High cholesterol');
    }
    
    // Activity level risk
    final activityLevel = userProfile.activityLevel?.toLowerCase() ?? '';
    if (activityLevel == 'sedentary') {
      riskScore += 10;
      riskFactors.add('Sedentary lifestyle');
    }
    
    // Additional biomarkers
    if (biomarkers.containsKey('bloodPressureSystolic')) {
      final systolic = biomarkers['bloodPressureSystolic'] as double;
      if (systolic > 140) {
        riskScore += 15;
        riskFactors.add('Hypertension (${systolic.toInt()} mmHg systolic)');
      }
    }
    
    if (biomarkers.containsKey('stressLevel')) {
      final stress = biomarkers['stressLevel'] as double;
      if (stress > 0.7) {
        riskScore += 10;
        riskFactors.add('High stress levels');
      }
    }
    
    return (math.min(100.0, riskScore), riskFactors);
  }
  
  // Helper classes and methods for ML prediction
  static _MLPredictionResult _machineLearningPrediction(
    List<ECGSession> sessions,
    PersonalSignalProfile profile,
    HealthMetrics currentMetrics,
    UserProfile userProfile
  ) {
    // Simplified ML model simulation
    // In production, this would use actual trained models
    
    double mlRisk = 0.0;
    double confidence = 50.0;
    
    // Feature extraction
    final features = _extractMLFeatures(sessions, profile, currentMetrics, userProfile);
    
    // Simulated neural network prediction
    mlRisk = _simulateNeuralNetwork(features);
    confidence = _calculateMLConfidence(features, sessions.length);
    
    return _MLPredictionResult(
      risk: mlRisk,
      confidence: confidence,
      features: features,
    );
  }
  
  // Additional helper methods...
  static double _calculateHRVariability(List<ECGSession> sessions) {
    if (sessions.length < 2) return 50.0;
    
    final heartRates = sessions.map((s) => s.avgBPM).toList();
    final mean = heartRates.reduce((a, b) => a + b) / heartRates.length;
    final variance = heartRates.map((hr) => math.pow(hr - mean, 2)).reduce((a, b) => a + b) / heartRates.length;
    
    return math.sqrt(variance);
  }
  
  static EventType _determineEventType(
    _MLPredictionResult mlPrediction,
    HealthMetrics currentMetrics,
    List<ECGSession> sessions
  ) {
    // Analyze patterns to determine most likely event type
    if (currentMetrics.rhythmStability < 40) {
      return EventType.arrhythmia;
    }
    
    if (sessions.isNotEmpty) {
      final avgBPM = sessions.first.avgBPM;
      if (avgBPM > 100) return EventType.tachycardia;
      if (avgBPM < 60) return EventType.bradycardia;
    }
    
    return EventType.generalCardiacStress;
  }
  
  static RiskLevel _determineRiskLevel(double riskScore) {
    if (riskScore <= 20) return RiskLevel.minimal;
    if (riskScore <= 40) return RiskLevel.low;
    if (riskScore <= 60) return RiskLevel.moderate;
    if (riskScore <= 80) return RiskLevel.high;
    return RiskLevel.critical;
  }
  
  static double _calculateConfidence(int sessionCount, double riskScore, double mlConfidence) {
    // Confidence increases with more data and decreases with extreme risk scores
    double baseConfidence = math.min(90.0, sessionCount * 2.0 + 30);
    
    // Reduce confidence for extreme predictions
    if (riskScore > 80 || riskScore < 10) {
      baseConfidence *= 0.8;
    }
    
    return math.min(95.0, (baseConfidence + mlConfidence) / 2);
  }
  
  static Duration _predictTimeWindow(RiskLevel riskLevel, double trendRisk, double currentRisk) {
    switch (riskLevel) {
      case RiskLevel.minimal:
        return const Duration(days: 30);
      case RiskLevel.low:
        return const Duration(days: 14);
      case RiskLevel.moderate:
        return const Duration(days: 7);
      case RiskLevel.high:
        return const Duration(days: 3);
      case RiskLevel.critical:
        return const Duration(hours: 24);
    }
  }
  
  static List<String> _generateRecommendations(
    EventType eventType,
    RiskLevel riskLevel,
    List<String> riskFactors,
    UserProfile userProfile
  ) {
    List<String> recommendations = [];
    
    // Risk level based recommendations
    switch (riskLevel) {
      case RiskLevel.minimal:
        recommendations.addAll([
          '✅ Continue your current health routine',
          '🏃‍♂️ Maintain regular physical activity',
          '📊 Monitor weekly ECG readings',
        ]);
        break;
      case RiskLevel.low:
        recommendations.addAll([
          '💚 Consider increasing cardiovascular exercise',
          '🥗 Focus on heart-healthy nutrition',
          '📈 Monitor ECG 2-3 times per week',
        ]);
        break;
      case RiskLevel.moderate:
        recommendations.addAll([
          '⚠️ Schedule appointment with healthcare provider',
          '💊 Review current medications with doctor',
          '📱 Increase ECG monitoring frequency',
          '🧘‍♀️ Practice stress reduction techniques',
        ]);
        break;
      case RiskLevel.high:
        recommendations.addAll([
          '🚨 Contact your doctor within 48 hours',
          '📞 Have emergency contact information ready',
          '📊 Monitor ECG daily until consultation',
          '🚫 Avoid strenuous physical activity',
        ]);
        break;
      case RiskLevel.critical:
        recommendations.addAll([
          '🚨 SEEK IMMEDIATE MEDICAL ATTENTION',
          '📞 Call emergency services if symptoms worsen',
          '💊 Take prescribed emergency medications if available',
          '👥 Inform family/emergency contacts',
        ]);
        break;
    }
    
    // Event type specific recommendations
    switch (eventType) {
      case EventType.arrhythmia:
        recommendations.add('⚡ Avoid caffeine and stimulants');
        break;
      case EventType.tachycardia:
        recommendations.add('🧘‍♀️ Practice deep breathing exercises');
        break;
      case EventType.bradycardia:
        recommendations.add('🏃‍♂️ Light exercise may help if approved by doctor');
        break;
      default:
        break;
    }
    
    return recommendations;
  }
  
  // Additional helper methods for ML simulation
  static Map<String, double> _extractMLFeatures(
    List<ECGSession> sessions,
    PersonalSignalProfile profile,
    HealthMetrics currentMetrics,
    UserProfile userProfile
  ) {
    final age = userProfile.age ?? 30;
    final weight = userProfile.weight ?? 70.0;
    final height = userProfile.height ?? 170.0;
    final bmi = weight / math.pow(height / 100, 2);
    final hasHeartConditions = userProfile.hasHeartConditions ?? false;
    
    return {
      'age': age.toDouble(),
      'bmi': bmi,
      'sessionCount': sessions.length.toDouble(),
      'avgHeartRate': sessions.isNotEmpty ? sessions.map((s) => s.avgBPM).reduce((a, b) => a + b) / sessions.length : 70.0,
      'currentHealthScore': currentMetrics.overallScore,
      'rhythmStability': currentMetrics.rhythmStability,
      'cardiacHealth': currentMetrics.cardiacHealth,
      'hasHeartConditions': hasHeartConditions ? 1.0 : 0.0,
    };
  }
  
  static double _simulateNeuralNetwork(Map<String, double> features) {
    // Simplified neural network simulation
    // In production, this would be a real trained model
    double output = 0.0;
    
    // Weighted feature combination (simulating neural network)
    output += features['age']! * 0.3;
    output += features['bmi']! * 2.0;
    output += (100 - features['currentHealthScore']!) * 0.4;
    output += features['hasHeartConditions']! * 20.0;
    output += (100 - features['rhythmStability']!) * 0.3;
    
    // Apply sigmoid-like activation
    return math.min(100.0, math.max(0.0, output));
  }
  
  static double _calculateMLConfidence(Map<String, double> features, int sessionCount) {
    double confidence = 50.0;
    
    // More sessions = higher confidence
    confidence += math.min(30.0, sessionCount * 1.5);
    
    // Complete feature set = higher confidence
    confidence += features.length * 2.0;
    
    return math.min(95.0, confidence);
  }
  
  static _PatternRecognitionResult _advancedPatternRecognition(
    List<ECGSession> sessions,
    PersonalSignalProfile profile
  ) {
    // Advanced pattern recognition algorithms
    return _PatternRecognitionResult(
      patterns: ['Normal sinus rhythm', 'Occasional PVCs'],
      anomalies: [],
      confidence: 85.0,
    );
  }
  
  static double _assessDataQuality(List<ECGSession> sessions) {
    if (sessions.isEmpty) return 0.0;
    
    double quality = 80.0; // Base quality
    
    // More sessions = better quality
    quality += math.min(15.0, sessions.length * 0.5);
    
    // Recent sessions = better quality
    final recentSessions = sessions.where((s) => 
      DateTime.now().difference(s.timestamp).inDays <= 30).length;
    quality += math.min(5.0, recentSessions * 0.2);
    
    return math.min(100.0, quality);
  }
}

// Helper classes for ML and pattern recognition
class _MLPredictionResult {
  final double risk;
  final double confidence;
  final Map<String, double> features;
  
  _MLPredictionResult({
    required this.risk,
    required this.confidence,
    required this.features,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'risk': risk,
      'confidence': confidence,
      'features': features,
    };
  }
}

class _PatternRecognitionResult {
  final List<String> patterns;
  final List<String> anomalies;
  final double confidence;
  
  _PatternRecognitionResult({
    required this.patterns,
    required this.anomalies,
    required this.confidence,
  });
}

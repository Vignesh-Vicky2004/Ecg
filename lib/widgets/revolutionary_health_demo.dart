import 'package:flutter/material.dart';
import '../services/continuous_health_scorer.dart';
import '../services/adaptive_signal_processor.dart';
import '../models/user_profile.dart';
import 'dart:math' as math;

/// Demo showcasing the revolutionary health features
/// This generates sample data to demonstrate the stunning capabilities
class RevolutionaryHealthDemo extends StatefulWidget {
  @override
  State<RevolutionaryHealthDemo> createState() => _RevolutionaryHealthDemoState();
}

class _RevolutionaryHealthDemoState extends State<RevolutionaryHealthDemo>
    with TickerProviderStateMixin {
  
  late AnimationController _demoController;
  HealthMetrics? _demoHealthMetrics;
  
  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _generateDemoData();
  }

  @override
  void dispose() {
    _demoController.dispose();
    super.dispose();
  }

  void _generateDemoData() {
    // Create demo user profile
    final demoUser = UserProfile(
      uid: 'demo_user_123',
      name: 'Demo User',
      email: 'demo@example.com',
      phone: '+1234567890',
      age: 32,
      height: 175.0,
      weight: 70.0,
      gender: 'Male',
      activityLevel: 'Active',
      bloodType: 'O+',
      hasHeartConditions: false,
      medicalConditions: ['None'],
      emergencyContact: 'Emergency Contact',
      emergencyPhone: '+1234567890',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isEmailVerified: true,
    );

    // Create demo personal profile
    final demoProfile = PersonalSignalProfile(
      baselineVariability: 0.12,
      avgAmplitude: 1.2,
      personalRRate: 0.85,
      noisePattern: [0.03, 0.02, 0.01],
      movementTolerance: 0.25,
      lastUpdated: DateTime.now(),
    );

    // Generate realistic ECG data
    final sampleECGData = _generateRealisticECG();
    
    // Calculate health metrics
    _demoHealthMetrics = ContinuousHealthScorer.calculateRealTimeScore(
      sampleECGData,
      demoProfile,
      [], // No history for demo
      demoUser,
      currentTime: DateTime.now(),
      stressLevel: 0.3,
      activityLevel: 0.6,
    );
    
    setState(() {});
  }

  List<double> _generateRealisticECG() {
    final ecgData = <double>[];
    final random = math.Random();
    
    // Generate 1000 points simulating ECG waveform
    for (int i = 0; i < 1000; i++) {
      double value = 0.0;
      
      // P wave
      if (i % 125 >= 10 && i % 125 <= 25) {
        value += 0.2 * math.sin((i % 125 - 10) * math.pi / 15);
      }
      
      // QRS complex
      if (i % 125 >= 35 && i % 125 <= 50) {
        if (i % 125 >= 40 && i % 125 <= 45) {
          value += 2.0 * math.sin((i % 125 - 40) * math.pi / 5);
        } else {
          value -= 0.5 * math.sin((i % 125 - 35) * math.pi / 15);
        }
      }
      
      // T wave
      if (i % 125 >= 65 && i % 125 <= 90) {
        value += 0.4 * math.sin((i % 125 - 65) * math.pi / 25);
      }
      
      // Add realistic noise
      value += (random.nextDouble() - 0.5) * 0.05;
      
      ecgData.add(value);
    }
    
    return ecgData;
  }

  @override
  Widget build(BuildContext context) {
    if (_demoHealthMetrics == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '🚀 REVOLUTIONARY HEALTH DEMO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main demo card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(_demoHealthMetrics!.healthColor).withOpacity(0.4),
                    Colors.black,
                  ],
                  center: Alignment.center,
                  radius: 1.0,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Color(_demoHealthMetrics!.healthColor),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(_demoHealthMetrics!.healthColor).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Animated health emoji
                  AnimatedBuilder(
                    animation: _demoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_demoController.value * 0.2),
                        child: Text(
                          _demoHealthMetrics!.healthEmoji,
                          style: TextStyle(
                            fontSize: 80,
                            shadows: [
                              Shadow(
                                color: Color(_demoHealthMetrics!.healthColor),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Health score
                  Text(
                    '${_demoHealthMetrics!.overallScore.toInt()}',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Color(_demoHealthMetrics!.healthColor),
                      shadows: [
                        Shadow(
                          color: Color(_demoHealthMetrics!.healthColor),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  
                  Text(
                    _demoHealthMetrics!.healthStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(_demoHealthMetrics!.healthColor),
                      letterSpacing: 3,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  const Text(
                    'REAL-TIME CARDIAC HEALTH SCORE',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Component breakdown
            Text(
              '📊 COMPONENT BREAKDOWN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildDemoScoreCard('❤️ CARDIAC HEALTH', _demoHealthMetrics!.cardiacHealth),
            const SizedBox(height: 15),
            _buildDemoScoreCard('⚡ RHYTHM STABILITY', _demoHealthMetrics!.rhythmStability),
            const SizedBox(height: 15),
            _buildDemoScoreCard('📡 SIGNAL QUALITY', _demoHealthMetrics!.signalQuality),
            const SizedBox(height: 15),
            _buildDemoScoreCard('📈 TREND ANALYSIS', _demoHealthMetrics!.trendScore),
            
            const SizedBox(height: 30),
            
            // AI Insights
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.3),
                    Colors.blue.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🤖', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 10),
                      Text(
                        'AI HEALTH INSIGHTS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ..._demoHealthMetrics!.insights.map((insight) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Text(
                      insight,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Revolutionary features list
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚀 REVOLUTIONARY FEATURES',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...[
                    '✨ Real-time ML-based health scoring',
                    '🧠 Adaptive signal processing with personal learning',
                    '📊 Multi-component health analysis',
                    '🤖 AI-powered health insights',
                    '⚡ Sub-second health status updates',
                    '🎯 Personalized baseline comparisons',
                    '📈 Predictive trend analysis',
                    '🔥 Patent-worthy innovation',
                  ].map((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Demo regeneration button
            ElevatedButton.icon(
              onPressed: _generateDemoData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'GENERATE NEW DEMO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(_demoHealthMetrics!.healthColor),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoScoreCard(String title, double score) {
    final color = _getScoreColor(score);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1500),
                      height: 10,
                      width: (score / 100) * 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.6), color],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: color,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${score.toInt()}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return const Color(0xFF00C853);
    if (score >= 80) return const Color(0xFF66BB6A);
    if (score >= 70) return const Color(0xFFFFB74D);
    if (score >= 60) return const Color(0xFFFF7043);
    return const Color(0xFFE53935);
  }
}

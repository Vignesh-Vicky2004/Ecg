import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/continuous_health_scorer.dart';
import '../services/adaptive_signal_processor.dart';
import '../models/user_profile.dart';
import '../models/ecg_session.dart';
import '../services/firebase_service.dart';
import '../core/utils/utils.dart';
import 'package:fl_chart/fl_chart.dart';

/// Revolutionary Real-Time Health Dashboard
/// This displays the most stunning health visualization that even Apple can't compete with
class RealTimeHealthDashboard extends StatefulWidget {
  final List<double> liveECGData;
  final PersonalSignalProfile personalProfile;
  final UserProfile userProfile;
  
  const RealTimeHealthDashboard({
    Key? key,
    required this.liveECGData,
    required this.personalProfile,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<RealTimeHealthDashboard> createState() => _RealTimeHealthDashboardState();
}

class _RealTimeHealthDashboardState extends State<RealTimeHealthDashboard>
    with TickerProviderStateMixin {
  
  Timer? _updateTimer;
  HealthMetrics? _currentHealthMetrics;
  List<HealthMetrics> _healthHistory = [];
  List<ECGSession> _recentSessions = [];
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _scoreController;
  late AnimationController _ringController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    _loadRecentSessions();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    _scoreController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _loadRecentSessions() async {
    try {
      // Fix: Use userProfile.uid instead of email to fetch sessions
      final sessions = await FirebaseService.getUserECGSessions(widget.userProfile.uid);
      _recentSessions = sessions.map((data) => ECGSession.fromFirestore(data)).toList();
      if (mounted) setState(() {});
    } catch (e) {
      LoggerService.error('Error loading recent sessions', e);
    }
  }

  void _startRealTimeUpdates() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (widget.liveECGData.isNotEmpty) {
        final healthMetrics = ContinuousHealthScorer.calculateRealTimeScore(
          widget.liveECGData,
          widget.personalProfile,
          _recentSessions,
          widget.userProfile,
        );
        
        setState(() {
          _currentHealthMetrics = healthMetrics;
          _healthHistory.add(healthMetrics);
          
          // Keep only last 100 readings for performance
          if (_healthHistory.length > 100) {
            _healthHistory.removeAt(0);
          }
        });
        
        // Trigger score animation when score changes significantly
        if (_healthHistory.length > 1) {
          final scoreDiff = (_currentHealthMetrics!.overallScore - 
                           _healthHistory[_healthHistory.length - 2].overallScore).abs();
          if (scoreDiff > 5) {
            _scoreController.reset();
            _scoreController.forward();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentHealthMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar with stunning gradient
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(_currentHealthMetrics!.healthColor).withOpacity(0.8),
                      Color(_currentHealthMetrics!.healthColor).withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const FlexibleSpaceBar(
                  title: Text(
                    '⚡ LIVE HEALTH',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
            ),
            
            // Main health score display
            SliverToBoxAdapter(
              child: _buildMainHealthScore(),
            ),
            
            // Component scores
            SliverToBoxAdapter(
              child: _buildComponentScores(),
            ),
            
            // Real-time health chart
            SliverToBoxAdapter(
              child: _buildHealthChart(),
            ),
            
            // AI Insights
            SliverToBoxAdapter(
              child: _buildAIInsights(),
            ),
            
            // Health rings visualization
            SliverToBoxAdapter(
              child: _buildHealthRings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainHealthScore() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color(_currentHealthMetrics!.healthColor).withOpacity(0.3),
            Colors.black,
          ],
          center: Alignment.center,
          radius: 1.0,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Color(_currentHealthMetrics!.healthColor),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(_currentHealthMetrics!.healthColor).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated pulsing heart
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Text(
                  _currentHealthMetrics!.healthEmoji,
                  style: TextStyle(
                    fontSize: 60,
                    shadows: [
                      Shadow(
                        color: Color(_currentHealthMetrics!.healthColor),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Animated health score
          AnimatedBuilder(
            animation: _scoreController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Color(_currentHealthMetrics!.healthColor),
                    Colors.white,
                    Color(_currentHealthMetrics!.healthColor),
                  ],
                  stops: [0.0, _scoreController.value, 1.0],
                ).createShader(bounds),
                child: Text(
                  '${_currentHealthMetrics!.overallScore.toInt()}',
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          Text(
            _currentHealthMetrics!.healthStatus.toUpperCase(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(_currentHealthMetrics!.healthColor),
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 10),
          
          Text(
            'CARDIAC HEALTH SCORE',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentScores() {
    final metrics = _currentHealthMetrics!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildScoreCard('CARDIAC', metrics.cardiacHealth, '❤️'),
          const SizedBox(height: 15),
          _buildScoreCard('RHYTHM', metrics.rhythmStability, '⚡'),
          const SizedBox(height: 15),
          _buildScoreCard('SIGNAL', metrics.signalQuality, '📡'),
          const SizedBox(height: 15),
          _buildScoreCard('TREND', metrics.trendScore, '📈'),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, double score, String emoji) {
    final color = _getScoreColor(score);
    
    return Container(
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
          Text(
            emoji,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(width: 20),
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
                const SizedBox(height: 5),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      height: 8,
                      width: (score / 100) * 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.6), color],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: color,
                            blurRadius: 8,
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
            '${score.toInt()}',
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

  Widget _buildHealthChart() {
    if (_healthHistory.length < 2) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(20),
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
            '⚡ REAL-TIME HEALTH TREND',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: _healthHistory.length.toDouble() - 1,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _healthHistory.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.overallScore);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Color(_currentHealthMetrics!.healthColor).withOpacity(0.3),
                        Color(_currentHealthMetrics!.healthColor),
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Color(_currentHealthMetrics!.healthColor).withOpacity(0.3),
                          Color(_currentHealthMetrics!.healthColor).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      margin: const EdgeInsets.all(20),
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
              Text(
                '🤖',
                style: TextStyle(fontSize: 24),
              ),
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
          ..._currentHealthMetrics!.insights.map((insight) => Container(
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
    );
  }

  Widget _buildHealthRings() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            '⭕ HEALTH RINGS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: HealthRingsPainter(
                  cardiacHealth: _currentHealthMetrics!.cardiacHealth,
                  rhythmStability: _currentHealthMetrics!.rhythmStability,
                  signalQuality: _currentHealthMetrics!.signalQuality,
                  animationValue: _ringController.value,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RingLegend(color: Colors.red, label: 'CARDIAC'),
              _RingLegend(color: Colors.blue, label: 'RHYTHM'),
              _RingLegend(color: Colors.green, label: 'SIGNAL'),
            ],
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

class _RingLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _RingLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class HealthRingsPainter extends CustomPainter {
  final double cardiacHealth;
  final double rhythmStability;
  final double signalQuality;
  final double animationValue;

  HealthRingsPainter({
    required this.cardiacHealth,
    required this.rhythmStability,
    required this.signalQuality,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw rings
    _drawRing(canvas, center, radius - 30, cardiacHealth, Colors.red, animationValue);
    _drawRing(canvas, center, radius - 20, rhythmStability, Colors.blue, animationValue);
    _drawRing(canvas, center, radius - 10, signalQuality, Colors.green, animationValue);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double score, Color color, double animation) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Background ring
    canvas.drawCircle(center, radius, paint);

    // Foreground ring
    paint.color = color;
    paint.shader = SweepGradient(
      colors: [color.withOpacity(0.3), color, color.withOpacity(0.3)],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(animation * 2 * math.pi),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final sweepAngle = (score / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

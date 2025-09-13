import 'package:flutter/material.dart';
import '../services/predictive_cardiac_detector.dart';

/// Revolutionary Predictive Cardiac Risk Dashboard
/// Displays advanced cardiac event predictions with stunning visuals
class PredictiveRiskDashboard extends StatefulWidget {
  final CardiacPrediction prediction;
  final VoidCallback? onEmergencyAction;
  final VoidCallback? onViewDetails;
  
  const PredictiveRiskDashboard({
    Key? key,
    required this.prediction,
    this.onEmergencyAction,
    this.onViewDetails,
  }) : super(key: key);

  @override
  State<PredictiveRiskDashboard> createState() => _PredictiveRiskDashboardState();
}

class _PredictiveRiskDashboardState extends State<PredictiveRiskDashboard>
    with TickerProviderStateMixin {
  late AnimationController _riskController;
  late AnimationController _pulseController;
  late AnimationController _emergencyController;
  late Animation<double> _riskAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _emergencyAnimation;

  @override
  void initState() {
    super.initState();
    
    _riskController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _emergencyController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _riskAnimation = Tween<double>(
      begin: 0.0,
      end: widget.prediction.riskScore / 100,
    ).animate(CurvedAnimation(
      parent: _riskController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _emergencyAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _emergencyController,
      curve: Curves.bounceInOut,
    ));
    
    _startAnimations();
  }
  
  void _startAnimations() {
    _riskController.forward();
    
    if (widget.prediction.riskLevel.index >= RiskLevel.moderate.index) {
      _pulseController.repeat(reverse: true);
    }
    
    if (widget.prediction.riskLevel == RiskLevel.critical) {
      _emergencyController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _riskController.dispose();
    _pulseController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(widget.prediction.riskColor).withOpacity(0.1),
            Color(widget.prediction.riskColor).withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(widget.prediction.riskColor).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRiskIndicator(),
            const SizedBox(height: 24),
            _buildPredictionDetails(),
            const SizedBox(height: 20),
            _buildRecommendations(),
            if (widget.prediction.riskLevel.index >= RiskLevel.high.index)
              _buildEmergencySection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(widget.prediction.riskColor),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(widget.prediction.riskColor).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Predictive Cardiac Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                'AI-Powered Risk Assessment',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(widget.prediction.riskColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(widget.prediction.riskColor).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.prediction.riskEmoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.prediction.confidence.toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(widget.prediction.riskColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRiskIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Risk Level: ${widget.prediction.riskLevel.name.toUpperCase()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.prediction.riskColor),
                ),
              ),
              Text(
                '${widget.prediction.riskScore.toInt()}/100',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.prediction.riskColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _riskAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 20),
                painter: RiskBarPainter(
                  progress: _riskAnimation.value,
                  riskColor: Color(widget.prediction.riskColor),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            widget.prediction.urgencyMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPredictionDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prediction Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Event Type', _formatEventType(widget.prediction.eventType)),
          _buildDetailRow('Time Window', _formatTimeWindow(widget.prediction.timeWindow)),
          _buildDetailRow('Confidence', '${widget.prediction.confidence.toInt()}%'),
          _buildDetailRow('Analysis Time', _formatDateTime(widget.prediction.predictionTime)),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.prediction.recommendations.map((recommendation) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                recommendation,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmergencySection() {
    return AnimatedBuilder(
      animation: _emergencyAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _emergencyAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[600]!, Colors.red[700]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Emergency Action Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onEmergencyAction,
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Emergency'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onViewDetails,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatEventType(EventType eventType) {
    switch (eventType) {
      case EventType.arrhythmia:
        return 'Arrhythmia';
      case EventType.tachycardia:
        return 'Tachycardia';
      case EventType.bradycardia:
        return 'Bradycardia';
      case EventType.atrialFibrillation:
        return 'Atrial Fibrillation';
      case EventType.ventricularArrhythmia:
        return 'Ventricular Arrhythmia';
      case EventType.heartBlock:
        return 'Heart Block';
      case EventType.ischemicEvent:
        return 'Ischemic Event';
      case EventType.generalCardiacStress:
        return 'General Cardiac Stress';
    }
  }
  
  String _formatTimeWindow(Duration timeWindow) {
    if (timeWindow.inDays > 0) {
      return '${timeWindow.inDays} days';
    } else if (timeWindow.inHours > 0) {
      return '${timeWindow.inHours} hours';
    } else {
      return '${timeWindow.inMinutes} minutes';
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for risk level visualization
class RiskBarPainter extends CustomPainter {
  final double progress;
  final Color riskColor;
  
  RiskBarPainter({
    required this.progress,
    required this.riskColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    
    final Paint progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          riskColor.withOpacity(0.6),
          riskColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    // Draw background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(10),
      ),
      backgroundPaint,
    );
    
    // Draw progress
    if (progress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width * progress, size.height),
          const Radius.circular(10),
        ),
        progressPaint,
      );
    }
    
    // Add risk level markers
    final markerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    
    for (int i = 1; i < 5; i++) {
      final x = size.width * (i * 0.2);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        markerPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

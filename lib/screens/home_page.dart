import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/config_service.dart';
import '../features/localization/presentation/bloc/localization_bloc.dart';
import '../features/localization/presentation/bloc/localization_state.dart';
import '../widgets/revolutionary_health_demo.dart';
import 'dart:convert';
import 'dart:async';

class HomePage extends StatefulWidget {
  final String userName;
  final Function(String) onNavigate;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.userName,
    required this.onNavigate,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  String _healthTip = "";
  bool _isLoadingTip = false;
  
  // Real Bluetooth state
  String _bluetoothDeviceName = "";
  String _bluetoothStatus = "";
  Timer? _bluetoothCheckTimer;

  // Bluetooth connection state
  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  
  // Track if widget is disposed to prevent setState calls
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true; // Preserve state during rebuilds

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Delay initialization to ensure widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _getNewHealthTip();
        _checkBluetoothStatus();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _bluetoothCheckTimer?.cancel();
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Pause timers when app is not active to prevent lifecycle issues
    if (state != AppLifecycleState.resumed) {
      _bluetoothCheckTimer?.cancel();
    } else if (mounted && !_isDisposed) {
      // Resume when app becomes active
      _checkBluetoothStatus();
    }
  }

  void _checkBluetoothStatus() {
    // Get localization bloc for strings
    final localizationBloc = context.read<LocalizationBloc>();
    
    // Cancel existing timer to prevent multiple timers
    _bluetoothCheckTimer?.cancel();
    
    // Check connected devices periodically
    _bluetoothCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final devices = FlutterBluePlus.connectedDevices;
        bool hasECGDevice = false;
        String deviceName = localizationBloc.getString('no_device');
        
        for (var device in devices) {
          String name = device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString();
          if (name.toLowerCase().contains('b869h') ||
              name.toLowerCase().contains('v5.0') ||
              name.toLowerCase().contains('hm-10') ||
              name.toLowerCase().contains('hm10') ||
              name.toLowerCase().contains('ecg') ||
              name.toLowerCase().contains('heart')) {
            hasECGDevice = true;
            deviceName = name;
            break;
          }
        }
        
        // Only update state if still mounted and values have changed
        if (mounted && !_isDisposed) {
          final newDeviceName = hasECGDevice ? deviceName : localizationBloc.getString('no_device');
          final newStatus = hasECGDevice ? localizationBloc.getString('connected') : localizationBloc.getString('disconnected');
          
          if (_bluetoothDeviceName != newDeviceName || _bluetoothStatus != newStatus) {
            setState(() {
              _bluetoothDeviceName = newDeviceName;
              _bluetoothStatus = newStatus;
            });
          }
        }
      } catch (e) {
        // Handle any Bluetooth errors gracefully
        print('Bluetooth check error: $e');
        if (mounted && !_isDisposed) {
          setState(() {
            _bluetoothDeviceName = localizationBloc.getString('no_device');
            _bluetoothStatus = localizationBloc.getString('disconnected');
          });
        }
      }
    });
  }

  Future<void> _getNewHealthTip() async {
    if (!mounted || _isDisposed) return;
    
    setState(() {
      _isLoadingTip = true;
    });

    try {
      final localizationBloc = context.read<LocalizationBloc>();
      final localizationState = localizationBloc.state;
      
      // Get current language for AI response
      final currentLanguage = localizationState is LocalizationLoaded 
          ? localizationState.currentLanguage 
          : 'en';
      
      final languageMap = {
        'en': 'English',
        'hi': 'Hindi (हिंदी)',
        'ta': 'Tamil (தமிழ்)',
        'te': 'Telugu (తెలుగు)',
        'ml': 'Malayalam (മലയാളം)',
        'kn': 'Kannada (ಕನ್ನಡ)',
        'bn': 'Bengali (বাংলা)',
        'gu': 'Gujarati (ગુજરાતી)',
        'mr': 'Marathi (मराठी)',
        'pa': 'Punjabi (ਪੰਜਾਬੀ)',
      };
      final responseLanguage = languageMap[currentLanguage] ?? 'English';
      
      final healthTipPrompt = '''
${localizationBloc.getString('health_tip_ai_prompt')}

IMPORTANT: Respond completely in $responseLanguage language. Provide a practical, actionable health tip for maintaining good cardiovascular health. Keep it concise (2-3 sentences) and easy to understand.
''';

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': healthTipPrompt}
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse(ConfigService.geminiApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final text = result['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && mounted && !_isDisposed) {
          setState(() {
            _healthTip = text;
          });
        }
      }
    } catch (error) {
      print("Error fetching health tip: $error");
      if (mounted && !_isDisposed) {
        final localizationBloc = context.read<LocalizationBloc>();
        setState(() {
          _healthTip = localizationBloc.getString('could_not_load_tip');
        });
      }
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _isLoadingTip = false;
      });
    }
  }

  /// Show the revolutionary health demo
  void _showRevolutionaryDemo() {
    if (!mounted || _isDisposed) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RevolutionaryHealthDemo(),
        fullscreenDialog: true,
      ),
    );
  }

  /// Show predictive cardiac analysis information
  void _showPredictiveAnalysisInfo() {
    if (!mounted || _isDisposed) return;
    
    final localizationBloc = context.read<LocalizationBloc>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Color(0xFF667EEA), size: 28),
            const SizedBox(width: 8),
            Text(localizationBloc.getString('predictive_cardiac_ai')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🧠 ${localizationBloc.getString('revolutionary_ai_technology')}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${localizationBloc.getString('our_predictive_ai_can')}\n\n'
                '🔮 ${localizationBloc.getString('predict_cardiac_events')}\n'
                '📊 ${localizationBloc.getString('analyze_patterns')}\n'
                '⚠️ ${localizationBloc.getString('early_warning_alerts')}\n'
                '💡 ${localizationBloc.getString('personalized_recommendations')}\n'
                '🎯 ${localizationBloc.getString('risk_scores')}\n'
                '🚨 ${localizationBloc.getString('detect_critical_conditions')}',
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ ${localizationBloc.getString('patent_pending_technology')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizationBloc.getString('advanced_ml_algorithms'),
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizationBloc.getString('close')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNavigate('record'); // Go to record page to generate data
            },
            icon: const Icon(Icons.favorite),
            label: Text(localizationBloc.getString('try_now')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        final localizationBloc = context.read<LocalizationBloc>();
        final theme = Theme.of(context);
        
        // Get current language from state
        final currentLanguage = localizationState is LocalizationLoaded 
            ? localizationState.currentLanguage 
            : 'en';
        
        // Force rebuild when language changes by using language as key
        return Column(
          key: ValueKey('home_page_$currentLanguage'),
          children: [
            // Header with premium gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Top header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizationBloc.getString('welcome_to_cardiart'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${localizationBloc.getString('hello')} ${widget.userName}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.bell,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content area with rounded corners
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                transform: Matrix4.translationValues(0, -24, 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // User & Device Info
                        _buildUserInfo(localizationBloc),
                        const SizedBox(height: 16),
                        _buildDeviceInfo(localizationBloc),
                        const SizedBox(height: 32),
                        
                        // Health Overview
                        _buildHealthOverview(localizationBloc),
                        const SizedBox(height: 24),
                        
                        // Quick Actions
                        _buildQuickActions(localizationBloc),
                        const SizedBox(height: 24),
                        
                        // Health Tip
                        _buildHealthTip(localizationBloc),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfo(LocalizationBloc localizationBloc) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  widget.userName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SN ${localizationBloc.getString('sn_number')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(LocalizationBloc localizationBloc) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _bluetoothStatus == localizationBloc.getString('connected') 
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.outline.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.bluetooth,
                      color: _bluetoothStatus == localizationBloc.getString('connected') 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bluetoothDeviceName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _bluetoothStatus,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _bluetoothStatus == localizationBloc.getString('connected') 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _bluetoothStatus == localizationBloc.getString('connected') 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _bluetoothStatus == localizationBloc.getString('connected') ? LucideIcons.check : LucideIcons.bluetooth,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildHealthOverview(LocalizationBloc localizationBloc) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizationBloc.getString('health_overview'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      '85',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Text(
                      localizationBloc.getString('avg_bpm_label'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      localizationBloc.getString('normal'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      localizationBloc.getString('last_reading_label'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => widget.onNavigate('history'),
            child: Center(
              child: Text(
                localizationBloc.getString('view_details'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(LocalizationBloc localizationBloc) {
    return Column(
      children: [
        // First row - existing actions
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onNavigate('record'),
                child: Container(
                  height: 112,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.heartPulse,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizationBloc.getString('start_recording'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onNavigate('ai-insights'),
                child: Container(
                  height: 112,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.brainCircuit,
                        color: Color(0xFF2563EB),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizationBloc.getString('ai_analysis'),
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Second row - Revolutionary Health Demo
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _showRevolutionaryDemo,
          child: Container(
            width: double.infinity,
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B6B),
                  Color(0xFF4ECDC4),
                  Color(0xFF45B7D1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ECDC4).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.rocket,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: const Text(
                    '🚀 REVOLUTIONARY HEALTH DEMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '✨',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
        
        // Third row - NEW! Predictive Cardiac Analysis
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _showPredictiveAnalysisInfo,
          child: Container(
            width: double.infinity,
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                  Color(0xFF6B73FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: const Text(
                    '🧠 PREDICTIVE CARDIAC AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '🔮',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTip(LocalizationBloc localizationBloc) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [
            const Color(0xFF1E3A8A).withOpacity(0.1),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ] : [
            const Color(0xFF3B82F6).withOpacity(0.05),
            const Color(0xFF1E3A8A).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.lightbulb,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '✨ ${localizationBloc.getString('health_tip')}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _getNewHealthTip,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.refreshCw,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _isLoadingTip 
                  ? Row(
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Getting a new tip...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _healthTip.isNotEmpty ? _healthTip : localizationBloc.getString('staying_hydrated_tip'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
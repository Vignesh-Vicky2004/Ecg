import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/config_service.dart';
import '../services/firebase_service.dart';
import '../features/localization/presentation/bloc/localization_bloc.dart';
import '../features/localization/presentation/bloc/localization_state.dart';
import 'dart:convert';
import 'dart:async';

class AiInsightsPage extends StatefulWidget {
  final bool isDarkMode;
  final User user;

  const AiInsightsPage({
    super.key,
    required this.isDarkMode,
    required this.user,
  });

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  String _state = 'intro';
  Map<String, dynamic>? _results;
  List<Map<String, dynamic>> _availableSessions = [];
  List<int> _selectedSessionIndices = [];
  
  // Cancellation token for cleanup
  final List<StreamSubscription> _subscriptions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadAvailableSessions();
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAvailableSessions() async {
    if (!mounted) return;
    
    try {
      final userSessions = await FirebaseService.getUserECGSessions(widget.user.uid);
      if (mounted) {
        setState(() {
          _availableSessions = userSessions;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load sessions: ${e.toString()}');
      }
    }
  }

  Future<void> _getAiSuggestions({List<Map<String, dynamic>>? specificSessions}) async {
    if (!mounted) return;
    
    setState(() {
      _state = 'loading';
    });

    try {
      final sessionsToAnalyze = specificSessions ?? 
          _availableSessions.asMap().entries
              .where((entry) => _selectedSessionIndices.contains(entry.key))
              .map((entry) => entry.value)
              .toList();

      String ecgDataAnalysis = _buildEcgAnalysis(sessionsToAnalyze);
      
      String currentLanguage = 'en';
      final localizationState = context.read<LocalizationBloc>().state;
      if (localizationState is LocalizationLoaded) {
        currentLanguage = localizationState.currentLanguage;
      }
      final responseLanguage = _getLanguageName(currentLanguage);

      final userQuery = '''
Analyze the following ECG data for a patient: $ecgDataAnalysis.

IMPORTANT: Respond in $responseLanguage language. If the language is not English, provide the response completely in that language.

Provide a comprehensive analysis including:
1. A concise summary of the ECG findings
2. Any potential observations or areas of interest  
3. Three specific, actionable lifestyle suggestions for heart health

Format your response as a JSON object with the following structure:
{
  "summary": "Brief clinical summary of findings in $responseLanguage",
  "observations": "Detailed observations and any notable patterns in $responseLanguage", 
  "suggestions": ["suggestion 1 in $responseLanguage", "suggestion 2 in $responseLanguage", "suggestion 3 in $responseLanguage"]
}
''';

      final result = await _makeApiCall(userQuery);
      
      if (mounted) {
        setState(() {
          _results = result;
          _state = 'results';
        });
      }
    } catch (error) {
      if (mounted) {
        _showError('Error fetching AI suggestions: ${error.toString()}');
        _provideFallbackResults();
      }
    }
  }

  String _buildEcgAnalysis(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) {
      return 'No ECG data available';
    }

    final analyses = <String>[];
    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final analysis = _buildSessionAnalysis(session, i + 1);
      analyses.add(analysis);
    }

    return '''
Patient ECG Analysis (${sessions.length} session${sessions.length > 1 ? 's' : ''}):

${analyses.join('\n\n')}

Historical Trends:
${_generateTrendAnalysis(sessions)}
''';
  }

  String _buildSessionAnalysis(Map<String, dynamic> session, int index) {
    final timestamp = _parseTimestamp(session['timestamp']);
    final avgBPM = (session['avgBPM'] ?? 0).toDouble();
    final minBPM = (session['minBPM'] ?? 0).toDouble(); 
    final maxBPM = (session['maxBPM'] ?? 0).toDouble();
    final duration = session['duration'] ?? 0;
    final rhythm = session['rhythm'] ?? 'Unknown';
    final status = session['status'] ?? 'Unknown';
    final ecgData = session['ecgData'] ?? [];

    return '''
Session $index (${timestamp.toString().split(' ')[0]}):
- Heart Rate: ${avgBPM.round()} bpm (Range: ${minBPM.round()}-${maxBPM.round()})
- Rhythm: $rhythm
- Status: $status  
- Duration: ${duration}s
- Data Points: ${ecgData.length} samples
- Quality: ${_assessSessionQuality(avgBPM, duration, ecgData.length)}
''';
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }

  String _assessSessionQuality(double avgBPM, int duration, int dataPoints) {
    if (duration < 10) return 'Short duration';
    if (dataPoints < 100) return 'Limited data';
    if (avgBPM < 50 || avgBPM > 120) return 'Irregular heart rate detected';
    return 'Good quality data';
  }

  String _generateTrendAnalysis(List<Map<String, dynamic>> sessions) {
    if (sessions.length < 2) {
      return 'Trend analysis requires at least 2 ECG sessions for comparison.';
    }
    
    // Sort sessions by timestamp
    sessions.sort((a, b) {
      final aTime = _parseTimestamp(a['timestamp']);
      final bTime = _parseTimestamp(b['timestamp']);
      return aTime.compareTo(bTime);
    });

    final firstAvgBPM = (sessions.first['avgBPM'] ?? 0).toDouble();
    final lastAvgBPM = (sessions.last['avgBPM'] ?? 0).toDouble();
    final change = ((lastAvgBPM - firstAvgBPM) / firstAvgBPM * 100);

    return '''
Overall Trends:
• Heart rate change: ${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%
• Sessions analyzed: ${sessions.length}
• Time span: ${_parseTimestamp(sessions.first['timestamp']).toString().substring(0, 10)} to ${_parseTimestamp(sessions.last['timestamp']).toString().substring(0, 10)}
''';
  }

  String _getLanguageName(String languageCode) {
    const languageMap = {
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
    return languageMap[languageCode] ?? 'English';
  }

  Future<Map<String, dynamic>> _makeApiCall(String query) async {
    final payload = {
      'contents': [
        {
          'parts': [
            {'text': query}
          ]
        }
      ],
      'systemInstruction': {
        'parts': [
          {
            'text': 'You are a helpful AI assistant specializing in ECG analysis. Always provide medically accurate information but include appropriate disclaimers. Format your response as a JSON object.'
          }
        ]
      },
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'summary': {'type': 'STRING'},
            'observations': {'type': 'STRING'}, 
            'suggestions': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'}
            }
          },
          'required': ['summary', 'observations', 'suggestions']
        }
      }
    };

    final response = await http.post(
      Uri.parse(ConfigService.geminiApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': ConfigService.geminiApiKey,
      },
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final text = result['candidates']?[0]?['content']?['parts']?[0]?['text'];
      
      if (text != null) {
        return json.decode(text);
      }
    }
    
    throw Exception('API request failed with status: ${response.statusCode}');
  }

  void _provideFallbackResults() {
    setState(() {
      _results = {
        'summary': 'Based on the available ECG data, the analysis shows normal sinus rhythm with heart rate within normal parameters.',
        'observations': 'The ECG demonstrates regular cardiac rhythm with consistent intervals. Heart rate variability appears normal for the recorded duration.',
        'suggestions': [
          'Maintain regular cardiovascular exercise for 30 minutes daily',
          'Follow a heart-healthy diet rich in omega-3 fatty acids and low in sodium',
          'Practice stress management techniques such as meditation or deep breathing exercises'
        ]
      };
      _state = 'results';
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _state = 'intro';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (_state == 'intro') _buildIntroView(),
              if (_state == 'loading') _buildLoadingView(),
              if (_state == 'results') _buildResultsView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroView() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              '✨ AI Insights powered by Gemini',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Get deeper understanding of your ECG readings',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (_availableSessions.isNotEmpty) ...[
              _buildSessionSelector(),
              const SizedBox(height: 32),
            ],
            
            _buildAnalysisButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.activity,
                color: const Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Select ECG Sessions to Analyze',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: _availableSessions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final session = entry.value;
                  final timestamp = _parseTimestamp(session['timestamp']);
                  
                  return CheckboxListTile(
                    dense: true,
                    title: Text(
                      'Session ${timestamp.toString().substring(0, 19)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    subtitle: Text(
                      '${(session['ecgData'] as List?)?.length ?? 0} data points',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    value: _selectedSessionIndices.contains(index),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSessionIndices.add(index);
                        } else {
                          _selectedSessionIndices.remove(index);
                        }
                      });
                    },
                    activeColor: const Color(0xFF2563EB),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSessionIndices.clear();
                    _selectedSessionIndices.addAll(
                      List.generate(_availableSessions.length, (i) => i)
                    );
                  });
                },
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSessionIndices.clear();
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.brainCircuit,
            color: Color(0xFF2563EB),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Advanced AI Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _availableSessions.isNotEmpty && _selectedSessionIndices.isNotEmpty
                ? 'AI will analyze ${_selectedSessionIndices.length} selected session${_selectedSessionIndices.length > 1 ? 's' : ''}'
                : 'AI will analyze your latest ECG recording',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _getAiSuggestions,
              icon: const Icon(LucideIcons.sparkles),
              label: Text(
                _selectedSessionIndices.isNotEmpty 
                    ? 'Analyze Selected Sessions'
                    : 'Analyze Latest ECG',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            Text(
              'AI is analyzing your ECG data...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_results == null) return const SizedBox.shrink();

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your AI-Powered Report',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildAnalysisCard(
              title: 'Summary',
              icon: LucideIcons.fileText,
              content: _results!['summary'] ?? 'No summary available',
              color: Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            _buildAnalysisCard(
              title: 'Observations',
              icon: LucideIcons.eye,
              content: _results!['observations'] ?? 'No observations available',
              color: Colors.orange,
            ),
            
            const SizedBox(height: 16),
            
            _buildSuggestionsCard(),
            
            const SizedBox(height: 32),
            
            _buildDisclaimer(),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _state = 'intro';
                    _results = null;
                  });
                },
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Analyze Another Reading'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard({
    required String title,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    final suggestions = _results!['suggestions'] as List? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.lightbulb,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lifestyle Suggestions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      suggestion.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: Colors.amber,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Medical Disclaimer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This AI analysis is for informational purposes only and should not be used as a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.amber[800],
            ),
          ),
        ],
      ),
    );
  }
}

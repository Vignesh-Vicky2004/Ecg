import 'package:ecg/screens/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/firebase_service.dart';
import '../services/pdf_report_service.dart';
import '../features/localization/presentation/bloc/localization_bloc.dart';
import '../features/localization/presentation/bloc/localization_state.dart';
import '../models/ecg_session.dart';
import '../models/user_profile.dart';
import '../widgets/language_selector.dart';
import 'patient_info_dialog.dart';

class ProfilePage extends StatelessWidget {
  final String userName;
  final String email;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final User? currentUser;
  final String currentLanguage;
  final Function(String) changeLanguage;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.email,
    required this.onLogout,
    required this.isDarkMode,
    required this.toggleTheme,
    this.currentUser,
    required this.currentLanguage,
    required this.changeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        final theme = Theme.of(context);
        
        // Helper function to get translation
        String _getString(String key) {
          if (localizationState is LocalizationLoaded) {
            return localizationState.translations[key] ?? key;
          }
          return key;
        }
        
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Profile section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFE6F2FF),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF007BFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // General section
            _buildSectionHeader(_getString('general')),
            const SizedBox(height: 8),
            _buildSettingsGroup([
              _buildSettingsItem(
                icon: LucideIcons.user,
                title: _getString('edit_profile'),
                onTap: () => _navigateToEditProfile(context),
              ),
              _buildSettingsItem(
                icon: LucideIcons.phone,
                title: 'Emergency Contact',
                onTap: () {
                  // TODO: Implement emergency contact
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency Contact coming soon!')),
                  );
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Appearance section
            _buildSectionHeader(_getString('appearance')),
            const SizedBox(height: 8),
            _buildSettingsGroup([
              _buildThemeToggle(),
            ]),
            
            const SizedBox(height: 24),
            
            // Language section
            _buildSectionHeader(_getString('language')),
            const SizedBox(height: 8),
            LanguageSelector(
              currentLanguage: currentLanguage,
              onLanguageChanged: changeLanguage,
            ),
            
            const SizedBox(height: 24),
            
            // Data section
            _buildSectionHeader(_getString('data')),
            const SizedBox(height: 8),
            _buildSettingsGroup([
              _buildSettingsItem(
                icon: LucideIcons.download,
                title: _getString('export_ecg_history'),
                onTap: () => _exportECGHistory(context),
              ),
            ]),
            
            const SizedBox(height: 32),
            
            // Logout button
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onLogout();
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Center(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            trailing ??
                Icon(
                  LucideIcons.chevronRight,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            LucideIcons.moon,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dark Mode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Add a small delay to ensure smooth animation
              Future.delayed(const Duration(milliseconds: 100), () {
                toggleTheme();
              });
            },
            child: Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2563EB) : Colors.grey[300],
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportECGHistory(BuildContext context) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your profile and ECG sessions...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Get user profile data first
      final userProfile = await FirebaseService.getUserProfileData(currentUser!.uid);
      
      if (userProfile == null || !userProfile.isProfileComplete) {
        Navigator.of(context).pop(); // Close loading dialog
        _showIncompleteProfileDialog(context);
        return;
      }

      // Get all ECG sessions for the user
      final sessionMaps = await FirebaseService.getECGSessions(currentUser!.uid);
      final sessions = sessionMaps.map((data) {
        return ECGSession.fromFirestore(data);
      }).toList();

      Navigator.of(context).pop(); // Close loading dialog

      if (sessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No ECG sessions found to export')),
        );
        return;
      }

      // Show confirmation dialog with user profile info
      _showExportConfirmationDialog(context, userProfile, sessions);

    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, 'Failed to load data: $e');
      }
    }
  }

  void _showIncompleteProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350), // Add max width constraint
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please complete your profile with name, age, height, weight, and gender to generate professional reports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(isDarkMode: isDarkMode),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportConfirmationDialog(BuildContext context, UserProfile userProfile, List<ECGSession> sessions) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400), // Add max width constraint
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.fileText,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded( // Wrap title text in Expanded
                    child: Text(
                      'Generate Professional Reports',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Name: ${userProfile.name}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Age: ${userProfile.age} years',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Gender: ${userProfile.gender}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Height: ${userProfile.height} cm',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Weight: ${userProfile.weight} kg',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will generate ${sessions.length} professional ECG report${sessions.length > 1 ? 's' : ''} using your profile information.',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  // First row with Cancel and Generate buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _generateReportsWithProfile(context, userProfile, sessions);
                          },
                          icon: const Icon(LucideIcons.download, size: 16),
                          label: const Text('Generate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Second row with Custom Info button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showManualPatientInfoDialog(context, sessions);
                      },
                      icon: const Icon(LucideIcons.edit, size: 14),
                      label: const Text('Use Custom Patient Info'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateReportsWithProfile(BuildContext context, UserProfile userProfile, List<ECGSession> sessions) async {
    _showGeneratingDialog(context);

    try {
      // Generate reports for all sessions using profile data
      final List<dynamic> reportFiles = [];
      
      for (int i = 0; i < sessions.length; i++) {
        final session = sessions[i];
        final reportId = 'ECG_${DateTime.now().millisecondsSinceEpoch}_${i + 1}';
        
        final pdfFile = await PDFReportService.generateECGReport(
          session: session,
          patientName: userProfile.name ?? 'Unknown',
          patientAge: userProfile.ageString ?? 'Unknown',
          patientGender: userProfile.gender ?? 'Unknown',
          patientHeight: userProfile.heightString ?? 'Unknown',
          patientWeight: userProfile.weightString ?? 'Unknown',
          reportId: reportId,
        );
        
        reportFiles.add(pdfFile);
      }

      // Check if context is still valid before using Navigator
      if (context.mounted) {
        Navigator.of(context).pop(); // Close generating dialog
        _showExportSuccessDialog(context, reportFiles, userProfile.name ?? 'Unknown', sessions.length);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close generating dialog
        _showErrorDialog(context, 'Failed to generate reports: $e');
      }
    }
  }

  void _showManualPatientInfoDialog(BuildContext context, List<ECGSession> sessions) {
    // Show the original patient info dialog for custom patient information
    showDialog(
      context: context,
      builder: (context) => PatientInfoDialog(
        isDarkMode: isDarkMode,
        onSubmit: (patientInfo) async {
          _showGeneratingDialog(context);

          try {
            // Generate reports for all sessions with custom patient info
            final List<dynamic> reportFiles = [];
            
            for (int i = 0; i < sessions.length; i++) {
              final session = sessions[i];
              final reportId = 'ECG_${DateTime.now().millisecondsSinceEpoch}_${i + 1}';
              
              final pdfFile = await PDFReportService.generateECGReport(
                session: session,
                patientName: patientInfo['name']!,
                patientAge: patientInfo['age']!,
                patientGender: patientInfo['gender']!,
                patientHeight: patientInfo['height']!,
                patientWeight: patientInfo['weight']!,
                reportId: reportId,
              );
              
              reportFiles.add(pdfFile);
            }

            // Check if context is still valid before using Navigator
            if (context.mounted) {
              Navigator.of(context).pop(); // Close generating dialog
              _showExportSuccessDialog(context, reportFiles, patientInfo['name']!, sessions.length);
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop(); // Close generating dialog
              _showErrorDialog(context, 'Failed to generate reports: $e');
            }
          }
        },
      ),
    );
  }

  void _showGeneratingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300), // Add max width constraint
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
              const SizedBox(height: 16),
              Text(
                'Generating Professional Reports...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few moments',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportSuccessDialog(BuildContext context, List<dynamic> reportFiles, String patientName, int sessionCount) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350), // Add max width constraint
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.checkCircle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Export Complete!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generated $sessionCount professional ECG reports for $patientName.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Share all reports
                    for (final file in reportFiles) {
                      await PDFReportService.shareReport(file, patientName);
                    }
                  },
                  icon: const Icon(LucideIcons.share2),
                  label: const Text('Share All Reports'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        title: Text(
          'Error',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(isDarkMode: isDarkMode),
      ),
    );
  }
}

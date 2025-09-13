import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/onboarding_modal.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../core/error/unified_error_handler.dart';
import 'home_page.dart';
import 'record_page.dart';
import 'history_page.dart';
import 'ai_insights_page.dart';
import 'profile_page.dart';

class MainApp extends StatefulWidget {
  final User user;
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final String currentLanguage;
  final Function(String) changeLanguage;

  const MainApp({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.toggleTheme,
    required this.currentLanguage,
    required this.changeLanguage,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  String _currentPage = 'home';

  @override
  bool get wantKeepAlive => true; // This will keep the state alive during rebuilds

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentPage();
    
    // Setup error listener
    ErrorHandler.addListener(_onError);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle app lifecycle changes if needed
  }

  void _loadCurrentPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPage = prefs.getString('current_page') ?? 'home';
      if (mounted) {
        setState(() {
          _currentPage = savedPage;
        });
      }
    } catch (e) {
      ErrorHandler.handleError(e, 
        userMessage: 'Failed to load saved page',
        severity: ErrorSeverity.warning,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ErrorHandler.removeListener(_onError);
    super.dispose();
  }

  void _onError(AppError error) {
    if (mounted && error.severity == ErrorSeverity.critical) {
      ErrorHandler.showErrorSnackBar(context, error);
    }
  }

  void _setPage(String page) async {
    if (!mounted) return;
    
    try {
      setState(() {
        _currentPage = page;
      });
      
      // Save current page to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_page', page);
    } catch (e) {
      ErrorHandler.handleError(e,
        userMessage: 'Failed to save page state',
        severity: ErrorSeverity.warning,
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    } catch (e) {
      ErrorHandler.handleError(e,
        userMessage: 'Failed to sign out',
        severity: ErrorSeverity.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          _buildCurrentPage(),
          const OnboardingModal(),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        activePage: _currentPage,
        onPageChanged: _setPage,
      ),
    );
  }

  Widget _buildCurrentPage() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Get the user name from UserProfile if available, otherwise fallback to Firebase User
        String userName = "User";
        if (authState is AuthAuthenticated && authState.userProfile?.name != null) {
          userName = authState.userProfile!.name!;
        } else {
          userName = widget.user.displayName ?? 
                    widget.user.email?.split('@')[0] ?? 
                    "User";
        }
        
        final pages = {
          'home': HomePage(
            userName: userName,
            onNavigate: _setPage,
            isDarkMode: widget.isDarkMode,
          ),
          'record': RecordPage(
            isDarkMode: widget.isDarkMode,
            user: widget.user,
          ),
          'history': HistoryPage(
            user: widget.user,
          ),
          'ai-insights': AiInsightsPage(
            isDarkMode: widget.isDarkMode,
            user: widget.user,
          ),
          'profile': ProfilePage(
            userName: userName,
            email: widget.user.email ?? '',
            onLogout: _handleLogout,
            isDarkMode: widget.isDarkMode,
            toggleTheme: widget.toggleTheme,
            currentUser: widget.user,
            currentLanguage: widget.currentLanguage,
            changeLanguage: widget.changeLanguage,
          ),
        };

        final pageKeys = pages.keys.toList();
        final currentIndex = pageKeys.indexOf(_currentPage);

        return IndexedStack(
          key: ValueKey('main_indexed_stack_${_currentPage}'), // More specific key
          index: currentIndex >= 0 ? currentIndex : 0, // Ensure valid index
          children: pageKeys.map((pageKey) => 
            Container(
              key: ValueKey('page_container_$pageKey'),
              child: pages[pageKey]!,
            )
          ).toList(),
        );
      },
    );
  }
}

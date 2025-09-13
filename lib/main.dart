import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Core imports
import 'core/app/app_initializer.dart';
import 'core/widgets/error_widgets.dart';
import 'core/utils/utils.dart';

// BLoC imports
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/theme/presentation/bloc/theme_bloc.dart';
import 'features/theme/presentation/bloc/theme_event.dart';
import 'features/theme/presentation/bloc/theme_state.dart';
import 'features/localization/presentation/bloc/localization_bloc.dart';
import 'features/localization/presentation/bloc/localization_event.dart';
import 'features/localization/presentation/bloc/localization_state.dart';
import 'features/ecg/presentation/bloc/ecg_bloc.dart';
import 'features/ecg/presentation/bloc/ecg_event.dart';

// Theme
import 'features/theme/data/app_theme.dart';

// Screens
import 'screens/auth_screen.dart';
import 'screens/main_app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the application
  try {
    await AppInitializer.initialize();
    runApp(const ECGApp());
  } catch (error) {
        LoggerService.error('Failed to initialize app', error);
    runApp(AppInitializationErrorApp(error: error));
  }
}

/// Main application widget with proper BLoC architecture
class ECGApp extends StatelessWidget {
  const ECGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Theme BLoC
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(const ThemeInitialized()),
        ),
        // Localization BLoC
        BlocProvider<LocalizationBloc>(
          create: (context) => LocalizationBloc()..add(const LocalizationInitialized()),
        ),
        // Authentication BLoC
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(const AuthCheckRequested()),
        ),
        // ECG BLoC
        BlocProvider<ECGBloc>(
          create: (context) => ECGBloc()..add(const ECGInitialized()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocalizationBloc, LocalizationState>(
            builder: (context, localizationState) {
              // Determine theme mode
              final themeMode = themeState is ThemeLoaded 
                  ? themeState.themeMode 
                  : ThemeMode.system;

              return MaterialApp(
                title: 'Cardiart',
                debugShowCheckedModeBanner: false,
                
                // Theme configuration
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                
                // Home widget with authentication routing
                home: const AuthenticationRouter(),
                
                // System UI overlay style will be handled by theme
                builder: (context, child) {
                  return child ?? const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Authentication router that determines which screen to show
class AuthenticationRouter extends StatelessWidget {
  const AuthenticationRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle authentication errors
        if (state is AuthError) {
          ErrorSnackBar.show(context, state.failure);
        }
        
        // Handle password reset confirmation
        if (state is AuthPasswordResetSent) {
          ErrorSnackBar.showSuccess(
            context, 
            'Password reset email sent to ${state.email}',
          );
        }
      },
      builder: (context, authState) {
        if (authState is AuthLoading) {
          return const AppLoadingScreen();
        }
        
        if (authState is AuthAuthenticated) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<LocalizationBloc, LocalizationState>(
                builder: (context, localizationState) {
                  final isDarkMode = themeState is ThemeLoaded ? themeState.isDarkMode : false;
                  final currentLanguage = localizationState is LocalizationLoaded 
                      ? localizationState.currentLanguage 
                      : 'en';
                  
                  return MainApp(
                    user: authState.user,
                    isDarkMode: isDarkMode,
                    toggleTheme: () => context.read<ThemeBloc>().add(const ThemeToggled()),
                    currentLanguage: currentLanguage,
                    changeLanguage: (language) => context.read<LocalizationBloc>()
                        .add(LanguageChanged(languageCode: language)),
                  );
                },
              );
            },
          );
        }
        
        if (authState is AuthError) {
          return AppErrorScreen(failure: authState.failure);
        }
        
        // Default to auth screen for unauthenticated users
        return const AuthScreen();
      },
    );
  }
}

/// Loading screen shown during app initialization and auth checks
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            BlocBuilder<LocalizationBloc, LocalizationState>(
              builder: (context, state) {
                final getString = state is LocalizationLoaded 
                    ? state.getString 
                    : (String key) => key;
                
                return Text(
                  getString('loading'),
                  style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
            const SizedBox(height: 8),
            BlocBuilder<LocalizationBloc, LocalizationState>(
              builder: (context, state) {
                final getString = state is LocalizationLoaded 
                    ? state.getString 
                    : (String key) => key;
                
                return Text(
                  getString('app_name'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen for authentication and app-level errors
class AppErrorScreen extends StatelessWidget {
  final dynamic failure;

  const AppErrorScreen({super.key, required this.failure});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ErrorDisplayWidget(
            failure: failure,
            onRetry: () {
              // Retry authentication check
              context.read<AuthBloc>().add(const AuthCheckRequested());
            },
          ),
        ),
      ),
    );
  }
}

/// Minimal error app shown when initialization completely fails
class AppInitializationErrorApp extends StatelessWidget {
  final dynamic error;

  const AppInitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cardiart - Initialization Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to start the application. Please try restarting the app.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // This won't actually restart the app but provides user feedback
                    // In a real app, you might want to exit or provide more recovery options
                  },
                  child: const Text('OK'),
                ),
                if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Error Details'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          error.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
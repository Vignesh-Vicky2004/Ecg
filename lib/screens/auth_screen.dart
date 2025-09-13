import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/localization/presentation/bloc/localization_bloc.dart';
import '../features/localization/presentation/bloc/localization_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedActivityLevel = 'Moderate';
  bool _hasHeartConditions = false;
  final _medicalConditionsController = TextEditingController();
  String _error = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Form validation
    if (!_validateForm()) {
      return;
    }

    if (_isLogin) {
      context.read<AuthBloc>().add(AuthSignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ));
    } else {
      // For now, we'll just use the display name
      // In a real app, you'd save the profile data separately
      context.read<AuthBloc>().add(AuthSignUpRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      ));
    }
  }

  bool _validateForm() {
    final localizationState = context.read<LocalizationBloc>().state;
    String getString(String key) {
      if (localizationState is LocalizationLoaded) {
        return localizationState.getString(key);
      }
      return key;
    }

    // Email validation
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _error = getString('email');
      });
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      setState(() {
        _error = getString('invalid_email');
      });
      return false;
    }

    // Password validation
    if (_passwordController.text.isEmpty) {
      setState(() {
        _error = getString('password');
      });
      return false;
    }

    if (!_isLogin && _passwordController.text.length < 6) {
      setState(() {
        _error = getString('password_too_short');
      });
      return false;
    }

    // Confirm password validation for registration
    if (!_isLogin && _passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = getString('passwords_do_not_match');
      });
      return false;
    }

    // Registration-specific validations
    if (!_isLogin) {
      if (_nameController.text.trim().isEmpty) {
        setState(() {
          _error = 'Please enter your full name.';
        });
        return false;
      }

      if (_ageController.text.trim().isEmpty) {
        setState(() {
          _error = 'Please enter your age.';
        });
        return false;
      }

      final age = int.tryParse(_ageController.text.trim());
      if (age == null || age < 1 || age > 120) {
        setState(() {
          _error = 'Please enter a valid age between 1 and 120.';
        });
        return false;
      }

      if (_heightController.text.trim().isEmpty) {
        setState(() {
          _error = 'Please enter your height.';
        });
        return false;
      }

      if (_weightController.text.trim().isEmpty) {
        setState(() {
          _error = 'Please enter your weight.';
        });
        return false;
      }
    }

    setState(() {
      _error = '';
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            setState(() {
              _error = state.failure.toString();
            });
          } else if (state is AuthLoading) {
            setState(() {
              _error = '';
            });
          }
        },
        builder: (context, authState) {
          return BlocBuilder<LocalizationBloc, LocalizationState>(
            builder: (context, localizationState) {
              String getString(String key) {
                if (localizationState is LocalizationLoaded) {
                  return localizationState.getString(key);
                }
                return key;
              }

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      
                      // App Logo/Title
                      Column(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 64,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            getString('app_name'),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin ? 'Welcome Back!' : 'Create Account',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 48),

                      // Login/Register Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isLogin ? Theme.of(context).primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    getString('sign_in'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isLogin ? Colors.white : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isLogin ? Theme.of(context).primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    getString('sign_up'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !_isLogin ? Colors.white : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Error Message
                      if (_error.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),

                      // Form Fields
                      if (!_isLogin) ...[
                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: getString('email'),
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: getString('password'),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password (for registration)
                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: getString('confirm_password'),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Additional Profile Fields
                        _buildProfileFields(context, getString),
                      ],

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authState is AuthLoading ? null : _handleSubmit,
                          child: authState is AuthLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _isLogin ? getString('sign_in') : getString('sign_up'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),

                      // Forgot Password (for login)
                      if (_isLogin) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            if (_emailController.text.trim().isNotEmpty) {
                              context.read<AuthBloc>().add(
                                AuthForgotPasswordRequested(email: _emailController.text.trim())
                              );
                            } else {
                              setState(() {
                                _error = 'Please enter your email address first';
                              });
                            }
                          },
                          child: Text(getString('forgot_password')),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Toggle between login/register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin
                                ? "Don't have an account? "
                                : getString('already_have_account'),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? getString('create_account') : getString('sign_in'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
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
        },
      ),
    );
  }

  Widget _buildProfileFields(BuildContext context, String Function(String) getString) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Age and Gender Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person),
                ),
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Height and Weight Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  prefixIcon: Icon(Icons.height),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Activity Level
        DropdownButtonFormField<String>(
          value: _selectedActivityLevel,
          decoration: const InputDecoration(
            labelText: 'Activity Level',
            prefixIcon: Icon(Icons.fitness_center),
          ),
          items: ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedActivityLevel = newValue;
              });
            }
          },
        ),
        const SizedBox(height: 16),

        // Heart Conditions Checkbox
        CheckboxListTile(
          title: const Text('I have existing heart conditions'),
          value: _hasHeartConditions,
          onChanged: (bool? value) {
            setState(() {
              _hasHeartConditions = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),

        // Medical Conditions (if has heart conditions)
        if (_hasHeartConditions) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _medicalConditionsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Please describe your heart conditions',
              prefixIcon: Icon(Icons.medical_services),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ],
    );
  }
}
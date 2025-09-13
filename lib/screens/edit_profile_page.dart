import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  final bool isDarkMode;

  const EditProfilePage({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  String _selectedGender = 'Male';
  String _selectedActivityLevel = 'Moderate';
  String _selectedBloodType = 'O+';
  bool _hasHeartConditions = false;
  bool _isLoading = false;
  bool _isSaving = false;
  File? _profileImage;
  String? _profileImageUrl;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalConditionsController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = data['email'] ?? user.email ?? '';
            _phoneController.text = data['phone'] ?? '';
            _ageController.text = data['age']?.toString() ?? '';
            _heightController.text = data['height']?.toString() ?? '';
            _weightController.text = data['weight']?.toString() ?? '';
            _selectedGender = data['gender'] ?? 'Male';
            _selectedActivityLevel = data['activityLevel'] ?? 'Moderate';
            _selectedBloodType = data['bloodType'] ?? 'O+';
            _hasHeartConditions = data['hasHeartConditions'] ?? false;
            _medicalConditionsController.text = data['medicalConditions'] ?? '';
            _emergencyContactController.text = data['emergencyContact'] ?? '';
            _emergencyPhoneController.text = data['emergencyPhone'] ?? '';
            _profileImageUrl = data['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (mounted) {
          setState(() {
            _profileImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final newEmail = _emailController.text.trim();
      final bool emailChanged = newEmail != user.email;

      // Create UserProfile object with updated data
      final currentProfile = await FirebaseService.getUserProfileData(user.uid);
      if (currentProfile == null) {
        throw Exception('Could not load current profile');
      }

      final updatedProfile = currentProfile.copyWith(
        displayName: _nameController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        height: double.tryParse(_heightController.text.trim()),
        weight: double.tryParse(_weightController.text.trim()),
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel,
        bloodType: _selectedBloodType,
        hasHeartConditions: _hasHeartConditions,
        medicalConditions: _hasHeartConditions ? [_medicalConditionsController.text.trim()] : null,
        emergencyContact: _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
        updatedAt: DateTime.now(),
      );
      
      // Always update Firestore data first
      await FirebaseService.updateUserProfile(updatedProfile);

      // If email has changed, handle it separately
      if (emailChanged) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); 
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && mounted) {
        // Call the re-authentication helper
        final user = FirebaseAuth.instance.currentUser;
        final newEmail = _emailController.text.trim();
        if (user != null) {
          await _reauthenticateAndRetryUpdate(user, newEmail);
        }
      } else if (mounted) {
        // Handle other FirebaseAuth errors (e.g., email-already-in-use)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message ?? "An unknown error occurred."}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle other general errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // The re-auth flow handles its own _isSaving state, so only set it to false
        // if not in that flow or if it fails early.
        if (_isSaving) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  // Add a helper method to show the re-authentication dialog
  Future<void> _reauthenticateAndRetryUpdate(User user, String newEmail) async {
    // Use a separate key for the dialog's form
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();
    final TextEditingController passwordController = TextEditingController();

    // Show a dialog asking for the user's password
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Your Identity'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Please enter your password'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password cannot be empty';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    // If the user confirmed and entered a password
    if (confirmed == true) {
      setState(() { _isSaving = true; });

      try {
        // Get the credential
        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!, // Use the user's current email
          password: passwordController.text.trim(),
        );

        // Re-authenticate
        await user.reauthenticateWithCredential(credential);

        // Retry updating the email
        await user.verifyBeforeUpdateEmail(newEmail);
        
        if (mounted) {
          // Now you can proceed with the rest of the profile save
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email updated successfully! Profile saved.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }

      } on FirebaseAuthException catch (e) {
        // Handle wrong password or other errors during re-authentication
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message ?? "Could not verify password."}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
         if (mounted) { setState(() { _isSaving = false; }); }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          border: Border.all(
                            color: const Color(0xFF2563EB),
                            width: 3,
                          ),
                        ),
                        child: _profileImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _profileImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildDefaultAvatar();
                                      },
                                    ),
                                  )
                                : _buildDefaultAvatar(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: LucideIcons.user,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 32),
              
              // Health Information Section
              _buildSectionHeader('Health Information'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      hint: '25',
                      icon: LucideIcons.calendar,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your age';
                        }
                        final age = int.tryParse(value.trim());
                        if (age == null || age < 1 || age > 120) {
                          return 'Please enter a valid age';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: ['Male', 'Female', 'Other'],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      hint: '170',
                      icon: LucideIcons.ruler,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your height';
                        }
                        final height = double.tryParse(value.trim());
                        if (height == null || height < 50 || height > 250) {
                          return 'Please enter a valid height';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      hint: '70',
                      icon: LucideIcons.scale,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your weight';
                        }
                        final weight = double.tryParse(value.trim());
                        if (weight == null || weight < 20 || weight > 300) {
                          return 'Please enter a valid weight';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Blood Type',
                      value: _selectedBloodType,
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Activity Level',
                      value: _selectedActivityLevel,
                      items: ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'],
                      onChanged: (value) {
                        setState(() {
                          _selectedActivityLevel = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Heart Conditions Section
              _buildCheckboxField(
                label: 'Do you have any known heart conditions?',
                value: _hasHeartConditions,
                onChanged: (value) {
                  setState(() {
                    _hasHeartConditions = value!;
                  });
                },
              ),
              
              if (_hasHeartConditions) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _medicalConditionsController,
                  label: 'Medical Conditions & Medications',
                  hint: 'Please describe any heart conditions, medications, allergies, etc.',
                  icon: LucideIcons.heartPulse,
                  maxLines: 3,
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Emergency Contact Section
              _buildSectionHeader('Emergency Contact'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emergencyContactController,
                label: 'Emergency Contact Name',
                hint: 'Enter emergency contact name',
                icon: LucideIcons.userCheck,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emergencyPhoneController,
                label: 'Emergency Contact Phone',
                hint: 'Enter emergency contact phone',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      LucideIcons.user,
      size: 50,
      color: const Color(0xFF2563EB),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: widget.isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
            prefixIcon: Icon(
              icon,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              size: 20,
            ),
            filled: true,
            fillColor: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              dropdownColor: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxField({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

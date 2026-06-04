import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vision/providers/auth_provider.dart';
import 'package:vision/providers/sos_provider.dart';
import 'package:vision/screens/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _contactsFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  late TextEditingController _motherController;
  late TextEditingController _fatherController;
  late TextEditingController _friendController;

  bool _isEditingProfile = false;
  bool _isEditingContacts = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authNotifierProvider);
    
    _nameController = TextEditingController(text: authState.user?.name);
    _phoneController = TextEditingController(text: authState.user?.phone);

    final contacts = authState.contacts;
    _motherController = TextEditingController(text: contacts?['mother'] ?? '');
    _fatherController = TextEditingController(text: contacts?['father'] ?? '');
    _friendController = TextEditingController(text: contacts?['friend'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _motherController.dispose();
    _fatherController.dispose();
    _friendController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    if (!_profileFormKey.currentState!.validate()) return;
    
    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      setState(() => _isEditingProfile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _saveContactsChanges() async {
    if (!_contactsFormKey.currentState!.validate()) return;

    try {
      await ref.read(authNotifierProvider.notifier).updateContacts(
        mother: _motherController.text.trim(),
        father: _fatherController.text.trim(),
        friend: _friendController.text.trim(),
      );
      setState(() => _isEditingContacts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency contacts updated!', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update contacts: $e', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final sosState = ref.watch(sosNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'USER PROFILE',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. User Profile Details ---
              Form(
                key: _profileFormKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PROFILE DETAILS',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isEditingProfile ? Icons.check_circle_outline_rounded : Icons.edit_outlined,
                              color: const Color(0xFF2563EB),
                            ),
                            onPressed: () {
                              if (_isEditingProfile) {
                                _saveProfileChanges();
                              } else {
                                setState(() => _isEditingProfile = true);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        controller: _nameController,
                        label: 'Full Name',
                        isEditing: _isEditingProfile,
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        isEditing: _isEditingProfile,
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Email (Non-editable)
                      _buildEditableField(
                        controller: TextEditingController(text: authState.user?.email),
                        label: 'Email Address',
                        isEditing: false,
                        icon: Icons.email_outlined,
                        validator: (_) => null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. Emergency Contacts ---
              Form(
                key: _contactsFormKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EMERGENCY CONTACTS',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isEditingContacts ? Icons.check_circle_outline_rounded : Icons.edit_outlined,
                              color: const Color(0xFF2563EB),
                            ),
                            onPressed: () {
                              if (_isEditingContacts) {
                                _saveContactsChanges();
                              } else {
                                setState(() => _isEditingContacts = true);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        controller: _motherController,
                        label: 'Mother Contacts',
                        isEditing: _isEditingContacts,
                        icon: Icons.family_restroom_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Mother's name/number is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        controller: _fatherController,
                        label: 'Father Contacts',
                        isEditing: _isEditingContacts,
                        icon: Icons.family_restroom_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Father's name/number is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        controller: _friendController,
                        label: 'Friend Contacts',
                        isEditing: _isEditingContacts,
                        icon: Icons.people_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Friend's name/number is required";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Current Location Telemetry ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAST RECORDED TELEMETRY',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Latitude:',
                          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                        ),
                        Text(
                          sosState.latitude.toStringAsFixed(6),
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Longitude:',
                          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                        ),
                        Text(
                          sosState.longitude.toStringAsFixed(6),
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Timestamp:',
                          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                        ),
                        Expanded(
                          child: Text(
                            _formatTimestamp(sosState.lastUpdated),
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 4. Secure Sign Out Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: Text(
                  'SECURE SIGN OUT',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                onPressed: authState.isLoading ? null : _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required bool isEditing,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: isEditing,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(
        color: isEditing ? Colors.white : const Color(0xFF94A3B8),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: isEditing
            ? const Color(0xFF0F172A).withOpacity(0.4)
            : const Color(0xFF1E293B).withOpacity(0.2),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorStyle: GoogleFonts.outfit(color: const Color(0xFFEF4444)),
      ),
      validator: validator,
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty || timestamp == 'NEVER' || timestamp == '0') {
      return 'NEVER';
    }
    try {
      final parsed = DateTime.tryParse(timestamp);
      if (parsed != null) {
        final localTime = parsed.toLocal();
        return DateFormat('dd MMM yyyy, hh:mm:ss a').format(localTime);
      }
    } catch (_) {}
    try {
      int? ms = int.tryParse(timestamp);
      if (ms != null && ms > 0) {
        if (ms < 10000000000) {
          ms = ms * 1000;
        }
        final localTime = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
        return DateFormat('dd MMM yyyy, hh:mm:ss a').format(localTime);
      }
    } catch (_) {}
    return timestamp;
  }
}

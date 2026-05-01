import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curasync/config/theme.dart';
import 'package:curasync/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // ─── Role Toggle ───
  bool _isDoctor = false;

  // ─── Shared Controllers ───
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ─── Patient-specific ───
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  // ─── Doctor-specific ───
  String? _selectedSpecialty;
  final _experienceController = TextEditingController();
  bool _agreedToTerms = false;

  // ─── State ───
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const List<String> _specialties = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _experienceController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _switchRole(bool toDoctor) {
    if (_isDoctor == toDoctor) return;
    _animController.reverse().then((_) {
      setState(() => _isDoctor = toDoctor);
      _animController.forward();
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_isDoctor && !_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to Terms of Service'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final extraFields = _isDoctor
        ? {
            'specialty': _selectedSpecialty,
            'experienceYears': int.tryParse(_experienceController.text) ?? 0,
          }
        : {
            'age': int.tryParse(_ageController.text) ?? 0,
            'weight': int.tryParse(_weightController.text) ?? 0,
          };

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _isDoctor ? 'doctor' : 'patient',
      extraFields: extraFields,
    );

    if (!mounted) return;

    if (success) {
      // Navigate based on role
      if (authProvider.isDoctor) {
        Navigator.pushReplacementNamed(context, '/doctor-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/patient-home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ─── Logo ───
                  _buildLogo(),

                  const SizedBox(height: 28),

                  // ─── Heading ───
                  Text(
                    _isDoctor ? 'Create your profile' : 'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your details to begin your journey.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Role Toggle ───
                  Center(child: _buildRoleToggle()),

                  const SizedBox(height: 28),

                  // ─── Form Fields (animated) ───
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shared fields
                        _buildFieldLabel('FULL NAME'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: _isDoctor ? 'Dr. Julian Vane' : 'Johnathan Doe',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Name is required' : null,
                        ),

                        const SizedBox(height: 20),
                        _buildFieldLabel('EMAIL ADDRESS'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: _isDoctor
                              ? 'vane.clinical@sync.com'
                              : 'john@clinic.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        _buildFieldLabel('PASSWORD'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: '••••••••',
                          obscure: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textHint,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 6) {
                              return 'Must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        _buildFieldLabel('CONFIRM PASSWORD'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: '••••••••',
                          obscure: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textHint,
                              size: 20,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Please confirm password' : null,
                        ),

                        const SizedBox(height: 20),

                        // ─── Role-specific fields ───
                        if (_isDoctor) ..._buildDoctorFields(),
                        if (!_isDoctor) ..._buildPatientFields(),

                        const SizedBox(height: 28),

                        // ─── Submit Button ───
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppTheme.primaryBlue.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _isDoctor
                                        ? 'Create Doctor Account'
                                        : 'Create Patient Account',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ─── Login Link ───
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?  ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                      context, '/login');
                                },
                                child: Text(
                                  'Login',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo Widget ───
  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _isDoctor ? Icons.medical_services_outlined : Icons.favorite_outline,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'CuraSync',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
        ),
      ],
    );
  }

  // ─── Role Toggle ───
  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: 'I am a Patient',
            isActive: !_isDoctor,
            onTap: () => _switchRole(false),
          ),
          _buildToggleButton(
            label: 'I am a Doctor',
            isActive: _isDoctor,
            onTap: () => _switchRole(true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // ─── Field Label ───
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
    );
  }

  // ─── Text Field ───
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
        suffix: suffix,
      ),
    );
  }

  // ─── Patient-specific fields ───
  List<Widget> _buildPatientFields() {
    return [
      _buildFieldLabel('AGE'),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _ageController,
        hint: '24',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 20),
      _buildFieldLabel('WEIGHT'),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _weightController,
        hint: '70',
        keyboardType: TextInputType.number,
        suffix: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.inputBorder.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'KG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    ];
  }

  // ─── Doctor-specific fields ───
  List<Widget> _buildDoctorFields() {
    return [
      _buildFieldLabel('SPECIALTY'),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _selectedSpecialty,
        decoration: InputDecoration(
          hintText: 'Select Specialization',
          hintStyle: const TextStyle(
            color: AppTheme.textHint,
            fontSize: 15,
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textSecondary),
        items: _specialties.map((s) {
          return DropdownMenuItem(value: s, child: Text(s));
        }).toList(),
        onChanged: (val) => setState(() => _selectedSpecialty = val),
        validator: (v) => v == null ? 'Specialty is required' : null,
        borderRadius: BorderRadius.circular(14),
        dropdownColor: AppTheme.surfaceWhite,
      ),
      const SizedBox(height: 20),
      _buildFieldLabel('EXPERIENCE (YEARS)'),
      const SizedBox(height: 8),
      _buildTextField(
        controller: _experienceController,
        hint: '0',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 20),

      // ─── Terms checkbox ───
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              activeColor: AppTheme.primaryBlue,
              side: BorderSide(color: AppTheme.inputBorder, width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                children: const [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

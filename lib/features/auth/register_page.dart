import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/dialog_utils.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscureText = true;
  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: false,
        title: 'Validation Error',
        message: 'Please fill in all fields.',
        buttonText: 'OK',
        onPressed: () => Navigator.pop(context),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: false,
        title: 'Invalid Email',
        message: 'Please enter a valid email address.',
        buttonText: 'OK',
        onPressed: () => Navigator.pop(context),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        AppDialogs.showStatusDialog(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: result['message'],
          buttonText: 'Go to Login',
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        );
      } else {
        AppDialogs.showStatusDialog(
          context: context,
          isSuccess: false,
          title: 'Registration Failed',
          message: result['message'],
          buttonText: 'Try Again',
          onPressed: () => Navigator.pop(context),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/other/splashscreen.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top section (Back button & Mascot)
              Expanded(
                flex: 35,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Back Button
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF4A6B38)),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4A6B38),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Mascot
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: const Offset(0, 60), // Shift down to peek behind the form
                        child: Image.asset(
                          'assets/images/mascot/avatar1.png',
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom section (Form Card)
              Expanded(
                flex: 65,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBF5), // Soft Moya cream color
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -5), // Shadow going upwards
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Title
                        Center(
                          child: RichText(
                            text: const TextSpan(
                              text: 'Register',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Username Field
                        const Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your username',
                            hintStyle: const TextStyle(color: Color(0xFFA0AAB2), fontSize: 14),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFA0AAB2)),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFC4D4B9)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF4A6B38), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Email Field
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            setState(() {
                              if (value.isEmpty) {
                                _emailError = null;
                              } else if (!emailRegex.hasMatch(value)) {
                                _emailError = 'Please enter a valid email address';
                              } else {
                                _emailError = null;
                              }
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            errorText: _emailError,
                            hintStyle: const TextStyle(color: Color(0xFFA0AAB2), fontSize: 14),
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFA0AAB2)),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFC4D4B9)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF4A6B38), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Password Field
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: const TextStyle(color: Color(0xFFA0AAB2), fontSize: 14),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFA0AAB2)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFFA0AAB2),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFC4D4B9)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF4A6B38), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B7D46), // Moya Green
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'Register',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Login Link
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, AppRoutes.login);
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5B7D46),
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

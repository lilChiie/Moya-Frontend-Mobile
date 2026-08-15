import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/dialog_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both email and password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.login(
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
          buttonText: 'Continue',
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.mainNav,
              (route) => false,
            );
          },
        );
      } else {
        AppDialogs.showStatusDialog(
          context: context,
          isSuccess: false,
          title: 'Login Failed',
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
                              text: 'Login',
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
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
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
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Register Link
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, AppRoutes.register);
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: 'Don\'t have an account? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5B7D46),
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Register',
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

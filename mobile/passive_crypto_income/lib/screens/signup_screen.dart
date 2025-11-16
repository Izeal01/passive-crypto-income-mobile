import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';  // FIXED: Added for saving user_email
import '../services/api_service.dart';
import 'home_screen.dart';  // FIXED: Removed unused import 'login_screen.dart'

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();  // FIXED: Added Form for validation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;  // FIXED: Use Form validation
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.signup({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
      if (response['status'] == 'user created') {
        final userEmail = response['email'] ?? _emailController.text.trim();
        // FIXED: Save user_email to SharedPreferences for ApiKeysProvider
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', userEmail);
        if (mounted) {  // FIXED: Separate mounted for navigation (resolves use_build_context_synchronously)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userEmail: userEmail)),
          );
        }
      } else {
        throw Exception('Signup failed: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignUp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final googleSignIn = GoogleSignIn(scopes: <String>['email']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-Up cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('No ID token received from Google');
      }

      final response = await ApiService.postWithRetry('/google_signup', {'id_token': googleAuth.idToken});
      if (response['status'] == 'user created') {
        final userEmail = response['email'] ?? googleUser.email;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', userEmail);
        if (response.containsKey('token')) {
          await ApiService.setAuthToken(response['token']);
        }
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userEmail: userEmail)),
          );
        }
      } else {
        throw Exception('Google signup failed: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Google Sign-Up error: $e');
      if (mounted) {
        setState(() {
          _error = 'Google Sign-Up failed: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
          ),
          child: IntrinsicHeight(
            child: Form(  // FIXED: Wrapped in Form for validation
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: TextFormField(  // FIXED: Changed to TextFormField for validation
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                  Flexible(
                    child: TextFormField(  // FIXED: Changed to TextFormField for validation
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: _validatePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signup,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.person_add),
                      label: const Text('Sign Up'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Login'),
                  ),
                  if (_error != null) 
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 30),
                  const Text('Or sign up with Google', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _googleSignUp,
                      icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                      label: const Text('Sign up with Google', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

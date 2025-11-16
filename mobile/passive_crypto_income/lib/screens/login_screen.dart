import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _retryLogin(_emailController.text.trim(), _passwordController.text);
      if (response['status'] == 'logged in') {
        final userEmail = response['email'] ?? _emailController.text.trim();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', userEmail);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userEmail: userEmail)),
          );
        }
      } else {
        throw Exception('Login failed: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _retryLogin(String email, String password, {int retries = 3}) async {
    const delayBase = Duration(seconds: 3);
    for (int i = 0; i < retries; i++) {
      try {
        final user = {'email': email, 'password': password};
        final response = await ApiService.login(user);
        return response;
      } catch (e) {
        debugPrint('Login attempt ${i+1}/$retries failed: $e');
        if (i < retries - 1) {
          await Future.delayed(delayBase * (i + 1));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
      }
    }
    throw Exception('Login failed after $retries attempts');
  }

  Future<void> _signup() async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final googleSignIn = GoogleSignIn(scopes: <String>['email']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('No ID token received from Google');
      }

      final response = await ApiService.postWithRetry('/google_login', {'id_token': googleAuth.idToken});
      if (response['status'] == 'logged in') {
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
        throw Exception('Google login failed: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (mounted) setState(() => _error = 'Google Sign-In failed: $e');
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
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          child: IntrinsicHeight(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  TextButton(
                    onPressed: _signup,
                    child: const Text('Sign Up'),
                  ),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                  const Text('Or login with Google', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _googleSignIn,
                      icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                      label: const Text('Sign in with Google', style: TextStyle(color: Colors.white)),
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

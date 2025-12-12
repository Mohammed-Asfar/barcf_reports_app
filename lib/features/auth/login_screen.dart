import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_service.dart';
import '../reports/screens/reports_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReportsScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      // Background is handled by theme (Dark Navy)
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
          margin: const EdgeInsets.all(32),
          child: Row(
            children: [
              // LEFT SIDE - FORM
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get Started',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome to BARCF Reports',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[400],
                                    ),
                          ),
                          const SizedBox(height: 48),

                          // Username
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(
                                color: Colors
                                    .black87), // Input text dark on white field
                            decoration: const InputDecoration(
                              hintText: 'Username or Email',
                              prefixIcon:
                                  Icon(Icons.person, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(30)), // Pill/Rounded shape
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter username' : null,
                          ),
                          const SizedBox(height: 24),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              hintText: 'Password',
                              prefixIcon: Icon(Icons.lock, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30)),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                            ),
                            obscureText: true,
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter password' : null,
                            onFieldSubmitted: (_) => _login(),
                          ),

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  () {}, // TODO: Implement forgot password
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),

                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // RIGHT SIDE - ILLUSTRATION (Visible on Desktop)
              if (isDesktop)
                Expanded(
                  child: Stack(
                    children: [
                      // Pseudo-Door Arch
                      Positioned.fill(
                        child: FractionallySizedBox(
                          widthFactor: 0.6,
                          heightFactor: 0.8,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(1000)),
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child:
                            Icon(Icons.login, size: 100, color: Colors.black26),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

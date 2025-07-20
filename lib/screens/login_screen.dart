import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:important_places_explorer/screens/signup_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Login successful. The StreamBuilder in MyApp (main.dart) will handle navigation
      // to HomeScreen automatically, so no explicit Navigator.pushReplacement here.
    } on FirebaseAuthException catch (e) {
      String message;
      // Handle specific Firebase authentication error codes
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled.';
      } else {
        message = e.message ?? 'An unknown error occurred.';
      }
      // Check if the widget is still in the widget tree before calling setState.
      if (!mounted) return;
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      // Catch any other unexpected errors
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      // Always stop loading, regardless of success or error
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"), // AppBar title specific to Login
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 30),
              const Text(
                "Welcome Back!", // Greeting for login screen
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),
              // Display error message if any
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              // Show CircularProgressIndicator while loading, otherwise buttons
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _login, // Call login method
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Button to navigate to the SignupScreen
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Create New Account", // Text for signup navigation
                            style: TextStyle(fontSize: 18, color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Forgot password functionality not implemented.')),
                  );
                },
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

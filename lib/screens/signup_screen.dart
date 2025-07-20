import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:cloud_firestore/cloud_firestore.dart'; // For Cloud Firestore
import 'dart:io'; // For File operations

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController(); // New: For user's display name
  final _bioController = TextEditingController(); // New: For user's bio

  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance; // Firebase Storage instance
  final _firestore = FirebaseFirestore.instance; // Cloud Firestore instance

  bool _isLoading = false;
  String? _errorMessage;
  File? _pickedImage; // To store the picked image file

  // Function to pick an image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _isLoading = false;
      });
      return;
    }

    if (_displayNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a display name.';
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-created', message: 'Failed to create user.');
      }

      String? photoUrl;
      // 2. Upload image to Firebase Storage if picked
      if (_pickedImage != null) {
        final storageRef = _storage.ref().child('user_images').child('${user.uid}.jpg');
        UploadTask uploadTask = storageRef.putFile(_pickedImage!);
        TaskSnapshot snapshot = await uploadTask;
        photoUrl = await snapshot.ref.getDownloadURL();
      }

      // 3. Update Firebase Auth user profile (display name, photo URL)
      await user.updateDisplayName(_displayNameController.text.trim());
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      // Reload user to get updated profile details immediately
      await user.reload();
      user = _auth.currentUser; // Get the reloaded user object

      // 4. Save additional user data (bio) to Cloud Firestore
      await _firestore.collection('users').doc(user!.uid).set({
        'email': user.email,
        'displayName': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(), // Timestamp of creation
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );
      Navigator.of(context).pop(); // Go back to LoginScreen
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password accounts are not enabled. Please enable them in Firebase Console.';
      } else {
        message = e.message ?? 'An unknown error occurred during authentication.';
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                  child: _pickedImage == null
                      ? Icon(Icons.camera_alt, size: 40, color: Theme.of(context).primaryColor)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _displayNameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: "Display Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
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
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_reset),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bioController,
                keyboardType: TextInputType.multiline,
                maxLines: 3, // Allow multiple lines for bio
                decoration: InputDecoration(
                  labelText: "Bio (Optional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Already have an account? Login",
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

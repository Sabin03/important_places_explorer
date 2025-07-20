import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'settings_screen.dart'; // Assuming this file exists
import 'login_screen.dart';   // Assuming this file exists
import 'edit_profile_screen.dart'; // Import the new EditProfileScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Handle case where user is not logged in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
          centerTitle: true,
          elevation: 4,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 80, color: Colors.grey.shade500),
                const SizedBox(height: 20),
                const Text(
                  "You are not logged in.",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Please log in to view your profile.",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Log In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Display user profile if logged in
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 4,
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            title: const Text(
              "Your Profile",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            // Using a ValueKey ensures the FutureBuilder rebuilds when the user changes
            key: ValueKey(user!.uid),
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.grey.shade200,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Error loading profile: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'User profile not found.',
                      style: TextStyle(color: Colors.orange.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final userData = snapshot.data!.data();
              final displayName =
                  userData?['displayName'] ?? user?.displayName ?? 'Guest User';
              final photoUrl = userData?['photoUrl'] ?? user?.photoURL;
              final email = user?.email ?? 'No email provided';
              final bio = userData?['bio'] ?? 'No bio added.';

              return SliverFillRemaining(
                hasScrollBody: true,
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? Icon(Icons.person,
                                      size: 60,
                                      color:
                                          Theme.of(context).colorScheme.primary)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(email,
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 15)),
                            const SizedBox(height: 8),
                            Text(bio,
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                // Navigate to EditProfileScreen and await result
                                final bool? updated = await Navigator.of(context)
                                    .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(
                                      currentName: displayName,
                                      currentBio: bio,
                                      currentPhotoUrl: photoUrl,
                                    ),
                                  ),
                                );

                                // If profile was updated, refresh the screen
                                if (updated == true) {
                                  setState(() {
                                    // This will trigger the FutureBuilder to re-fetch data
                                  });
                                }
                              },
                              icon: const Icon(Icons.edit, size: 20),
                              label: const Text("Edit Profile"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
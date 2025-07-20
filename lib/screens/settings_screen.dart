import 'dart:io'; // For Platform check
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _openIOSLanguageSettings(BuildContext context) async {
    const url = 'App-Prefs:General&path=LANGUAGE_AND_REGION';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open iOS Language Settings")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(context, Icons.manage_accounts, "Account Settings"),
          _buildDivider(),
          _buildSettingsTile(context, Icons.post_add, "Your Posts"),
          _buildDivider(),
          _buildSettingsTile(context, Icons.notifications_active, "Notifications"),
          _buildDivider(),

          // 🌐 Language setting tile
          ListTile(
            leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
            title: const Text("Language"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              if (Platform.isIOS) {
                _openIOSLanguageSettings(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Only supported on iOS devices.")),
                );
              }
            },
          ),

          _buildDivider(),
          _buildSettingsTile(context, Icons.lock, "Privacy Policy"),
          _buildDivider(),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text("Log Out"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title tapped')),
        );
      },
    );
  }

  Widget _buildDivider() => const Divider(indent: 16, endIndent: 16, height: 0);
}
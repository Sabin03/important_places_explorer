import 'dart:io';
import 'dart:ui'; // For BackdropFilter

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final String? currentPhotoUrl;

  const EditProfileScreen({
    Key? key,
    required this.currentName,
    required this.currentBio,
    this.currentPhotoUrl,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  File? _newImageFile;
  bool _isLoading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _bioController = TextEditingController(text: widget.currentBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _newImageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File file, String uid) async {
    try {
      final compressedFile = await _compressFile(file);

      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('$uid.jpg');
      await ref.putFile(compressedFile);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  Future<File> _compressFile(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final split = filePath.substring(0, lastIndex);
    final outPath = '${split}_compressed.jpg';

    final compressedBytes = await FlutterImageCompress.compressWithFile(
      filePath,
      quality: 70,
      minWidth: 600,
      minHeight: 600,
      format: CompressFormat.jpeg,
    );

    if (compressedBytes == null) {
      debugPrint("Image compression failed, returning original file.");
      return file;
    }

    final compressedFile = await File(outPath).writeAsBytes(compressedBytes);
    return compressedFile;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? photoUrl = widget.currentPhotoUrl;

      if (_newImageFile != null) {
        final uploadedUrl = await _uploadImage(_newImageFile!, user.uid);
        if (uploadedUrl != null) {
          photoUrl = uploadedUrl;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image.')),
          );
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
      }, SetOptions(merge: true));

      await user.updateDisplayName(_nameController.text.trim());
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _newImageFile != null
                              ? FileImage(_newImageFile!)
                              : (widget.currentPhotoUrl != null
                                  ? NetworkImage(widget.currentPhotoUrl!)
                                  : null) as ImageProvider<Object>?,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          child: (_newImageFile == null &&
                                  widget.currentPhotoUrl == null)
                              ? Icon(Icons.person,
                                  size: 60,
                                  color:
                                      Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: InkWell(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.camera_alt,
                                  size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a display name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

if (_isLoading)
  Center(
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
        ],
      ),
    );
  }
}
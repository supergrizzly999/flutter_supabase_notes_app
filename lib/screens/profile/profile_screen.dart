import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../../models/profile_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Profile? _profile;
  bool _isLoading = true;
  final TextEditingController _usernameController = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getProfile();
      if (mounted && data != null) {
        setState(() {
          _profile = Profile.fromJson(data);
          _usernameController.text = _profile?.username ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Gagal memuat profil: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (imageFile != null) {
      if (mounted) {
        setState(() {
          _selectedImage = imageFile;
        });
      }

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        if (mounted) {
          setState(() {
            _webImageBytes = bytes;
          });
        }
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_usernameController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Username tidak boleh kosong',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    String? avatarUrl;

    try {
      if (_selectedImage != null) {
        final fileName =
            '${supabase.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        avatarUrl = kIsWeb && _webImageBytes != null
            ? await _supabaseService.uploadImageBytes(_webImageBytes!, fileName)
            : await _supabaseService.uploadImage(File(_selectedImage!.path), fileName);
      }

      await _supabaseService.updateProfile(
        username: _usernameController.text,
        avatarUrl: avatarUrl ?? _profile?.avatarUrl,
      );

      if (mounted) {
        // Langsung navigasi ke halaman home tanpa popup
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Gagal memperbarui profil: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarPreview;

    if (_selectedImage != null) {
      if (kIsWeb && _webImageBytes != null) {
        avatarPreview = MemoryImage(_webImageBytes!);
      } else if (!kIsWeb) {
        avatarPreview = FileImage(File(_selectedImage!.path));
      }
    } else if (_profile?.avatarUrl != null) {
      avatarPreview = NetworkImage(_profile!.avatarUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Profil Saya'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Gagal memuat profil.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: avatarPreview,
                          backgroundColor: Colors.grey[300],
                          child: avatarPreview == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Ganti Avatar'),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _updateProfile,
                          icon: const Icon(Icons.save),
                          label: const Text('Simpan Perubahan'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

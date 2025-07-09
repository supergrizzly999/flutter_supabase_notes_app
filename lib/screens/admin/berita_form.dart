import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../models/berita_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_input_field.dart';

class BeritaFormScreen extends StatefulWidget {
  const BeritaFormScreen({super.key});

  @override
  State<BeritaFormScreen> createState() => _BeritaFormScreenState();
}

class _BeritaFormScreenState extends State<BeritaFormScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isLoading = false;
  Berita? _existingBerita;
  XFile? _imageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (Get.arguments is Berita) {
      _existingBerita = Get.arguments as Berita;
      _titleController.text = _existingBerita!.title;
      _contentController.text = _existingBerita!.content;
      _existingImageUrl = _existingBerita!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() {
        _imageFile = imageFile;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl = _existingImageUrl;

        if (_imageFile != null) {
          final fileName =
              '${supabase.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          if (kIsWeb) {
            final imageBytes = await _imageFile!.readAsBytes();
            imageUrl = await _supabaseService.uploadImageBytes(
              imageBytes,
              fileName,
            );
          } else {
            final file = File(_imageFile!.path);
            imageUrl = await _supabaseService.uploadImage(
              file,
              fileName,
            );
          }
        }

        if (_existingBerita != null) {
          await _supabaseService.updateBerita(
            id: _existingBerita!.id,
            title: _titleController.text,
            content: _contentController.text,
            imageUrl: imageUrl,
          );
        } else {
          await _supabaseService.addBerita(
            title: _titleController.text,
            content: _contentController.text,
            imageUrl: imageUrl,
          );
        }

        Get.back(result: true);
      } catch (e) {
        Get.snackbar(
          'Error',
          'Gagal menyimpan berita: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingBerita == null ? 'Tambah Berita' : 'Edit Berita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _imageFile != null
                  ? (kIsWeb
                      ? Image.network(
                          _imageFile!.path,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_imageFile!.path),
                          height: 150,
                          fit: BoxFit.cover,
                        ))
                  : (_existingImageUrl != null
                      ? Image.network(
                          _existingImageUrl!,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar'),
              ),
              const SizedBox(height: 16),
              CustomInputField(
                controller: _titleController,
                labelText: 'Judul Berita',
                validator: (value) =>
                    value!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                controller: _contentController,
                labelText: 'Isi Berita',
                maxLines: 10,
                keyboardType: TextInputType.multiline,
                validator: (value) =>
                    value!.isEmpty ? 'Isi berita tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Berita'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

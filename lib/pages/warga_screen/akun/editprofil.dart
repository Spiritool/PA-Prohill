import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  final String initialName;
  final String initialPhone;

  const EditProfilePage({
    super.key,
    required this.initialName,
    required this.initialPhone,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _photoSelected = false;

  String? fotoUrl;
  final Color primaryColor = const Color(0xFF006E7F);

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    phoneController = TextEditingController(text: widget.initialPhone);
    _loadFotoUrl();
  }

  void _loadFotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fotoUrl = prefs.getString('user_profile_photo');
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      final fileExtension = pickedImage.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        setState(() {
          _image = pickedImage;
          _photoSelected = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format tidak didukung. Hanya JPG, JPEG, atau PNG.'),
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama harus minimal 8 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _updateUserData();
      if (_photoSelected) {
        await _uploadProfilePhoto();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context, {'name': name, 'phone': phone});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    final token = prefs.getString('token');

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://192.168.223.205:8000/api/user/update/$userId"),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['nama'] = name;
    request.fields['no_hp'] = phone;
    request.fields['_method'] = 'PUT';

    final response = await request.send();
    if (response.statusCode == 200) {
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);
    } else {
      throw Exception('Gagal update data. Status: ${response.statusCode}');
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_image == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    final token = prefs.getString('token');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://192.168.223.205:8000/api/user/$userId/foto-profile"),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['_method'] = 'PUT';
    request.files.add(await http.MultipartFile.fromPath(
      'foto_profile',
      _image!.path,
    ));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      final fotoUrlFromServer = data['data']['foto_profile'];
      log('[log] link foto baru: $fotoUrlFromServer');

      if (fotoUrlFromServer is String) {
        await prefs.setString('user_profile_photo', fotoUrlFromServer);
        setState(() {
          fotoUrl = fotoUrlFromServer;
          _photoSelected = false;
          _image = null;
        });
      }
    } else {
      throw Exception('Gagal upload foto. Status: ${response.statusCode}');
    }
  }

  Widget _buildProfilePhoto() {
    ImageProvider? imageProvider;
    if (_image != null) {
      imageProvider = FileImage(File(_image!.path));
    } else if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(fotoUrl!);
    }

    return Center(
      child: GestureDetector(
        onTap: () => _getImage(ImageSource.gallery),
        child: Stack(
          children: [
            ClipOval(
              child: Container(
                width: 250,
                height: 250,
                color: primaryColor.withOpacity(0.1),
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        width: 250,
                        height: 250,
                      )
                    : Icon(Icons.person, size: 120, color: primaryColor),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: label.toLowerCase().contains("hp")
                ? TextInputType.phone
                : TextInputType.text,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: label,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfilePhoto(),
            const SizedBox(height: 32),
            _customTextField(controller: nameController, label: 'Nama Lengkap'),
            const SizedBox(height: 20),
            _customTextField(controller: phoneController, label: 'No. HP'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Simpan',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

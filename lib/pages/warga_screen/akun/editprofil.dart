import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

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
      Uri.parse("$baseipapi/api/user/update/$userId"),
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
      Uri.parse("$baseipapi/api/user/$userId/foto-profile"),
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
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6600).withOpacity(0.8),
                const Color(0xFFFF8533).withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6600).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6600).withOpacity(0.1),
                    ),
                    child: imageProvider != null
                        ? ClipOval(
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.cover,
                              width: 264,
                              height: 264,
                            ),
                          )
                        : Icon(
                            Icons.person_outline,
                            size: 80,
                            color: const Color(0xFFFF6600).withOpacity(0.6),
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 15,
                right: 15,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6600).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: label.toLowerCase().contains("hp")
                ? TextInputType.phone
                : TextInputType.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              hintText: 'Masukkan $label',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        prefixIcon,
                        color: const Color(0xFFFF6600).withOpacity(0.7),
                        size: 22,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6600),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
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
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.black87,
              size: 24,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfilePhoto(),
              const SizedBox(height: 40),

              // Section Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 20),
                child: Text(
                  'Informasi Personal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              _customTextField(
                controller: nameController,
                label: 'Nama Lengkap',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 24),

              _customTextField(
                controller: phoneController,
                label: 'No. HP',
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 40),

              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6600).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.save_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

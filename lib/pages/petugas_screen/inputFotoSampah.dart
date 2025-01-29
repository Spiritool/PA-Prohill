import 'package:dlh_project/pages/petugas_screen/Home_Konten.dart';
import 'package:dlh_project/pages/petugas_screen/historyPetugas.dart';
import 'package:dlh_project/pages/petugas_screen/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InputFotoSampah extends StatefulWidget {
  final int idSampah;

  const InputFotoSampah({super.key, required this.idSampah});

  @override
  _InputFotoSampahState createState() => _InputFotoSampahState();
}

class _InputFotoSampahState extends State<InputFotoSampah> {
  File? _imageFile;
  int? _userId;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('id_user_petugas');
    });
    if (_userId == null) {
      print('User ID not found in SharedPreferences');
    } else {
      print('User ID loaded: $_userId');
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  void _showImageSourceSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Foto'),
          actions: [
            TextButton(
              child: const Text('Kamera'),
              onPressed: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.camera);
              },
            ),
            TextButton(
              child: const Text('Galeri'),
              onPressed: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitData() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('user_id') ?? 0;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://jera.kerissumenep.com/api/pengangkutan-sampah-liar/done/${widget.idSampah}',
        ),
      );

      request.fields['id_user_petugas'] = idUser.toString();
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_pengangkutan_sampah',
          _imageFile!.path,
        ),
      );

      await request.send();

      // Menampilkan snackbar keberhasilan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto Berhasil di Inputkan dan Status menjadi Done.'),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePetugasPage()),
          (Route<dynamic> route) => false,
        );
      });
    } catch (e) {
      Navigator.pop(context); // Dismiss loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
      print('An error occurred: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Foto"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _imageFile == null
                  ? const Text('No image selected.')
                  : Image.file(_imageFile!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showImageSourceSelection,
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green),
                child: const Text('Pick Image'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

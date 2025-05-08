import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapSingle extends StatefulWidget {
  final dynamic sampah;
  final bool isDaurUlang; // Menerima objek sampah lengkap

  const MapSingle({
    Key? key,
    required this.sampah,
    required this.isDaurUlang, // Parameter wajib
  }) : super(key: key);

  @override
  _MapSingleState createState() => _MapSingleState();
}

class _MapSingleState extends State<MapSingle> {
  LatLng? sampahPosition;
  LatLng? petugasPosition;
  List<LatLng> routePoints = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  LatLng? _parseCoordinate(String url) {
    try {
      final uri = Uri.parse(url);
      final query = uri.queryParameters['query'];

      if (query != null) {
        final parts = query.split(',');
        final lat = double.tryParse(parts[0]) ?? 0.0;
        final lon = double.tryParse(parts[1]) ?? 0.0;
        return LatLng(lat, lon);
      }
    } catch (e) {
      print('Error parsing coordinate: $e');
    }
    return null;
  }

  Future<void> _initializeMap() async {
    try {
      // 1. Dapatkan lokasi petugas (GPS)
      await _getCurrentLocation();

      // 2. Ekstrak koordinat dari objek sampah
      _extractSampahPosition();

      // 3. Generate rute jika kedua posisi tersedia
      if (petugasPosition != null && sampahPosition != null) {
        await generateRoute(petugasPosition!, sampahPosition!);
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  void _extractSampahPosition() {
    try {
      final coordinateUrl = widget.isDaurUlang
          ? widget.sampah.alamat.kordinat
          : widget.sampah.kordinat;

      setState(() {
        sampahPosition = _parseCoordinate(coordinateUrl);
      });
    } catch (e) {
      throw Exception('Gagal memproses koordinat: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final status = await Permission.location.request();
      if (!status.isGranted) throw Exception('Izin lokasi ditolak');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        petugasPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      throw Exception('Gagal mendapatkan lokasi: $e');
    }
  }

  Future<void> generateRoute(LatLng start, LatLng end) async {
    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          routePoints =
              coords.map((point) => LatLng(point[1], point[0])).toList();
        });
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Routing error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Peta Lokasi Sampah"),
        centerTitle: true,
      ),
      body: _buildMapContent(),
    );
  }

  Widget _buildMapContent() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage.isNotEmpty) return Center(child: Text(errorMessage));
    if (sampahPosition == null)
      return const Center(child: Text('Lokasi sampah tidak valid'));

    return FlutterMap(
      options: MapOptions(
        center: sampahPosition,
        zoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (petugasPosition != null)
              Marker(
                width: 40,
                height: 40,
                point: petugasPosition!,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: ClipOval(
                    child: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/847/847969.png', // ganti link PNG kalau perlu
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            if (sampahPosition != null) // Tambahkan pengecekan null
              Marker(
                width: 40,
                height: 40,
                point:
                    sampahPosition!, // Gunakan bang operator (!) karena sudah dicek null
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

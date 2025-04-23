import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class MapPetugas2 extends StatefulWidget {
  const MapPetugas2({super.key});

  @override
  State<MapPetugas2> createState() => _MapPetugas2State();
}

class _MapPetugas2State extends State<MapPetugas2> {
  List<LatLng> routePoints = [];
  final MapController _mapController = MapController();
  List<String> koordinatList = [];

  // Lokasi TPA statis
  final LatLng tpaLocation = LatLng(-7.000468646396472, 113.85141955621073);

  @override
  void initState() {
    super.initState();
    _fetchKoordinatFromApi();
  }

  Future<void> _fetchKoordinatFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final urls = [
      'https://prohildlhcilegon.id/api/pengangkutan-sampah-liar/history/by-petugas/$userId/proses',
      'https://prohildlhcilegon.id/api/pengangkutan-sampah-liar/history/by-petugas/$userId/pending',
      'https://prohildlhcilegon.id/api/pengangkutan-sampah/history/by-petugas/$userId/proses',
      'https://prohildlhcilegon.id/api/pengangkutan-sampah/history/by-petugas/$userId/pending',
    ];

    List<String> result = [];

    for (final url in urls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final dataList = decoded['data'];

          if (dataList is List) {
            for (final item in dataList) {
              final kordinatValue =
                  item['kordinat'] ?? item['alamat']?['kordinat'];

              if (kordinatValue is String && kordinatValue.contains('query=')) {
                result.add(kordinatValue);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error saat fetch dari API: $e');
      }
    }

    setState(() {
      koordinatList.clear();
      koordinatList.addAll(result);
    });

    await _generateRoute();
  }

  double calculateDistanceInKm(LatLng start, LatLng end) {
    const earthRadius = 6371.0; // in km

    final dLat = (end.latitude - start.latitude) * (3.1415926 / 180);
    final dLng = (end.longitude - start.longitude) * (3.1415926 / 180);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(start.latitude * (3.1415926 / 180)) *
            cos(end.latitude * (3.1415926 / 180)) *
            (sin(dLng / 2) * sin(dLng / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  Future<void> _generateRoute() async {
    const double maxDistanceInKm = 10.0; // Radius maksimal

    // Menyaring koordinat yang berada dalam radius yang ditentukan
    final destinations = koordinatList
        .map(_extractLatLng)
        .whereType<LatLng>()
        .where((point) =>
            calculateDistanceInKm(tpaLocation, point) <= maxDistanceInKm)
        .toList();

    if (destinations.isEmpty) {
      debugPrint('Tidak ada koordinat dalam radius $maxDistanceInKm km');
      return;
    }

    // Menggabungkan TPA dan semua titik tujuan
    final allPoints = [tpaLocation, ...destinations];

    // Menggabungkan koordinat semua titik menjadi satu string
    final coordsStr =
        allPoints.map((p) => '${p.longitude},${p.latitude}').join(';');

    // Permintaan ke OSRM Trip API dengan banyak titik
    final url =
        'http://router.project-osrm.org/trip/v1/driving/$coordsStr?geometries=geojson&roundtrip=false&source=first&destination=last';

    print('URL: $url'); // Debug URL

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['trips'][0]['geometry']['coordinates'] as List;

      final points = coords.map((c) => LatLng(c[1], c[0])).toList();

      setState(() {
        routePoints = points;
      });
    } else {
      debugPrint('Gagal ambil rute: ${response.statusCode}');
    }
  }

  LatLng? _extractLatLng(String url) {
    try {
      final uri = Uri.parse(url);
      final query = uri.queryParameters['query'];
      if (query == null) throw Exception("Query not found");

      final parts = query.split(',');
      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);

      if (lat == 0.0 && lng == 0.0) return null;
      return LatLng(lat, lng);
    } catch (e) {
      debugPrint('Error extracting LatLng: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Laporan Sampah')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: tpaLocation,
              zoom: 14,
              minZoom: 5,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: tpaLocation,
                    child: const Icon(Icons.location_on, color: Colors.blue),
                  ),
                  ...koordinatList
                      .map((url) => _extractLatLng(url))
                      .where((latLng) => latLng != null)
                      .map((latLng) => Marker(
                            width: 40,
                            height: 40,
                            point: latLng!,
                            child: const Icon(Icons.location_on,
                                color: Colors.red),
                          )),
                ],
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: Colors.green,
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 80,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoomIn",
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.center, newZoom);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoomOut",
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.center, newZoom);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

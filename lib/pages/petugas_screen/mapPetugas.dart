import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class mapPetugas extends StatefulWidget {
  const mapPetugas({super.key});

  @override
  State<mapPetugas> createState() => _mapPetugasState();
}

class _mapPetugasState extends State<mapPetugas> {
  LatLng? currentPosition;
  List<LatLng> routePoints = [];
  double _zoomLevel = 14;

  List<String> koordinatList = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchData();
  }



  Future<void> _loadUserAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    setState(() {
      currentPosition = const LatLng(-7.000468646396472, 113.85141955621073);
    });

    await _fetchKoordinatFromApi(userId);

    if (koordinatList.isNotEmpty) {
      await _generateRoute();
    }
  }

  Future<void> _fetchKoordinatFromApi(int userId) async {
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
              final dynamic kordinatValue =
                  item['kordinat'] ?? item['alamat']?['kordinat'];

              if (kordinatValue is String && kordinatValue.contains('query=')) {
                result.add(kordinatValue);
              }
            }
          } else {
            debugPrint('Respons tidak mengandung daftar data: $dataList');
          }
        } else {
          debugPrint('Gagal fetch dari $url: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error saat fetch dari API $url: $e');
      }
    }

    setState(() {
      koordinatList.clear();
      koordinatList.addAll(result);
    });
    debugPrint('Hasil koordinatList: $koordinatList');
  }

  Future<void> _generateRoute() async {
    if (currentPosition == null || koordinatList.isEmpty) return;

    final destinations =
        koordinatList.map(_extractLatLng).whereType<LatLng>().toList();

    final allPoints = [currentPosition!, ...destinations];

    final coordsStr =
        allPoints.map((p) => '${p.longitude},${p.latitude}').join(';');

    final url =
        'http://router.project-osrm.org/trip/v1/driving/$coordsStr?geometries=geojson';

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
    if (currentPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Peta Laporan Sampah')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: currentPosition,
              zoom: _zoomLevel,
              minZoom: 5,
              maxZoom: 19,
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  _zoomLevel =
                      position.zoom ?? 14.0; // Fallback to 14.0 if zoom is null
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              if (_zoomLevel < 16) // Show clusters when zoom is low
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 120,
                    size: const Size(40, 40),
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: currentPosition!,
                        child:
                            const Icon(Icons.my_location, color: Colors.blue),
                      ),
                      ...koordinatList.map((url) {
                        final latLng = _extractLatLng(url);
                        if (latLng == null) {
                          return null; // Skip if latLng is null
                        }
                        return Marker(
                          width: 40,
                          height: 40,
                          point: latLng,
                          child: GestureDetector(
                            onTap: () {
                              _showDetail(latLng);
                            },
                            child: const Icon(Icons.location_on,
                                color: Colors.red),
                          ),
                        );
                      }).whereType<
                          Marker>(), // Ensure we only get valid markers
                    ],
                    onClusterTap: (cluster) {
                      // Ambil semua koordinat marker dalam cluster
                      List<LatLng> coordinates =
                          cluster.markers.map((m) => m.point).toList();

                      // Hitung rata-rata lat dan lng untuk mendapatkan center
                      final avgLat = coordinates
                              .map((c) => c.latitude)
                              .reduce((a, b) => a + b) /
                          coordinates.length;
                      final avgLng = coordinates
                              .map((c) => c.longitude)
                              .reduce((a, b) => a + b) /
                          coordinates.length;

                      final clusterCenter = LatLng(avgLat, avgLng);

                      const double targetZoom = 16.0;

                      // Pindah ke center cluster dengan zoom yang diinginkan
                      _mapController.move(clusterCenter, targetZoom);

                      setState(() {
                        _zoomLevel = targetZoom;
                      });
                    },
                    builder: (context, markers) {
                      return Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${markers.length}',
                            style: const TextStyle(color: Colors.white)),
                      );
                    },
                  ),
                )
              else // Show individual markers when zoom is high
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: currentPosition!,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                    ...koordinatList
                        .map((url) => _extractLatLng(url))
                        .where((latLng) => latLng != null)
                        .map((latLng) => Marker(
                              width: 40,
                              height: 40,
                              point: latLng!,
                              child: GestureDetector(
                                onTap: () {
                                  _showDetail(latLng);
                                },
                                child: const Icon(Icons.location_on,
                                    color: Colors.red),
                              ),
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
              // Layer dari GeoJSON
              // MarkerLayer(markers: geoJsonParser.markers),
              // PolylineLayer(polylines: geoJsonParser.polylines),
              // PolygonLayer(polygons: geoJsonParser.polygons),
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

  void _showDetail(LatLng location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar modal bisa disesuaikan ukurannya
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Detail
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  'Detail Lokasi Sampah',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Konten Detail
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Latitude: ${location.latitude}, Longitude: ${location.longitude}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tombol Aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Open in Google Maps
                      final url =
                          'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
                      launch(url);
                    },
                    child: const Text('Cek Lokasi'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Chat on WhatsApp
                      const whatsappUrl =
                          'https://wa.me/+6281234567890'; // Replace with actual phone number
                      launch(whatsappUrl);
                    },
                    child: const Text('Chat via WhatsApp'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

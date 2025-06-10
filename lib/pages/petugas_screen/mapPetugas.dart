import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class mapPetugas extends StatefulWidget {
  const mapPetugas({super.key});

  @override
  State<mapPetugas> createState() => _mapPetugasState();
}

class _mapPetugasState extends State<mapPetugas> {
  LatLng? currentPosition;
  List<LatLng> routePoints = [];
  double _zoomLevel = 14;
  final LatLng lokasiTPA =
      const LatLng(-7.000468646396472, 113.85141955621073); // Lokasi TPA

  List<Map<String, dynamic>> koordinatList = [];

  final MapController _mapController = MapController();

  late StreamSubscription<Position> positionStream;

  List<int> _estimatedTime = [];

  @override
  void initState() {
    super.initState();
    _startLocationTimer();
    _loadUserAndFetchData();
  }

  @override
  void dispose() {
    _locationTimer?.cancel(); // jangan lupa matikan timer
    super.dispose();
  }

  Future<void> _loadUserAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });

    await _fetchKoordinatFromApi(userId);

    if (koordinatList.isNotEmpty) {
      await _generateRoute();
    }
  }

  double calculateDistanceInKm(LatLng point1, LatLng point2) {
    const earthRadius = 6371.0; // Radius bumi dalam km
    final dLat =
        (point2.latitude - point1.latitude) * (3.141592653589793 / 180);
    final dLng =
        (point2.longitude - point1.longitude) * (3.141592653589793 / 180);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(point1.latitude * (3.141592653589793 / 180)) *
            cos(point2.latitude * (3.141592653589793 / 180)) *
            (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = earthRadius * c; // Hasil dalam km
    return distance;
  }

Future<void> _fetchKoordinatFromApi(int userId) async {
  final urls = [
    '$baseipapi/api/pengangkutan-sampah-liar/history/by-petugas/$userId/proses',
    '$baseipapi/api/pengangkutan-sampah-liar/history/by-petugas/$userId/pending',
    '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/proses',
    '$baseipapi/api/pengangkutan-sampah/history/by-petugas/$userId/pending',
  ];

  List<Map<String, dynamic>> result = [];

  for (final url in urls) {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dataList = decoded['data'];

        String jenisSampah = '';
        if (url.contains('sampah-liar')) {
          jenisSampah = 'Sampah Liar';
        } else if (url.contains('pengangkutan-sampah')) {
          jenisSampah = 'Sampah Daur Ulang';
        }

        if (dataList is List) {
          for (final item in dataList) {
            String? kordinatValue;

            if (item['kordinat'] != null && item['kordinat'].toString().contains('query=')) {
              kordinatValue = item['kordinat'];
            } else if (item['alamat'] != null &&
                       item['alamat']['kordinat'] != null) {
              kordinatValue = item['alamat']['kordinat'];
            } else if (item['warga'] != null &&
                       item['warga']['alamat'] is List &&
                       item['warga']['alamat'].isNotEmpty &&
                       item['warga']['alamat'][0]['kordinat'] != null) {
              kordinatValue = item['warga']['alamat'][0]['kordinat'];
            }

            if (kordinatValue != null && kordinatValue.contains('query=')) {
              result.add({
                'kordinat': kordinatValue,
                'jenis_sampah': jenisSampah,
              });
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
  if (currentPosition == null || koordinatList.isEmpty || lokasiTPA == null) {
    debugPrint("Posisi awal, daftar koordinat, atau TPA tidak valid.");
    return;
  }

  const double maxDistanceInKm = 10.0;

  final destinations = koordinatList
      .map(_extractLatLngFromMap)
      .whereType<LatLng>()
      .where((point) =>
          calculateDistanceInKm(currentPosition!, point) <= maxDistanceInKm)
      .toList();

  final allPoints = [
    currentPosition!,
    ...destinations,
    lokasiTPA,
  ];

  final jsonPoints = allPoints
      .map((p) => {'lat': p.latitude, 'lng': p.longitude})
      .toList();

  final url = Uri.parse('http://192.168.1.18:5000/trip');
  debugPrint('🔄 Mengirim ke API lokal: $url');
  debugPrint('🧭 Koordinat dikirim: $jsonPoints');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'coordinates': jsonPoints}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['route'] as List;

      final points = coords
          .map<LatLng>((c) => LatLng(c[0].toDouble(), c[1].toDouble())) // ✅ FIXED
          .toList();

      setState(() {
        routePoints = points;
      });

      print("✅ Rute diterima: $routePoints");

      List<int> estimatedTimes = [];
      for (int i = 0; i < points.length - 1; i++) {
        final distance = calculateDistanceInKm(points[i], points[i + 1]);
        final duration = (distance / 50) * 60;
        estimatedTimes.add(duration <= 0 ? 1 : duration.toInt());
      }

      setState(() {
        _estimatedTime = estimatedTimes;
      });

      print("🕒 Estimasi waktu: $estimatedTimes");
    } else {
      debugPrint('❌ Gagal ambil rute dari API lokal: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ Error saat ambil rute dari API lokal: $e');
  }
}

  Timer? _locationTimer;

  void _startLocationTimer() {
    _locationTimer?.cancel(); // pastikan tidak dobel timer

    if (!mounted) return;
    setState(() {
      // perubahan state
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Opsional: tambahkan filter jarak minimal untuk update (hemat redraw)
        const double minDistanceToUpdate = 10.0; // meter

        final distance = currentPosition == null
            ? double.infinity
            : Geolocator.distanceBetween(
                currentPosition!.latitude,
                currentPosition!.longitude,
                position.latitude,
                position.longitude,
              );

        if (distance > minDistanceToUpdate) {
          setState(() {
            currentPosition = LatLng(position.latitude, position.longitude);
          });

          await _generateRoute(); // hanya dijalankan jika lokasi berubah cukup jauh
        }
      } catch (e) {
        debugPrint('Gagal mendapatkan lokasi: $e');
      }
    });
  }

  LatLng? _extractLatLngFromMap(Map<String, dynamic> item) {
    final url = item['kordinat'];
    if (url is! String || !url.contains('query=')) return null;
    return _extractLatLng(url);
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
                  _zoomLevel = position.zoom ?? 14.0;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              // Gunakan ternary operator untuk if-else MarkerLayer
              _zoomLevel < 16
                  ? MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 120,
                        size: const Size(40, 40),
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: lokasiTPA,
                            child: const FaIcon(
                              FontAwesomeIcons.dumpster,
                              color: Colors.brown,
                              size: 30,
                            ),
                          ),
                          ...koordinatList.map((item) {
                            final url = item['kordinat'];
                            if (url is! String) return null;

                            final latLng = _extractLatLng(url);
                            if (latLng == null) return null;

                            return Marker(
                              width: 40,
                              height: 40,
                              point: latLng,
                              child: GestureDetector(
                                onTap: () => _showDetail(latLng),
                                child: const Icon(Icons.location_on,
                                    color: Colors.red),
                              ),
                            );
                          }).whereType<Marker>(),
                        ],
                        onClusterTap: (cluster) {
                          List<LatLng> coordinates =
                              cluster.markers.map((m) => m.point).toList();

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
                            child: Text(
                              '${markers.length}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    )
                  : MarkerLayer(
                      markers: [
                        // Marker untuk posisi petugas (currentPosition)
                        Marker(
                          width: 40,
                          height: 40,
                          point: currentPosition!,
                          child:
                              const Icon(Icons.my_location, color: Colors.blue),
                        ),

                        // Menambahkan markers untuk setiap koordinat yang berhasil diekstrak
                        ...koordinatList
                            .asMap()
                            .map((index, data) {
                              final latLng = _extractLatLngFromMap(data);
                              if (latLng == null) return MapEntry(index, null);

                              // Jika ini adalah marker pertama, beri warna biru
                              final color =
                                  index == 0 ? Colors.blue : Colors.red;

                              return MapEntry(
                                index,
                                Marker(
                                  width: 40,
                                  height: 40,
                                  point: latLng,
                                  child: GestureDetector(
                                    onTap: () => _showDetail(latLng),
                                    child:
                                        Icon(Icons.location_on, color: color),
                                  ),
                                ),
                              );
                            })
                            .values
                            .whereType<Marker>(),

                        // Marker untuk lokasi TPA (lokasiTPA)
                        Marker(
                          width: 40,
                          height: 40,
                          point: lokasiTPA,
                          child: const FaIcon(
                            FontAwesomeIcons.dumpster,
                            color: Colors.brown,
                            size: 30,
                          ),
                        ),
                      ],
                    ),

              // Tambahkan marker posisi petugas secara permanen

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
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: currentPosition!,
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
                  )
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

  void _showDetail(LatLng location) {
    // Cari data yang cocok dari koordinatList
    final matchedData = koordinatList.firstWhere(
      (item) {
        final point = _extractLatLngFromMap(item);
        return point?.latitude == location.latitude &&
            point?.longitude == location.longitude;
      },
      orElse: () => {},
    );

    final jenisSampah = matchedData['jenis_sampah'] ?? 'Tidak diketahui';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Jenis Sampah: $jenisSampah',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      const whatsappUrl =
                          'https://wa.me/+6281234567890'; // Ganti dengan nomor WA asli
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

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
import 'package:dlh_project/pages/petugas_screen/detail_daur_ulang.dart';
import 'package:dlh_project/pages/petugas_screen/detail_liar.dart';
import 'package:dlh_project/pages/petugas_screen/sampah.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class mapPetugas extends StatefulWidget {
  const mapPetugas({super.key});

  @override
  State<mapPetugas> createState() => _mapPetugasState();
}

class LocationData {
  final LatLng position;
  final String jenisSampah;
  final int itemId;
  final String status;
  final double distance;
  final int estimatedTime;
  final Map<String, dynamic>
      originalData; // TAMBAHKAN INI untuk menyimpan data original

  LocationData({
    required this.position,
    required this.jenisSampah,
    required this.itemId,
    required this.status,
    required this.distance,
    required this.estimatedTime,
    required this.originalData, // TAMBAHKAN INI
  });
}

class _mapPetugasState extends State<mapPetugas> {
  LatLng? currentPosition;
  List<LatLng> routePoints = [];
  double _zoomLevel = 14;
  final LatLng lokasiTPA = const LatLng(-7.000468646396472, 113.85141955621073);

  List<Map<String, dynamic>> koordinatList = [];
  List<LocationData> processedLocations = [];
  LocationData? nearestLocation;

  final MapController _mapController = MapController();
  Timer? _locationTimer;
  bool _showDistanceInfo = true;

  bool _showBottomSheet = true; // Tetap ada
  double _bottomSheetHeight = 280.0; // tinggi default
  final double _minBottomSheetHeight = 60.0; // tinggi minimum (hanya handle)
  final double _maxBottomSheetHeight = 280.0; // tinggi maksimum

  @override
  void initState() {
    super.initState();
    _startLocationTimer();
    _loadUserAndFetchData();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
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
    await _processLocationData();

    if (koordinatList.isNotEmpty) {
      await _generateRoute();
    }
  }

  Future<void> _processLocationData() async {
    if (currentPosition == null) return;

    List<LocationData> locations = [];

    for (var item in koordinatList) {
      final latLng = _extractLatLngFromMap(item);
      if (latLng != null) {
        final distance = calculateDistanceInKm(currentPosition!, latLng);
        final estimatedTime = _calculateEstimatedTime(distance);

        locations.add(LocationData(
          position: latLng,
          jenisSampah: item['jenis_sampah'] ?? 'Tidak diketahui',
          itemId: item['item_id'] ?? 0,
          status: item['status'] ?? 'unknown',
          distance: distance,
          estimatedTime: estimatedTime,
          originalData: item, // TAMBAHKAN INI untuk menyimpan data asli
        ));
      }
    }

    // Urutkan berdasarkan jarak
    locations.sort((a, b) => a.distance.compareTo(b.distance));

    setState(() {
      processedLocations = locations;
      nearestLocation = locations.isNotEmpty ? locations.first : null;
    });
  }

  int _calculateEstimatedTime(double distanceKm) {
    // Estimasi waktu berdasarkan kecepatan rata-rata 30 km/jam di dalam kota
    final timeInHours = distanceKm / 30.0;
    final timeInMinutes = (timeInHours * 60).round();
    return timeInMinutes < 1 ? 1 : timeInMinutes;
  }

  double calculateDistanceInKm(LatLng point1, LatLng point2) {
    const earthRadius = 6371.0;
    final dLat =
        (point2.latitude - point1.latitude) * (3.141592653589793 / 180);
    final dLng =
        (point2.longitude - point1.longitude) * (3.141592653589793 / 180);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(point1.latitude * (3.141592653589793 / 180)) *
            cos(point2.latitude * (3.141592653589793 / 180)) *
            (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = earthRadius * c;
    return distance;
  }

  Color _getMarkerColor(LocationData location) {
    if (nearestLocation != null &&
        location.position.latitude == nearestLocation!.position.latitude &&
        location.position.longitude == nearestLocation!.position.longitude) {
      return Colors.green; // Terdekat = hijau
    } else if (location.distance <= 2.0) {
      return Colors.orange; // Dekat (≤2km) = orange
    } else if (location.distance <= 5.0) {
      return Colors.red; // Sedang (≤5km) = merah
    } else {
      return Colors.grey; // Jauh (>5km) = abu-abu
    }
  }

  IconData _getMarkerIcon(String jenisSampah) {
    if (jenisSampah.contains('Liar')) {
      return Icons.delete_forever;
    } else if (jenisSampah.contains('Daur Ulang')) {
      return Icons.recycling;
    }
    return Icons.location_on;
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes menit';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
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
              String? koordinat;

              if (item['kordinat'] != null && item['kordinat'] is String) {
                koordinat = item['kordinat'];
              } else if (item['alamat'] != null &&
                  item['alamat']['kordinat'] != null) {
                koordinat = item['alamat']['kordinat'];
              } else if (item['warga'] != null &&
                  item['warga']['alamat'] != null) {
                final alamatList = item['warga']['alamat'];
                if (alamatList is List && alamatList.isNotEmpty) {
                  for (final alamat in alamatList) {
                    if (alamat['kordinat'] != null &&
                        alamat['kordinat'] is String) {
                      koordinat = alamat['kordinat'];
                      break;
                    }
                  }
                }
              }

              if (koordinat != null && koordinat.contains('query=')) {
                // TAMBAHKAN SEMUA DATA YANG DIPERLUKAN
                result.add({
                  'kordinat': koordinat,
                  'jenis_sampah': jenisSampah,
                  'item_id': item['id'],
                  'status': item['status'],
                  'full_data': item, // SIMPAN SEMUA DATA ASLI
                  'api_source': url, // UNTUK TAHU DARI API MANA
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error saat fetch dari API $url: $e');
      }
    }

    setState(() {
      koordinatList.clear();
      koordinatList.addAll(result);
    });
  }

  Future<void> _generateRoute() async {
    if (currentPosition == null || lokasiTPA == null) {
      debugPrint("Posisi awal atau TPA tidak valid.");
      return;
    }

    const double maxDistanceInKm = 10.0;

    final destinations = koordinatList
        .map(_extractLatLngFromMap)
        .whereType<LatLng>()
        .where((point) =>
            calculateDistanceInKm(currentPosition!, point) <= maxDistanceInKm)
        .toList();

    if (destinations.isEmpty) {
      final url =
          'http://router.project-osrm.org/route/v1/driving/${currentPosition!.longitude},${currentPosition!.latitude};${lokasiTPA.longitude},${lokasiTPA.latitude}?overview=full&geometries=geojson';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final coords = data['routes'][0]['geometry']['coordinates'] as List;

          setState(() {
            routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
          });
        }
      } catch (e) {
        debugPrint('Error ambil rute langsung ke TPA: $e');
      }
      return;
    }

    final allPoints = [
      currentPosition!,
      ...destinations,
      lokasiTPA,
    ];

    final coordsStr =
        allPoints.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url = 'http://router.project-osrm.org/trip/v1/driving/$coordsStr'
        '?geometries=geojson&roundtrip=false&source=first&destination=last';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final trips = data['trips'];
        if (trips != null && trips.isNotEmpty) {
          final coords = trips[0]['geometry']['coordinates'] as List;
          final points = coords.map((c) => LatLng(c[1], c[0])).toList();

          setState(() {
            routePoints = points;
          });
        }
      }
    } catch (e) {
      debugPrint('Error ambil rute: $e');
    }
  }

  void _startLocationTimer() {
    _locationTimer?.cancel();

    if (!mounted) return;

    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        const double minDistanceToUpdate = 10.0;

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

          await _processLocationData();
          await _generateRoute();
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

  void _navigateToDetailPage(LocationData location) {
    final fullData = location.originalData['full_data'];

    if (location.jenisSampah.contains('Daur Ulang')) {
      // Untuk sampah daur ulang, convert ke SampahData
      try {
        final sampahData = SampahData.fromJson(fullData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailSampahDaurUlangPage(sampah: sampahData),
          ),
        );
      } catch (e) {
        debugPrint('Error parsing SampahData: $e');
        _showErrorSnackBar('Gagal memuat detail laporan sampah daur ulang');
      }
    } else if (location.jenisSampah.contains('Liar')) {
      // Untuk sampah liar, convert ke SampahLiarData
      try {
        final sampahLiarData = SampahLiarData.fromJson(fullData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailSampahLiarPage(sampah: sampahLiarData),
          ),
        );
      } catch (e) {
        debugPrint('Error parsing SampahLiarData: $e');
        _showErrorSnackBar('Gagal memuat detail laporan sampah liar');
      }
    } else {
      _showErrorSnackBar('Jenis sampah tidak dikenali');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDetail(LocationData location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Icon(
                    _getMarkerIcon(location.jenisSampah),
                    color: _getMarkerColor(location),
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detail Lokasi Sampah',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                  Icons.category, 'Jenis Sampah', location.jenisSampah),
              _buildDetailRow(Icons.straighten, 'Jarak',
                  _formatDistance(location.distance)),
              _buildDetailRow(Icons.access_time, 'Estimasi Waktu',
                  _formatTime(location.estimatedTime)),
              _buildDetailRow(Icons.info, 'Status', location.status),
              const SizedBox(height: 20),

              // GANTI BAGIAN TOMBOL DENGAN YANG BARU
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _mapController.move(location.position, 18.0);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Tutup modal dulu
                        _navigateToDetailPage(location);
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Detail Laporan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan statistik singkat
  Widget _buildStatsCard() {
    return Positioned(
      top: 50,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 16),
            const SizedBox(width: 4),
            Text(
              '${processedLocations.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Replace your _buildEnhancedLocationsList method with this improved version

  Widget _buildEnhancedLocationsList() {
    return Container(
      height: _maxBottomSheetHeight, // Langsung maksimum, tidak ada animasi
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header area (tidak bisa di-tap lagi)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Daftar Lokasi (${processedLocations.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Terurut jarak',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Legend
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildEnhancedLegendItem(Colors.green, Icons.star, 'Terdekat'),
                const SizedBox(width: 8),
                _buildEnhancedLegendItem(Colors.orange, Icons.near_me, '< 2km'),
                const SizedBox(width: 8),
                _buildEnhancedLegendItem(
                    Colors.red, Icons.location_on, '< 5km'),
                const SizedBox(width: 8),
                _buildEnhancedLegendItem(
                    Colors.grey, Icons.location_off, '> 5km'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List
          Flexible(
            child: processedLocations.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Tidak ada lokasi tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: processedLocations.length,
                    itemBuilder: (context, index) {
                      final location = processedLocations[index];
                      final isNearest = index == 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: isNearest
                              ? LinearGradient(
                                  colors: [
                                    Colors.green.shade50,
                                    Colors.green.shade100
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isNearest ? null : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isNearest ? Colors.green : Colors.grey.shade300,
                            width: isNearest ? 2 : 1,
                          ),
                          boxShadow: [
                            if (isNearest)
                              BoxShadow(
                                color: Colors.green.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _mapController.move(location.position, 18.0);
                              _showDetail(location);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _getMarkerColor(location)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getMarkerIcon(location.jenisSampah),
                                      color: _getMarkerColor(location),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                location.jenisSampah,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isNearest
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ),
                                            if (isNearest)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'TERDEKAT',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.straighten,
                                                        size: 14,
                                                        color: Colors.blue),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatDistance(
                                                          location.distance),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                        Icons.access_time,
                                                        size: 14,
                                                        color: Colors.orange),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatTime(location
                                                          .estimatedTime),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.orange,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Colors.grey.shade400,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTPADetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.recycling,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tempat Pemrosesan Akhir (TPA)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.location_on, 'Lokasi', 'TPA Kota'),
              _buildDetailRow(Icons.info, 'Status', 'Aktif'),
              _buildDetailRow(
                  Icons.schedule, 'Jam Operasional', '06:00 - 18:00'),
              if (currentPosition != null)
                _buildDetailRow(
                    Icons.straighten,
                    'Jarak dari lokasi Anda',
                    _formatDistance(
                        calculateDistanceInKm(currentPosition!, lokasiTPA))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _mapController.move(lokasiTPA, 18.0);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigasi ke TPA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedLegendItem(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Update method untuk build dengan tampilan yang lebih baik
  @override
// Replace your build method with this improved version

  @override
  Widget build(BuildContext context) {
    if (currentPosition == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade600],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Memuat lokasi...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Peta Laporan Sampah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadUserAndFetchData();
            },
          ),
        ],
      ),
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
              _zoomLevel < 16
                  ? MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 120,
                        size: const Size(40, 40),
                        markers: [
                          Marker(
                            width: 60,
                            height: 60,
                            point: lokasiTPA,
                            child: GestureDetector(
                              onTap: () => _showTPADetail(),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow effect
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Main container
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade400,
                                          Colors.green.shade700
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.recycling,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  // Label badge
                                  Positioned(
                                    bottom: -5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade800,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white, width: 1),
                                      ),
                                      child: const Text(
                                        'TPA',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ...processedLocations.map((location) {
                            return Marker(
                              width: 40,
                              height: 40,
                              point: location.position,
                              child: GestureDetector(
                                onTap: () => _showDetail(location),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getMarkerColor(location)
                                            .withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _getMarkerIcon(location.jenisSampah),
                                    color: _getMarkerColor(location),
                                    size: 30,
                                  ),
                                ),
                              ),
                            );
                          }),
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
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade300,
                                  Colors.orange.shade600
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${markers.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : MarkerLayer(
                      markers: [
                        ...processedLocations.map((location) {
                          return Marker(
                            width: 40,
                            height: 40,
                            point: location.position,
                            child: GestureDetector(
                              onTap: () => _showDetail(location),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getMarkerColor(location)
                                          .withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getMarkerIcon(location.jenisSampah),
                                  color: _getMarkerColor(location),
                                  size: 30,
                                ),
                              ),
                            ),
                          );
                        }),
                        Marker(
                          width: 60,
                          height: 60,
                          point: lokasiTPA,
                          child: GestureDetector(
                            onTap: () => _showTPADetail(),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer glow effect
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                // Main container
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.shade400,
                                        Colors.green.shade700
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.recycling,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                // Label badge
                                Positioned(
                                  bottom: -5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade800,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white, width: 1),
                                    ),
                                    child: const Text(
                                      'TPA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5.0,
                      color: Colors.green,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 50,
                    height: 50,
                    point: currentPosition!,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.blue, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
          _buildStatsCard(),
          // Replace the floating action buttons section in your build method

          Positioned(
            bottom: _showBottomSheet ? _maxBottomSheetHeight + 20 : 20,
            right: 16,
            child: Column(
              children: [
                // HANYA tombol list untuk show/hide, langsung maksimum saat dibuka
                FloatingActionButton(
                  mini: true,
                  heroTag: "toggleBottomSheet",
                  backgroundColor:
                      _showBottomSheet ? Colors.orange : Colors.white,
                  onPressed: () {
                    setState(() {
                      _showBottomSheet = !_showBottomSheet;
                    });
                  },
                  child: Icon(
                    Icons.list,
                    color: _showBottomSheet ? Colors.white : Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoomIn",
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.center, newZoom);
                  },
                  child: const Icon(Icons.add, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoomOut",
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.center, newZoom);
                  },
                  child: const Icon(Icons.remove, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: "myLocation",
                  backgroundColor: Colors.blue,
                  onPressed: () {
                    if (currentPosition != null) {
                      _mapController.move(currentPosition!, 16.0);
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: (processedLocations.isNotEmpty && _showBottomSheet)
          ? _buildEnhancedLocationsList()
          : null,
    );
  }
}

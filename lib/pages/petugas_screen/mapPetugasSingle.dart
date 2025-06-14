import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void startLiveTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      final newPetugasPosition = LatLng(position.latitude, position.longitude);

      // Tunggu 10 detik sebelum update
      await Future.delayed(const Duration(seconds: 10));

      if (sampahPosition != null) {
        final newRoute = await generateRoute(newPetugasPosition, sampahPosition!);

        setState(() {
          petugasPosition = newPetugasPosition;
          routePoints = newRoute;
        });
      }
    });
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
      await _getCurrentLocation(); // posisi awal petugas
      _extractSampahPosition();    // posisi sampah

      if (petugasPosition != null && sampahPosition != null) {
        final initialRoute = await generateRoute(petugasPosition!, sampahPosition!);

        setState(() {
          routePoints = initialRoute;
          isLoading = false;
        });

        startLiveTracking(); // mulai update posisi + rute setiap 10 detik
      } else {
        setState(() => isLoading = false);
      }
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

  Future<List<LatLng>> generateRoute(LatLng start, LatLng end) async {
    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;

        return coords.map((point) => LatLng(point[1], point[0])).toList();
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Routing error: $e');
      return [];
    }
  }

  // Method to get marker icon based on sampah type
  IconData _getMarkerIcon() {
    if (widget.isDaurUlang) {
      return Icons.recycling;
    } else {
      return Icons.delete_forever;
    }
  }

  // Method to get marker color
  Color _getMarkerColor() {
    return Colors.red; // For single location, use red as default
  }

  // Method to center map to show both markers
  void _centerMapToBothMarkers() {
    if (petugasPosition != null && sampahPosition != null) {
      // Calculate bounds to include both markers
      double minLat = petugasPosition!.latitude < sampahPosition!.latitude 
          ? petugasPosition!.latitude : sampahPosition!.latitude;
      double maxLat = petugasPosition!.latitude > sampahPosition!.latitude 
          ? petugasPosition!.latitude : sampahPosition!.latitude;
      double minLng = petugasPosition!.longitude < sampahPosition!.longitude 
          ? petugasPosition!.longitude : sampahPosition!.longitude;
      double maxLng = petugasPosition!.longitude > sampahPosition!.longitude 
          ? petugasPosition!.longitude : sampahPosition!.longitude;
      
      // Add some padding
      double latPadding = (maxLat - minLat) * 0.2;
      double lngPadding = (maxLng - minLng) * 0.2;
      
      // Calculate center point
      LatLng center = LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      );
      
      // Calculate appropriate zoom level based on distance
      double distance = Geolocator.distanceBetween(
        petugasPosition!.latitude,
        petugasPosition!.longitude,
        sampahPosition!.latitude,
        sampahPosition!.longitude,
      );
      
      double zoom = 15.0;
      if (distance > 5000) zoom = 12.0;
      else if (distance > 2000) zoom = 13.0;
      else if (distance > 1000) zoom = 14.0;
      
      _mapController.move(center, zoom);
    }
  }

  // Widget for control buttons
  Widget _buildControlButtons() {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: "centerBoth",
            backgroundColor: Colors.white,
            onPressed: _centerMapToBothMarkers,
            child: const Icon(Icons.center_focus_strong, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            heroTag: "centerPetugas",
            backgroundColor: Colors.blue,
            onPressed: () {
              if (petugasPosition != null) {
                _mapController.move(petugasPosition!, 16.0);
              }
            },
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            heroTag: "centerSampah",
            backgroundColor: Colors.red,
            onPressed: () {
              if (sampahPosition != null) {
                _mapController.move(sampahPosition!, 16.0);
              }
            },
            child: const Icon(Icons.location_pin, color: Colors.white),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Peta ${widget.isDaurUlang ? 'Sampah Daur Ulang' : 'Sampah Liar'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildMapContent(),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    if (isLoading) {
      return Container(
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
                'Memuat peta...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = '';
                });
                _initializeMap();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    
    if (sampahPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Lokasi sampah tidak valid',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: sampahPosition,
        zoom: 15,
        minZoom: 5,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
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
            // Petugas marker - improved style like in main map
            if (petugasPosition != null)
              Marker(
                width: 50,
                height: 50,
                point: petugasPosition!,
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
              ),
            // Sampah marker - improved style like in main map
            if (sampahPosition != null)
              Marker(
                width: 50,
                height: 50,
                point: sampahPosition!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getMarkerColor().withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getMarkerIcon(),
                    color: _getMarkerColor(),
                    size: 35,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Correct import
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_animate/flutter_animate.dart';

class TouchGrassScreen extends StatefulWidget {
  const TouchGrassScreen({super.key});

  @override
  State<TouchGrassScreen> createState() => _TouchGrassScreenState();
}

class _TouchGrassScreenState extends State<TouchGrassScreen> {
  // Default location: Samarinda, East Kalimantan (Center/Iconic)
  final LatLng _center = const LatLng(-0.502183, 117.153801);

  // Mock "Healing Spots" (Parks, Cafes)
  final List<Map<String, dynamic>> _healingSpots = [
    {
      'name': 'Taman Samarendah',
      'lat': -0.4948,
      'lng': 117.1436,
      'type': 'Park'
    },
    {
      'name': 'Mahakam Lampion Garden',
      'lat': -0.5065,
      'lng': 117.1332,
      'type': 'Park'
    },
    {
      'name': 'Coffe Toffee Samarinda',
      'lat': -0.4900,
      'lng': 117.1450,
      'type': 'Cafe'
    },
    {
      'name': 'Islamic Center Samarinda',
      'lat': -0.5042,
      'lng': 117.1246,
      'type': 'Religious'
    },
  ];

  Future<void> _launchGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal buka Maps, bro.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Touch Grass 🌱'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Cari spot ijo-ijo deket lo biar gak stress!')),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              // In older flutter_map versions 'center' might be required, check version
              // Assuming flutter_map ^6.0.0 or similar based on `flutter pub add`
              initialCenter: _center,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token={accessToken}',
                additionalOptions: {
                  'accessToken':
                      'pk.eyJ1Ijoia291c296byIsImEiOiJjbWRsOHk1anYxM29qMmpvbXg5Y3NrNDkwIn0.JgeP6F7f2UXRGOw303K7ew',
                },
                userAgentPackageName: 'com.burnoutbuster',
              ),
              MarkerLayer(
                markers: _healingSpots.map((spot) {
                  return Marker(
                    point: LatLng(spot['lat'], spot['lng']),
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => _buildSpotDetail(spot),
                        );
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 40,
                      )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: 1.seconds,
                            curve: Curves.easeInOut,
                          ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: const Color(0xFF1E293B).withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Healing Spots Samarinda',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Klik pin merah buat liat detail & navigasi.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotDetail(Map<String, dynamic> spot) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spot['name'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(spot['type']),
            backgroundColor: const Color(0xFF10B981),
            labelStyle: const TextStyle(color: Colors.black),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.heavyImpact();
                _launchGoogleMaps(spot['lat'], spot['lng']);
              },
              icon: const Icon(Icons.map),
              label: const Text('Navigasi ke Sini (GAds)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

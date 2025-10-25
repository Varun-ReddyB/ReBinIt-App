import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isMapView = true;
  bool _showOpenOnly = false;
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  LatLng _initialCenter = LatLng(17.385044, 78.486671);
  List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;

  // 🗺️ Replace this with your real OpenRouteService API key (for routing)
  static const String _apiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjE4YTRlY2QyZjk1NzQ0MWJiYzdlMjliMWFiNDE3ZTQ0IiwiaCI6Im11cm11cjY0In0=";

  // 🟩 Replace this with your MapTiler API key
  static const String _mapTilerKey = "DSCdNH9B1tGEUujqzGoV";

  final List<Map<String, dynamic>> _allCenters = [
    {
      "name": "Green Recycling Hub",
      "location": LatLng(17.385044, 78.486671),
      "waste": "Plastic, Paper",
      "status": "Open",
    },
    {
      "name": "Eco Waste Center",
      "location": LatLng(17.390000, 78.480000),
      "waste": "E-Waste, Metal",
      "status": "Closed",
    },
    {
      "name": "Smart Recycling Point",
      "location": LatLng(17.395000, 78.490000),
      "waste": "Glass, Plastic",
      "status": "Open",
    },
  ];

  List<Map<String, dynamic>> get _filteredCenters {
    if (_showOpenOnly) {
      return _allCenters.where((center) => center["status"] == "Open").toList();
    }
    return _allCenters;
  }

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _initialCenter = _userLocation!;
      });

      _mapController.move(_userLocation!, 13);

      // ✅ Live location updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
        });
      });
    } catch (e) {
      debugPrint("Error fetching location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching location: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Recycling Map", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() => _isMapView = !_isMapView);
            },
          ),
        ],
      ),
      body: _isMapView ? _buildMapView() : _buildListView(),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 13,
      ),
      children: [
        // 🗺️ MapTiler TileLayer
        TileLayer(
          urlTemplate:
              'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$_mapTilerKey',
          additionalOptions: {'key': _mapTilerKey},
          userAgentPackageName: 'com.example.rebinit_app',
          tileProvider: CancellableNetworkTileProvider(),
        ),

        // 🧍‍♂️ User + Center Markers
        MarkerLayer(
          markers: [
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.blue, size: 40),
              ),
            ..._filteredCenters.map((center) {
              return Marker(
                point: center["location"],
                child: GestureDetector(
                  onTap: () => _showCenterDetails(center),
                  child: Icon(
                    Icons.location_on,
                    color: center["status"] == "Open"
                        ? Colors.green
                        : Colors.red,
                    size: 40,
                  ),
                ),
              );
            }),
          ],
        ),

        // 🚗 Route Line
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 5,
                color: Colors.blue,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredCenters.length,
      itemBuilder: (context, index) {
        final center = _filteredCenters[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          child: ListTile(
            leading: Icon(
              Icons.location_on,
              color: center["status"] == "Open" ? Colors.green : Colors.red,
            ),
            title: Text(center["name"],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text("Waste: ${center["waste"]}\nStatus: ${center["status"]}"),
            trailing: IconButton(
              icon: const Icon(Icons.map, color: Colors.green),
              onPressed: () async {
                setState(() => _isMapView = true);
                _mapController.move(center["location"], 13);
              },
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Filter Recycling Centers",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("Show Open Only"),
                    const Spacer(),
                    Switch(
                      value: _showOpenOnly,
                      onChanged: (value) {
                        setState(() => _showOpenOnly = value);
                        this.setState(() {});
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Apply Filters"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCenterDetails(Map<String, dynamic> center) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(center["name"]),
        content: Text(
            "Waste Accepted: ${center["waste"]}\nStatus: ${center["status"]}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              await _getRoute(center["location"]);
            },
            child: const Text("Show Route"),
          ),
        ],
      ),
    );
  }

  Future<void> _getRoute(LatLng destination) async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User location not available.")),
      );
      return;
    }

    final url =
        Uri.parse("https://api.openrouteservice.org/v2/directions/driving-car");

    final body = jsonEncode({
      "coordinates": [
        [_userLocation!.longitude, _userLocation!.latitude],
        [destination.longitude, destination.latitude]
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": _apiKey,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["features"] != null && data["features"].isNotEmpty) {
          final coords =
              data["features"][0]["geometry"]["coordinates"] as List;
          setState(() {
            _routePoints =
                coords.map((c) => LatLng(c[1], c[0])).toList();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Route loaded successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No route data found.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed: ${response.statusCode} ${response.reasonPhrase}")),
        );
        debugPrint("Response: ${response.body}");
      }
    } catch (e, stack) {
      debugPrint("Error fetching route: $e");
      debugPrint("Stack trace: $stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching route: $e")),
      );
    }
  }
}

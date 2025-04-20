import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLatLng = LatLng(37.7749, -122.4194); // Default (San Francisco)
  String _threatStatus = "No status yet"; // Status received from backend
  final String _backendUrl = "https://your-backend.com/api/threat_status"; // Backend URL

  final List<String> _locations = [
    "Annangar", "Saidapet", "Egmore", "Koyambedu", "Kodambakkam", "Madhavaram",
    "Tambaram", "Triplicane", "Vepery", "Perambur", "Velachery", "Chengalpattu",
    "Arumbakkam", "Vadapalani", "Besant Nagar", "Nungambakkam", "Parktown", "Porur",
    "Sholinganallur", "Thiruvanmiyur", "Ashok Nagar", "Potheri", "T Nagar", "Avadi",
    "Ambattur", "Guindy", "Kilpauk", "Manali", "Adyar", "Teynampet", "Royapettah", "Mylapore"
  ];

  String? _fromLocation;
  String? _toLocation;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  /// Requests location permissions at runtime
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Location permissions are permanently denied.");
      return;
    }

    _getRealTimeLocation();
  }

  /// Fetches real-time user location and updates the marker.
  Future<void> _getRealTimeLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Enable location services.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentLatLng, 15.0);
    });

    // Listen for real-time location updates
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position newPosition) {
      setState(() {
        _currentLatLng = LatLng(newPosition.latitude, newPosition.longitude);
      });
    });
  }

  /// Moves the map and marker to the current location.
  Future<void> _moveToCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );
    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentLatLng, 15.0);
    });
  }

  /// Opens the travel dialog to select "From" and "To" locations.
  void _showTravelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you travelling?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // From dropdown
              DropdownButtonFormField<String>(
                value: _fromLocation,
                hint: Text("From"),
                items: _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _fromLocation = newValue;
                  });
                },
              ),
              SizedBox(height: 10),
              // To dropdown
              DropdownButtonFormField<String>(
                value: _toLocation,
                hint: Text("To"),
                items: _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _toLocation = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _checkThreatStatusForTravel();
                Navigator.pop(context);
              },
              child: Text("Check Threat Status"),
            ),
          ],
        );
      },
    );
  }

  /// Sends the selected locations to the backend for threat status.
  Future<void> _checkThreatStatusForTravel() async {
    if (_fromLocation == null || _toLocation == null) {
      _showSnackBar("Please select both From and To locations.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "from": _fromLocation,
          "to": _toLocation,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _threatStatus = responseData["status"] ?? "No status returned";
        });
      } else {
        _showSnackBar("Failed to fetch threat status.");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  /// Sends the pinned latitude/longitude to the backend.
  Future<void> _checkThreatStatus() async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "latitude": _currentLatLng.latitude,
          "longitude": _currentLatLng.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _threatStatus = responseData["status"] ?? "No status returned";
        });
      } else {
        _showSnackBar("Failed to fetch threat status.");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  /// Displays a snackbar message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // MAP SECTION
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLatLng,
                    initialZoom: 15,
                    onTap: (tapPosition, newLatLng) {
                      setState(() {
                        _currentLatLng = newLatLng;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLatLng,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),

                // "Are You Travelling?" Button (Top Right)
                Positioned(
                  top: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _showTravelDialog,
                    child: Text("Are You Travelling?"),
                  ),
                ),

                // FloatingActionButton for current location (Bottom Right)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _moveToCurrentLocation,
                    child: Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),

          // Display Lat/Long
          Text("Latitude: ${_currentLatLng.latitude}, Longitude: ${_currentLatLng.longitude}"),

          // Button to check threat status for pinned location
          ElevatedButton(
            onPressed: _checkThreatStatus,
            child: Text("Check Threat Status"),
          ),

          // Show threat status
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Threat Status: $_threatStatus",
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          )
        ],
      ),
    );
  }
}

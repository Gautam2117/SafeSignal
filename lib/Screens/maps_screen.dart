import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentPosition;
  List<Marker> _markers = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = position;
      _addUserLocationMarker();
      _fetchDisasterReports(); // Fetch disaster reports from Firestore
    });
  }

  void _addUserLocationMarker() {
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: Icon(
            Icons.location_pin,
            color: Colors.blueAccent,
            size: 40,
          ),
        ),
      );
    }
  }

  Future<void> _fetchDisasterReports() async {
    QuerySnapshot snapshot = await _firestore.collection('disaster_reports').get();
    Map<String, int> locationFrequency = {};

    // Process Firestore data and generate markers
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var location = data['location'];
      var latLng = await _getLatLngFromAddress(location);

      if (latLng != null) {
        String locationKey = "${latLng.latitude},${latLng.longitude}";
        locationFrequency[locationKey] = (locationFrequency[locationKey] ?? 0) + 1;

        // Check how many reports are within a 2-mile radius
        int nearbyReportCount = _countNearbyReports(latLng, locationFrequency);

        // Set the pin color based on report frequency
        Color markerColor = _getMarkerColor(nearbyReportCount);

        _markers.add(
          Marker(
            point: latLng,
            child: Icon(
              Icons.warning,
              color: markerColor,
              size: 40,
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  // Convert an address into a LatLng
  Future<LatLng?> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print("Error getting LatLng from address: $e");
    }
    return null;
  }

  // Count nearby reports within 2 miles (~3.2 km) of a given location
  int _countNearbyReports(LatLng targetLocation, Map<String, int> locationFrequency) {
    const double radiusMiles = 2.0;
    const double radiusKm = radiusMiles * 1.60934;

    int count = 0;
    for (String key in locationFrequency.keys) {
      List<String> parts = key.split(',');
      double lat = double.parse(parts[0]);
      double lng = double.parse(parts[1]);
      LatLng location = LatLng(lat, lng);

      double distance = Geolocator.distanceBetween(
        targetLocation.latitude,
        targetLocation.longitude,
        location.latitude,
        location.longitude,
      );

      // Convert distance to kilometers and check if it's within the radius
      if (distance <= (radiusKm * 1000)) {
        count += locationFrequency[key]!;
      }
    }
    return count;
  }

  // Determine marker color based on nearby report frequency
  Color _getMarkerColor(int count) {
    if (count >= 10) {
      return Colors.red; // More than 10 reports
    } else if (count >= 5) {
      return Colors.yellow; // Between 5 and 9 reports
    } else {
      return Colors.green; // Less than 5 reports
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          initialZoom: 12.0, // Adjust zoom level
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}

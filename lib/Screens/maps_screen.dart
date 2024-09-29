import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
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
      _fetchDisasterReports();
    });
  }

  void _addUserLocationMarker() {
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  Future<void> _fetchDisasterReports() async {
    QuerySnapshot snapshot = await _firestore.collection('disaster_reports').get();
    Map<String, int> locationFrequency = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var lat = data['latitude'];
      var lng = data['longitude'];

      if (lat != null && lng != null) {
        LatLng latLng = LatLng(lat, lng);
        String locationKey = "${latLng.latitude},${latLng.longitude}";
        locationFrequency[locationKey] = (locationFrequency[locationKey] ?? 0) + 1;

        int nearbyReportCount = _countNearbyReports(latLng, locationFrequency);
        Color markerColor = _getMarkerColor(nearbyReportCount);
        _addDisasterMarker(latLng, markerColor);
        _addDisasterCircle(latLng, nearbyReportCount);
      }
    }
    setState(() {});
  }

  void _addDisasterMarker(LatLng latLng, Color color) {
    _markers.add(
      Marker(
        markerId: MarkerId(latLng.toString()),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          color == Colors.red
              ? BitmapDescriptor.hueRed
              : color == Colors.yellow
              ? BitmapDescriptor.hueYellow
              : BitmapDescriptor.hueGreen,
        ),
      ),
    );
  }

  void _addDisasterCircle(LatLng latLng, int reportCount) {
    double radius = reportCount >= 10 ? 1000 : reportCount >= 5 ? 500 : 200;
    Color color = _getMarkerColor(reportCount);

    _circles.add(
      Circle(
        circleId: CircleId(latLng.toString()),
        center: latLng,
        radius: radius,
        strokeWidth: 2,
        strokeColor: color.withOpacity(0.5),
        fillColor: color.withOpacity(0.2),
      ),
    );
  }

  int _countNearbyReports(LatLng targetLocation, Map<String, int> locationFrequency) {
    const double radiusKm = 3.2;
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

      if (distance <= (radiusKm * 1000)) {
        count += locationFrequency[key]!;
      }
    }
    return count;
  }

  Color _getMarkerColor(int count) {
    if (count >= 10) {
      return Colors.red;
    } else if (count >= 5) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 12.0,
        ),
        markers: _markers,
        circles: _circles,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}

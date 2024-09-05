import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _username = 'Guest';
  String _email = '';
  String _phoneNumber = 'Not Provided';
  String _location = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserLocation();
  }

  Future<void> _fetchUserData() async {
    _user = _auth.currentUser;

    if (_user != null) {
      try {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();

        if (userDoc.exists) {
          setState(() {
            _username = userDoc['username'] ?? _user!.email!;
            _email = userDoc['email'] ?? 'No email';
            _phoneNumber = userDoc['phoneNumber'] ?? 'Not Provided';
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error fetching user data: ${e.toString()}")));
      }
    }
  }

  Future<void> _fetchUserLocation() async {
    try {
      // Check permission for location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _location = 'Location services are disabled.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _location = 'Location permissions are denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _location = 'Location permissions are permanently denied';
        });
        return;
      }

      // Fetch the current position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Get the address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      setState(() {
        _location = "${place.street}, ${place.locality}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _location = 'Failed to get location: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[800],
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // User Name
            Text(
              _username, // Dynamic user name
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            // Email
            _profileInfo(Icons.email, _email),

            const SizedBox(height: 10),

            // Phone Number
            _profileInfo(Icons.phone, _phoneNumber),

            const SizedBox(height: 10),

            // Location
            _profileInfo(Icons.location_on, _location),

            const SizedBox(height: 20),

            // Log Out Button
            ElevatedButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushReplacementNamed(context, '/auth');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for showing user info
  Widget _profileInfo(IconData icon, String info) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(width: 10),
        Text(info, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

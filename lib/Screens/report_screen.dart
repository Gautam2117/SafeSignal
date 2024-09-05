import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // For fetching logged-in user info

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _selectedDisasterType;
  String? _selectedSeverity;
  String _location = '';
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;  // Firebase Auth for logged-in user

  // Fetch current user's details
  User? get _user => _auth.currentUser;

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];
      String address = "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

      setState(() {
        _location = address;
        _locationController.text = _location;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _submitReport() async {
    // Ensure all required fields are filled
    if (_selectedDisasterType == null ||
        _locationController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedSeverity == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all the required fields'),
      ));
      return;
    }

    // Get the current date and time
    final DateTime now = DateTime.now();

    // Get the user name and email
    final String? userName = _user?.displayName ?? 'Anonymous';
    final String? userEmail = _user?.email ?? 'No Email';

    // Upload report data to Firestore
    try {
      await FirebaseFirestore.instance.collection('disaster_reports').add({
        'disasterType': _selectedDisasterType,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'severity': _selectedSeverity,
        'contactInfo': _contactController.text.isNotEmpty ? _contactController.text : 'N/A',
        'userName': userName,
        'userEmail': userEmail,
        'reportDate': now.toIso8601String(),
        'imageURL': _image != null ? _image!.path : null,  // You can later upload the image to Firebase Storage and store the download URL
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Report successfully submitted!'),
      ));
      _clearForm();
    } catch (e) {
      print('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to submit report. Try again later.'),
      ));
    }
  }

  // Clear form after submission
  void _clearForm() {
    setState(() {
      _selectedDisasterType = null;
      _selectedSeverity = null;
      _locationController.clear();
      _descriptionController.clear();
      _contactController.clear();
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Disaster'),
        backgroundColor: const Color(0xFF001F3F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Disaster Type'),
              items: ['Flood', 'Earthquake', 'Fire', 'Other']
                  .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedDisasterType = val),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Location Details',
                labelStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(Icons.location_on, color: Colors.blueAccent),
                  onPressed: _getCurrentLocation,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Description/Details'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Severity Level'),
              items: ['Low', 'Medium', 'High', 'Critical']
                  .map((severity) => DropdownMenuItem(
                value: severity,
                child: Text(severity, style: TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedSeverity = val),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _contactController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Contact Information (Optional)'),
            ),
            const SizedBox(height: 20),
            _image != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_image!, height: 150, fit: BoxFit.cover),
            )
                : TextButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt, color: Colors.blueAccent),
              label: Text('Upload Disaster Photo'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitReport,
                child: const Text('Submit Report', style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6278ff),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

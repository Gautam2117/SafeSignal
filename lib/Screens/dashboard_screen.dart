import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hackx/Screens/report_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _newsArticles = [];
  Position? _currentPosition;
  String? _country;
  List<bool> _showFullDescription = [];
  int userReportCount = 0;
  List<dynamic> nearbyReports = [];
  String? userEmail;
  List<dynamic> userReports = [];
  bool _isLoadingNews = true;
  String? _currentCity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
      _fetchUserDetails();
    });
  }

  void _fetchUserDetails() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email;
      _getCurrentLocation();
      _fetchUserReports();
      _fetchNearbyReports();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
        return;
      } else if (permission == LocationPermission.denied) {
        print('Location permissions are denied.');
        return;
      }
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      _fetchCountryFromCoordinates();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _fetchCountryFromCoordinates() async {
    if (_currentPosition != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        Placemark place = placemarks[0];
        setState(() {
          _country = place.country;
        });
        _fetchNews();
      } catch (e) {
        print('Error fetching country: $e');
      }
    }
  }

  Future<void> _fetchNews() async {
    if (_country == null) {
      print('Country not determined yet');
      return;
    }

    String apiKey = '4183513e6bff45638598cd78e452bbe5';
    String locationQuery = '$_country disaster';

    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/everything?q=$locationQuery&apiKey=$apiKey'),
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['articles'] != null) {
          setState(() {
            _newsArticles = responseData['articles']
                .where((article) {
              String title = article['title'].toLowerCase();
              String description = article['description']?.toLowerCase() ?? '';
              return title.contains('disaster') ||
                  description.contains('disaster') ||
                  title.contains('emergency') ||
                  description.contains('emergency') ||
                  title.contains('catastrophe') ||
                  description.contains('catastrophe');
            })
                .toList();
            _showFullDescription = List.filled(_newsArticles.length, false);
            _isLoadingNews = false;
          });
        } else {
          print('No disaster-related articles found for $_country.');
          setState(() {
            _isLoadingNews = false;
          });
        }
      } else {
        throw Exception('Failed to load news: ${response.body}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      setState(() {
        _isLoadingNews = false;
      });
    }
  }

  Future<void> _fetchUserReports() async {
    if (userEmail == null) return;
    var collection = FirebaseFirestore.instance.collection('disaster_reports');
    var query = collection.where('userEmail', isEqualTo: userEmail);

    query.get().then((querySnapshot) {
      setState(() {
        userReports = querySnapshot.docs.map((doc) => doc.data()).toList();
        userReportCount = userReports.length;
      });
    });
  }

  Future<void> _fetchNearbyReports() async {
    if (_currentPosition == null) {
      print("Current position not available");
      return;
    }

    var collection = FirebaseFirestore.instance.collection('disaster_reports');
    var snapshot = await collection.get();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var locationAddress = data['location'];

      try {
        List<Location> locations = await locationFromAddress(locationAddress);

        if (locations.isNotEmpty) {
          var reportLocation = locations.first;

          double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            reportLocation.latitude,
            reportLocation.longitude,
          );

          if (distanceInMeters <= 5000) { // Adjust the radius as needed
            setState(() {
              nearbyReports.add(data);
            });
          }
        }
      } catch (e) {
        print("Error converting address or calculating distance: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportScreen()), // Navigate to ReportScreen
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.redAccent, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _dashboardCard('My Reports', userReportCount.toString()),
              _dashboardCard('Nearby cases', '${nearbyReports.length} within 2km', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NearbyReportsScreen(nearbyReports: nearbyReports),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          _isLoadingNews
              ? _newsSkeletonLoader()
              : _newsArticles.isNotEmpty
              ? CarouselSlider.builder(
            options: CarouselOptions(
              autoPlay: true,
              height: 250,
              enlargeCenterPage: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
            ),
            itemCount: _newsArticles.length,
            itemBuilder: (context, index, realIdx) {
              return _newsCard(_newsArticles[index], index);
            },
          )
              : const Center(child: Text('No news available')),
        ],
      ),
    );
  }

  Widget _dashboardCard(String title, String value, {VoidCallback? onTap}) {
    return Card(
      color: const Color(0xFF6278ff),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newsCard(dynamic article, int index) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(article['urlToImage'] ?? 'https://via.placeholder.com/400'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.black.withOpacity(0.6),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                article['title'] ?? 'No Title',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  _showFullDescription[index]
                      ? (article['description'] ?? 'No Description')
                      : (article['description'] != null && article['description'].length > 50)
                      ? article['description'].substring(0, 50) + '...'
                      : article['description'] ?? 'No Description',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showFullDescription[index] = !_showFullDescription[index];
                  });
                },
                child: Text(
                  _showFullDescription[index] ? 'Show Less' : 'Show More',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _newsSkeletonLoader() {
    return Container(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3, // Number of skeleton items
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }
}

class NearbyReportsScreen extends StatelessWidget {
  final List<dynamic> nearbyReports;

  NearbyReportsScreen({required this.nearbyReports});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Reports"),
        backgroundColor: const Color(0xFF101820),
      ),
      body: nearbyReports.isNotEmpty
          ? ListView.builder(
        itemCount: nearbyReports.length,
        itemBuilder: (context, index) {
          var report = nearbyReports[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.all(10.0),
            child: ListTile(
              title: Text(
                report['disasterType'] ?? 'No Title',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(report['description'] ?? 'No Description'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(report: report),
                  ),
                );
              },
            ),
          );
        },
      )
          : const Center(child: Text("No nearby reports found")),
    );
  }
}

class ReportDetailScreen extends StatelessWidget {
  final dynamic report;

  ReportDetailScreen({required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report['disasterType'] ?? 'Report Details'),
        backgroundColor: const Color(0xFF101820),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report['imageURL'] != null && report['imageURL'].isNotEmpty)
              Image.file(
                File(report['imageURL']),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Image could not be loaded.');
                },
              )
            else
              const Text('No Image Available'),

            const SizedBox(height: 20),

            // Disaster Type
            Text(
              report['disasterType'] ?? 'No Disaster Type',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              report['description'] ?? 'No Description',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Report Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  report['reportDate'] ?? 'No Date',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Severity
            Text(
              'Severity: ${report['severity'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    report['location'] ?? 'No Location',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Contact Info
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Contact: ${report['contactInfo'] ?? 'No Contact Info'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // User Information
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Reported by: ${report['userName'] ?? 'Anonymous'} (${report['userEmail'] ?? 'No Email'})',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Screens/contact_screen.dart';
import 'Screens/dashboard_screen.dart';
import 'Screens/maps_screen.dart';
import 'Screens/profile_screen.dart';
import 'Screens/report_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    MapScreen(),
    ContactScreen(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820), // Dark background for premium feel
      appBar: AppBar(
        centerTitle: true,
        title: const Text('SafeSignal', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: const Color(0xFF2d3796), // Deep blue for disaster theme
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF001F3F), Color(0xFF203A43), Color(0xFF2C5364)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _pages[_selectedIndex], // Display the selected page
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          onPressed: () async {
            const number = '100'; // The emergency number to call
            bool? res = await FlutterPhoneDirectCaller.callNumber(number); // Directly call the number
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.phone, size: 30), // Phone icon for calling
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Custom BottomNavigationBar with reduced space and increased height
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2d3796),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.redAccent, // Disaster-themed red color for selected item
        unselectedItemColor: Colors.white, // White for unselected items
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        iconSize: 28, // Increase icon size if needed
        selectedFontSize: 14, // Control the font size for selected items
        unselectedFontSize: 12, // Control the font size for unselected items
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0), // Reduce the space
              child: Icon(Icons.dashboard_outlined),
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0), // Reduce the space
              child: Icon(Icons.pin_drop_outlined),
            ),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0), // Reduce the space
              child: Icon(Icons.contact_phone_outlined),
            ),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0), // Reduce the space
              child: Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
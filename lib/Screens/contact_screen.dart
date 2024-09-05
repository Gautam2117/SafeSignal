import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart'; // For direct phone calls

class ContactScreen extends StatelessWidget {
  final List<EmergencyService> emergencyServices = [
    EmergencyService(
        type: 'Fire',
        icon: Icons.local_fire_department,
        contacts: [
          EmergencyContact(name: 'Fire Brigade', number: '101'),
          EmergencyContact(name: 'Emergency Helpline', number: '112'),
        ]),
    EmergencyService(
        type: 'Police',
        icon: Icons.local_police,
        contacts: [
          EmergencyContact(name: 'Police Department', number: '100'),
          EmergencyContact(name: 'Emergency Helpline', number: '112'),
        ]),
    EmergencyService(
        type: 'Medical',
        icon: Icons.local_hospital,
        contacts: [
          EmergencyContact(name: 'Ambulance', number: '108'),
          EmergencyContact(name: 'Emergency Helpline', number: '112'),
        ]),
    EmergencyService(
        type: 'Flood',
        icon: Icons.water_damage,
        contacts: [
          EmergencyContact(name: 'Disaster Management', number: '1070'),
          EmergencyContact(name: 'Emergency Helpline', number: '112'),
        ]),
    EmergencyService(
        type: 'Earthquake',
        icon: Icons.terrain,  // Updated with a related icon for earthquake
        contacts: [
          EmergencyContact(name: 'Disaster Response Force', number: '1090'),
          EmergencyContact(name: 'Emergency Helpline', number: '112'),
        ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Title
            const Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),

            // List of emergency services
            Expanded(
              child: ListView.builder(
                itemCount: emergencyServices.length,
                itemBuilder: (context, index) {
                  return _emergencyServiceCard(context, emergencyServices[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyServiceCard(BuildContext context, EmergencyService service) {
    return Card(
      color: const Color(0xFF6278ff),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          _showEmergencyContacts(context, service);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(service.icon, color: Colors.orange, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  service.type,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom sheet to show contacts with swipe feature
  void _showEmergencyContacts(BuildContext context, EmergencyService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101820),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${service.type} Contacts',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // List of contacts with swipeable functionality
              ListView.builder(
                shrinkWrap: true,
                itemCount: service.contacts.length,
                itemBuilder: (context, index) {
                  return _slidableContactTile(service.contacts[index]);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget for swipeable contact tile
  Widget _slidableContactTile(EmergencyContact contact) {
    return Slidable(
      key: ValueKey(contact.number),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              _makePhoneCall(contact.number);
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.call,
            label: 'Call',
          ),
        ],
      ),
      child: Card(
        color: const Color(0xFF2C5364),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: const Icon(Icons.phone, color: Colors.orange, size: 40),
          title: Text(
            contact.name,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.left,
          ),
          subtitle: Text(
            contact.number,
            style: const TextStyle(color: Colors.orange),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }

  // Function to make a phone call using flutter_phone_direct_caller
  Future<void> _makePhoneCall(String number) async {
    await FlutterPhoneDirectCaller.callNumber(number);
  }
}

class EmergencyService {
  final String type;
  final IconData icon;
  final List<EmergencyContact> contacts;

  EmergencyService({required this.type, required this.icon, required this.contacts});
}

class EmergencyContact {
  final String name;
  final String number;

  EmergencyContact({required this.name, required this.number});
}

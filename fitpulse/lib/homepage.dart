import 'package:flutter/material.dart';
import 'map.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of screens for each tab
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    const MapScreen(),
    const Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  // Handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email; //get information from the current loged user
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Progress for Heart Points and Steps
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,  // Adjust the size for a larger radius
                        height: 150, // Adjust the size for a larger radius
                        child: CircularProgressIndicator(
                          value: 0.2,  // Example value
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      Icon(
                        Icons.directions_walk,  // Step icon
                        size: 50,               // Adjust size as needed
                        color: Colors.deepPurple,  // Change color if needed
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "1/3500",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text("Steps"),
                ],
              ),
            ),

            const SizedBox(height: 30),
            
            // Metrics Row (Calories, Move Minutes, Distance, Sleep)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                MetricWidget(label: 'Cal', value: '345'),
                MetricWidget(label: 'Move min', value: '154'),
                MetricWidget(label: 'km', value: '4.6'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Heart Rate Section
            Card(
              child: ListTile(
                leading: Icon(Icons.favorite, color: Colors.red),
                title: const Text('Heart Rate'),
                subtitle: Row(
                  children: const [
                    Text(
                      '78 bpm',  // Example heart rate value
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Weekly Target Section
            Card(
              child: ListTile(
                leading: Icon(Icons.track_changes),
                title: const Text('Your weekly target'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('102 of 150'),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(value: 0.68),  // Example progress
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Daily Goals Section
            Card(
              child: ListTile(
                leading: Icon(Icons.flag),
                title: const Text('Your daily goals'),
                subtitle: Row(
                  children: const [
                    Text('3/7 Achieved'),
                    Spacer(),
                    Icon(Icons.check_circle, color: Colors.blue),
                    Icon(Icons.check_circle, color: Colors.blue),
                    Icon(Icons.check_circle, color: Colors.blue),
                    Icon(Icons.circle, color: Colors.grey),
                    Icon(Icons.circle, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricWidget extends StatelessWidget {
  final String label;
  final String value;

  const MetricWidget({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

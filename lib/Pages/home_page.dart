import 'package:flutter/material.dart';
import 'package:surfspot/Widgets/detailed_forecast.dart';
import 'package:surfspot/Widgets/find_my_spot.dart';
import 'package:surfspot/Widgets/notify_me.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Placeholder widgets for now
  final List<Widget> _pages = [
    FindMySpot(), // FindMySpot()
    DetailedForecast(), // DetailedForecast()
    NotifyMe(), // NotifyMe()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surf Spot'),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find Spot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.waves),
            label: 'Forecast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notify Me',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}
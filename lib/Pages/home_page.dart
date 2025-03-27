import 'package:flutter/material.dart';
import 'package:surfspot/Widgets/detailed_forecast.dart';
import 'package:surfspot/Widgets/find_my_spot.dart';
import 'package:surfspot/Widgets/notify_me.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Placeholder widgets for now
  final List<Widget> _pages = [
    const FindMySpot(),
    const DetailedForecast(),
    const NotifyMe(),
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
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.blue,
        child: SingleChildScrollView(
            child: _pages[_selectedIndex]
        ),
      ),
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
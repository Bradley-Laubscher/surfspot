import 'package:flutter/material.dart';
import 'package:surfspot/Widgets/spot_guide.dart';
import 'package:surfspot/Widgets/find_my_spot.dart';
import 'package:surfspot/Widgets/notify_me.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSettingsSelected(String value) {
    switch (value) {
      case 'dark_mode':
        setState(() {
          _isDarkMode = !_isDarkMode;
        });
        break;
      case 'about':
        showAboutDialog(
          context: context,
          applicationName: 'Surf Spot',
          applicationVersion: '1.0.0',
          children: const [
            Text('A simple surf forecast app made with Flutter.'),
          ],
        );
        break;
      case 'contact':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Contact'),
            content: const Text('Email: bradleylaubscherwow@gmail.com'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      FindMySpot(isDarkMode: _isDarkMode),
      const SpotGuide(),
      const NotifyMe(),
    ];

    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Surf Spot'),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings),
              onSelected: _onSettingsSelected,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'dark_mode',
                  child: Row(
                    children: [
                      const Icon(Icons.dark_mode),
                      const SizedBox(width: 8),
                      Text(_isDarkMode ? 'Light Mode' : 'Dark Mode'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'about',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text('About'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'contact',
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined),
                      SizedBox(width: 8),
                      Text('Contact'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.blue,
          child: SingleChildScrollView(
            child: pages[_selectedIndex],
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
              label: 'Guide',
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
      ),
    );
  }
}
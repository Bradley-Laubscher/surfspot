import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surfspot/Providers/theme_provider.dart';
import 'package:surfspot/Theme/app_theme.dart';
import 'package:surfspot/Widgets/spot_guide.dart';
import 'package:surfspot/Widgets/find_my_spot.dart';
import 'package:surfspot/Widgets/notify_me.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Find Spot'),
    NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Guide'),
    NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notify Me'),
  ];

  void _onSettingsSelected(String value) {
    switch (value) {
      case 'dark_mode':
        context.read<ThemeProvider>().toggleDarkMode();
        break;
      case 'about':
        showAboutDialog(
          context: context,
          applicationName: 'Surf Spot',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.waves_rounded, color: AppColors.teal, size: 32),
          children: const [
            Text('A surf forecast app for South African surf spots, built with Flutter.'),
          ],
        );
        break;
      case 'contact':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final isDesktop = AppBreakpoints.isTablet(context);

    const pages = [
      FindMySpot(),
      SpotGuide(),
      NotifyMe(),
    ];

    final appBar = AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode ? AppColors.heroGradientDark : AppColors.heroGradientLight,
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.waves_rounded, color: AppColors.aqua),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
              children: const [
                TextSpan(text: 'SURF'),
                TextSpan(text: 'SPOT', style: TextStyle(color: AppColors.aqua)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: _onSettingsSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'dark_mode',
                child: Row(
                  children: [
                    Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                    const SizedBox(width: 8),
                    Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
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
        ),
      ],
    );

    final body = SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: pages[_selectedIndex],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: _destinations,
      ),
    );
  }
}

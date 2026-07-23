import 'package:flutter/material.dart';
import 'package:surfspot/Theme/app_theme.dart';

import '../Globals/config.dart';

class SpotGuide extends StatelessWidget {
  const SpotGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isTablet(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
          child: Column(
            children: locations.map((spot) => _SpotCard(spot: spot)).toList(),
          ),
        ),
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final Map<String, dynamic> spot;

  const _SpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    final image = spot['image'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: image != null
                  ? Image.asset(image, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.midOcean, AppColors.teal]),
                      ),
                      child: const Icon(Icons.waves_rounded, color: Colors.white70),
                    ),
            ),
          ),
          title: Text(
            spot['name'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: _DifficultyStars(rating: spot['difficultyRating']),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                      _InfoTile(icon: Icons.waves_rounded, label: 'Best Swell', value: spot['bestSwell']),
                      _InfoTile(icon: Icons.air_rounded, label: 'Best Wind', value: spot['bestWind']),
                      _InfoTile(icon: Icons.water_rounded, label: 'Best Tide', value: spot['tide']),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Hazards', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (spot['hazards'] as List).map((hazard) {
                      return Chip(
                        avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.coral),
                        label: Text(hazard),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyStars extends StatelessWidget {
  final int rating;

  const _DifficultyStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: AppColors.sunsetGold,
          size: 16,
        );
      }),
    );
  }
}

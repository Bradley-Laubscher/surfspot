import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surfspot/Providers/location_provider.dart';
import 'package:surfspot/Providers/surf_conditions_provider.dart';
import 'package:surfspot/Theme/app_theme.dart';
import 'package:surfspot/Utils/compass.dart';
import 'package:surfspot/Utils/formatting.dart';
import 'package:surfspot/Utils/surf_scoring.dart';
import 'package:surfspot/Globals/config.dart';

/// Hero banner that highlights whichever configured spot has the best surf
/// window today, so the user can tell at a glance where to go without
/// reading every spot's forecast individually.
class SpotOfTheDay extends StatelessWidget {
  const SpotOfTheDay({super.key});

  @override
  Widget build(BuildContext context) {
    final conditions = context.watch<SurfConditionsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode ? AppColors.heroGradientDark : AppColors.heroGradientLight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: _buildContent(context, conditions),
    );
  }

  Widget _buildContent(BuildContext context, SurfConditionsProvider conditions) {
    if (conditions.isLoading) {
      return const SizedBox(
        height: 96,
        child: Center(
          child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
        ),
      );
    }

    final forecast = conditions.spotOfTheDay;
    if (conditions.error != null || forecast == null) {
      return Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              conditions.error ?? "No surf data available right now.",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }

    final window = forecast.todaysBestWindow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.sunsetGold, size: 20),
            const SizedBox(width: 6),
            Text(
              "SPOT OF THE DAY",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Wrap (not Row) so a long spot name can never force the rating pill
        // off the edge - it just drops to its own line instead of erroring.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                forecast.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
            ),
            if (window != null) _RatingPill(rating: window.bestHour.rating),
          ],
        ),
        const SizedBox(height: 12),
        if (window != null) ...[
          _conditionSummary(context, window),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final index = locations.indexWhere((l) => l["name"] == forecast.name);
                if (index != -1) {
                  Provider.of<LocationProvider>(context, listen: false).setLocation(index);
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: const Text("View forecast", style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else
          const Text(
            "No standout surf window in today's forecast - check back tomorrow.",
            style: TextStyle(color: Colors.white70),
          ),
      ],
    );
  }

  Widget _conditionSummary(BuildContext context, SurfWindow window) {
    final reading = window.bestHour.reading;
    final windDirection = reading.windDirection;
    final windSpeed = reading.windSpeed;
    final windLabel = windDirection != null ? nearestCardinal(windDirection) : null;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.waves_rounded,
          label: "${reading.waveHeight.toStringAsFixed(1)}m @ ${reading.wavePeriod.toStringAsFixed(0)}s",
        ),
        if (windSpeed != null)
          _InfoChip(
            icon: Icons.air_rounded,
            label: "${windSpeed.toStringAsFixed(0)} km/h${windLabel != null ? ' $windLabel' : ''}",
          ),
        _InfoChip(
          icon: Icons.schedule_rounded,
          label: "Best ${formatHour(window.start.reading.time)} - ${formatHour(window.end.reading.time)}",
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _RatingPill extends StatelessWidget {
  final SurfRating rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    final color = surfRatingColor(rating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(surfRatingIcon(rating), size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(rating.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

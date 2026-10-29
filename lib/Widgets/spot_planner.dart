import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surfspot/Providers/location_provider.dart';
import 'package:surfspot/Providers/surf_conditions_provider.dart';
import 'package:surfspot/Theme/app_theme.dart';
import 'package:surfspot/Utils/compass.dart';
import 'package:surfspot/Utils/formatting.dart';
import 'package:surfspot/Utils/horizontal_scroll.dart';
import 'package:surfspot/Utils/surf_scoring.dart';
import 'package:surfspot/Globals/config.dart';

/// Hero banner for planning a session: the user picks the day they want to
/// surf and it recommends the best configured spot for that day, explains
/// why, and ranks the alternatives - so they can tell where to go without
/// reading every spot's forecast individually.
class SpotPlanner extends StatelessWidget {
  const SpotPlanner({super.key});

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

    final day = conditions.selectedDay;
    final ranking = conditions.rankingFor(day);
    if (conditions.error != null || ranking.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              conditions.error ?? "No surf windows in the forecast right now.",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }

    final best = ranking.first;
    final window = best.window;
    final today = isToday(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(today ? Icons.emoji_events_rounded : Icons.event_available_rounded, color: AppColors.sunsetGold, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                today ? "SPOT OF THE DAY" : "BEST SPOT FOR ${dayLabel(day).toUpperCase()}",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DayPicker(conditions: conditions),
        const SizedBox(height: 16),
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
                best.forecast.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
            ),
            _RatingPill(rating: window.bestHour.rating),
          ],
        ),
        const SizedBox(height: 12),
        _conditionSummary(context, window),
        const SizedBox(height: 14),
        _WhyThisSpot(hour: window.bestHour),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _selectSpot(context, best.forecast.name),
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            label: const Text("View forecast", style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (ranking.length > 1) ...[
          const SizedBox(height: 18),
          Text(
            "OTHER OPTIONS",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white60, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          for (int i = 1; i < ranking.length; i++)
            _RunnerUpRow(
              rank: i + 1,
              recommendation: ranking[i],
              onTap: () => _selectSpot(context, ranking[i].forecast.name),
            ),
        ],
      ],
    );
  }

  static void _selectSpot(BuildContext context, String name) {
    final index = locations.indexWhere((l) => l["name"] == name);
    if (index != -1) {
      Provider.of<LocationProvider>(context, listen: false).setLocation(index);
    }
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

/// Horizontal row of selectable days, each marked with the best rating any
/// spot reaches that day so the user can also spot which day is best.
class _DayPicker extends StatefulWidget {
  final SurfConditionsProvider conditions;

  const _DayPicker({required this.conditions});

  @override
  State<_DayPicker> createState() => _DayPickerState();
}

class _DayPickerState extends State<_DayPicker> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conditions = widget.conditions;
    final days = conditions.plannableDays;
    final selected = conditions.selectedDay;

    return SizedBox(
      height: 66,
      child: HorizontalWheelScroll(
        controller: _scrollController,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final day = days[index];
            return _DayChip(
              day: day,
              bestRating: conditions.recommendationFor(day)?.window.bestHour.rating,
              isSelected: isSameDay(day, selected),
              onTap: () => conditions.selectDay(day),
            );
          },
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime day;
  final SurfRating? bestRating;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({required this.day, required this.bestRating, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? AppColors.deepOcean : Colors.white;
    final bestRating = this.bestRating;

    return Material(
      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isToday(day) ? "Today" : shortWeekday(day),
                style: TextStyle(color: foreground.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                "${day.day}",
                style: TextStyle(color: foreground, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (bestRating != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: surfRatingColor(bestRating)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The factors behind the recommended hour's score, strongest first, so the
/// recommendation reads as reasoning rather than an opaque pick.
class _WhyThisSpot extends StatelessWidget {
  final ScoredHour hour;

  const _WhyThisSpot({required this.hour});

  @override
  Widget build(BuildContext context) {
    final factors = [...hour.factors]..sort((a, b) => b.points.compareTo(a.points));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final factor in factors)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon(factor.points), size: 16, color: _color(factor.points)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(factor.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static IconData _icon(int points) {
    if (points >= 1) return Icons.check_circle_rounded;
    if (points == 0) return Icons.remove_circle_outline_rounded;
    return Icons.warning_amber_rounded;
  }

  static Color _color(int points) {
    if (points >= 2) return AppColors.good;
    if (points == 1) return Colors.white70;
    if (points == 0) return AppColors.fair;
    return AppColors.poor;
  }
}

class _RunnerUpRow extends StatelessWidget {
  final int rank;
  final SpotRecommendation recommendation;
  final VoidCallback onTap;

  const _RunnerUpRow({required this.rank, required this.recommendation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final window = recommendation.window;
    final rating = window.bestHour.rating;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text("$rank", style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: Text(
                recommendation.forecast.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              "${formatHour(window.start.reading.time)} - ${formatHour(window.end.reading.time)}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: surfRatingColor(rating)),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 34,
              child: Text(rating.label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
      ),
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

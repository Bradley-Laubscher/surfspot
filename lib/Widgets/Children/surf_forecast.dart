import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surfspot/Providers/location_provider.dart';
import 'package:surfspot/Providers/surf_conditions_provider.dart';
import 'package:surfspot/Theme/app_theme.dart';
import 'package:surfspot/Utils/formatting.dart';
import 'package:surfspot/Utils/horizontal_scroll.dart';
import 'package:surfspot/Utils/surf_scoring.dart';

/// Displays the cached forecast for the currently selected spot. Data comes
/// from [SurfConditionsProvider], which fetches every spot once up front -
/// switching spots here is instant, with no per-tap network round trip.
class SurfForecast extends StatelessWidget {
  const SurfForecast({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedName = context.watch<LocationProvider>().selectedLocation["name"];
    final conditions = context.watch<SurfConditionsProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 320),
          child: _buildBody(context, conditions, selectedName),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SurfConditionsProvider conditions, String selectedName) {
    if (conditions.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (conditions.error != null) {
      return _ErrorState(message: conditions.error!, onRetry: conditions.loadAll);
    }

    final forecast = conditions.forecastFor(selectedName);
    if (forecast == null || forecast.hours.isEmpty) {
      return const Center(child: Text("No forecast available for this spot."));
    }

    final days = forecast.byDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SummaryHeader(name: forecast.name, window: forecast.todaysBestWindow),
        const SizedBox(height: 16),
        for (int i = 0; i < days.length; i++) ...[
          if (i > 0) const Divider(height: 28),
          _DaySection(hours: days[i]),
        ],
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final String name;
  final SurfWindow? window;

  const _SummaryHeader({required this.name, required this.window});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final window = this.window;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                window != null
                    ? "Best today: ${formatHour(window.start.reading.time)} - ${formatHour(window.end.reading.time)}"
                    : "No standout window today",
                style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (window != null) _RatingBadge(rating: window.bestHour.rating),
      ],
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final SurfRating rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final color = surfRatingColor(rating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(surfRatingIcon(rating), size: 16, color: color),
          const SizedBox(width: 4),
          Text(rating.label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DaySection extends StatefulWidget {
  final List<ScoredHour> hours;

  const _DaySection({required this.hours});

  @override
  State<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<_DaySection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dayLabel(widget.hours.first.reading.time), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 128,
          child: HorizontalWheelScroll(
            controller: _scrollController,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.hours.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _HourTile(hour: widget.hours[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _HourTile extends StatelessWidget {
  final ScoredHour hour;

  const _HourTile({required this.hour});

  @override
  Widget build(BuildContext context) {
    final reading = hour.reading;
    final color = surfRatingColor(hour.rating);
    final windSpeed = reading.windSpeed;
    final windDirection = reading.windDirection;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(formatHour(reading.time), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Transform.rotate(
            angle: (reading.swellDirection * 3.1415926535) / 180,
            child: Icon(Icons.arrow_upward_rounded, size: 18, color: colorScheme.primary),
          ),
          Text("${reading.waveHeight.toStringAsFixed(1)}m", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Text("${reading.wavePeriod.toStringAsFixed(0)}s", style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          if (windSpeed != null && windDirection != null) ...[
            Transform.rotate(
              angle: (windDirection * 3.1415926535) / 180,
              child: Icon(Icons.air_rounded, size: 13, color: colorScheme.onSurfaceVariant),
            ),
            Text("${windSpeed.toStringAsFixed(0)}km/h", style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

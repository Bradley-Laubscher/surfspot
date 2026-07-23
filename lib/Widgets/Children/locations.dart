import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surfspot/Globals/config.dart';
import 'package:surfspot/Providers/location_provider.dart';
import 'package:surfspot/Providers/surf_conditions_provider.dart';
import 'package:surfspot/Theme/app_theme.dart';
import 'package:surfspot/Utils/horizontal_scroll.dart';
import 'package:surfspot/Utils/surf_scoring.dart';

const double _cardWidth = 148;
const double _cardHeight = 168;

class LocationList extends StatefulWidget {
  const LocationList({super.key});

  @override
  State<LocationList> createState() => _LocationListState();
}

class _LocationListState extends State<LocationList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedName = context.watch<LocationProvider>().selectedLocation["name"];
    final conditions = context.watch<SurfConditionsProvider>();

    return SizedBox(
      height: _cardHeight,
      child: HorizontalWheelScroll(
        controller: _scrollController,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: locations.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final spot = locations[index];
            final isSelected = spot["name"] == selectedName;
            final forecast = conditions.forecastFor(spot["name"]);
            final todayRating = forecast?.todaysBestWindow?.bestHour.rating;

            return _LocationCard(
              spot: spot,
              isSelected: isSelected,
              rating: todayRating,
              onTap: () => context.read<LocationProvider>().setLocation(index),
            );
          },
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> spot;
  final bool isSelected;
  final SurfRating? rating;
  final VoidCallback onTap;

  const _LocationCard({required this.spot, required this.isSelected, required this.rating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = spot["image"] as String?;
    final rating = this.rating;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: _cardWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.teal : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.28 : 0.14),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image.asset(image, fit: BoxFit.cover)
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.midOcean, AppColors.teal],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.waves_rounded, color: Colors.white54, size: 40),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              if (rating != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: surfRatingColor(rating),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  spot["name"],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

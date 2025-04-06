import 'package:flutter/material.dart';

import '../Globals/config.dart';

class SpotGuide extends StatefulWidget {
  const SpotGuide({super.key});

  @override
  State<SpotGuide> createState() => _SpotGuideState();
}

class _SpotGuideState extends State<SpotGuide> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.9,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final spot = locations[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                tilePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    spot['image'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  spot['name'],
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Difficulty Rating Title and Stars
                        const Text(
                          'Difficulty Rating:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        _difficultyStars(spot['difficultyRating']),
                        _infoRow('Best Swell', spot['bestSwell']),
                        _infoRow('Best Wind', spot['bestWind']),
                        _infoRow('Best Tide', spot['tide']),
                        const SizedBox(height: 8),
                        const Text('Hazards:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        ...List.generate(
                          (spot['hazards'] as List).length,
                              (i) => Text('- ${spot['hazards'][i]}'),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }

  Widget _difficultyStars(int rating) {
    return Row(
      children: List.generate(
        5,
            (index) {
          if (index < rating) {
            return const Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            );
          } else {
            return const Icon(
              Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          }
        },
      ),
    );
  }
}
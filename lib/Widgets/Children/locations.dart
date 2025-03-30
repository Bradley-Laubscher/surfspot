import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surfspot/Globals/config.dart';
import 'package:surfspot/Providers/location_provider.dart';

class LocationList extends StatefulWidget {
  const LocationList({super.key});

  @override
  State<LocationList> createState() => _LocationListState();
}

class _LocationListState extends State<LocationList> {
  final ScrollController _scrollController = ScrollController();
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 170),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.2,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              String locationName = locations[index]["name"];
              String imagePath = locations[index]["image"];

              return ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: GestureDetector(
                    onTap: () {
                      Provider.of<LocationProvider>(context, listen: false).setLocation(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: _hoveredIndex == index
                          ? MediaQuery.of(context).size.width * 0.16
                          : MediaQuery.of(context).size.width * 0.15,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _hoveredIndex == index ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: Image.asset(
                                  imagePath,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  locationName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
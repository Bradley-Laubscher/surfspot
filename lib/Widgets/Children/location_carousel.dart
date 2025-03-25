import 'package:flutter/material.dart';

class LocationCarousel extends StatefulWidget {
  const LocationCarousel({super.key});

  @override
  State<LocationCarousel> createState() => _LocationCarouselState();
}

class _LocationCarouselState extends State<LocationCarousel> {
  @override
  Widget build(BuildContext context) {
    return  ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 200,
        minWidth: 400
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        width: MediaQuery.of(context).size.width*0.8,
        height: MediaQuery.of(context).size.height*0.1,
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.black,
              width: 1,
              style: BorderStyle.solid
          )
        ),
        child: Placeholder(),
      )
    );
  }
}

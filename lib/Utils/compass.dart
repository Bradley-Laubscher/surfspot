/// Maps 8-point compass names (as used in Globals/config.dart) to degrees.
const Map<String, double> cardinalDegrees = {
  "North": 0,
  "North-East": 45,
  "East": 90,
  "South-East": 135,
  "South": 180,
  "South-West": 225,
  "West": 270,
  "North-West": 315,
};

double? cardinalToDegrees(String cardinal) => cardinalDegrees[cardinal];

/// Smallest angle (0-180) between two compass bearings.
double angularDifference(double a, double b) {
  double diff = (a - b).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}

/// Whether [actualDegrees] falls within [tolerance] degrees of the compass
/// sector named [idealCardinal] (e.g. actual swell direction vs a spot's
/// bestSwell). Returns false if the cardinal name isn't recognised.
bool directionMatches(double actualDegrees, String idealCardinal,
    {double tolerance = 45}) {
  final ideal = cardinalToDegrees(idealCardinal);
  if (ideal == null) return false;
  return angularDifference(actualDegrees, ideal) <= tolerance;
}

/// The closest 8-point compass name for a bearing in degrees, e.g. for
/// displaying "wind from the North-West" from a raw degree value.
String nearestCardinal(double degrees) {
  return cardinalDegrees.entries
      .reduce((a, b) => angularDifference(degrees, a.value) <= angularDifference(degrees, b.value) ? a : b)
      .key;
}

import 'package:geolocator/geolocator.dart';

/// Calculates straight-line distance between two GPS coordinates.
/// Uses geolocator's distanceBetween which implements the Haversine formula.
class DistanceCalculator {
  DistanceCalculator._();

  /// Returns distance in kilometers between two coordinates.
  static double distanceInKm(double lat1, double lng1, double lat2, double lng2) {
    final distanceInMeters = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return distanceInMeters / 1000.0;
  }

  /// Returns distance as a readable string: "1.8 km" or "850 m"
  static String distanceLabel(double lat1, double lng1, double lat2, double lng2) {
    final distanceM = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    if (distanceM < 1000) {
      return '${distanceM.toStringAsFixed(0)} m';
    }
    return '${(distanceM / 1000).toStringAsFixed(1)} km';
  }

  /// Sorts a list of items by distance from a reference point.
  /// [getCoords] is a function that extracts (lat, lng) from an item.
  static List<T> sortByDistance<T>(
    List<T> items,
    double fromLat,
    double fromLng,
    (double, double) Function(T) getCoords,
  ) {
    return [...items]..sort((a, b) {
        final (aLat, aLng) = getCoords(a);
        final (bLat, bLng) = getCoords(b);
        final distA = distanceInKm(fromLat, fromLng, aLat, aLng);
        final distB = distanceInKm(fromLat, fromLng, bLat, bLng);
        return distA.compareTo(distB);
      });
  }
}

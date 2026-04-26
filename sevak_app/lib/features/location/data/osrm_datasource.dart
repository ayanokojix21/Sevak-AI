import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmDatasource {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Fetches a driving route from [start] to [end].
  /// Returns a map containing the polyline 'points', 'distance' in meters, and 'duration' in seconds.
  Future<Map<String, dynamic>> getRoute(LatLng start, LatLng end) async {
    // OSRM expects coordinates in longitude,latitude format
    final url = '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (data['code'] == 'Ok' && routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          // GeoJSON coordinates are [longitude, latitude]
          final points = coordinates.map((coord) {
            final c = coord as List<dynamic>;
            return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
          }).toList();

          return {
            'points': points,
            'distance': (route['distance'] as num?)?.toDouble() ?? 0.0, // in meters
            'duration': (route['duration'] as num?)?.toDouble() ?? 0.0, // in seconds
          };
        }
      }
      throw Exception('Failed to fetch route from OSRM: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error while fetching route: $e');
    }
  }
}

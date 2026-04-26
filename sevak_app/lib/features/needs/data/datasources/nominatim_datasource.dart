import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/env_config.dart';

class NominatimDatasource {
  static const String _baseUrl = '${AppConstants.nominatimBaseUrl}/search';
  
  /// Respect Nominatim's 1-req/sec policy
  DateTime? _lastRequestTime;

  Future<Map<String, double>> geocode(String address) async {
    // Throttle requests to max 1 per second
    if (_lastRequestTime != null) {
      final timeSinceLast = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLast.inSeconds < 1) {
        await Future.delayed(Duration(seconds: 1) - timeSinceLast);
      }
    }

    _lastRequestTime = DateTime.now();

    final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(address)}&format=json&limit=1');
    
    // Custom User-Agent is REQUIRED by Nominatim Terms of Service
    final response = await http.get(uri, headers: {
      'User-Agent': EnvConfig.nominatimUserAgent,
    });

    if (response.statusCode == 200) {
      final List<dynamic> results = jsonDecode(response.body) as List<dynamic>;
      if (results.isNotEmpty) {
        final firstResult = results.first as Map<String, dynamic>;
        return {
          'lat': double.parse(firstResult['lat'].toString()),
          'lng': double.parse(firstResult['lon'].toString()), // Nominatim uses 'lon'
        };
      } else {
        throw Exception('No geocoding results found for address: $address');
      }
    } else {
      throw Exception('Nominatim API error: ${response.statusCode}');
    }
  }

  Future<String> reverseGeocode(double lat, double lng) async {
    if (_lastRequestTime != null) {
      final timeSinceLast = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLast.inSeconds < 1) {
        await Future.delayed(const Duration(seconds: 1) - timeSinceLast);
      }
    }
    _lastRequestTime = DateTime.now();

    final uri = Uri.parse('${AppConstants.nominatimBaseUrl}/reverse?lat=$lat&lon=$lng&format=json');
    
    final response = await http.get(uri, headers: {
      'User-Agent': EnvConfig.nominatimUserAgent,
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = jsonDecode(response.body) as Map<String, dynamic>;
      return result['display_name'] as String? ?? 'Unknown Location';
    } else {
      throw Exception('Nominatim API error: ${response.statusCode}');
    }
  }
}

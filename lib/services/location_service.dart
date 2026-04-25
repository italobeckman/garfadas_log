import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json';

  Future<List<Map<String, dynamic>>> searchPlaces(String query, {String? city, String? state}) async {
    if (query.trim().isEmpty) return [];

    try {
      String searchTerms = query.trim();
      if (city != null && city.isNotEmpty) searchTerms += " in $city";
      if (state != null && state.isNotEmpty) searchTerms += ", $state";

      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

      final uri = Uri.parse(
        '$_baseUrl?query=${Uri.encodeComponent(searchTerms)}&type=restaurant&language=pt-BR&key=$apiKey',
      );
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);
        
        if (decodedResponse['status'] == 'OK' && decodedResponse['results'] != null) {
          final List<dynamic> results = decodedResponse['results'];
          
          return results.map((item) {
            String mappedType = 'establishment';
            if (item['types'] != null) {
              final typesList = item['types'] as List;
              if (typesList.contains('restaurant')) mappedType = 'restaurant';
              else if (typesList.contains('cafe')) mappedType = 'cafe';
              else if (typesList.contains('bakery')) mappedType = 'bakery';
              else if (typesList.contains('bar')) mappedType = 'bar';
              else if (typesList.contains('meal_takeaway') || typesList.contains('fast_food')) mappedType = 'fast_food';
            }

            return {
              'name': item['name'],
              'display_name': item['formatted_address'],
              'type': mappedType,
            };
          }).toList();
        } else {
          final errorMessage = decodedResponse['error_message'] ?? 'Sem mensagem de erro detalhada.';
          debugPrint('Google Places API Error/Status: ${decodedResponse['status']} - $errorMessage');
          return [];
        }
      } else {
        debugPrint('HTTP Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('LocationService Exception: $e');
      return [];
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  Future<List<Map<String, dynamic>>> searchPlaces(String query, {String? city, String? state}) async {
    if (query.trim().isEmpty) return [];

    try {
      String searchTerms = query.trim();
      if (city != null && city.isNotEmpty) searchTerms += " $city";
      if (state != null && state.isNotEmpty) searchTerms += " $state";
      searchTerms += " Brasil";
      
      debugPrint('SUPABASE EDGE FUNCTION QUERY: $searchTerms');
      
      // Chama a Edge Function criada no Supabase
      final response = await Supabase.instance.client.functions.invoke(
        'hyper-responder',
        body: {'query': searchTerms},
      );

      final data = response.data;

      if (data != null && data['status'] == 'OK' && data['results'] != null) {
        final List<dynamic> results = data['results'];
        
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
        final errorMessage = data != null ? data['error_message'] : 'Erro desconhecido';
        debugPrint('Edge Function / Google API Error: $errorMessage');
        return [];
      }
    } catch (e) {
      debugPrint('LocationService Exception: $e');
      return [];
    }
  }
}

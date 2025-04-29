import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'package:customer/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../model/palce_model.dart';

// Tu servicio de Google
class GoogleGeocodingService {
  final String apiKey;

  GoogleGeocodingService({required this.apiKey});
  double _deg2rad(double deg) => deg * (pi / 180);

  Future<Place?> reverseGeocode(double lat, double lng) async {
    final geocodeUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
    );

    final geocodeResponse = await http.get(geocodeUrl);

    if (geocodeResponse.statusCode == 200) {
      final geocodeData = jsonDecode(geocodeResponse.body);
      if (geocodeData['status'] == 'OK' && geocodeData['results'].isNotEmpty) {
        final firstResult = geocodeData['results'][0];
        final formattedAddress = firstResult['formatted_address'];
        final geometry = firstResult['geometry']['location'];
        final addressComponents =
            firstResult['address_components'] as List<dynamic>;
        final placeId = firstResult['place_id'];

        // Obtener detalles adicionales del lugar
        final placeDetails = await _getPlaceDetails(placeId, firstResult);

        print("placeDetails: $placeDetails");
        return Place(
            displayName: placeDetails['displayName'],
            lat: geometry['lat'],
            lon: geometry['lng']);
      }
    }

    return null;
  }

  Future<Map<String, dynamic>> _getPlaceDetails(
      String placeId, Map<String, dynamic> geocodeResult) async {
    final placeDetailsUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey',
    );

    final placeDetailsResponse = await http.get(placeDetailsUrl);

    if (placeDetailsResponse.statusCode == 200) {
      final detailsData = jsonDecode(placeDetailsResponse.body);

      if (detailsData['status'] == 'OK' && detailsData['result'] != null) {
        final result = detailsData['result'];
        final geometry = result['geometry']['location'];
        final latResult = (geometry['lat'] as num).toDouble();
        final lonResult = (geometry['lng'] as num).toDouble();

        String address = result['formatted_address'] ?? 'Sin dirección';
        if (RegExp(r'^[A-Z0-9]{4,}\+').hasMatch(address)) {
          final parts =
              address.split(',').skip(1).map((e) => e.trim()).toList();
          address = parts.join(', ');
        }

        final addressComponents = result['address_components'] as List<dynamic>;
        String city = '';

        for (var component in addressComponents) {
          final types = List<String>.from(component['types'] ?? []);
          if (types.contains('locality')) {
            city = component['long_name'];
          }
        }

        final countryComp = addressComponents.firstWhere(
          (comp) => (comp['types'] as List).contains('country'),
          orElse: () => null,
        );
        final country = countryComp != null
            ? countryComp['long_name'] as String
            : 'Desconocido';

        final displayName = '$address';

        return {
          'displayName': displayName,
          'nameDetails': result['name'],
        };
      }
    }

    return {};
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radio de la Tierra en km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
}

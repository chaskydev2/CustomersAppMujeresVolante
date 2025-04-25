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
        final placeDetails = await _getPlaceDetails(placeId);

        return Place(
          displayName: formattedAddress,
          lat: geometry['lat'],
          lon: geometry['lng'],
          extraTags: placeDetails['extraTags'],
          nameDetails: placeDetails['nameDetails'],
        );
      }
    }

    return null;
  }

  Future<Map<String, dynamic>> _getPlaceDetails(String placeId) async {
    final detailsUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,international_phone_number,website,opening_hours,rating,user_ratings_total&key=$apiKey',
    );

    final detailsResponse = await http.get(detailsUrl);

    if (detailsResponse.statusCode == 200) {
      final detailsData = jsonDecode(detailsResponse.body);
      if (detailsData['status'] == 'OK' && detailsData['result'] != null) {
        final result = detailsData['result'];

        // Puedes mapear los campos adicionales según tus necesidades
        final extraTags = ExtraTags(
          population: result['user_ratings_total']?.toString(),
          place: result['types'] != null && result['types'].isNotEmpty
              ? result['types'][0]
              : null,
        );

        final nameDetails = NameDetails(
          name: result['name'],
          nameEs:
              null, // Google no proporciona nombres en diferentes idiomas directamente
          nameEn: null,
        );

        return {
          'extraTags': extraTags,
          'nameDetails': nameDetails,
        };
      }
    }

    return {
      'extraTags': null,
      'nameDetails': null,
    };
  }

  Future<List<Place>> search(String query,
      {required double centerLat, required double centerLon}) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final List<Place> places = [];

        for (final result in data['results']) {
          final location = result['geometry']['location'];
          final lat = location['lat'];
          final lon = location['lng'];

          final distance = _calculateDistance(centerLat, centerLon, lat, lon);
          if (distance > 50) continue;

          final formattedAddress = result['formatted_address'];
          final placeId = result['place_id'];

          final placeDetails = await _getPlaceDetails(placeId);

          places.add(
            Place(
              displayName: formattedAddress,
              lat: lat,
              lon: lon,
              extraTags: placeDetails['extraTags'],
              nameDetails: placeDetails['nameDetails'],
            ),
          );
        }

        return places;
      }
    }

    return [];
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

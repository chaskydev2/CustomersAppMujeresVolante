import 'dart:convert';
import 'dart:developer';
import 'package:customer/model/palce_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:customer/utils/utils.dart';
import 'dart:math';

class OsmSearchPlaceController extends GetxController {
  Rx<TextEditingController> searchTxtController = TextEditingController().obs;
  RxList<Place> suggestionsList = <Place>[].obs;
  final String apiKeyNew = 'AIzaSyBF8F0YnhknJa_cvyMmaJvRVTqPS-somdk';

  @override
  void onInit() {
    super.onInit();
    searchTxtController.value.addListener(() {
      _onChanged();
    });
  }

  _onChanged() {
    fetchAddress(searchTxtController.value.text);
  }

  fetchAddress(String text) async {
    if (text.isEmpty) {
      suggestionsList.clear();
      return;
    }

    List<Place> results = await searchInBolivia(text);
    print(":: fetchAddress (BO) :: ${results}");
    suggestionsList.value = results;
  }

  Future<List<Place>> searchInBolivia(String text) async {
    final locationData = await Utils.getCurrentLocation();
    final lat = locationData.latitude;
    final lon = locationData.longitude;

    final urlAutocomplete = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$text'
      '&components=country:BO'
      '&location=$lat,$lon'
      '&radius=50000' // 50km a la redonda, ajustable
      '&types=establishment'
      '&key=$apiKeyNew',
    );

    final responseAutocomplete = await http.get(urlAutocomplete);
    if (responseAutocomplete.statusCode != 200) {
      throw Exception(
          "Error del servidor (autocomplete): ${responseAutocomplete.statusCode}");
    }

    final autoData = jsonDecode(responseAutocomplete.body);
    final predictions = autoData['predictions'] as List<dynamic>?;

    if (autoData['status'] != 'OK' ||
        predictions == null ||
        predictions.isEmpty) {
      print(
          "Google Places Autocomplete API status=${autoData['status']}, resultados=${predictions?.length ?? 0}");
      return <Place>[];
    }

    List<Place> searchResults = [];

    for (final prediction in predictions) {
      final placeId = prediction['place_id'];
      final urlDetails = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,geometry,address_components,formatted_address&key=$apiKeyNew',
      );

      final responseDetails = await http.get(urlDetails);
      if (responseDetails.statusCode != 200) {
        continue; // Saltamos si falla este lugar
      }

      final detailsData = jsonDecode(responseDetails.body);
      if (detailsData['status'] != 'OK' || detailsData['result'] == null) {
        continue;
      }

      final result = detailsData['result'];
      final geometry = result['geometry']['location'];
      final latResult = (geometry['lat'] as num).toDouble();
      final lonResult = (geometry['lng'] as num).toDouble();

      // Calculamos la distancia desde la ubicación actual
      final distance = calculateDistance(lat, lon, latResult, lonResult);
      if (distance > 50) continue;

      // Obtenemos la dirección formateada
      String address = result['formatted_address'] ?? 'Sin dirección';

      // Verificar y eliminar el Plus Code si está presente en la dirección
      if (RegExp(r'^[A-Z0-9]{4,}\+').hasMatch(address)) {
        final parts = address.split(',').skip(1).map((e) => e.trim()).toList();
        address = parts.join(', ');
      }

      // Obtener los componentes de la dirección (por ejemplo, ciudad)
      final addressComponents = result['address_components'] as List<dynamic>;
      String city = '';

      for (var component in addressComponents) {
        final types = List<String>.from(component['types'] ?? []);
        if (types.contains('locality')) {
          city = component['long_name'];
        }
      }

      // Buscar componente de país
      final countryComp = addressComponents.firstWhere(
        (comp) => (comp['types'] as List).contains('country'),
        orElse: () => null,
      );
      final country = countryComp != null
          ? countryComp['long_name'] as String
          : 'Desconocido';

      /*
      searchResults.add(
        SearchInfo(
          point: GeoPoint(latitude: latResult, longitude: lonResult),
          address: Address(
            country: country,
            name: address,
            city: city, // Solo incluimos la ciudad
          ),
        ),
      );
      */

      searchResults
          .add(Place(displayName: address, lat: latResult, lon: lonResult));
    }

    return searchResults;
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // Radio de la Tierra en kilómetros

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Retorna la distancia en kilómetros
  }

  double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
}

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:customer/utils/utils.dart';
import 'dart:math';

class OsmSearchPlaceController extends GetxController {
  Rx<TextEditingController> searchTxtController = TextEditingController().obs;
  RxList<SearchInfo> suggestionsList = <SearchInfo>[].obs;
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

    List<SearchInfo> results = await searchInBolivia(text);
    print(":: fetchAddress (BO) :: ${results}");
    suggestionsList.value = results;
  }

  Future<List<SearchInfo>> searchInBolivia(String text) async {
    final locationData = await Utils.getCurrentLocation();
    final lat = locationData.latitude;
    final lon = locationData.longitude;

    final searchQuery = "$text, Cochabamba, Bolivia";
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=$searchQuery&key=$apiKeyNew',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception("Error del servidor: código ${response.statusCode}");
    }

    final detailsData = jsonDecode(response.body);
    final status = detailsData['status'] as String? ?? 'UNKNOWN';
    final results = detailsData['results'] as List<dynamic>?;

    // Si no es OK, simplemente regresamos lista vacía en lugar de excepción
    if (status != 'OK' || results == null || results.isEmpty) {
      print(
          "Google Geocode API status=$status, resultados=${results?.length ?? 0}");
      return <SearchInfo>[];
    }

    // Filtro para asegurarse de que solo se devuelvan resultados dentro de 50 km
    return results.where((e) {
      final latResult = (e['geometry']['location']['lat'] as num).toDouble();
      final lonResult = (e['geometry']['location']['lng'] as num).toDouble();

      // Calcula la distancia entre la ubicación actual y el resultado
      double distance = calculateDistance(lat, lon, latResult, lonResult);
      return distance <= 50; // Filtra por 50 km
    }).map((e) {
      final latResult = (e['geometry']['location']['lat'] as num).toDouble();
      final lonResult = (e['geometry']['location']['lng'] as num).toDouble();
      final address = e['formatted_address'] as String;

      // Busca el componente de país
      final countryComp = (e['address_components'] as List<dynamic>).firstWhere(
        (comp) => (comp['types'] as List).contains('country'),
        orElse: () => null,
      );
      final country = countryComp != null
          ? countryComp['long_name'] as String
          : 'Desconocido';

      return SearchInfo(
        point: GeoPoint(latitude: latResult, longitude: lonResult),
        address: Address(
          country: country,
          name: address,
        ),
      );
    }).toList();
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

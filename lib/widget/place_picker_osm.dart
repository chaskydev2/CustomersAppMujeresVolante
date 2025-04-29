import 'package:customer/services/googleGeocodingService.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/osm_map_search_place.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Importa Google Maps
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../model/palce_model.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? selectedLocation;
  late GoogleMapController mapController;
  Place? place;

  TextEditingController textController = TextEditingController();
  Set<Marker> _markers = {}; // Utilizamos un conjunto de marcadores

  final GoogleGeocodingService geocodingService =
      GoogleGeocodingService(apiKey: 'AIzaSyBF8F0YnhknJa_cvyMmaJvRVTqPS-somdk');

  CameraPosition? _currentCameraPosition;

  SearchInfo? places;

  @override
  void initState() {
    super.initState();
  }

  _listerTapPosition(lt, lg) async {
    try {
      final placeResult = await geocodingService.reverseGeocode(
        lt,
        lg,
      );

      if (placeResult != null) {
        setState(() {
          place = placeResult;
        });
      } else {
        print('No se pudo obtener información del lugar.');
      }
    } catch (e) {
      print('Error en reverseGeocode: $e');
    }
  }

  addMarker(LatLng position) async {
    // Agregar marcador en la nueva ubicación
    setState(() {
      _markers.clear(); // Limpiar los marcadores anteriores
      _markers.add(Marker(
        markerId: MarkerId('selected_location'),
        position: position,
        icon: BitmapDescriptor
            .defaultMarker, // Puedes cambiar el ícono si lo deseas
      ));
    });

    // Geocodificación inversa

    try {
      final placeResult = await geocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (placeResult != null) {
        setState(() {
          place = placeResult;
        });
      } else {
        print('No se pudo obtener información del lugar.');
      }
    } catch (e) {
      print('Error en reverseGeocode: $e');
    }
  }

  Future<void> _setUserLocation() async {
    try {
      final locationData = await Utils.getCurrentLocation();
      final selected = LatLng(locationData.latitude, locationData.longitude);

      setState(() {
        selectedLocation = selected;
      });
      print("Selected Location: $selectedLocation");

      await addMarker(selected);
      await mapController.animateCamera(CameraUpdate.newLatLng(selected));

      try {
        final placeResult = await geocodingService.reverseGeocode(
          selected.latitude,
          selected.longitude,
        );

        if (placeResult != null) {
          setState(() {
            place = placeResult;
          });
        } else {
          print('No se pudo obtener información del lugar.');
        }
      } catch (e) {
        print('Error en reverseGeocode: $e');
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Picker'.tr),
      ),
      body: Stack(
        children: [
          GoogleMap(
              initialCameraPosition: CameraPosition(
                target: selectedLocation ??
                    LatLng(0.0,
                        0.0), // Asegúrate de tener una ubicación predeterminada
                zoom: 14,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _setUserLocation();
              },
              markers: _markers,
              onTap: (LatLng position) {
                addMarker(position);
              },
              onCameraMove: (CameraPosition position) {
                _currentCameraPosition = position;
              }),
          if (place?.displayName != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place?.displayName ?? '',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          Get.back(result: place);
                        },
                        icon: const Icon(
                          Icons.check_circle,
                          size: 40,
                          color: Colors.black,
                        ))
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 00),
                  child: InkWell(
                    onTap: () async {
                      Get.to(const OsmSearchPlacesApi())?.then((value) async {
                        if (value != null) {
                          print("Search :: ${value.lat}");
                          print("Search :: ${value.lon}");
                          SearchInfo place = SearchInfo(
                            address: value.displayName ?? '',
                            point: LatLng(
                              value.lat,
                              value.lon,
                            ),
                          );

                          print("SearchText :: ${place.address}");
                          print("SearchTextPoint :: ${place.point}");
                          textController = TextEditingController(
                              text: place.address..toString());
                          await addMarker(place.point);

                          if (mapController != null) {
                            _listerTapPosition(
                                place.point.latitude, place.point.longitude);
                            mapController.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: place.point,
                                  zoom:
                                      16, // Puedes ajustar el zoom como quieras
                                ),
                              ),
                            );
                          }
                          // print("Search :: ${place.point.toString()}");
                        }
                      });
                    },
                    child: buildTextField(
                      title: "Search Address".tr,
                      textController: textController,
                    ),
                  ),
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setUserLocation,
        child: Icon(Icons.my_location,
            color: themeChange.getThem()
                ? AppColors.darkModePrimary
                : AppColors.primary),
      ),
    );
  }

  Widget buildTextField(
      {required title, required TextEditingController textController}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: TextField(
        controller: textController,
        textInputAction: TextInputAction.done,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: const Icon(
              Icons.location_on,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: title,
          hintStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabled: false,
        ),
      ),
    );
  }
}

class SearchInfo {
  final String address; // Dirección del lugar
  final LatLng point; // Coordenadas del lugar (latitud y longitud)

  SearchInfo({required this.address, required this.point});

  // Método para crear un objeto SearchInfo desde un JSON (útil si la búsqueda proviene de una API)
  factory SearchInfo.fromJson(Map<String, dynamic> json) {
    return SearchInfo(
      address: json['address'] ?? '',
      point: LatLng(
        json['latitude'] ?? 0.0,
        json['longitude'] ?? 0.0,
      ),
    );
  }

  // Método para convertir el objeto a un mapa (JSON), por si necesitas enviarlo o almacenarlo
  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': point.latitude,
      'longitude': point.longitude,
    };
  }
}

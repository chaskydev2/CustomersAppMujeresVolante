import 'dart:math';
import 'dart:async';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/fire_store_utils.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingController extends GetxController {
  final String mapAPIKey = "AIzaSyBF8F0YnhknJa_cvyMmaJvRVTqPS-somdk";
  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    addMarkerSetup();
    getArgument();
    // playSound();
  }

  @override
  void onClose() {
    ShowToastDialog.closeLoader();
    super.onClose();
  }

  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;
  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<InterCityOrderModel> intercityOrderModel = InterCityOrderModel().obs;

  RxBool isLoading = true.obs;
  RxString type = "".obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    print("==== Argumentos recibidos ====");
    print(argumentData);

    if (argumentData != null) {
      type.value = argumentData['type'];
      print("Tipo de orden: ${type.value}");

      if (type.value == "orderModel") {
        OrderModel argumentOrderModel = argumentData['orderModel'];
        print("Datos del modelo de orden:");
        print("==== Ubicación de origen (pasajero) ====");
        print("Latitud: ${argumentOrderModel.sourceLocationLAtLng?.latitude}");
        print(
            "Longitud: ${argumentOrderModel.sourceLocationLAtLng?.longitude}");

        print("==== Ubicación de destino ====");
        print(
            "Latitud: ${argumentOrderModel.destinationLocationLAtLng?.latitude}");
        print(
            "Longitud: ${argumentOrderModel.destinationLocationLAtLng?.longitude}");

        // Agregar el marcador del pasajero INMEDIATAMENTE
        if (argumentOrderModel.sourceLocationLAtLng?.latitude != null &&
            argumentOrderModel.sourceLocationLAtLng?.longitude != null) {
          // Limpiar marcadores existentes
          markers.clear();

          // Agregar el marcador rojo del pasajero
          addMarker(
              latitude: argumentOrderModel.sourceLocationLAtLng!.latitude,
              longitude: argumentOrderModel.sourceLocationLAtLng!.longitude,
              id: "Pasajero",
              descriptor: BitmapDescriptor.defaultMarker,
              rotation: 0.0);

          // Agregar el marcador del conductor inmediatamente
          if (driverUserModel.value.location != null) {
            addMarker(
                latitude: driverUserModel.value.location!.latitude,
                longitude: driverUserModel.value.location!.longitude,
                id: "Conductor",
                descriptor: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
                rotation: driverUserModel.value.rotation);

            // Trazar la ruta inmediatamente
            getPolyline(
                sourceLatitude: driverUserModel.value.location!.latitude,
                sourceLongitude: driverUserModel.value.location!.longitude,
                destinationLatitude:
                    argumentOrderModel.sourceLocationLAtLng!.latitude,
                destinationLongitude:
                    argumentOrderModel.sourceLocationLAtLng!.longitude);
          }

          // Mover la cámara para mostrar toda la ruta
          if (mapController != null) {
            mapController!.animateCamera(CameraUpdate.newLatLngBounds(
                LatLngBounds(
                    southwest: LatLng(
                        min(
                            driverUserModel.value.location!.latitude ?? 0,
                            argumentOrderModel.sourceLocationLAtLng!.latitude ??
                                0),
                        min(
                            driverUserModel.value.location!.longitude ?? 0,
                            argumentOrderModel
                                    .sourceLocationLAtLng!.longitude ??
                                0)),
                    northeast: LatLng(
                        max(
                            driverUserModel.value.location!.latitude ?? 0,
                            argumentOrderModel.sourceLocationLAtLng!.latitude ??
                                0),
                        max(
                            driverUserModel.value.location!.longitude ?? 0,
                            argumentOrderModel
                                    .sourceLocationLAtLng!.longitude ??
                                0))),
                100 // padding
                ));
          }

          print("🔴 Marcadores y ruta agregados inicialmente");
        }

        FireStoreUtils.fireStore
            .collection(CollectionName.orders)
            .doc(argumentOrderModel.id)
            .snapshots()
            .listen((event) {
          if (event.data() != null) {
            OrderModel orderModelStream = OrderModel.fromJson(event.data()!);

            orderModel.value = orderModelStream;
            FireStoreUtils.fireStore
                .collection(CollectionName.driverUsers)
                .doc(argumentOrderModel.driverId)
                .snapshots()
                .listen((event) {
              if (event.data() != null) {
                driverUserModel.value = DriverUserModel.fromJson(event.data()!);
                print("==== Datos del conductor ====");
                print(
                    "Ubicación del conductor: ${driverUserModel.value.location?.latitude}, ${driverUserModel.value.location?.longitude}");

                // Actualizar marcador y ruta cuando el conductor se mueve
                if (driverUserModel.value.location != null) {
                  // Actualizar marcador del conductor
                  addMarker(
                      latitude: driverUserModel.value.location!.latitude,
                      longitude: driverUserModel.value.location!.longitude,
                      id: "Conductor",
                      descriptor: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue),
                      rotation: driverUserModel.value.rotation);

                  // Actualizar la ruta
                  getPolyline(
                      sourceLatitude: driverUserModel.value.location!.latitude,
                      sourceLongitude:
                          driverUserModel.value.location!.longitude,
                      destinationLatitude:
                          orderModel.value.sourceLocationLAtLng!.latitude,
                      destinationLongitude:
                          orderModel.value.sourceLocationLAtLng!.longitude);
                }
              }
            });

            if (orderModel.value.status == Constant.rideComplete) {
              Get.back();
            }
          }
        });
      } else {
        InterCityOrderModel argumentOrderModel =
            argumentData['interCityOrderModel'];
        print("Datos del modelo de orden intercity:");
        print("Source: ${argumentOrderModel.sourceLocationLAtLng}");
        print("Destination: ${argumentOrderModel.destinationLocationLAtLng}");

        FireStoreUtils.fireStore
            .collection(CollectionName.ordersIntercity)
            .doc(argumentOrderModel.id)
            .snapshots()
            .listen((event) {
          if (event.data() != null) {
            InterCityOrderModel orderModelStream =
                InterCityOrderModel.fromJson(event.data()!);
            print("====>");
            intercityOrderModel.value = orderModelStream;
            FireStoreUtils.fireStore
                .collection(CollectionName.driverUsers)
                .doc(argumentOrderModel.driverId)
                .snapshots()
                .listen((event) {
              if (event.data() != null) {
                driverUserModel.value = DriverUserModel.fromJson(event.data()!);
                if (Constant.selectedMapType != 'osm') {
                  if (intercityOrderModel.value.status ==
                      Constant.rideInProgress) {
                    getPolyline(
                        sourceLatitude:
                            driverUserModel.value.location!.latitude,
                        sourceLongitude:
                            driverUserModel.value.location!.longitude,
                        destinationLatitude: intercityOrderModel
                            .value.destinationLocationLAtLng!.latitude,
                        destinationLongitude: intercityOrderModel
                            .value.destinationLocationLAtLng!.longitude);
                  } else {
                    getPolyline(
                        sourceLatitude:
                            driverUserModel.value.location!.latitude,
                        sourceLongitude:
                            driverUserModel.value.location!.longitude,
                        destinationLatitude: intercityOrderModel
                            .value.sourceLocationLAtLng!.latitude,
                        destinationLongitude: intercityOrderModel
                            .value.sourceLocationLAtLng!.longitude);
                  }
                }
              }
            });

            if (intercityOrderModel.value.status == Constant.rideComplete) {
              Get.back();
            }
          }
        });
      }
    }
    isLoading.value = false;
    update();
  }

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? driverIcon;

  void getPolyline(
      {required double? sourceLatitude,
      required double? sourceLongitude,
      required double? destinationLatitude,
      required double? destinationLongitude}) async {
    print("==== Trazando ruta del conductor al pasajero ====");

    // Verificar API key primero
    print("API Key actual: '${mapAPIKey}'");
    print("API Key length: ${mapAPIKey.length}");

    if (mapAPIKey.isEmpty) {
      print("❌ Error: API key de Google Maps no configurada");
      return;
    }
    print("API Key configurada: ${mapAPIKey}");

    if (sourceLatitude != null &&
        sourceLongitude != null &&
        destinationLatitude != null &&
        destinationLongitude != null) {
      try {
        print(
            "Obteniendo ruta desde ($sourceLatitude, $sourceLongitude) hasta ($destinationLatitude, $destinationLongitude)");

        final request = PolylineRequest(
          origin: PointLatLng(sourceLatitude, sourceLongitude),
          destination: PointLatLng(destinationLatitude, destinationLongitude),
          mode: TravelMode.driving,
        );

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
            googleApiKey: mapAPIKey, request: request);

        print("Respuesta de Google: ${result.errorMessage ?? 'Sin errores'}");
        print("Puntos recibidos: ${result.points.length}");

        if (result.points.isNotEmpty) {
          List<LatLng> polylineCoordinates = result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          PolylineId id = const PolylineId("poly");
          final Polyline polyline = Polyline(
              polylineId: id,
              color: Colors.blue,
              points: polylineCoordinates,
              width: 5,
              geodesic: true);

          polyLines.clear();
          polyLines[id] = polyline;
          print("✅ Ruta trazada con ${polylineCoordinates.length} puntos");

          // Forzar actualización de la UI
          update();
        } else {
          print("❌ No se recibieron puntos para la ruta");
          print("Error message: ${result.errorMessage}");

          // Si falla, al menos dibujar una línea recta
          PolylineId id = const PolylineId("poly");
          final Polyline polyline = Polyline(
            polylineId: id,
            color: Colors.blue,
            points: [
              LatLng(sourceLatitude, sourceLongitude),
              LatLng(destinationLatitude, destinationLongitude)
            ],
            width: 5,
          );

          polyLines.clear();
          polyLines[id] = polyline;
          update();
        }
      } catch (e) {
        print("❌ Error al trazar la ruta: $e");
      }
    } else {
      print("❌ Coordenadas incompletas para trazar la ruta");
    }
    print("==== Trazando ruta del conductor al pasajero ====");

    if (sourceLatitude != null &&
        sourceLongitude != null &&
        destinationLatitude != null &&
        destinationLongitude != null) {
      try {
        // 1. Crear el request para obtener la ruta
        final request = PolylineRequest(
          origin: PointLatLng(sourceLatitude, sourceLongitude),
          destination: PointLatLng(destinationLatitude, destinationLongitude),
          mode: TravelMode.driving,
        );

        // 2. Obtener la ruta de Google
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
            googleApiKey: mapAPIKey, request: request);

        print("Respuesta de Google: ${result.errorMessage ?? 'Sin errores'}");

        // 3. Si tenemos puntos, crear la polyline
        if (result.points.isNotEmpty) {
          // Convertir los puntos a coordenadas para el mapa
          List<LatLng> polylineCoordinates = result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          // Crear la polyline
          PolylineId id = const PolylineId("poly");
          final Polyline polyline = Polyline(
              polylineId: id,
              color: Colors.blue,
              points: polylineCoordinates,
              width: 3,
              geodesic: true);

          // Agregar la polyline al mapa
          polyLines.clear(); // Limpiar polylines anteriores
          polyLines[id] = polyline;

          print("✅ Ruta trazada con ${polylineCoordinates.length} puntos");

          // Actualizar la UI
          update();
        } else {
          print("❌ Error al obtener la ruta: ${result.errorMessage}");
        }
      } catch (e) {
        print("❌ Error al trazar la ruta: $e");
      }
    }
  }

  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;

  addMarker(
      {required double? latitude,
      required double? longitude,
      required String id,
      required BitmapDescriptor descriptor,
      required double? rotation}) {
    if (latitude == null || longitude == null) {
      print("Error: Coordenadas nulas para el marcador $id");
      return;
    }

    print("Agregando marcador: $id en ($latitude, $longitude)");
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(
        markerId: markerId,
        position: LatLng(latitude, longitude),
        icon: descriptor,
        infoWindow: InfoWindow(title: id),
        visible: true);
    markers[markerId] = marker;
    update(); // Forzar actualización de la UI
    print("Marcador agregado. Total de marcadores: ${markers.length}");
  }

  addMarkerSetup() async {
    print("==== Inicializando marcadores ====");
    try {
      // Usar marcadores predeterminados de Google Maps
      departureIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed); // Punto rojo para origen
      destinationIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen); // Punto verde para destino
      driverIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue); // Punto azul para conductor

      print("Marcadores predeterminados configurados exitosamente");
    } catch (e) {
      print("Error al configurar los marcadores: $e");
    }
  }

  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;
  PolylinePoints polylinePoints = PolylinePoints();

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null) return;

    LatLngBounds bounds;

    if (source.latitude > destination.latitude &&
        source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(source.latitude, destination.longitude),
          northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destination.latitude, source.longitude),
          northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 10);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(
      CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }
}

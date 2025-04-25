import 'dart:convert';

import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'dart:math';

class HomeController extends GetxController {
  DashBoardController dashboardController = Get.put(DashBoardController());

  Rx<TextEditingController> sourceLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> destinationLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> offerYourRateController =
      TextEditingController().obs;
  Rx<ServiceModel> selectedType = ServiceModel().obs;

  Rx<LocationLatLng> sourceLocationLAtLng = LocationLatLng().obs;
  Rx<LocationLatLng> destinationLocationLAtLng = LocationLatLng().obs;

  RxString currentLocation = "".obs;
  RxBool isLoading = true.obs;
  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;
  RxList bannerList = <BannerModel>[].obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxBool isAcSelected = false.obs;
  RxDouble extraDistance = 0.0.obs;
  final PageController pageController =
      PageController(viewportFraction: 0.96, keepPage: true);

  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  String? startNightTime;
  String? endNightTime;
  DateTime startNightTimeString = DateTime.now();
  DateTime endNightTimeString = DateTime.now();

  @override
  void onInit() {
    // TODO: implement onInit
    getLocation();
    getServiceType();
    getPaymentData();
    getContact();
    super.onInit();
  }

  Future<void> getLocation() async {
    try {
      Constant.currentLocation = await Utils.getCurrentLocation();
      if (Constant.currentLocation == null) return;

      if (Constant.selectedMapType == 'google') {
        List<Placemark> placeMarks = await placemarkFromCoordinates(
          Constant.currentLocation!.latitude,
          Constant.currentLocation!.longitude,
        );
        Constant.country = placeMarks.first.country;
        Constant.city = placeMarks.first.locality;
        currentLocation.value =
            "${placeMarks.first.name}, ${placeMarks.first.subLocality}, ${placeMarks.first.locality}, ${placeMarks.first.administrativeArea}, ${placeMarks.first.postalCode}, ${placeMarks.first.country}";
      } else {
        Place place = await Nominatim.reverseSearch(
          lat: Constant.currentLocation!.latitude,
          lon: Constant.currentLocation!.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
        );
        currentLocation.value = place.displayName.toString();
        Constant.country = place.address?['country'] ?? '';
        Constant.city = place.address?['city'] ?? '';
      }
    } catch (e) {
      ShowToastDialog.showToast(
        "Location access permission is currently unavailable. You're unable to retrieve any location data. Please grant permission from your device settings.",
        duration: const Duration(seconds: 3),
      );
    }
  }

  getServiceType() async {
    await FireStoreUtils.getService().then((value) {
      serviceList.value = value;
      if (serviceList.isNotEmpty) {
        selectedType.value = serviceList.first;
      }
    });

    await FireStoreUtils.getBanner().then((value) {
      bannerList.value = value;
    });

    await FireStoreUtils().getTaxList().then((value) {
      if (value != null) {
        Constant.taxList = value;
      }
    });

    await FireStoreUtils().getAirports().then((value) {
      if (value != null) {
        Constant.airaPortList = value;
      }
    });

    String token = await NotificationService.getToken();
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      userModel.value = value!;
      userModel.value.fcmToken = token;
      FireStoreUtils.updateUser(userModel.value);
    });

    isLoading.value = false;
  }

  RxString duration = "".obs;
  RxString distance = "".obs;
  RxString amount = "".obs;
  RxString acCharge = "".obs;
  RxString nonAcCharge = "".obs;
  RxString basicFare = "".obs;
  RxString basicFareCharge = "".obs;
  RxString nightCharge = "".obs;
  RxDouble totalAmount = 0.0.obs;
  RxDouble totalNightFare = 0.0.obs;
  RxBool isAcNonAc = false.obs;
  DateTime currentTime = DateTime.now();
  DateTime currentDate = DateTime.now();

  double convertToMinutes(String duration) {
    double durationValue = 0.0;

    try {
      final RegExp hoursRegex = RegExp(r"(\d+)\s*hour");
      final RegExp minutesRegex = RegExp(r"(\d+)\s*min");

      final Match? hoursMatch = hoursRegex.firstMatch(duration);
      if (hoursMatch != null) {
        int hours = int.parse(hoursMatch.group(1)!.trim());
        durationValue += hours * 60;
      }

      final Match? minutesMatch = minutesRegex.firstMatch(duration);
      if (minutesMatch != null) {
        int minutes = int.parse(minutesMatch.group(1)!.trim());
        durationValue += minutes;
      }
    } catch (e) {
      print("Exception: $e");
      throw FormatException("Invalid duration format: $duration");
    }

    return durationValue;
  }

  calculateDurationAndDistance() async {
    if (Constant.selectedMapType == 'osm') {
      if (sourceLocationLAtLng.value.latitude != null &&
          destinationLocationLAtLng.value.latitude != null) {
        ShowToastDialog.showLoader("Please wait");
        await Constant.getDurationOsmDistance(
                LatLng(sourceLocationLAtLng.value.latitude!,
                    sourceLocationLAtLng.value.longitude!),
                LatLng(destinationLocationLAtLng.value.latitude!,
                    destinationLocationLAtLng.value.longitude!))
            .then((value) {
          if (value != {} && value.isNotEmpty) {
            int hours = value['routes'].first['duration'] ~/ 3600;
            int minutes =
                ((value['routes'].first['duration'] % 3600) / 60).round();
            duration.value = '$hours hours $minutes minutes'.trim();
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value['routes'].first['distance'] / 1000).toString();
            } else {
              distance.value =
                  (value['routes'].first['distance'] / 1609.34).toString();
            }
          }
          update();
        });
      }
      ShowToastDialog.closeLoader();
    } else {
      if (sourceLocationLAtLng.value.latitude != null &&
          destinationLocationLAtLng.value.latitude != null) {
        ShowToastDialog.showLoader("Please wait");
        await Constant.getDurationDistance(
                LatLng(sourceLocationLAtLng.value.latitude!,
                    sourceLocationLAtLng.value.longitude!),
                LatLng(destinationLocationLAtLng.value.latitude!,
                    destinationLocationLAtLng.value.longitude!))
            .then((value) {
          if (value != null) {
            duration.value =
                value.rows!.first.elements!.first.duration!.text.toString();
            print("duration :: 00 :: ${duration.value}");
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value.rows!.first.elements!.first.distance!.value!.toInt() /
                          1000)
                      .toString();
            } else {
              distance.value =
                  (value.rows!.first.elements!.first.distance!.value!.toInt() /
                          1609.34)
                      .toString();
            }
          }
          update();
        });
        ShowToastDialog.closeLoader();
      }
    }
  }

  calculateAmount() async {
    acCharge.value = selectedType.value.acCharge.toString();
    nonAcCharge.value = selectedType.value.nonAcCharge.toString();
    basicFare.value = selectedType.value.basicFare.toString();
    basicFareCharge.value = selectedType.value.basicFareCharge.toString();
    isAcNonAc.value = selectedType.value.isAcNonAc ?? false;
    String formatTime(String? time) {
      if (time == null || !time.contains(":")) {
        return "00:00";
      }
      List<String> parts = time.split(':');
      if (parts.length != 2) return "00:00";
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
    }

    startNightTime = formatTime(selectedType.value.startNightTime);
    endNightTime = formatTime(selectedType.value.endNightTime);

    List<String> startParts = startNightTime!.split(':');
    List<String> endParts = endNightTime!.split(':');

    startNightTimeString = DateTime(currentDate.year, currentDate.month,
        currentDate.day, int.parse(startParts[0]), int.parse(startParts[1]));
    endNightTimeString = DateTime(currentDate.year, currentDate.month,
        currentDate.day, int.parse(endParts[0]), int.parse(endParts[1]));

    nightCharge.value = selectedType.value.nightCharge.toString();

    basicFare.value = '50';

    if (sourceLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.latitude != null) {
      double durationValueInMinutes = convertToMinutes(duration.toString());
      if (double.parse(distance.value.isNotEmpty ? distance.value : '0') <=
          double.parse(basicFare.value.isNotEmpty ? basicFare.value : '0')) {
        amount.value = 40.toString();

        totalNightFare.value =
            double.parse(amount.value.isNotEmpty ? amount.value : '0');
        if (currentTime.isAfter(startNightTimeString) &&
            currentTime.isBefore(endNightTimeString)) {
          amount.value = (totalNightFare.value *
                  double.parse(nightCharge.value.toString().isNotEmpty
                      ? nightCharge.value.toString()
                      : '0'))
              .toStringAsFixed(2);
        }
      } else {
        double distanceValue = double.tryParse(distance.value) ??
            Random().nextDouble() * 10; // Valor aleatorio si es null
        double basicFareValue = double.tryParse(basicFare.value) ??
            Random().nextDouble() * 10; // Valor aleatorio si es null
        double extraDist = distanceValue - basicFareValue;
        extraDistance.value = extraDist;
        double nonAcChargeValue =
            double.tryParse(nonAcCharge.value.toString()) ??
                Random().nextDouble() * 10; // Valor aleatorio si es null
        double acChargeValue = double.tryParse(acCharge.value.toString()) ??
            Random().nextDouble() * 10; // Valor aleatorio si es null
        double perKmCharge = isAcNonAc.value == true
            ? isAcSelected.value == false
                ? nonAcChargeValue
                : acChargeValue
            : double.tryParse(selectedType.value.kmCharge.toString()) ??
                Random().nextDouble() * 10; // Valor aleatorio si es null
        double perMinuteCharge =
            double.tryParse(selectedType.value.perMinuteCharge.toString()) ??
                Random().nextDouble() * 10; // Valor aleatorio si es null
        double durationInMinutes =
            double.tryParse(durationValueInMinutes.toString()) ??
                Random().nextDouble() * 10; // Valor aleatorio si es null
        double basicFareChargeValue =
            double.tryParse(basicFareCharge.value.toString()) ??
                Random().nextDouble() * 10; // Valor aleatorio si es null
        totalAmount.value = (perKmCharge * extraDist) +
            (durationInMinutes * perMinuteCharge) +
            basicFareChargeValue;

        totalNightFare.value = totalAmount.value;
        amount.value = totalNightFare.value.toStringAsFixed(2);

        if (currentTime.isAfter(startNightTimeString) &&
            currentTime.isBefore(endNightTimeString)) {
          amount.value = (totalNightFare.value *
                  double.parse(nightCharge.value.toString().isNotEmpty
                      ? nightCharge.value.toString()
                      : '0'))
              .toStringAsFixed(2);
        }
      }
      offerYourRateController.value.text = amount.value;
    }
    update();
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  RxString selectedPaymentMethod = "".obs;

  RxList airPortList = <AriPortModel>[].obs;

  getPaymentData() async {
    await FireStoreUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
      }
    });

    await FireStoreUtils().getZone().then((value) {
      if (value != null) {
        zoneList.value = value;
      }
    });
  }

  RxList<ContactModel> contactList = <ContactModel>[].obs;
  Rx<ContactModel> selectedTakingRide =
      ContactModel(fullName: "Myself", contactNumber: "").obs;
  Rx<AriPortModel> selectedAirPort = AriPortModel().obs;

  setContact() {
    print(jsonEncode(contactList));
    Preferences.setString(
        Preferences.contactList,
        json.encode(contactList
            .map<Map<String, dynamic>>((music) => music.toJson())
            .toList()));
    getContact();
  }

  getContact() {
    String contactListJson = Preferences.getString(Preferences.contactList);

    if (contactListJson.isNotEmpty) {
      print("---->");
      contactList.clear();
      contactList.value = (json.decode(contactListJson) as List<dynamic>)
          .map<ContactModel>((item) => ContactModel.fromJson(item))
          .toList();
    }
  }
}

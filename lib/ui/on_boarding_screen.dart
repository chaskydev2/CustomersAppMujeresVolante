import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controller/on_boarding_controller.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/ui/auth_screen/login_screen.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<OnBoardingController>(
      init: OnBoardingController(),
      builder: (controller) {
        return Scaffold(
          body: controller.isLoading.value
              ? Constant.loader()
              : Stack(
                  children: [
                    // Imagen de fondo con opacidad
                    Positioned.fill(
                      child: Stack(
                        children: [
                          // Imagen correspondiente al índice
                          Image.asset(
                            controller.selectedPageIndex.value == 0
                                ? "assets/images/driver-woman.jpg"
                                : "assets/images/mujeresvolante.png",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          // Capa de color con opacidad
                          Container(
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),

                    // Contenido del onboarding
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: PageView.builder(
                              controller: controller.pageController,
                              onPageChanged: controller.selectedPageIndex.call,
                              itemCount: 2, // Limitar a 2 pasos
                              itemBuilder: (context, index) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 90),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(40),
                                        child: CachedNetworkImage(
                                          imageUrl: controller
                                              .onBoardingList[index].image
                                              .toString(),
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) =>
                                              Constant.loader(),
                                          errorWidget: (context, url, error) =>
                                              Image.network(
                                                  Constant.userPlaceHolder),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            Constant.localizationTitle(
                                                controller.onBoardingList[index]
                                                    .title),
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20.0),
                                            child: Text(
                                              Constant.localizationDescription(
                                                  controller
                                                      .onBoardingList[index]
                                                      .description),
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white70,
                                                letterSpacing: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                );
                              }),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              if (controller.selectedPageIndex.value != 1)
                                InkWell(
                                  onTap: () {
                                    controller.pageController.jumpToPage(1);
                                  },
                                  child: Text(
                                    'skip'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    2, // Limitar a 2 pasos
                                    (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: controller
                                                    .selectedPageIndex.value ==
                                                index
                                            ? 30
                                            : 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: controller.selectedPageIndex
                                                      .value ==
                                                  index
                                              ? AppColors.primary
                                              : const Color(0xffD4D5E0),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20.0)),
                                        )),
                                  ),
                                ),
                              ),
                              ButtonThem.buildButton(
                                context,
                                title: controller.selectedPageIndex.value == 1
                                    ? 'Get started'.tr
                                    : 'Next'.tr,
                                btnRadius: 30,
                                textColor: Colors.white,
                                onPress: () {
                                  if (controller.selectedPageIndex.value == 1) {
                                    Preferences.setBoolean(
                                        Preferences.isFinishOnBoardingKey,
                                        true);
                                    Get.offAll(const LoginScreen());
                                  } else {
                                    controller.pageController.jumpToPage(
                                        controller.selectedPageIndex.value + 1);
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

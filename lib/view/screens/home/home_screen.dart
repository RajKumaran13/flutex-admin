import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutex_admin/core/route/route.dart';
import 'package:flutex_admin/core/utils/color_resources.dart';
import 'package:flutex_admin/core/utils/dimensions.dart';
import 'package:flutex_admin/core/utils/images.dart';
import 'package:flutex_admin/core/utils/local_strings.dart';
import 'package:flutex_admin/core/utils/style.dart';
import 'package:flutex_admin/view/components/app-bar/action_button_icon_widget.dart';
import 'package:flutex_admin/view/components/circle_image_button.dart';
import 'package:flutex_admin/view/components/custom_loader/custom_loader.dart';
import 'package:flutex_admin/view/components/will_pop_widget.dart';
import 'package:flutex_admin/view/screens/home/widget/dashboard_card.dart';
import 'package:flutex_admin/view/screens/home/widget/drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutex_admin/data/controller/home/home_controller.dart';
import 'package:flutex_admin/data/repo/home/home_repo.dart';
import 'package:flutex_admin/data/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  Map<String, dynamic>? overviewData;

  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(HomeRepo(apiClient: Get.find()));
    final controller = Get.put(HomeController(homeRepo: Get.find()));
    controller.isLoading = true;

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      checkSession();
      controller.initialData();
    });
  }

  // Firestore stream function
  Stream<DocumentSnapshot<Map<String, dynamic>>> _getDashboardStream() {
    return FirebaseFirestore.instance
        .collection('dashboard')
        .doc('overview')
        .snapshots();
  }
  void checkSession() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Navigate to login screen
      Get.offNamed('/login');
    } else {
      // User logged in
      print('Logged in as: ${user.email}');
    }
  }

  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopWidget(
      nextRoute: '',
      child: GetBuilder<HomeController>(builder: (controller) {
        return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              toolbarHeight: 50,
              leading: Builder(builder: (context) {
                return IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                );
              }),
              centerTitle: true,
              title: CachedNetworkImage(
                  imageUrl: controller.homeModel.overview?.perfexLogo ?? '',
                  fit: BoxFit.cover,
                  height: 30,
                  errorWidget: (ctx, object, trx) {
                    return Image.asset(
                      MyImages.appLogo,
                      fit: BoxFit.cover,
                      height: 30,
                    );
                  },
                  placeholder: (ctx, trx) {
                    return Image.asset(
                      MyImages.appLogo,
                    );
                  }),
              actions: [
                ActionButtonIconWidget(
                  pressed: () => Get.toNamed(RouteHelper.settingsScreen),
                  icon: Icons.settings,
                  size: 35,
                  iconColor: Colors.white,
                ),
              ],
            ),
            drawer: const HomeDrawer(),
            body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _getDashboardStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CustomLoader());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('No data available'));
                  }

                  final data = snapshot.data!.data()!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(Dimensions.space10),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: ColorResources.blueGreyColor,
                                radius: 32,
                                child: CircleImageWidget(
                                  imagePath: controller
                                          .homeModel.staff?.profileImage ??
                                      '',
                                  isAsset: false,
                                  isProfile: true,
                                  width: 60,
                                  height: 60,
                                ),
                              ),
                              const SizedBox(width: Dimensions.space20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                      text: TextSpan(children: [
                                    TextSpan(
                                      text: '${LocalStrings.welcome.tr} ',
                                      style: regularLarge.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .color),
                                    ),
                                    TextSpan(
                                      // text: overviewData?['name'] ?? '',
                                      // '${controller.homeModel.staff?.firstName ?? ''} ${controller.homeModel.staff?.lastName ?? ''}',
                                      style: regularLarge.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .color),
                                    ),
                                  ])),
                                  const SizedBox(height: Dimensions.space5),
                                  Text(
                                    data['name'] ?? '',
                                    // controller.homeModel.staff?.email ?? '',
                                    style: regularSmall.copyWith(
                                        color: ColorResources.blueGreyColor),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            DashboardCard(
                              currentValue:
                                  data['invoicesAwaitingPaymentTotal'] ?? 0,
                              totalValue: data['totalInvoices'] ?? 0,
                              percent:
                                  data['invoicesAwaitingPaymentPercent'] ?? '0',
                              icon: Icons.attach_money_rounded,
                              title: 'Invoices Awaiting Payment',
                            ),
                            // DashboardCard(
                            //   currentValue: controller.homeModel.overview
                            //           ?.invoicesAwaitingPaymentTotal ??
                            //       0,
                            //   totalValue: controller
                            //           .homeModel.overview?.totalInvoices ??
                            //       0,
                            //   percent: controller.homeModel.overview
                            //           ?.invoicesAwaitingPaymentPercent ??
                            //       '0',
                            //   icon: Icons.attach_money_rounded,
                            //   title: LocalStrings.invoicesAwaitingPayment.tr,
                            // ),
                            // DashboardCard(
                            //   currentValue: controller.homeModel.overview
                            //           ?.leadsConvertedTotal ??
                            //       0,
                            //   totalValue:
                            //       controller.homeModel.overview?.totalLeads ??
                            //           0,
                            //   percent: controller.homeModel.overview
                            //           ?.leadsConvertedPercent ??
                            //       '0',
                            //   icon: Icons.move_up_rounded,
                            //   title: LocalStrings.convertedLeads.tr,
                            // ),
                            DashboardCard(
                              currentValue: data['leadsConvertedTotal'] ?? 0,
                              totalValue: data['totalLeads'] ?? 0,
                              percent: data['leadsConvertedPercent'] ?? '0',
                              icon: Icons.move_up_rounded,
                              title: 'Converted Leads',
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // DashboardCard(
                            //   currentValue: controller.homeModel.overview
                            //           ?.notFinishedTasksTotal ??
                            //       0,
                            //   totalValue:
                            //       controller.homeModel.overview?.totalTasks ??
                            //           0,
                            //   percent: controller.homeModel.overview
                            //           ?.notFinishedTasksPercent ??
                            //       '0',
                            //   icon: Icons.task_outlined,
                            //   title: LocalStrings.notCompleted.tr,
                            // ),
                            DashboardCard(
                              currentValue: data['notFinishedTasksTotal'] ?? 0,
                              totalValue: data['totalTasks'] ?? 0,
                              percent: data['notFinishedTasksPercent'] ?? '0',
                              icon: Icons.task_outlined,
                              title: 'Not Completed',
                            ),
                            // DashboardCard(
                            //   currentValue: controller.homeModel.overview
                            //           ?.projectsInProgressTotal ??
                            //       0,
                            //   totalValue: controller
                            //           .homeModel.overview?.totalProjects ??
                            //       0,
                            //   percent: controller.homeModel.overview
                            //           ?.inProgressProjectsPercent ??
                            //       '0',
                            //   icon: Icons.dashboard_customize_rounded,
                            //   title: LocalStrings.projectsInProgress.tr,
                            // ),
                            DashboardCard(
                              currentValue:
                                  data['projectsInProgressTotal'] ?? 0,
                              totalValue: data['totalProjects'] ?? 0,
                              percent: data['inProgressProjectsPercent'] ?? '0',
                              icon: Icons.dashboard_customize_rounded,
                              title: 'Projects in Progress',
                            ),
                          ],
                        ),
                        // CarouselSlider(
                        //   items: [
                        //     HomeInvoicesCard(
                        //         invoices: controller.homeModel.data?.invoices),
                        //     HomeEstimatesCard(
                        //         estimates:
                        //             controller.homeModel.data?.estimates),
                        //     HomeProposalsCard(
                        //         proposals:
                        //             controller.homeModel.data?.proposals),
                        //   ],
                        //   options: CarouselOptions(
                        //     height: 450.0,
                        //     aspectRatio: 16 / 9,
                        //     viewportFraction: 1,
                        //     initialPage: 0,
                        //     enableInfiniteScroll: true,
                        //     enlargeCenterPage: false,
                        //     onPageChanged: (index, i) {
                        //       currentPageIndex = index;
                        //       setState(() {});
                        //     },
                        //   ),
                        // ),
                        const SizedBox(height: Dimensions.space10),
                        Center(
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                    3,
                                    (index) => Container(
                                          margin: const EdgeInsets.all(3),
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: index == currentPageIndex
                                                  ? ColorResources.primaryColor
                                                  : Colors.transparent,
                                              border: Border.all(
                                                  color: ColorResources
                                                      .primaryColor,
                                                  width: 1)),
                                        )))),
                      ],
                    ),
                  );
                }));
      }),
    );
  }
}
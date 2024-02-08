import 'package:flutter/material.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_sample/screens/company_screen.dart';
import 'package:likeminds_feed_nova_sample/screens/profile_screen.dart';

class TabApp extends StatefulWidget {
  final Widget feedWidget;
  final Widget profileWidget;
  final String userName;
  const TabApp({
    super.key,
    required this.feedWidget,
    required this.profileWidget,
    required this.userName,
  });

  @override
  State<TabApp> createState() => _TabAppState();
}

class _TabAppState extends State<TabApp> with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabController.index,
        elevation: 10,
        backgroundColor: ColorTheme.darkBlack500,
        onTap: (int index) {
          tabController.animateTo(index);
          setState(() {});
        },
        unselectedLabelStyle: const TextStyle(color: ColorTheme.lightWhite300),
        selectedLabelStyle: const TextStyle(color: ColorTheme.primaryColor),
        selectedItemColor: ColorTheme.primaryColor,
        unselectedItemColor: ColorTheme.lightWhite300,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: ColorTheme.lightWhite300,
            ),
            label: 'Home',
            activeIcon: Icon(
              Icons.home,
              color: ColorTheme.primaryColor,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_2_sharp,
              color: ColorTheme.lightWhite300,
            ),
            activeIcon: Icon(
              Icons.person_2_sharp,
              color: ColorTheme.primaryColor,
            ),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.group,
              color: ColorTheme.lightWhite300,
            ),
            activeIcon: Icon(
              Icons.group,
              color: ColorTheme.primaryColor,
            ),
            label: 'Company',
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          HomeScreen(
            feedWidget: widget.feedWidget,
          ), // First tab content
          ProfileScreen(
            profileWidget: widget.profileWidget,
            userName: widget.userName,
          ), // Second tab content
          const CompanyScreen(),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Widget feedWidget;

  const HomeScreen({
    super.key,
    required this.feedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return feedWidget;
  }
}

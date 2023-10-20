import 'package:flutter/material.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed/likeminds_feed.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO Nova: Replace with your own User Object
  late User user;

  @override
  void initState() {
    super.initState();
    // TODO Nova: Replace with your own User Object
    user = UserLocalPreference.instance.fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: ColorTheme.backgroundColor,
      ),
      body: CustomScrollView(
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),

          const SliverToBoxAdapter(
            child: Center(
              child: CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(
                    'https://randomuser.me/api/portraits/lego/2.jpg'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ColorTheme.lightWhite300,
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'Software Developer',
                  style: TextStyle(
                    fontSize: 18,
                    color: ColorTheme.lightWhite300,
                  ),
                ),
              ),
            ),
          ),

          // User Description
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'I am a passionate software developer with a keen interest in mobile app development. '
                'My goal is to create amazing and user-friendly applications that bring value to people\'s lives.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorTheme.lightWhite300,
                ),
              ),
            ),
          ),
          UserFeedWidget(
            userId: user.userUniqueId,
          ),
        ],
      ),
    );
  }
}

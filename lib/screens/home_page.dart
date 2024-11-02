import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:waitingboard/screens/providers_list.dart';
import 'wait_times_page.dart';
import 'add_provider_page.dart';
import 'dashboard_page.dart'; // Import DashboardPage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // We have two tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: const Text('Wait Time Dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wait Times'),
            Tab(text: 'Board'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Add Provider') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProviderPage()),
                  );
                } else if (value == 'Providers List') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProviderListPage()),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'Add Provider', child: Text('Add Provider')),
                PopupMenuItem(value: 'Providers List', child: Text('Providers List')),
              ],
              child: Icon(
                CupertinoIcons.person_crop_circle_fill_badge_plus,
                size: 40,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TabBarView(
          controller: _tabController,
          children: [
            WaitTimesPage(tabController: _tabController),
            DashboardPage(), // Replace placeholder with DashboardPage
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/worker_verification_tab.dart';
import '../widgets/ai_demand_map_tab.dart';
import '../widgets/sos_monitoring_tab.dart';
import '../widgets/welfare_fund_tab.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isRefreshing = false;

  void _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live regional metrics updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool isHindi = appState.locale == 'Hindi';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHindi ? 'दिल्ली शहरी श्रमिक सहकारी संघ' : 'Delhi Urban Workers Co-op',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const Text('System Administrator', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          actions: [
            if (_isRefreshing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(280),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.admin_panel_settings),
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'English', label: Text('English')),
                          ButtonSegment(value: 'Hindi', label: Text('हिंदी')),
                        ],
                        selected: {appState.locale},
                        onSelectionChanged: (val) {
                          appState.toggleLanguage();
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(child: _buildMetricCard('Verified Workers', '1,240 / 1,500', Icons.people)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMetricCard('Completed Jobs', '${appState.totalActiveJobs} Today', Icons.check_circle)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: _buildMetricCard('Gross Volume', '₹1,19,700', Icons.currency_rupee)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMetricCard('Welfare Fund (3%)', '₹${appState.welfarePool} Today', Icons.shield)),
                    ],
                  ),
                ),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(icon: Icon(Icons.verified_user), text: 'Verification Queue'),
                    Tab(icon: Icon(Icons.map), text: 'AI Demand Heatmap'),
                    Tab(icon: Icon(Icons.warning), text: 'Live & SOS Monitoring'),
                    Tab(icon: Icon(Icons.account_balance_wallet), text: 'Welfare Fund'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            WorkerVerificationTab(),
            AIDemandMapTab(),
            SosMonitoringTab(),
            WelfareFundTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

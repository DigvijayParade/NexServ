import '../../profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/localization.dart';
import '../widgets/booking_bottom_sheet.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _profileAddress = '';

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final addr = doc.data()?['address'] ?? '';
    if (mounted) setState(() => _profileAddress = addr);
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Electrician', 'name_hi': 'बिजली मिस्त्री', 'name_mr': 'इलेक्ट्रिशियन', 'icon': Icons.bolt, 'color': Colors.amber.shade700},
    {'name': 'Plumber', 'name_hi': 'प्लंबर', 'name_mr': 'प्लंबर', 'icon': Icons.water_drop, 'color': Colors.blue.shade600},
    {'name': 'Carpenter', 'name_hi': 'बढ़ई', 'name_mr': 'सुतार', 'icon': Icons.handyman, 'color': Colors.brown.shade500},
    {'name': 'Cleaning', 'name_hi': 'सफाई', 'name_mr': 'स्वच्छता', 'icon': Icons.cleaning_services, 'color': Colors.cyan.shade600},
    {'name': 'Repair', 'name_hi': 'मरम्मत', 'name_mr': 'दुरुस्ती', 'icon': Icons.build, 'color': Colors.deepOrange.shade500},
    {'name': 'Painter', 'name_hi': 'पेंटर', 'name_mr': 'रंगारी', 'icon': Icons.format_paint, 'color': Colors.purple.shade600},
  ];

  void _openBookingSheet(String categoryName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allow for custom rounded corners in bottom sheet
      builder: (context) => BookingBottomSheet(categoryName: categoryName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String loc = appState.locale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Simulated Uber-style Map Header
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Mock Map Background
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      image: const DecorationImage(
                        // Mock grid pattern representing a map
                        image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
                        repeat: ImageRepeat.repeat,
                        opacity: 0.3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 100,
                          left: 80,
                          child: Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 48),
                        ),
                        Positioned(
                          top: 140,
                          right: 100,
                          child: Icon(Icons.electric_scooter, color: Colors.blue.shade700, size: 32),
                        ),
                        Positioned(
                          bottom: 60,
                          left: 150,
                          child: Icon(Icons.plumbing, color: Colors.amber.shade700, size: 36),
                        ),
                      ],
                    ),
                  ),
                  // Search Bar Overlay
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: InkWell(
                      onTap: () {
                        showSearch(context: context, delegate: CustomSearchDelegate());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 28, color: Colors.black87),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppLocalizations.tr(loc, 'What service do you need?', 'आपको कौन सी सेवा चाहिए?', 'तुम्हाला कोणती सेवा हवी आहे?'),
                                style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Voice Search simulator active.')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mic, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Header Top Bar
            title: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Live location tracking is mocked for this demo app.')),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 16, color: Colors.black),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _profileAddress.isNotEmpty ? _profileAddress : 'Loading...',
                              style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.person, color: Colors.black),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.language, color: Colors.black),
                    onSelected: (String value) {
                      appState.setLanguage(value);
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'English',
                        child: Text('English'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Hindi',
                        child: Text('हिंदी (Hindi)'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Marathi',
                        child: Text('मराठी (Marathi)'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Main Content Area
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promo Banner with real image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/promo_banner.jpg',
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                        // Gradient overlay for text readability
                        Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.tr(loc, 'Superfast Service', 'सुपरफास्ट सेवा', 'सुपरफास्ट सेवा'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.tr(loc, 'Co-op Workers in 15 mins', 'सहकारी कर्मचारी 15 मिनट में', 'सहकारी कामगार 15 मिनिटांत'),
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Service Grid (Uber-Style Large Cards)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.tr(loc, 'Suggestions', 'सुझाव', 'सूचना'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9, // Prevent text overflow
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return GestureDetector(
                        onTap: () => _openBookingSheet(cat['name']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat['icon'], color: cat['color'], size: 40),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  AppLocalizations.tr(loc, cat['name'], cat['name_hi'], cat['name_mr']),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis, // Prevent overflow
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Active Bookings / Recent Activity
                  Text(
                    AppLocalizations.tr(loc, 'Your Activity', 'आपकी गतिविधि', 'तुमची क्रियाकलाप'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('jobs')
                        .where('customer_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .orderBy('created_at', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: Text(
                              'No active bookings.\nTap a service above to book one!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'unknown';
                          
                          Color statusColor = Colors.orange;
                          IconData statusIcon = Icons.access_time;
                          if (status == 'assigned') {
                            statusColor = Colors.blue;
                            statusIcon = Icons.engineering;
                          } else if (status == 'completed') {
                            statusColor = Colors.green;
                            statusIcon = Icons.check_circle;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1), 
                                  shape: BoxShape.circle
                                ),
                                child: Icon(statusIcon, color: statusColor),
                              ),
                              title: Text(data['service_type'] ?? 'Service', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Status: ${status.toUpperCase()} • ₹${data['service_rate']}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                // Navigate to details or live tracking
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 100), // Padding for the floating action button to not block content
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final List<String> searchTerms = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'AC Repair',
    'House Cleaning',
    'Washing Machine Repair',
    'Pest Control'
  ];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text(
        'Searching for "$query"...',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var term in searchTerms) {
      if (term.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(term);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index];
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(result),
          onTap: () {
            query = result;
            showResults(context);
          },
        );
      },
    );
  }
}

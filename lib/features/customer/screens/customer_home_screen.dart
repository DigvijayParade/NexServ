import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../widgets/booking_bottom_sheet.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Electrician', 'name_hi': 'बिजली मिस्त्री', 'icon': Icons.bolt, 'color': Colors.amber.shade700},
    {'name': 'Plumber', 'name_hi': 'प्लंबर', 'icon': Icons.water_drop, 'color': Colors.blue.shade600},
    {'name': 'Carpenter', 'name_hi': 'बढ़ई', 'icon': Icons.handyman, 'color': Colors.brown.shade500},
    {'name': 'Cleaning', 'name_hi': 'सफाई', 'icon': Icons.cleaning_services, 'color': Colors.cyan.shade600},
    {'name': 'Repair', 'name_hi': 'मरम्मत', 'icon': Icons.build, 'color': Colors.deepOrange.shade500},
    {'name': 'More', 'name_hi': 'अन्य', 'icon': Icons.more_horiz, 'color': Colors.grey.shade700},
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
    final bool isHindi = appState.locale == 'Hindi';

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
                              isHindi ? 'आपको कौन सी सेवा चाहिए?' : 'What service do you need?',
                              style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic, color: Colors.black87),
                          ),
                        ],
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.near_me, size: 16, color: Colors.black),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Connaught Place, Delhi',
                            style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.language, color: Colors.black),
                    onPressed: () {
                      appState.toggleLanguage();
                    },
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
                                isHindi ? 'सुपरफास्ट सेवा' : 'Superfast Service',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isHindi ? 'सहकारी कर्मचारी 15 मिनट में' : 'Co-op Workers in 15 mins',
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
                        isHindi ? 'सुझाव' : 'Suggestions',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        isHindi ? 'सभी देखें' : 'See All',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
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
                                  isHindi ? cat['name_hi'] : cat['name'],
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
                    isHindi ? 'आपकी गतिविधि' : 'Your Activity',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                      title: const Text('Electrician - Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Worker arriving in 15 mins'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, '/liveTracking');
                      },
                    ),
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

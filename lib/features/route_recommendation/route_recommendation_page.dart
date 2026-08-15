import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';

class RouteRecommendationPage extends StatefulWidget {
  const RouteRecommendationPage({super.key});

  @override
  State<RouteRecommendationPage> createState() =>
      _RouteRecommendationPageState();
}

class _RouteRecommendationPageState extends State<RouteRecommendationPage> {
  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _destinations = [
    {
      'title': 'Museum Batam Raja Ali Haji',
      'time': '08.00 - 09.30',
      'lat': 1.1293,
      'lng': 104.0538,
    },
    {
      'title': 'Jembatan Barelang',
      'time': '09.45 - 11.00',
      'lat': 0.9859,
      'lng': 104.0454,
    },
    {
      'title': 'Pantai Nongsa',
      'time': '11.30 - 13.00',
      'lat': 1.1963,
      'lng': 104.0926,
    },
    {
      'title': 'Taman Rusa Sekupang',
      'time': '14.00 - 15.30',
      'lat': 1.1098,
      'lng': 103.9510,
    },
    {
      'title': 'Masjid Agung Batam',
      'time': '16.00 - 17.00',
      'lat': 1.1287,
      'lng': 104.0543,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Collect all latlng points
    final List<LatLng> routePoints = _destinations
        .map((dest) => LatLng(dest['lat'], dest['lng']))
        .toList();

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        backgroundColor: const Color(0xFF7D9240),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Route',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
            // ====================================================
            // MAP LAYER
            // ====================================================
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: routePoints.first,
                initialZoom: 10.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.moya_mobile',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: const Color(0xFF7D9240),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: _destinations.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final dest = entry.value;
                    return Marker(
                      point: LatLng(dest['lat'], dest['lng']),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF7D9240),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // ====================================================
            // BACK BUTTON (OPTIONAL, but good for UX)
            // ====================================================
            // Just leaving safe area empty if we are in bottom nav,
            // but if we need a back button we'd put it here.
            // Since it's in a bottom nav, no back button needed.

            // ====================================================
            // DRAGGABLE ITINERARY SUMMARY
            // ====================================================
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.15, // When dragged down, just show header
              maxChildSize: 0.85, // When dragged fully up
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      // DRAG HANDLE
                      SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 20),
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      // HEADER INFO
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Itinerary Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A2F),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Destinasi
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '5 Destinations',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Jam
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '8 Hour',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Harga
                                  const Text(
                                    'Rp 150.000',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1E3A2F),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(
                                color: Color(0xFFF0F0F0),
                                thickness: 1.5,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // TIMELINE LIST
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final dest = _destinations[index];
                              final isLast =
                                  index == _destinations.length - 1;

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Number and Line Column
                                    SizedBox(
                                      width: 40,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF2F5EA),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Color(0xFF7D9240),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (!isLast)
                                            Expanded(
                                              child: Container(
                                                width: 2,
                                                color: const Color(0xFFE8F0DF),
                                                margin: const EdgeInsets.symmetric(
                                                    vertical: 4),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Destination Details Column
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 32.0, top: 4.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dest['title'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF1E3A2F),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              dest['time'],
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _destinations.length,
                          ),
                        ),
                      ),
                      
                      // Bottom Padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
  }
}

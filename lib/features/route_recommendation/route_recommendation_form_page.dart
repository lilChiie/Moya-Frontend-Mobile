import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/tourism_service.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/services/route_service.dart';
import '../../core/utils/dialog_utils.dart';

class RouteRecommendationFormPage extends StatefulWidget {
  const RouteRecommendationFormPage({super.key});

  @override
  State<RouteRecommendationFormPage> createState() => _RouteRecommendationFormPageState();
}

class _RouteRecommendationFormPageState extends State<RouteRecommendationFormPage> {
  final RouteService _routeService = RouteService();

  // 1. Accessibility Needs / Available Facilities (Multiple Choice)
  Set<String> _selectedFacilities = {};
  List<String> _accessibilityOptions = [];
  List<Map<String, dynamic>> _rawAccessibility = [];

  // 2. Tourism Category (Multiple Choice)
  Set<String> _selectedCategories = {};
  List<String> _categoryOptions = [];
  List<Map<String, dynamic>> _rawCategories = [];

  bool _isLoadingData = true;
  bool _isSubmitting = false;

  // 3. Budget (Range Slider) - e.g., IDR 100k to 5M
  RangeValues _budgetRange = const RangeValues(200000, 1000000);

  // 4. Trip Duration (Hours Slider)
  double _durationHours = 4.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final tourismService = TourismService();
    final accessibilityService = AccessibilityService();

    final results = await Future.wait([
      tourismService.getTourismCategories(),
      accessibilityService.getAccessibilityNeeds(),
    ]);

    final tourismResult = results[0];
    final accessResult = results[1];

    if (mounted) {
      setState(() {
        if (tourismResult['success'] && tourismResult['data'] != null) {
          final List<dynamic> data = tourismResult['data'];
          _rawCategories = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _categoryOptions = _rawCategories.map((e) => (e['name'] ?? e['title'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
        }

        if (accessResult['success'] && accessResult['data'] != null) {
          final List<dynamic> data = accessResult['data'];
          _rawAccessibility = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _accessibilityOptions = _rawAccessibility.map((e) => (e['name'] ?? e['title'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
        }

        // Setup initial values
        if (_categoryOptions.isNotEmpty) {
          _selectedCategories = {_categoryOptions.first};
        }
        if (_accessibilityOptions.isNotEmpty) {
          _selectedFacilities = {_accessibilityOptions.first};
        }

        _isLoadingData = false;
      });
    }
  }

  int _getTourismId(String categoryName) {
    final found = _rawCategories.firstWhere(
      (c) => (c['name'] ?? '').toString().toLowerCase() == categoryName.toLowerCase(),
      orElse: () => {},
    );
    return found['id'] as int? ?? 3;
  }

  int _getAccessibilityId(String accessName) {
    if (accessName.toLowerCase() == 'none') return 3;
    final found = _rawAccessibility.firstWhere(
      (a) => (a['name'] ?? '').toString().toLowerCase() == accessName.toLowerCase(),
      orElse: () => {},
    );
    return found['id'] as int? ?? 3;
  }

  Future<void> _generateRoute() async {
    setState(() => _isSubmitting = true);

    Position? position;
    try {
      position = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    final selectedCat = _selectedCategories.isNotEmpty ? _selectedCategories.first : 'Culinary Tourism';
    final tourismId = _getTourismId(selectedCat);
    
    List<int> accessibilityIds = [];
    for (var facilityName in _selectedFacilities) {
      final id = _getAccessibilityId(facilityName);
      if (!accessibilityIds.contains(id)) {
        accessibilityIds.add(id);
      }
    }
    if (accessibilityIds.isEmpty) {
      accessibilityIds = [3];
    }

    final result = await _routeService.getRouteRecommendation(
      accessibilityIds: accessibilityIds,
      tourismId: tourismId,
      budget: _budgetRange.end,
      durationMinutes: (_durationHours * 60).toInt(),
      maxDistanceKm: 50.0,
      latitude: position?.latitude ?? 1.136,
      longitude: position?.longitude ?? 104.029,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushNamed(
        context,
        '/route_recommendation',
        arguments: result['data'],
      );
    } else {
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: false,
        title: 'Failed to create route',
        message: result['message'] ?? 'Failed to load route recommendations from server.',
        buttonText: 'OK',
        onPressed: () {
          Navigator.pop(context);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7D9240),
        foregroundColor: Colors.white,
        title: const Text(
          'Plan Your Trip',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize Your Experience',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A2F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us what you need, and we\'ll generate the best accessible route for you.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 1. Available Facilities (Multiple Choice)
                  _buildSectionTitle(
                    'Available Facilities',
                    subtitle: 'Select accessibility facilities you need',
                  ),
                  if (_isLoadingData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF7D9240))),
                    )
                  else
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _accessibilityOptions.map((option) {
                        final isSelected = _selectedFacilities.contains(option);
                        return FilterChip(
                          label: Text(
                            option,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFacilities.add(option);
                              } else {
                                if (_selectedFacilities.length > 1) {
                                  _selectedFacilities.remove(option);
                                }
                              }
                            });
                          },
                          selectedColor: const Color(0xFF7D9240),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF7D9240) : Colors.grey.shade300,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),

                  // 2. Tourism Category (Multiple Choice)
                  _buildSectionTitle(
                    'Tourism Category',
                    subtitle: 'Select categories you are interested in',
                  ),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _categoryOptions.map((option) {
                      final isSelected = _selectedCategories.contains(option);
                      return FilterChip(
                        label: Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(option);
                            } else {
                              if (_selectedCategories.length > 1) {
                                _selectedCategories.remove(option);
                              }
                            }
                          });
                        },
                        selectedColor: const Color(0xFF7D9240),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF7D9240) : Colors.grey.shade300,
                          ),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 3. Budget (Range Slider)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Budget Range'),
                      Text(
                        'Rp ${(_budgetRange.start / 1000).toStringAsFixed(0)}k - Rp ${(_budgetRange.end / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7D9240),
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _budgetRange,
                    min: 50000,
                    max: 5000000,
                    divisions: 99,
                    activeColor: const Color(0xFF7D9240),
                    inactiveColor: Colors.grey.shade300,
                    labels: RangeLabels(
                      'Rp ${(_budgetRange.start / 1000).toStringAsFixed(0)}k',
                      'Rp ${(_budgetRange.end / 1000).toStringAsFixed(0)}k',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _budgetRange = values;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. Trip Duration (Hours Slider)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Trip Duration'),
                      Text(
                        '${_durationHours.toInt()} Hours',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7D9240),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _durationHours,
                    min: 1,
                    max: 24,
                    divisions: 23,
                    activeColor: const Color(0xFF7D9240),
                    inactiveColor: Colors.grey.shade300,
                    label: '${_durationHours.toInt()} Hours',
                    onChanged: (value) {
                      setState(() {
                        _durationHours = value;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Submit Button Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _generateRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B7D46),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Generate Route',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class RouteRecommendationFormPage extends StatefulWidget {
  const RouteRecommendationFormPage({super.key});

  @override
  State<RouteRecommendationFormPage> createState() => _RouteRecommendationFormPageState();
}

class _RouteRecommendationFormPageState extends State<RouteRecommendationFormPage> {
  // 1. Accessibility Needs (Dropdown)
  String _selectedAccessibility = 'None';
  final List<String> _accessibilityOptions = ['Wheelchair', 'Visual Impairment', 'Hearing Impairment', 'None'];

  // 2. Tourism Category (Multiple Choice)
  final Set<String> _selectedCategories = {'Nature'};
  final List<String> _categoryOptions = ['Nature', 'Culinary', 'Culture', 'Shopping', 'Adventure'];

  // 3. Budget (Range Slider) - e.g., IDR 100k to 5M
  RangeValues _budgetRange = const RangeValues(200000, 1000000);

  // 4. Trip Duration (Hours Slider)
  double _durationHours = 4.0;

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
                  
                  // 1. Accessibility Needs (Dropdown)
                  _buildSectionTitle('Accessibility Needs'),
                  DropdownButtonFormField<String>(
                    value: _selectedAccessibility,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7D9240), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _accessibilityOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedAccessibility = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // 2. Tourism Category (Multiple Choice)
                  _buildSectionTitle(
                    'Tourism Category',
                    subtitle: 'You can select more than one category',
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Map/Itinerary Page
                  Navigator.pushNamed(context, '/route_recommendation');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B7D46),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
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

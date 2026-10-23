import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/services/review_service.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/services/route_service.dart';
import '../../core/utils/dialog_utils.dart';
import '../report/report_clean_condition_page.dart';
import '../report/clean_report_replies.dart';

class DestinationDetailPage extends StatefulWidget {
  const DestinationDetailPage({super.key});

  @override
  State<DestinationDetailPage> createState() =>
      _DestinationDetailPageState();
}

class _DestinationDetailPageState
    extends State<DestinationDetailPage> with SingleTickerProviderStateMixin {
  final TextEditingController _reviewController =
      TextEditingController();
  late TabController _tabController;
  bool _reviewsFetched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchAccessibilityMap();
  }

  Map<int, String> _accessibilityMap = {
    3: 'None',
    8: 'Limited Mobility',
    9: 'Wheelchair User',
  };

  Future<void> _fetchAccessibilityMap() async {
    final res = await AccessibilityService().getAccessibilityNeeds();
    if (res['success'] == true && res['data'] != null) {
      final List<dynamic> data = res['data'];
      final map = <int, String>{};
      for (var item in data) {
        if (item is Map && item['id'] != null && item['name'] != null) {
          final id = int.tryParse(item['id'].toString());
          if (id != null) {
            map[id] = item['name'].toString();
          }
        }
      }
      if (mounted && map.isNotEmpty) {
        setState(() {
          _accessibilityMap = map;
        });
      }
    }
  }

  IconData _getAccessibilityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('lift') || lower.contains('elevator')) {
      return Icons.elevator_outlined;
    } else if (lower.contains('parkir') || lower.contains('parking')) {
      return Icons.local_parking_outlined;
    } else if (lower.contains('toilet') || lower.contains('wc') || lower.contains('restroom') || lower.contains('kamar mandi')) {
      return Icons.wc_outlined;
    } else if (lower.contains('kursi roda') || lower.contains('wheelchair') || lower.contains('ramp') || lower.contains('mobility')) {
      return Icons.accessible_forward_outlined;
    } else if (lower.contains('tunanetra') || lower.contains('blind') || lower.contains('braille') || lower.contains('guiding')) {
      return Icons.visibility_outlined;
    } else if (lower.contains('tunarungu') || lower.contains('hearing') || lower.contains('audio') || lower.contains('suara')) {
      return Icons.hearing_outlined;
    } else {
      return Icons.accessible;
    }
  }

  List<String> _extractAccessibilityNames(dynamic accessData) {
    List<int> ids = [];
    if (accessData is List) {
      ids = accessData.map((e) => int.tryParse(e.toString()) ?? 0).where((id) => id != 0).toList();
    } else if (accessData is String) {
      try {
        final cleanStr = accessData.trim();
        if (cleanStr.startsWith('[') && cleanStr.endsWith(']')) {
          final decoded = jsonDecode(cleanStr);
          if (decoded is List) {
            ids = decoded.map((e) => int.tryParse(e.toString()) ?? 0).where((id) => id != 0).toList();
          }
        } else {
          ids = cleanStr.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((id) => id != 0).toList();
        }
      } catch (_) {
        final numVal = int.tryParse(accessData);
        if (numVal != null) ids = [numVal];
      }
    } else if (accessData is int) {
      ids = [accessData];
    }

    final names = <String>[];
    for (var id in ids) {
      if (_accessibilityMap.containsKey(id)) {
        final name = _accessibilityMap[id]!;
        if (name.toLowerCase() != 'none') {
          names.add(name);
        }
      } else if (id != 3 && id != 0) {
        names.add('Facility #$id');
      }
    }

    return names;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reviewsFetched) {
      final dest = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final destId = dest?['id'] as int?;
      if (destId != null) {
        _reviewsFetched = true;
        _fetchReviews(destId);
        _fetchReports(destId);
      }
    }
  }

  final ReviewService _reviewService = ReviewService();
  List<Map<String, dynamic>> _reviews = [];
  bool _reviewsLoading = false;
  bool _submittingReview = false;

  Map<String, dynamic>? _liveDestDetail;

  Future<void> _fetchReviews(int destinationId) async {
    setState(() => _reviewsLoading = true);
    final result = await _reviewService.getDestinationReviews(destinationId);
    if (result['success'] == true) {
      final list = result['data'] as List? ?? [];
      final destData = result['destination'] as Map<String, dynamic>?;
      setState(() {
        if (destData != null) _liveDestDetail = destData;
        _reviews = list.map<Map<String, dynamic>>((e) {
          final user = e['user'] is Map ? e['user'] as Map<String, dynamic> : null;
          return {
            'name': user?['name'] ?? e['name'] ?? e['user_name'] ?? e['username'] ?? 'User',
            'text': e['comment'] ?? e['review'] ?? e['text'] ?? '',
          };
        }).toList();
      });
    } else {
      debugPrint('[Reviews] failed: ${result['message']}');
    }
    setState(() => _reviewsLoading = false);
  }

  String _formatEntranceFee(dynamic fee) {
    if (fee == null) return 'Free';
    final numVal = num.tryParse(fee.toString());
    if (numVal == null || numVal == 0) return 'Free';
    final intVal = numVal.toInt();
    final formatted = intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '-';
    final intVal = int.tryParse(duration.toString());
    if (intVal == null || intVal == 0) return '$duration min';
    if (intVal >= 60) {
      final hours = intVal ~/ 60;
      final mins = intVal % 60;
      return mins > 0 ? '$hours hr $mins min' : '$hours hr';
    }
    return '$intVal min';
  }

  Map<String, String> _getOperatingHoursInfo(dynamic opening, dynamic closing) {
    String clean(dynamic val) {
      if (val == null) return '';
      final s = val.toString().trim();
      if (s.length >= 5) return s.substring(0, 5);
      return s;
    }

    final op = clean(opening);
    final cl = clean(closing);

    if (op.isEmpty && cl.isEmpty) {
      return {'duration': '24 Hours', 'time': 'Open 24/7'};
    }

    try {
      if (op.isNotEmpty && cl.isNotEmpty) {
        final opParts = op.split(':');
        final clParts = cl.split(':');
        if (opParts.length >= 2 && clParts.length >= 2) {
          final opHour = int.parse(opParts[0]);
          final opMin = int.parse(opParts[1]);
          final clHour = int.parse(clParts[0]);
          final clMin = int.parse(clParts[1]);

          var totalMins = (clHour * 60 + clMin) - (opHour * 60 + opMin);
          if (totalMins < 0) totalMins += 24 * 60;

          final diffHours = totalMins ~/ 60;
          final diffMins = totalMins % 60;

          String durationStr;
          if (diffHours > 0 && diffMins > 0) {
            durationStr = '$diffHours hr $diffMins min';
          } else if (diffHours > 0) {
            durationStr = '$diffHours Hours';
          } else {
            durationStr = '$diffMins mins';
          }

          return {'duration': durationStr, 'time': '$op - $cl'};
        }
      }
    } catch (_) {}

    if (op.isNotEmpty && cl.isNotEmpty) return {'duration': '$op - $cl', 'time': ''};
    if (op.isNotEmpty) return {'duration': 'Open: $op', 'time': ''};
    return {'duration': 'Closes: $cl', 'time': ''};
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBD9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0DF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF5B7D46),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A2F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview(int destinationId) async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) return;
    setState(() => _submittingReview = true);
    final result = await _reviewService.addReview(
      destinationId: destinationId,
      review: text,
    );
    setState(() => _submittingReview = false);
    if (!mounted) return;
    if (result['success'] == true) {
      _reviewController.clear();
      AppDialogs.showStatusDialog(
        context: context,
        title: 'Berhasil',
        message: result['message'] ?? 'Review berhasil dikirim!',
        isSuccess: true,
        buttonText: 'OK',
        onPressed: () => Navigator.pop(context),
      );
      _fetchReviews(destinationId);
    } else {
      AppDialogs.showStatusDialog(
        context: context,
        title: 'Failed',
        message: result['message'] ?? 'Failed to send review.',
        isSuccess: false,
        buttonText: 'OK',
        onPressed: () => Navigator.pop(context),
      );
    }
  }

  List<Map<String, dynamic>> _reports = [];
  bool _reportsLoading = false;

  Future<void> _fetchReports([int? destinationId]) async {
    setState(() => _reportsLoading = true);
    try {
      final queryParam = destinationId != null ? '?destination_id=$destinationId' : '';
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}$queryParam');
      final response = await http.get(url, headers: {
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = json['data'] as List? ?? [];

        final filteredList = destinationId != null
            ? list.where((e) {
                final destId = e['destination_id'];
                return destId != null && destId.toString() == destinationId.toString();
              }).toList()
            : list;

        setState(() {
          _reports = filteredList.map<Map<String, dynamic>>((e) {
            String? rawImg = e['image_url'] as String?;
            String? fullImgUrl;
            if (rawImg != null && rawImg.trim().isNotEmpty) {
              if (rawImg.startsWith('http://') || rawImg.startsWith('https://')) {
                fullImgUrl = rawImg.replaceFirst('http://', 'https://');
              } else {
                final cleanPath = rawImg.startsWith('/') ? rawImg : '/$rawImg';
                fullImgUrl = '${ApiConstants.baseUrl}$cleanPath';
              }
            }

            return {
              ...Map<String, dynamic>.from(e),
              'id': e['id']?.toString() ?? '-',
              'destination_id': e['destination_id'],
              'text': e['user_notes'] ?? '',
              'status': e['status'] ?? 'pending',
              'image_url': fullImgUrl,
              'admin_notes': e['admin_notes'] ?? 'No notes from the admin yet.',
              'ai_score': e['score'] != null
                  ? '${(e['score'] * 100).toStringAsFixed(0)}%'
                  : '-',
            };
          }).toList();
        });
      }
    } catch (_) {}
    setState(() => _reportsLoading = false);
  }

  // Reports are loaded from API â€” see _fetchLatestReports()

  Future<void> _replyToReport(Map<String, dynamic> report) async {
    final reportId = int.tryParse(report['id'].toString());
    final destinationId = int.tryParse(report['destination_id'].toString());
    if (reportId == null || destinationId == null) return;
    final destination = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => ReportCleanConditionPage(
      reportId: reportId,
      destinationId: destinationId,
      destinationName: (report['destination_name'] ?? _liveDestDetail?['name'] ?? destination?['title'] ?? destination?['name'] ?? 'Destination').toString(),
      reportNotes: (report['text'] ?? report['user_notes'] ?? '').toString(),
    )));
    if (mounted) await _fetchReports(destinationId);
  }

  void _showReportModal(BuildContext context, Map<String, dynamic> report) {
    final imageUrl = report['image_url'] as String?;
    final replies = report['clean_reports'] is List ? report['clean_reports'] as List : <dynamic>[];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        headers: const {'ngrok-skip-browser-warning': 'true'},
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 220,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report ID: ${report['id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Severity Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F5EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            report['ai_score'],
                            style: const TextStyle(color: Color(0xFF7D9240), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Clean-up evidence (${report['clean_reports_count'] ?? replies.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(report['status'] == 'resolved'
                        ? 'Resolved after admin verification.'
                        : 'Evidence is reviewed by an admin before this report is resolved.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7D9240),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reviews loaded from API â€” see _fetchReviews()

  @override
  void dispose() {
    _reviewController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? dest =
        ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>?;

    if (dest == null) {
      return const Scaffold(
        body: Center(
          child: Text('Destination data not found'),
        ),
      );
    }

    final distanceStr = dest['distance'] != null
        ? '${dest['distance'].toStringAsFixed(1)} KM'
        : '10 KM';

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: const Color(0xFF7D9240),
        onRefresh: () async {
          final destId = dest['id'] as int?;
          await Future.wait([
            if (destId != null) _fetchReports(destId),
            if (destId != null) _fetchReviews(destId),
            _fetchAccessibilityMap(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // =========================================================
          // APP BAR + HERO IMAGE
          // =========================================================
          SliverAppBar(
            expandedHeight: 480,
            pinned: true,
            automaticallyImplyLeading: false,

            backgroundColor: const Color(0xFF7D9240),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,

            systemOverlayStyle:
                SystemUiOverlayStyle.light,

            // -------------------------------------------------------
            // BACK BUTTON
            // -------------------------------------------------------
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

            // -------------------------------------------------------
            // PAGE TITLE
            // -------------------------------------------------------
            title: const Text(
              'Destination Detail',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            // -------------------------------------------------------
            // HERO IMAGE
            // -------------------------------------------------------
            flexibleSpace: Stack(
              fit: StackFit.expand,
              children: [
                // Hero image starts BELOW the toolbar
                Positioned(
                  top: kToolbarHeight +
                      MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: dest['image'] != null && dest['image'].toString().startsWith('http')
                      ? Image.network(
                          dest['image'],
                          headers: const {
                            'ngrok-skip-browser-warning': 'true',
                          },
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/other/splashscreen.png',
                          fit: BoxFit.cover,
                        ),
                ),

                // Solid green toolbar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: kToolbarHeight +
                      MediaQuery.of(context).padding.top,
                  child: Container(
                    color: const Color(0xFF7D9240),
                  ),
                ),
              ],
            ),
          ),

          // =========================================================
          // DESTINATION CONTENT
          // =========================================================
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),

                // More top spacing so title sits lower
                padding: const EdgeInsets.fromLTRB(
                  24,
                  44,
                  24,
                  24,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // DESTINATION NAME + DISTANCE
                    // =================================================
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            dest['title'] ??
                                'Nama Destinasi',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A2F),
                              height: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF2F5EA),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            distanceStr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(0xFF7D9240),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // CATEGORY + ACCESSIBILITY
                    // =================================================
                    Builder(
                      builder: (context) {
                        final accessData = _liveDestDetail?['accessibility_id'] ??
                            _liveDestDetail?['accessibility_ids'] ??
                            dest['accessibility_id'] ??
                            dest['accessibility_ids'];
                        final accessNames = _extractAccessibilityNames(accessData);
                        final firstAccess = accessNames.isNotEmpty ? accessNames.first : 'Accessible';

                        return Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              color: Colors.grey.shade600,
                              size: 19,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              dest['category'] ?? (dest['categories'] is List && (dest['categories'] as List).isNotEmpty
                                  ? (dest['categories'] as List).first
                                  : 'Tourism Destination'),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.accessible,
                              size: 19,
                              color: Color(0xFF7D9240),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                firstAccess,
                                style: const TextStyle(
                                  color: Color(0xFF7D9240),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // INFO GRID (Fee, Duration, Hours, Distance)
                    // =================================================
                    Builder(
                      builder: (context) {
                        final fee = _liveDestDetail?['entrance_fee'] ?? dest['entrance_fee'];
                        final dur = _liveDestDetail?['estimated_duration'] ?? dest['estimated_duration'];
                        final openT = _liveDestDetail?['opening_time'] ?? dest['opening_time'];
                        final closeT = _liveDestDetail?['closing_time'] ?? dest['closing_time'];
                        final opInfo = _getOperatingHoursInfo(openT, closeT);

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.confirmation_number_outlined,
                                    label: 'Entrance Fee',
                                    value: _formatEntranceFee(fee),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.access_time_rounded,
                                    label: 'Operating Hours',
                                    value: opInfo['duration']!,
                                    subtitle: opInfo['time'],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.timer_outlined,
                                    label: 'Est. Duration',
                                    value: _formatDuration(dur),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.directions_car_outlined,
                                    label: 'Distance',
                                    value: distanceStr,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // =================================================
                    // ACCESSIBILITY FEATURES CHIPS
                    // =================================================
                    const Text(
                      'Available Facilities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A2F),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Builder(
                      builder: (context) {
                        final accessData = _liveDestDetail?['accessibility_id'] ??
                            _liveDestDetail?['accessibility_ids'] ??
                            dest['accessibility_id'] ??
                            dest['accessibility_ids'];
                        final accessNames = _extractAccessibilityNames(accessData);

                        if (accessNames.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE7EBD9)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Available Facilities / None Registered',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: accessNames.map((name) {
                            final iconData = _getAccessibilityIcon(name);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F5EA),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF7D9240).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    iconData,
                                    size: 16,
                                    color: const Color(0xFF5B7D46),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E3A2F),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // =================================================
                    // DESCRIPTION
                    // =================================================
                    const Text(
                      'About this destination',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A2F),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Builder(
                      builder: (context) {
                        final rawDesc = _liveDestDetail?['description'] ?? dest['description'];
                        final descText = (rawDesc != null && rawDesc.toString().trim().isNotEmpty)
                            ? rawDesc.toString().trim()
                            : '${dest['title'] ?? 'Destinasi ini'} merupakan destinasi wisata yang menawarkan pemandangan menakjubkan dan fasilitas inklusif yang ramah difabel.';

                        return Text(
                          descText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.justify,
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // =================================================
                    // ACTION BUTTONS
                    // =================================================
                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed: () {
                              final title = _liveDestDetail?['name'] ?? dest['title'] ?? dest['name'] ?? 'Destination';
                              final lat = _liveDestDetail?['latitude'] ?? dest['lat'] ?? dest['latitude'];
                              final lng = _liveDestDetail?['longitude'] ?? dest['lng'] ?? dest['longitude'];
                              final duration = _liveDestDetail?['estimated_duration'] ?? dest['estimated_duration'];
                              final fee = _liveDestDetail?['entrance_fee'] ?? dest['entrance_fee'];
                              final img = _liveDestDetail?['image_url'] ?? dest['image_url'] ?? dest['image'];

                              TripRouteManager().addDestination({
                                'id': dest['id'],
                                'title': title,
                                'latitude': lat,
                                'longitude': lng,
                                'estimated_duration': duration,
                                'entrance_fee': fee,
                                'image_url': img,
                              });

                              AppDialogs.showStatusDialog(
                                context: context,
                                isSuccess: true,
                                title: 'Added to Route',
                                message: '$title has been added to your route.',
                                buttonText: 'View Route',
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/route_recommendation');
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.add_road,
                              size: 19,
                            ),
                            label: const Text(
                              'Add to Route',
                            ),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF7D9240,
                              ),
                              foregroundColor:
                                  Colors.white,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child:
                              OutlinedButton.icon(
                            onPressed: () {
                              final name = _liveDestDetail?['name'] ??
                                  dest['title'] ??
                                  dest['name'] ??
                                  'Destination';
                              Navigator.pushNamed(
                                context,
                                '/report_condition',
                                arguments: {
                                  'id': dest['id'] ?? _liveDestDetail?['id'],
                                  'name': name,
                                },
                              );
                            },
                            icon: const Icon(
                              Icons
                                  .camera_alt,
                              size: 19,
                            ),
                            label: const Text(
                              'Report Condition',
                            ),
                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(
                                0xFFD32F2F,
                              ),
                              side:
                                  const BorderSide(
                                color:
                                    Color(0xFFD32F2F),
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // =================================================
                    // DIVIDER
                    // =================================================
                    const Divider(
                      thickness: 1,
                      color: Color(0xFFEAEAEA),
                    ),

                    const SizedBox(height: 28),

                    // =================================================
                    // TABS: REVIEWS & REPORTS
                    // =================================================
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorColor: const Color(0xFF7D9240),
                        labelColor: const Color(0xFF7D9240),
                        unselectedLabelColor: Colors.grey,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                        tabs: const [
                          Tab(text: 'Reviews'),
                          Tab(text: 'Reports'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // TAB CONTENT
                    // =================================================
                    if (_tabController.index == 0) ...[
                      // =================================================
                      // LEAVE A REVIEW
                      // =================================================
                      const Text(
                        'Leave a Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A2F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reviewController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Share your experience...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF7D9240), width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FBF5),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submittingReview
                              ? null
                              : () => _submitReview(dest['id'] as int),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7D9240),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _submittingReview
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send Review', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // =================================================
                      // REVIEWS TAB
                      // =================================================
                      const Text(
                        'Latest Reviews',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A2F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_reviewsLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: Color(0xFF7D9240)),
                          ),
                        )
                      else if (_reviews.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'There are no reviews for this destination yet.\nBe the first!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length > 10 ? 10 : _reviews.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAF5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE7EBD9)),
                              ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     review['name']!,
                                     style: const TextStyle(
                                       fontSize: 14,
                                       fontWeight: FontWeight.bold,
                                       color: Color(0xFF1E3A2F),
                                     ),
                                   ),
                                   const SizedBox(height: 6),
                                   Text(
                                     review['text']!,
                                     style: TextStyle(
                                       color: Colors.grey.shade700,
                                       fontSize: 13,
                                       height: 1.5,
                                     ),
                                   ),
                                 ],
                               ),
                             );
                          },
                        ),
                    ] else ...[
                      // REPORTS TAB
                      const Text(
                        'Latest Reports',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A2F),
                        ),
                        ),
                      const SizedBox(height: 12),
                      if (_reportsLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: Color(0xFF7D9240)),
                          ),
                        )
                      else if (_reports.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('No reports for this destination yet.',
                                style: TextStyle(color: Colors.grey.shade500)),
                          ),
                        )
                      else
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reports.length > 10 ? 10 : _reports.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            final isResolved = report['status'] == 'resolved';
                            final imageUrl = report['image_url'] as String?;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [InkWell(
                              onTap: () => _showReportModal(context, report),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              headers: const {'ngrok-skip-browser-warning': 'true'},
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 64,
                                                height: 64,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            )
                                          : Container(
                                              width: 64,
                                              height: 64,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Report #${report['id']}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E3A2F),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isResolved ? const Color(0xFFE8F0DF) : Colors.orange.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  isResolved ? 'Resolved' : 'Pending',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isResolved ? const Color(0xFF5B7D46) : Colors.orange.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            report['text']?.isNotEmpty == true
                                                ? report['text']
                                                : 'No notes provided',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text('${report['clean_reports_count'] ?? (report['clean_reports'] is List ? (report['clean_reports'] as List).length : 0)} clean replies',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF5B7D46), fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            onPressed: () => _replyToReport(report),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF5B7D46),
                                              side: const BorderSide(color: Color(0xFF5B7D46)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: const Text('Report Clean Condition', textAlign: TextAlign.center),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (report['clean_reports'] is List)
                              CleanReportReplies(
                                key: ValueKey('replies-${report['id']}'),
                                replies: report['clean_reports'] as List,
                              ),
                            ],
                            );
                          },
                        ),
                    ],

                    const SizedBox(height: 32),

                    // =================================================
                      // Bottom spacing
                      const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

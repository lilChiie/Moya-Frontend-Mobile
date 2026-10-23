import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/clean_report_service.dart';
import '../../core/services/destination_service.dart';
import '../../core/services/report_service.dart';
import '../../core/utils/user_errors.dart';

const _green = Color(0xFF7D9240);
const _text = Color(0xFF1E3A2F);

class MyReportPage extends StatefulWidget {
  const MyReportPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<MyReportPage> createState() => _MyReportPageState();
}

class _MyReportPageState extends State<MyReportPage> {
  late final Future<Map<String, String>> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = _loadDestinations();
  }

  Future<Map<String, String>> _loadDestinations() async {
    final result = await DestinationService().getDestinations();
    if (result['success'] != true) return {};
    return {
      for (final item in result['data'] as List)
        item['id'].toString(): (item['name'] ?? 'Destination').toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'My Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: _green,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: _green,
                    tabs: [
                      Tab(text: 'Dirty Reports'),
                      Tab(text: 'Clean Reports'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ReportList(
                      clean: false,
                      load: ReportService().getMyReports,
                      destinations: _destinations,
                    ),
                    _ReportList(
                      clean: true,
                      load: CleanReportService().getMyReports,
                      destinations: _destinations,
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
}

class _ReportList extends StatefulWidget {
  const _ReportList({
    required this.clean,
    required this.load,
    required this.destinations,
  });
  final bool clean;
  final Future<Map<String, dynamic>> Function() load;
  final Future<Map<String, String>> destinations;

  @override
  State<_ReportList> createState() => _ReportListState();
}

class _ReportListState extends State<_ReportList>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _result;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _result = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final result = await widget.load();
    if (result['success'] != true) return result;
    final names = await widget.destinations;
    final reports =
        (result['data'] as List)
            .whereType<Map>()
            .map(
              (item) => {
                ...Map<String, dynamic>.from(item),
                'destination_name':
                    item['destination_name'] ??
                    (item['destination'] is Map
                        ? item['destination']['name']
                        : null) ??
                    names[item['destination_id'].toString()] ??
                    'Destination #${item['destination_id']}',
              },
            )
            .toList();
    reports.sort(
      (a, b) => (b['created_at'] ?? '').toString().compareTo(
        (a['created_at'] ?? '').toString(),
      ),
    );
    return {'success': true, 'data': reports};
  }

  Future<void> _refresh() async {
    final request = _load();
    setState(() => _result = request);
    await request;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _result,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        final result = snapshot.data;
        final failed = snapshot.hasError || result?['success'] != true;
        final reports = failed ? <dynamic>[] : result!['data'] as List;
        return RefreshIndicator(
          color: _green,
          onRefresh: _refresh,
          child:
              reports.isEmpty
                  ? LayoutBuilder(
                    builder:
                        (context, constraints) => ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE8F0DF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        failed
                                            ? Icons.cloud_off_outlined
                                            : widget.clean
                                            ? Icons.cleaning_services_outlined
                                            : Icons.report_outlined,
                                        size: 36,
                                        color: _green,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      failed
                                          ? 'Couldn’t load your reports'
                                          : widget.clean
                                          ? 'No clean reports yet'
                                          : 'No dirty reports yet',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: _text,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      failed
                                          ? (result?['message']?.toString() ??
                                              UserErrors.unavailable)
                                          : 'Reports you submit will appear here, along with their latest status.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF6F7466),
                                        height: 1.5,
                                      ),
                                    ),
                                    if (failed) ...[
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        onPressed: _refresh,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Try Again'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                  )
                  : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder:
                        (_, index) => _ReportCard(
                          report: reports[index],
                          clean: widget.clean,
                        ),
                  ),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.clean});
  final Map<String, dynamic> report;
  final bool clean;

  @override
  Widget build(BuildContext context) {
    final status = report['status']?.toString().toLowerCase() ?? '';
    final (label, color) = switch (status) {
      'resolved' => ('Resolved', const Color(0xFF5B7D46)),
      'verified' || 'approved' => ('Verified', const Color(0xFF5B7D46)),
      'rejected' => ('Rejected', const Color(0xFFC85C5C)),
      'pending' => ('Pending', const Color(0xFFAD7B24)),
      _ => ('Under review', const Color(0xFF6F7466)),
    };
    final notes =
        (report['notes'] ?? report['user_notes'] ?? '').toString().trim();
    final adminNotes = (report['admin_notes'] ?? '').toString().trim();
    final rawImage = report['image_url']?.toString() ?? '';
    final imageUrl =
        rawImage.isEmpty
            ? null
            : Uri.parse(ApiConstants.baseUrl).resolve(rawImage).toString();
    return Material(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE1E5D9)),
      ),
      child: InkWell(
        onTap:
            () => _showReportDialog(
              context,
              imageUrl,
              label,
              color,
              notes,
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                headers: const {'ngrok-skip-browser-warning': 'true'},
                errorBuilder:
                    (_, _, _) => Container(
                      height: 110,
                      color: const Color(0xFFF2F5EA),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 32,
                        color: _green,
                      ),
                    ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report['destination_name'].toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    clean ? 'Clean condition' : 'Dirty condition',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6F7466),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted on ${_date(report['created_at'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6F7466),
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      notes,
                      style: const TextStyle(height: 1.5, fontSize: 13),
                    ),
                  ],
                  if (report['verified_at'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reviewed on ${_date(report['verified_at'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6F7466),
                      ),
                    ),
                  ],
                  if (adminNotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F5EA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Review note',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            adminNotes,
                            style: const TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(
    BuildContext context,
    String? imageUrl,
    String status,
    Color statusColor,
    String notes,
  ) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child:
                          imageUrl == null
                              ? _dialogImageFallback()
                              : Image.network(
                                imageUrl,
                                headers: const {
                                  'ngrok-skip-browser-warning': 'true',
                                },
                                height: 220,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, _, _) => _dialogImageFallback(),
                              ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report ID: ${report['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            report['destination_name'].toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _text,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Submitted on',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _date(report['created_at']),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Your Notes:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notes,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                          if (report['verified_at'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Reviewed on ${_date(report['verified_at'])}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _dialogImageFallback() => Container(
    height: 220,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
  );

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Date unavailable';
    final local = date.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '${local.day} ${months[local.month - 1]} ${local.year}, $time';
  }
}

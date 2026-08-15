import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();

  // Filter types
  final List<String> _filters = ['All', 'Today', 'Yesterday', 'Last 7 Days'];
  String _activeFilter = 'All';

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final result = await _notificationService.getNotifications();
    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      setState(() {
        _notifications = data.map<Map<String, dynamic>>((e) {
          final item = Map<String, dynamic>.from(e as Map);
          final createdAtStr = item['created_at']?.toString() ?? '';
          final DateTime? dt = DateTime.tryParse(createdAtStr.replaceAll(' ', 'T'));
          
          return {
            'id': item['id'] as int? ?? 0,
            'title': item['title']?.toString() ?? 'Notification',
            'description': item['description']?.toString() ?? '',
            'isRead': item['is_read'] == true || item['is_read'] == 1,
            'timeStr': dt != null ? _formatTimeAgo(dt) : createdAtStr,
            'category': dt != null ? _categorizeTime(dt) : 'All',
            'icon': _getIconForNotif(item['title']?.toString() ?? '', item['description']?.toString() ?? ''),
            'color': _getColorForNotif(item['title']?.toString() ?? '', item['description']?.toString() ?? ''),
          };
        }).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(int id) async {
    // Optimistic update
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });

    await _notificationService.markAsRead(id);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24 && dateTime.day == now.day) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1 || (difference.inHours < 48 && dateTime.day == now.day - 1)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }

  String _categorizeTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final differenceInDays = today.difference(notifDate).inDays;

    if (differenceInDays == 0) {
      return 'Today';
    } else if (differenceInDays == 1) {
      return 'Yesterday';
    } else if (differenceInDays <= 7) {
      return 'Last 7 Days';
    } else {
      return 'Older';
    }
  }

  IconData _getIconForNotif(String title, String desc) {
    final t = '$title $desc'.toLowerCase();
    if (t.contains('profil') || t.contains('profile') || t.contains('akun') || t.contains('account')) {
      return Icons.person_outline;
    }
    if (t.contains('rute') || t.contains('route') || t.contains('itinerary')) {
      return Icons.map_outlined;
    }
    if (t.contains('peringkat') || t.contains('rank') || t.contains('trophy') || t.contains('leaderboard')) {
      return Icons.emoji_events_outlined;
    }
    if (t.contains('report') || t.contains('laporan')) {
      return Icons.camera_alt_outlined;
    }
    if (t.contains('review') || t.contains('ulasan')) {
      return Icons.rate_review_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _getColorForNotif(String title, String desc) {
    final t = '$title $desc'.toLowerCase();
    if (t.contains('profil') || t.contains('profile')) return Colors.blue;
    if (t.contains('peringkat') || t.contains('rank')) return const Color(0xFFFFB300);
    if (t.contains('rute') || t.contains('route')) return const Color(0xFF7D9240);
    if (t.contains('report') || t.contains('laporan')) return Colors.orange;
    if (t.contains('review') || t.contains('ulasan')) return Colors.teal;
    return const Color(0xFF7D9240);
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final displayedNotifications = _notifications.where((notif) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Last 7 Days') {
        return notif['category'] == 'Today' ||
            notif['category'] == 'Yesterday' ||
            notif['category'] == 'Last 7 Days';
      }
      return notif['category'] == _activeFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7D9240),
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
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
          // Filter Chips Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isActive = _activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey.shade700,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isActive,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _activeFilter = filter;
                          });
                        }
                      },
                      selectedColor: const Color(0xFF7D9240),
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isActive ? const Color(0xFF7D9240) : Colors.grey.shade300,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Notification List Section with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF7D9240),
              onRefresh: _fetchNotifications,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF7D9240)),
                    )
                  : displayedNotifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedNotifications.length,
                          itemBuilder: (context, index) {
                            final notif = displayedNotifications[index];
                            return _buildNotificationItem(notif);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final bool isRead = notif['isRead'] as bool;
    final int notifId = notif['id'] as int;

    return InkWell(
      onTap: () {
        if (!isRead && notifId > 0) {
          _markAsRead(notifId);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF2F5EA), // highlight if unread
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : const Color(0xFF7D9240).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (notif['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notif['icon'] as IconData,
                color: notif['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            color: const Color(0xFF1E3A2F),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif['description'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notif['timeStr'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are all caught up!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Filter types
  final List<String> _filters = ['All', 'Today', 'Yesterday', 'Last 7 Days'];
  String _activeFilter = 'All';

  // Mock Notification Data
  final List<Map<String, dynamic>> _allNotifications = [
    {
      'title': 'Rute Baru Ditambahkan!',
      'description': 'Rute ke Museum Batam telah ditambahkan ke itinerary Anda.',
      'timeStr': '2 jam yang lalu',
      'category': 'Hari Ini',
      'icon': Icons.map,
      'color': Colors.blue,
      'isRead': false,
    },
    {
      'title': 'Peringkat Naik 🏆',
      'description': 'Selamat! Anda telah naik peringkat menjadi "Explorer". Terus jelajahi Batam!',
      'timeStr': '5 jam yang lalu',
      'category': 'Hari Ini',
      'icon': Icons.emoji_events,
      'color': const Color(0xFFFFD700),
      'isRead': false,
    },
    {
      'title': 'Pengingat Perjalanan',
      'description': 'Besok Anda memiliki jadwal kunjungan ke Jembatan Barelang.',
      'timeStr': 'Kemarin',
      'category': 'Kemarin',
      'icon': Icons.calendar_today,
      'color': Colors.orange,
      'isRead': true,
    },
    {
      'title': 'Ulasan Anda Disukai',
      'description': 'Seseorang menyukai ulasan Anda tentang Seafood Sei Enam.',
      'timeStr': 'Kemarin',
      'category': 'Kemarin',
      'icon': Icons.favorite,
      'color': Colors.red,
      'isRead': true,
    },
    {
      'title': 'Destinasi Baru: Nagoya Hill',
      'description': 'Cek rekomendasi wisata belanja terbaik di Batam minggu ini.',
      'timeStr': '3 hari yang lalu',
      'category': '7 Hari Terakhir',
      'icon': Icons.storefront,
      'color': Colors.green,
      'isRead': true,
    },
    {
      'title': 'Selamat Datang di Moya!',
      'description': 'Lengkapi profil Anda untuk mendapatkan poin tambahan pertama.',
      'timeStr': '5 hari yang lalu',
      'category': '7 Hari Terakhir',
      'icon': Icons.celebration,
      'color': Colors.purple,
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final displayedNotifications = _allNotifications.where((notif) {
      if (_activeFilter == 'Semua') return true;
      if (_activeFilter == '7 Hari Terakhir') {
        return notif['category'] == 'Hari Ini' || 
               notif['category'] == 'Kemarin' || 
               notif['category'] == '7 Hari Terakhir';
      }
      return notif['category'] == _activeFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7D9240),
        foregroundColor: Colors.white,
        title: const Text(
          'Notifikasi',
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

          // Notification List Section
          Expanded(
            child: displayedNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedNotifications.length,
                    itemBuilder: (context, index) {
                      final notif = displayedNotifications[index];
                      return _buildNotificationItem(notif);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final bool isRead = notif['isRead'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF2F5EA), // highlight if unread
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : const Color(0xFF7D9240).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (notif['color'] as Color).withOpacity(0.1),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter waktu Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

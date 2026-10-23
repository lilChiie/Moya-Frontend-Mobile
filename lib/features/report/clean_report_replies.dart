import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';

/// A bounded preview of evidence replies beneath their original dirty report.
class CleanReportReplies extends StatefulWidget {
  const CleanReportReplies({super.key, required this.replies});
  final List<dynamic> replies;

  @override
  State<CleanReportReplies> createState() => _CleanReportRepliesState();
}

class _CleanReportRepliesState extends State<CleanReportReplies> {
  int _visible = 1;

  @override
  Widget build(BuildContext context) {
    final replies = widget.replies.whereType<Map>().toList();
    if (replies.isEmpty) return const SizedBox.shrink();
    final count = _visible.clamp(0, replies.length);
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.only(left: 16, top: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFE1E5D9), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final reply in replies.take(count)) _EvidenceReply(reply: reply),
          if (count < replies.length)
            TextButton(
              onPressed: () => setState(() => _visible += 3),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5B7D46),
              ),
              child: const Text('See more'),
            ),
          if (count > 1)
            TextButton(
              onPressed: () => setState(() => _visible = 1),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5B7D46),
              ),
              child: const Text('See less'),
            ),
        ],
      ),
    );
  }
}

class _EvidenceReply extends StatelessWidget {
  const _EvidenceReply({required this.reply});
  final Map reply;

  @override
  Widget build(BuildContext context) {
    final name =
        (reply['user_name'] ??
                (reply['user'] is Map ? reply['user']['name'] : null) ??
                'Community member')
            .toString();
    final notes = (reply['notes'] ?? '').toString().trim();
    final rawImage = (reply['image_url'] ?? '').toString().trim();
    final date =
        DateTime.tryParse(reply['created_at']?.toString() ?? '')?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFE8F0DF),
            child: Icon(
              Icons.person_outline,
              size: 19,
              color: Color(0xFF5B7D46),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A2F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date == null
                      ? 'Clean-up evidence'
                      : 'Clean-up evidence · ${date.day}/${date.month}/${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    notes,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
                if (rawImage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      Uri.parse(
                        ApiConstants.baseUrl,
                      ).resolve(rawImage).toString(),
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, _, _) => Container(
                            height: 100,
                            color: const Color(0xFFF2F5EA),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

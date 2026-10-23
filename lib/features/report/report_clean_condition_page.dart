import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/clean_report_service.dart';
import '../../core/utils/user_errors.dart';
import '../../core/utils/dialog_utils.dart';

class ReportCleanConditionPage extends StatefulWidget {
  const ReportCleanConditionPage({
    super.key,
    required this.destinationName,
    required this.destinationId,
    required this.reportId,
    this.reportNotes = '',
  });

  final String destinationName;
  final int destinationId;
  final int reportId;
  final String reportNotes;

  @override
  State<ReportCleanConditionPage> createState() =>
      _ReportCleanConditionPageState();
}

class _ReportCleanConditionPageState extends State<ReportCleanConditionPage> {
  final _notesController = TextEditingController();
  Uint8List? _photo;
  String _photoFilename = 'evidence.jpg';
  bool _submitting = false;
  final Map<String, int> _destinationIds = {};
  bool _pickingPhoto = false;
  final _destinationController = TextEditingController();
  String? _selectedDestination;

  @override
  void initState() {
    super.initState();
    _selectedDestination = widget.destinationName;
    _destinationController.text = widget.destinationName;
    _destinationIds[widget.destinationName] = widget.destinationId;
  }

  ButtonStyle get _photoButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF5B7D46),
    side: const BorderSide(color: Color(0xFF5B7D46)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(vertical: 12),
  );

  @override
  void dispose() {
    _notesController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _pickingPhoto = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoFilename = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open photo. Check camera or gallery permissions and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _submitReport() async {
    if (_submitting || _pickingPhoto || _photo == null) return;
    if (_selectedDestination == null ||
        _destinationController.text.trim() != _selectedDestination ||
        !_destinationIds.containsKey(_selectedDestination)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination from the list.'),
        ),
      );
      return;
    }
    final id = _destinationIds[_selectedDestination];
    if (id == null) return;
    setState(() => _submitting = true);
    Map<String, dynamic> result;
    try {
      result = await CleanReportService().submit(
        destinationId: id,
        reportId: widget.reportId,
        notes: _notesController.text.trim(),
        image: _photo!,
        filename: _photoFilename,
      );
    } catch (error) {
      result = {'success': false, 'message': UserErrors.fromError(error)};
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _photo = null;
        _notesController.clear();
      });
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: true,
        title: 'Success',
        message:
            result['message']?.toString() ??
            'Clean report submitted successfully',
        buttonText: 'OK',
        onPressed: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      );
    } else {
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: result['message']?.toString() ?? UserErrors.unavailable,
        buttonText: 'OK',
        onPressed: () => Navigator.pop(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF5B7D46);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Report Clean Condition',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF7D9240),
        foregroundColor: Colors.white,
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Destination',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _destinationController,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.place_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Replying to dirty report #${widget.reportId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A2F),
                      ),
                    ),
                    if (widget.reportNotes.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(widget.reportNotes),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share a recent photo showing the cleaned area.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Your Report Helps',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your photo is submitted as evidence for this dirty report. Other users can add their evidence too. An admin must verify the cleanup before the report is marked as resolved.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Upload Evidence *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('Make sure the cleaned area is clearly visible.'),
              const SizedBox(height: 12),
              if (_photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _photo!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        _pickingPhoto
                            ? null
                            : () => setState(() {
                              _photo = null;
                            }),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove Photo'),
                  ),
                ),
              ] else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No image selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: _photoButtonStyle,
                      onPressed:
                          _pickingPhoto
                              ? null
                              : () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: _photoButtonStyle,
                      onPressed:
                          _pickingPhoto
                              ? null
                              : () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 20),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Notes / Description (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Describe the cleaned area...',
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
                    borderSide: const BorderSide(
                      color: Color(0xFF7D9240),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    _photo != null && !_pickingPhoto && !_submitting
                        ? _submitReport
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _submitting ? 'Sending Report...' : 'Send Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

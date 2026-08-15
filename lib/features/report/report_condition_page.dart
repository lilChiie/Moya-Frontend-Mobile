import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/destination_service.dart';
import '../../core/services/report_service.dart';
import '../../core/utils/dialog_utils.dart';

class ReportConditionPage extends StatefulWidget {
  const ReportConditionPage({super.key});

  @override
  State<ReportConditionPage> createState() => _ReportConditionPageState();
}

class _ReportConditionPageState extends State<ReportConditionPage> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> _destinations = [];
  bool _isLoadingDestinations = true;
  bool _argsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsInitialized) {
      _argsInitialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        if (args is Map) {
          final name = args['name'] ?? args['title'];
          if (name != null && name.toString().isNotEmpty) {
            _destinationController.text = name.toString();
            if (args['id'] != null) {
              if (!_destinations.any((d) => d['id'] == args['id'])) {
                _destinations.add({
                  'id': args['id'],
                  'name': name.toString(),
                });
              }
            }
          }
        } else if (args is String && args.isNotEmpty) {
          _destinationController.text = args;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final destinationService = DestinationService();
    try {
      final response = await destinationService.getDestinations();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        if (mounted) {
          setState(() {
            final apiList = data.map((e) => e as Map<String, dynamic>).toList();
            if (_destinationController.text.isNotEmpty) {
              final match = apiList.firstWhere(
                (d) =>
                    d['name']?.toString().trim().toLowerCase() ==
                    _destinationController.text.trim().toLowerCase(),
                orElse: () => {},
              );
              if (match.isNotEmpty) {
                _destinationController.text = match['name'];
              }
            }
            _destinations = apiList;
            _isLoadingDestinations = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDestinations = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDestinations = false;
        });
        AppDialogs.showStatusDialog(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Failed to load destinations',
          buttonText: 'OK',
          onPressed: () => Navigator.pop(context),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 60, // Compress image to avoid 'Read failed' on large files
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitReport() async {
    final selectedDestName = _destinationController.text.trim();
    final selectedDest = _destinations.cast<Map<String, dynamic>?>().firstWhere(
      (dest) =>
          dest?['name']?.toString().trim().toLowerCase() ==
          selectedDestName.toLowerCase(),
      orElse: () => null,
    );

    if (selectedDest == null) {
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Please select a valid destination',
        buttonText: 'OK',
        onPressed: () => Navigator.pop(context),
      );
      return;
    }
    
    if (_imageFile == null) {
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Please upload an evidence image',
        buttonText: 'OK',
        onPressed: () => Navigator.pop(context),
      );
      return;
    }

    if (_notesController.text.isEmpty) {
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Please add some notes',
        buttonText: 'OK',
        onPressed: () => Navigator.pop(context),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF7D9240)),
      ),
    );
    
    final reportService = ReportService();
    final result = await reportService.submitReport(
      destinationId: selectedDest['id'],
      userNotes: _notesController.text,
      image: _imageFile!,
    );
    
    if (!mounted) return;
    Navigator.pop(context); // close loading dialog
    
    if (result['success']) {
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: result['message'] ?? 'Report submitted successfully',
        buttonText: 'OK',
        onPressed: () {
          Navigator.pop(context); // close dialog
          Navigator.pop(context); // exit page
        },
      );
    } else {
      AppDialogs.showStatusDialog(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: result['message'] ?? 'Failed to submit report',
        buttonText: 'OK',
        onPressed: () => Navigator.pop(context),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7D9240),
        foregroundColor: Colors.white,
        title: const Text(
          'Report Condition',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Evidence Section
            const Text(
              'Upload Evidence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                image: _imageFile != null
                    ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _imageFile == null
                  ? Column(
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
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5B7D46),
                      side: const BorderSide(color: Color(0xFF5B7D46)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5B7D46),
                      side: const BorderSide(color: Color(0xFF5B7D46)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Destination Section
            const Text(
              'Destination',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<String>(
                  controller: _destinationController,
                  initialSelection: _destinationController.text.isNotEmpty
                      ? _destinationController.text
                      : null,
                  width: constraints.maxWidth,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  leadingIcon: const Icon(Icons.search),
                  trailingIcon: _isLoadingDestinations
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF7D9240),
                          ),
                        )
                      : null,
                  hintText: 'Search or select destination...',
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                  ),
                  dropdownMenuEntries: _destinations.map((dest) {
                    return DropdownMenuEntry<String>(
                      value: dest['name'],
                      label: dest['name'],
                    );
                  }).toList(),
                );
              }
            ),
            const SizedBox(height: 32),

            // Notes Section
            const Text(
              'Notes / Description',
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
              decoration: InputDecoration(
                hintText: 'Describe the issue or condition you found...',
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
              ),
            ),
            const SizedBox(height: 48),

            // Submit Button
            ElevatedButton(
              onPressed: _submitReport,
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
                'Send Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

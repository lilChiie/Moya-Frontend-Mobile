import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/services/tourism_service.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/user_errors.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Future<Map<String, dynamic>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = TourismService().getTourismCategories();
  }

  Future<void> _reload() async {
    final request = TourismService().getTourismCategories();
    setState(() => _categories = request);
    await request;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF7D9240),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _categories,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7D9240)),
              );
            }
            final result = snapshot.data;
            if (snapshot.hasError || result?['success'] != true) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        result?['message']?.toString() ??
                            UserErrors.unavailable,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final categories = result!['data'] as List;
            return RefreshIndicator(
              color: const Color(0xFF7D9240),
              onRefresh: _reload,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                itemCount: categories.isEmpty ? 1 : categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No categories found')),
                    );
                  }
                  final name =
                      (categories[index]['name'] ??
                              categories[index]['title'] ??
                              'Category')
                          .toString();
                  return Material(
                    color: const Color(0xFFF9FBF5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE8F0DF)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Icon(
                        categoryIcon(name),
                        color: const Color(0xFF5B7D46),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.destinations,
                            arguments: name,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

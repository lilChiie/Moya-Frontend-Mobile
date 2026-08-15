import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DestinationDetailPage extends StatefulWidget {
  const DestinationDetailPage({super.key});

  @override
  State<DestinationDetailPage> createState() =>
      _DestinationDetailPageState();
}

class _DestinationDetailPageState
    extends State<DestinationDetailPage> {
  final TextEditingController _reviewController =
      TextEditingController();

  final List<Map<String, dynamic>> _mockReviews = [
    {
      'name': 'Budi S.',
      'text': 'Sangat indah dan bersih!',
    },
    {
      'name': 'Rina M.',
      'text': 'Aksesibilitas sudah lumayan baik.',
    },
    {
      'name': 'Agus K.',
      'text': 'Fasilitas memadai, staf ramah.',
    },
    {
      'name': 'Siti A.',
      'text': 'Cocok untuk liburan keluarga.',
    },
    {
      'name': 'Tono W.',
      'text': 'Pemandangan luar biasa!',
    },
    {
      'name': 'Lia F.',
      'text': 'Tempat parkir agak jauh.',
    },
    {
      'name': 'Dodi P.',
      'text': 'Recommended banget pokoknya.',
    },
    {
      'name': 'Nita R.',
      'text':
          'Toilet khusus disabilitas tersedia dan bersih.',
    },
    {
      'name': 'Eko J.',
      'text':
          'Aman dan nyaman untuk pengguna kursi roda.',
    },
    {
      'name': 'Maya K.',
      'text': 'Sangat terawat dengan baik.',
    },
  ];

  @override
  void dispose() {
    _reviewController.dispose();
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
      body: CustomScrollView(
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
                  child: Image.asset(
                    dest['image'] ??
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

                    const SizedBox(height: 20),

                    // =================================================
                    // DRIVE TIME
                    // =================================================
                    Row(
                      children: [
                        Icon(
                          Icons
                              .directions_car_outlined,
                          color:
                              Colors.grey.shade600,
                          size: 19,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '1 jam 20 menit',
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // =================================================
                    // CATEGORY + ACCESSIBILITY
                    // =================================================
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          color:
                              Colors.grey.shade600,
                          size: 19,
                        ),

                        const SizedBox(width: 7),

                        Text(
                          dest['category'] ??
                              'Tujuan Wisata',
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          width: 4,
                          height: 4,
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Icon(
                          Icons.accessible,
                          size: 19,
                          color:
                              Color(0xFF7D9240),
                        ),

                        const SizedBox(width: 5),

                        const Text(
                          'Accessible',
                          style: TextStyle(
                            color:
                                Color(0xFF7D9240),
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

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

                    Text(
                      '${dest['title']} merupakan destinasi wisata yang menawarkan pemandangan menakjubkan dan udara yang segar. Tempat ini telah dilengkapi dengan berbagai fasilitas inklusif untuk memudahkan mobilitas bagi penyandang disabilitas.\n\nPengunjung dapat menikmati aktivitas rekreasi di area yang luas, gazebo yang nyaman untuk bersantai, serta akses jalan khusus kursi roda yang mulus dari area parkir hingga ke berbagai titik utama. Terdapat pula area parkir prioritas, toilet umum aksesibel, pusat informasi, dan tempat ibadah yang ramah difabel.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
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
                            onPressed: () {},
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
                              Navigator.pushNamed(context, '/report_condition');
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
                    // REVIEWS
                    // =================================================
                    const Text(
                      '10 Latest Reviews',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A2F),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =================================================
                    // REVIEW CARDS
                    // =================================================
                    ListView.separated(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount:
                          _mockReviews.length,
                      separatorBuilder:
                          (context, index) =>
                              const SizedBox(
                        height: 10,
                      ),
                      itemBuilder:
                          (context, index) {
                        final review =
                            _mockReviews[index];

                        return Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          decoration:
                              BoxDecoration(
                            color: const Color(
                              0xFFF8FAF5,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFFE7EBD9,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                review['name']!,
                                style:
                                    const TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: Color(
                                    0xFF1E3A2F,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                review['text']!,
                                style: TextStyle(
                                  color: Colors
                                      .grey.shade700,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

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
                      controller:
                          _reviewController,
                      maxLines: 3,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Share your experience...',
                        hintStyle: TextStyle(
                          color:
                              Colors.grey.shade500,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              BorderSide(
                            color:
                                Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              BorderSide(
                            color:
                                Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(0xFF7D9240),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            const Color(0xFFF9FBF5),
                        contentPadding:
                            const EdgeInsets.all(
                          16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =================================================
                    // SEND REVIEW
                    // =================================================
                    SizedBox(
                      width: double.infinity,
                      child:
                          ElevatedButton(
                        onPressed: () {
                          if (_reviewController
                              .text
                              .trim()
                              .isNotEmpty) {
                            ScaffoldMessenger
                                    .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Review submitted! (Mock)',
                                ),
                              ),
                            );

                            _reviewController
                                .clear();
                          }
                        },
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
                        child: const Text(
                          'Send Review',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
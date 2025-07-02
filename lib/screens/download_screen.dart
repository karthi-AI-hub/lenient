import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/form_entry.dart';
import 'package:printing/printing.dart';
import 'dart:io';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9FB),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              elevation: 1.5,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(3, (index) {
                    final isSelected = _tabController.index == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(index),
                        child: Container(
                          margin: EdgeInsets.only(
                            left: index == 0 ? 0 : 4,
                            right: index == 2 ? 0 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Form ${index + 1}',
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF7ED957) : Colors.black,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    height: 3,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7ED957),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DownloadTab(formType: 1),
                  _DownloadTab(formType: 2),
                  _DownloadTab(formType: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadTab extends StatelessWidget {
  final int formType;
  const _DownloadTab({required this.formType});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FormEntry>('forms').listenable(),
      builder: (context, Box<FormEntry> box, _) {
        final finalizedForms = box.values.where((f) => f.status == FormStatus.finalized && f.formType == formType).toList();
        if (finalizedForms.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Text('No finalized forms yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.grey[600])),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          itemCount: finalizedForms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final form = finalizedForms[i];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 1.5,
              color: Colors.white,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SvgPicture.asset(
                      'assets/file-icon.svg',
                      height: 28,
                      width: 28,
                      color: const Color(0xFF2F2F2F),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          form.taskId.isNotEmpty ? form.taskId : 'Untitled Form',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: const Color(0xFF222222),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(form.dateTime, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (form.pdfPath != null) {
                        await Printing.layoutPdf(
                          onLayout: (_) async => await File(form.pdfPath!).readAsBytes(),
                        );
                      }
                    },
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7ED957),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/fill-download-icon.svg',
                          height: 28,
                          width: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 
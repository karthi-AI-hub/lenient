import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/form_entry.dart';
import 'form_entry_screen.dart';
import '../utils/lenient_snackbar.dart';
import '../utils/lenient_dialog.dart';

class FormsScreen extends StatefulWidget {
  const FormsScreen({super.key});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // To update tab selection UI
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
                  _FormsTab(formType: 1),
                  _FormsTab(formType: 2),
                  _FormsTab(formType: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormsTab extends StatelessWidget {
  final int formType;
  const _FormsTab({required this.formType});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FormEntry>('forms').listenable(),
      builder: (context, Box<FormEntry> box, _) {
        final savedForms = box.values.where((f) => f.status == FormStatus.saved && f.formType == formType).toList();
        if (savedForms.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Text('No saved forms.\nStart a new form from Home.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.grey[600])),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          itemCount: savedForms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final form = savedForms[i];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1.5,
              color: Colors.white,
              child: ListTile(
                title: Text(
                  form.taskId.isNotEmpty ? form.taskId : 'Untitled Form',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: const Color(0xFF222222),
                    fontFamily: 'Poppins',
                  ),
                ),
                subtitle: Text(form.dateTime, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await LenientDialog.showConfirm(
                          context,
                          title: 'Delete Form',
                          content: 'Are you sure you want to delete this form?',
                          confirmText: 'Delete',
                          cancelText: 'Cancel',
                          confirmColor: Colors.red,
                        );
                        if (confirm == true) {
                          LenientSnackbar.showError(context, 'Form deleted');
                          await Hive.box<FormEntry>('forms').delete(form.id);
                        }
                      },
                    ),
                    SvgPicture.asset(
                      'assets/edit-icon.svg',
                      height: 28,
                      width: 28,
                      color: const Color(0xFF7ED957),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FormEntryScreen(formId: form.id)),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
            );
          },
        );
      },
    );
  }
} 
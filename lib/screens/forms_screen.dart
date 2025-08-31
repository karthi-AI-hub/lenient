import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/form_model.dart';
import 'form_entry_screen.dart';
import '../utils/lenient_snackbar.dart';
import '../utils/lenient_dialog.dart';
import 'pdf_preview_screen.dart';
import '../utils/pdf_generator.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../services/supabase_service.dart';
import '../utils/lenient_refresh_indicator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

String getFriendlyErrorMessage(dynamic error) {
  final msg = error.toString();
  if (msg.contains('duplicate key value') &&
      msg.contains('forms_task_id_key')) {
    return 'Task ID already exists. Try another Task ID';
  } else if (msg.contains('row-level security policy') ||
      msg.contains('Unauthorized')) {
    return 'Not authorized to perform this action.';
  } else if (msg.contains('StorageException')) {
    return 'Upload failed. Try again';
  }
  return 'Something went wrong.';
}

Future<Uint8List> downloadSignature(String? url) async {
  if (url == null || url.isEmpty) return Uint8List(0);
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  }
  return Uint8List(0);
}

class FormsScreen extends StatefulWidget {
  const FormsScreen({super.key});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

// --- Status Filter Button Widget ---
class _StatusFilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StatusFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7ED957) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF7ED957)
                  : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7ED957).withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: selected ? Colors.white : Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedFilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool left;
  final bool right;
  const _SegmentedFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.left = false,
    this.right = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7ED957) : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: left ? const Radius.circular(12) : Radius.zero,
              bottomLeft: left ? const Radius.circular(12) : Radius.zero,
              topRight: right ? const Radius.circular(12) : Radius.zero,
              bottomRight: right ? const Radius.circular(12) : Radius.zero,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: selected ? Colors.white : Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormsScreenState extends State<FormsScreen> {
  // Status filter: 0 = ALL, 1 = ONGOING, 2 = COMPLETED
  int _statusFilter = 0;
  // For multi-select
  bool _selectionMode = false;
  final Set<String> _selectedFormIds = {};
  String _search = '';
  final TextEditingController _searchController = TextEditingController();
  int _refreshKey = 0;
  int _selectedTabIndex = 0;
  final List<String> _tabTypes = ['LTCR', 'LCCR'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9FB),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: 8,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(
                  2,
                  (i) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == i
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(i == 0 ? 10 : 0),
                            bottomLeft: Radius.circular(i == 0 ? 10 : 0),
                            topRight: Radius.circular(i == 1 ? 10 : 0),
                            bottomRight: Radius.circular(i == 1 ? 10 : 0),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Text(
                              _tabTypes[i],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: _selectedTabIndex == i
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 15,
                                color: _selectedTabIndex == i
                                    ? const Color(0xFF22B14C)
                                    : Colors.black,
                              ),
                            ),
                            if (_selectedTabIndex == i)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                height: 2,
                                width: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22B14C),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _search = val),
                decoration: InputDecoration(
                  hintText: 'Search forms...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF7ED957),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _SegmentedFilterButton(
                    label: 'ALL',
                    selected: _statusFilter == 0,
                    onTap: () => setState(() => _statusFilter = 0),
                    left: true,
                    right: false,
                  ),
                  _SegmentedFilterButton(
                    label: 'ONGOING',
                    selected: _statusFilter == 1,
                    onTap: () => setState(() => _statusFilter = 1),
                    left: false,
                    right: false,
                  ),
                  _SegmentedFilterButton(
                    label: 'COMPLETED',
                    selected: _statusFilter == 2,
                    onTap: () => setState(() => _statusFilter = 2),
                    left: false,
                    right: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<FormModel>>(
              key: ValueKey(_refreshKey),
              stream: SupabaseService.streamForms(),
              builder: (context, snapshot) {
                if (_selectionMode &&
                    _selectedFormIds.isNotEmpty &&
                    snapshot.hasData) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Delete Selected (${_selectedFormIds.length})',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final confirm = await LenientDialog.showConfirm(
                                  context,
                                  title: 'Delete Forms',
                                  content:
                                      'Are you sure you want to delete the selected forms?',
                                  confirmText: 'Delete',
                                  cancelText: 'Cancel',
                                  confirmColor: Colors.red,
                                );
                                if (confirm == true) {
                                  try {
                                    for (final formId in _selectedFormIds) {
                                      final form = snapshot.data!.firstWhere(
                                        (f) => f.id == formId,
                                      );
                                      await SupabaseService.deleteForm(
                                        form.id,
                                        [
                                          ...?form.beforePhotoUrls,
                                          ...?form.afterPhotoUrls,
                                        ],
                                        form.signatureUrl,
                                        taskId: form.taskId,
                                      );
                                    }
                                    LenientSnackbar.showSuccess(
                                      context,
                                      'Selected forms deleted',
                                    );
                                    setState(() {
                                      _refreshKey++;
                                      _selectedFormIds.clear();
                                      _selectionMode = false;
                                    });
                                  } catch (e) {
                                    LenientSnackbar.showError(
                                      context,
                                      getFriendlyErrorMessage(e),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectionMode = false;
                                  _selectedFormIds.clear();
                                });
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildFormsList(context, snapshot)),
                    ],
                  );
                }
                return _buildFormsList(context, snapshot);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsList(
    BuildContext context,
    AsyncSnapshot<List<FormModel>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7ED957),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _refreshKey++;
                  });
                },
              ),
            ],
          ),
        ),
      );
    } else if (snapshot.data == null || snapshot.data!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Text(
            'No forms found.\nCreate a new form from Home.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    } else {
      final allForms = snapshot.data!;
      final filtered = allForms.where((f) {
        final matchesTab =
            (_selectedTabIndex == 0 && f.taskId.startsWith('LTS-')) ||
            (_selectedTabIndex == 1 && f.taskId.startsWith('LCS-'));
        if (!matchesTab) return false;
        // Status filter
        if (_statusFilter == 1 && (f.status.toLowerCase() != 'ongoing'))
          return false;
        if (_statusFilter == 2 && (f.status.toLowerCase() != 'completed'))
          return false;
        if (_search.isEmpty) return true;
        final q = _search.toLowerCase();
        return f.taskId.toLowerCase().contains(q) ||
            f.companyName.toLowerCase().contains(q) ||
            (f.phone?.toLowerCase().contains(q) ?? false) ||
            (f.problemDescription?.toLowerCase().contains(q) ?? false) ||
            (f.reportDescription?.toLowerCase().contains(q) ?? false) ||
            (f.materialsDelivered?.toLowerCase().contains(q) ?? false) ||
            (f.materialsReceived?.toLowerCase().contains(q) ?? false) ||
            (f.addressLine?.toLowerCase().contains(q) ?? false) ||
            (f.addressCity?.toLowerCase().contains(q) ?? false);
      }).toList();
      if (filtered.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Text(
              'No forms in ${_tabTypes[_selectedTabIndex]}.\nCreate a new form from Home.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      }
      return LenientRefreshIndicator(
        onRefresh: () async {
          setState(() {
            _refreshKey++;
          });
        },
        successMessage: 'Data refreshed',
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final form = filtered[i];
            final isSelected = _selectedFormIds.contains(form.id);
            return GestureDetector(
              onLongPress: () {
                setState(() {
                  _selectionMode = true;
                  _selectedFormIds.add(form.id);
                });
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0.8,
                color: isSelected ? Colors.red[50] : Colors.white,
                shadowColor: const Color(0xFF7ED957).withOpacity(0.05),
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: ListTile(
                  leading: _selectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedFormIds.add(form.id);
                              } else {
                                _selectedFormIds.remove(form.id);
                                if (_selectedFormIds.isEmpty) {
                                  _selectionMode = false;
                                }
                              }
                            });
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  title: Text(
                    '${form.taskId}_${form.companyName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: (form.status.toLowerCase() == 'ongoing')
                          ? Colors.orange
                          : (form.status.toLowerCase() == 'completed')
                          ? const Color(0xFF7ED957)
                          : const Color(0xFF222222),
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(form.createdAt.toLocal()),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  trailing: !_selectionMode
                      ? PopupMenuButton<String>(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          icon: const Icon(
                            Icons.more_vert,
                            color: Color(0xFF7ED957),
                            size: 20,
                          ),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FormEntryScreen(
                                    formId: form.id,
                                    formType: _selectedTabIndex == 0
                                        ? 'LTCR'
                                        : 'LCCR',
                                  ),
                                ),
                              );
                            } else if (value == 'preview' || value == 'share') {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              try {
                                final pdfBytes = await generateTaskReportPDF(
                                  context: context,
                                  taskId: form.taskId,
                                  dateTime: DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(form.createdAt.toLocal()),
                                  companyName: form.companyName,
                                  phone: form.phone ?? '',
                                  addressLine: form.addressLine ?? '',
                                  addressCity: form.addressCity ?? '',
                                  reportedBy: form.reportedBy ?? '',
                                  problemDescription:
                                      form.problemDescription ?? '',
                                  reportDescription:
                                      form.reportDescription ?? '',
                                  materialsDelivered:
                                      form.materialsDelivered ?? '',
                                  materialsReceived:
                                      form.materialsReceived ?? '',
                                  beforePhotoUrls: form.beforePhotoUrls ?? [],
                                  afterPhotoUrls: form.afterPhotoUrls ?? [],
                                  customerName: form.customeName ?? '',
                                  signaturePoints: [],
                                  signatureImage: await downloadSignature(
                                    form.signatureUrl,
                                  ),
                                  rating: form.rating ?? 0,
                                  formType: form.formType,
                                );
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                if (value == 'preview') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PdfPreviewScreen(
                                        pdfBytes: pdfBytes,
                                        taskId: form.taskId,
                                        companyName: form.companyName,
                                      ),
                                    ),
                                  );
                                } else if (value == 'share') {
                                  await Printing.sharePdf(
                                    bytes: pdfBytes,
                                    filename:
                                        '${form.taskId}_${form.companyName}.pdf',
                                  );
                                }
                              } catch (e, st) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                debugPrint('Error generating PDF: $e');
                                debugPrint('StackTrace: $st');
                                LenientSnackbar.showError(
                                  context,
                                  'Failed to generate PDF: $e',
                                );
                              }
                            } else if (value == 'delete') {
                              final confirm = await LenientDialog.showConfirm(
                                context,
                                title: 'Delete Form',
                                content:
                                    'Are you sure you want to delete this form?',
                                confirmText: 'Delete',
                                cancelText: 'Cancel',
                                confirmColor: Colors.red,
                              );
                              if (confirm == true) {
                                try {
                                  await SupabaseService.deleteForm(
                                    form.id,
                                    [
                                      ...?form.beforePhotoUrls,
                                      ...?form.afterPhotoUrls,
                                    ],
                                    form.signatureUrl,
                                    taskId: form.taskId,
                                  );
                                  LenientSnackbar.showSuccess(
                                    context,
                                    'Form deleted',
                                  );
                                  setState(() {
                                    _refreshKey++;
                                  });
                                } catch (e) {
                                  LenientSnackbar.showError(
                                    context,
                                    getFriendlyErrorMessage(e),
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(
                                  Icons.edit,
                                  color: Color(0xFF7ED957),
                                ),
                                title: Text(
                                  'Edit',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'preview',
                              child: ListTile(
                                leading: Icon(
                                  Icons.picture_as_pdf,
                                  color: Color(0xFF7ED957),
                                ),
                                title: Text(
                                  'Preview / Download PDF',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share',
                              child: ListTile(
                                leading: Icon(
                                  Icons.share,
                                  color: Color(0xFF7ED957),
                                ),
                                title: Text(
                                  'Share PDF',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text(
                                  'Delete',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                            ),
                          ],
                        )
                      : null,
                  onTap: !_selectionMode
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedFormIds.remove(form.id);
                              if (_selectedFormIds.isEmpty) {
                                _selectionMode = false;
                              }
                            } else {
                              _selectedFormIds.add(form.id);
                            }
                          });
                        },
                ),
              ),
            );
          },
        ),
      );
    }
  }
}

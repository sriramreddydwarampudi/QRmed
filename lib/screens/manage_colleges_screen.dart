import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/screens/add_edit_college_screen.dart';
import '../models/college.dart';
import '../providers/college_provider.dart';
import '../widgets/management_list_widget.dart';

class ManageCollegesScreen extends StatefulWidget {
  const ManageCollegesScreen({super.key});

  @override
  State<ManageCollegesScreen> createState() => _ManageCollegesScreenState();
}

class _ManageCollegesScreenState extends State<ManageCollegesScreen> {
  @override
  void initState() {
    super.initState();
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    await Provider.of<CollegeProvider>(context, listen: false).fetchColleges();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colleges = Provider.of<CollegeProvider>(context).colleges;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Colleges'),
        elevation: 0,
      ),
      body: ManagementListWidget(
        items: colleges
            .map(
              (c) => ManagementListItem(
                id: c.id,
                title: c.name,
                subtitle: '${c.city} • ${c.type}',
                icon: Icons.school_outlined,
                iconColor: const Color(0xFF8B5CF6),
                actions: [
                  ManagementAction(
                    label: 'View',
                    icon: Icons.remove_red_eye,
                    color: const Color(0xFF2563EB),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('College Details'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow('Name', c.name),
                                _DetailRow('ID', c.id),
                                _DetailRow('City', c.city),
                                _DetailRow('Type', c.type),
                                _DetailRow('Seats', c.seats),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ManagementAction(
                    label: 'Edit',
                    icon: Icons.edit,
                    color: const Color(0xFF16A34A),
                    onPressed: () async {
                      final updatedCollege =
                          await Navigator.of(context).push<College>(
                        MaterialPageRoute(
                          builder: (context) => AddEditCollegeScreen(
                            college: c,
                          ),
                        ),
                      );
                      if (updatedCollege != null) {
                        await Provider.of<CollegeProvider>(context,
                                listen: false)
                            .updateCollege(updatedCollege.id, updatedCollege);
                        await _fetchColleges();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('College updated successfully.')),
                        );
                      }
                    },
                  ),
                  ManagementAction(
                    label: 'Delete',
                    icon: Icons.delete,
                    color: const Color(0xFFDC2626),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete College'),
                          content: const Text(
                              'Are you sure you want to delete this college?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await Provider.of<CollegeProvider>(context,
                                listen: false)
                            .deleteCollege(c.id);
                        await _fetchColleges();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('College deleted.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            )
            .toList(),
        emptyMessage: 'No colleges found',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newCollege = await Navigator.of(context).push<College>(
            MaterialPageRoute(
              builder: (context) => const AddEditCollegeScreen(),
            ),
          );
          if (newCollege != null) {
            await Provider.of<CollegeProvider>(context, listen: false)
                .addCollege(newCollege);
            await _fetchColleges();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('College added successfully.')),
            );
          }
        },
        tooltip: 'Add College',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/screens/add_edit_visitor_screen.dart'; // Updated import
import '../models/visitor.dart'; // Updated import
import '../providers/visitor_provider.dart'; // Updated import
import '../widgets/management_list_widget.dart';
import '../widgets/modern_details_dialog.dart';

class ManageVisitorsScreen extends StatefulWidget { // Renamed class
  final String collegeName;
  const ManageVisitorsScreen({super.key, required this.collegeName});

  @override
  State<ManageVisitorsScreen> createState() => _ManageVisitorsScreenState(); // Renamed state class
}

class _ManageVisitorsScreenState extends State<ManageVisitorsScreen> { // Renamed state class
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVisitors(); // Renamed method
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVisitors() async { // Renamed method
    setState(() => _isLoading = true);
    try {
      await Provider.of<VisitorProvider>(context, listen: false).fetchVisitors(); // Updated provider
    } catch (e) {
      debugPrint('Error fetching visitors: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final allVisitors = Provider.of<VisitorProvider>(context).visitors;
    final filteredVisitors = allVisitors
        .where((v) => v.collegeId.trim().toLowerCase() == widget.collegeName.trim().toLowerCase())
        .where((v) {
          return v.name.toLowerCase().contains(query) ||
              v.id.toLowerCase().contains(query) ||
              (v.email?.toLowerCase().contains(query) ?? false) ||
              (v.phone?.toLowerCase().contains(query) ?? false);
        })
        .toList(); // Changed variable name
        
    debugPrint('ManageVisitorsScreen: College ID: ${widget.collegeName}');
    debugPrint('ManageVisitorsScreen: Total visitors in provider: ${allVisitors.length}');
    debugPrint('ManageVisitorsScreen: Visitors after filtering: ${filteredVisitors.length}');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, ID or email...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF059669)),
                hintStyle: TextStyle(color: Colors.black54, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(color: Colors.black, fontSize: 15),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 20),
            onPressed: _fetchVisitors,
          ),
        ],
      ),
      body: ManagementListWidget(
        isLoading: _isLoading,
        items: filteredVisitors // Changed variable name
            .map(
              (v) => ManagementListItem( // Changed variable name
                id: v.id,
                title: v.name,
                subtitle: '${v.phone} • ${v.email}',
                icon: Icons.person_outline,
                iconColor: const Color(0xFF059669),
                actions: [
                  ManagementAction(
                    label: 'View',
                    icon: Icons.remove_red_eye,
                    color: const Color(0xFF2563EB),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ModernDetailsDialog(
                          title: 'Visitor Details', // Updated UI text
                          details: [
                            DetailRow(label: 'Name', value: v.name),
                            DetailRow(label: 'ID', value: v.id),
                            DetailRow(label: 'Password', value: v.password),
                            DetailRow(label: 'Phone', value: v.phone ?? '-'),
                            DetailRow(label: 'Email', value: v.email ?? '-'),
                            DetailRow(label: 'College', value: v.collegeId),
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
                      final updatedVisitor = // Changed variable name
                          await Navigator.of(context).push<Visitor>( // Using Visitor model
                        MaterialPageRoute(
                          builder: (context) => AddEditVisitorScreen( // Updated screen name
                            visitor: v, // Changed variable name
                            collegeId: widget.collegeName,
                          ),
                        ),
                      );
                      if (updatedVisitor != null) {
                        await Provider.of<VisitorProvider>(context, // Updated provider
                                listen: false)
                            .updateVisitor(updatedVisitor.id, updatedVisitor); // Updated method
                        await _fetchVisitors(); // Renamed method
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Visitor updated successfully.')), // Updated UI text
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
                          title: const Text('Delete Visitor'), // Updated UI text
                          content: const Text(
                              'Are you sure you want to delete this visitor?'), // Updated UI text
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
                        await Provider.of<VisitorProvider>(context, // Updated provider
                                listen: false)
                            .deleteVisitor(v.id); // Updated method
                        await _fetchVisitors(); // Renamed method
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visitor deleted.')), // Updated UI text
                        );
                      }
                    },
                  ),
                ],
              ),
            )
            .toList(),
        emptyMessage: query.isEmpty ? 'No visitors found' : 'No visitors match your search.', // Updated UI text
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newVisitor = await Navigator.of(context).push<Visitor>(
            MaterialPageRoute(
              builder: (context) => AddEditVisitorScreen(
                collegeId: widget.collegeName,
              ),
            ),
          );
          
          if (newVisitor != null) {
            await Provider.of<VisitorProvider>(context, listen: false).addVisitor(newVisitor);
            await _fetchVisitors();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Visitor added successfully.')),
            );
          }
        },
        tooltip: 'Add Visitor', // Updated UI text
        child: const Icon(Icons.add),
      ),
    );
  }
}

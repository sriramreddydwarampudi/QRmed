import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/college.dart';
import '../providers/college_provider.dart';
import '../services/auth_service.dart';

class ManageCollegesScreen extends StatefulWidget {
  const ManageCollegesScreen({super.key});

  @override
  State<ManageCollegesScreen> createState() => _ManageCollegesScreenState();
}

class _ManageCollegesScreenState extends State<ManageCollegesScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    final provider = Provider.of<CollegeProvider>(context, listen: false);
    try {
      debugPrint('Fetching colleges from Firestore...');
      await provider.fetchColleges();
      debugPrint('Colleges fetched: \\${provider.colleges.length}');
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e, stack) {
      debugPrint('Error fetching colleges: \\${e.toString()}');
      debugPrint(stack.toString());
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Colleges'),
      ),
      body: Consumer<CollegeProvider>(
        builder: (context, collegeProvider, _) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(child: Text('Error: $_error'));
          }
          final colleges = collegeProvider.colleges;
          if (colleges.isEmpty) {
            return const Center(child: Text('No colleges found.'));
          }
          return ListView.builder(
            itemCount: colleges.length,
            itemBuilder: (context, index) {
              final college = colleges[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(college.name),
                  subtitle: Text('${college.city} • ${college.type} • Seats: ${college.seats}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye),
                        tooltip: 'View',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('College Details'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Name: ${college.name}'),
                                  Text('City: ${college.city}'),
                                  Text('Type: ${college.type}'),
                                  Text('Seats: ${college.seats}'),
                                  Text('ID: ${college.id}'),
                                  Text('Latitude: ${college.latitude ?? '-'}'),
                                  Text('Longitude: ${college.longitude ?? '-'}'),
                                ],
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
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit',
                        onPressed: () async {
                          final updated = await Navigator.of(context).pushNamed(
                            '/addEditCollege',
                            arguments: college,
                          );
                          if (updated is College) {
                            collegeProvider.updateCollege(college.id, updated);
                            await _fetchColleges();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('College updated successfully.')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete College'),
                              content: const Text('Are you sure you want to delete this college?'),
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
                            collegeProvider.deleteCollege(college.id);
                            await _fetchColleges();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('College deleted.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newCollege = await Navigator.of(context).pushNamed('/addEditCollege');
          if (newCollege is College) {
            final provider = Provider.of<CollegeProvider>(context, listen: false);
            await provider.addCollege(newCollege);
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

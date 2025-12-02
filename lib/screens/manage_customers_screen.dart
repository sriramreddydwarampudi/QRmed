import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/screens/add_edit_customer_screen.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../widgets/management_list_widget.dart';
import '../widgets/modern_details_dialog.dart';

class ManageCustomersScreen extends StatefulWidget {
  final String collegeName;
  const ManageCustomersScreen({super.key, required this.collegeName});

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    await Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    setState(() {});
  }

  String get _generatedId {
    final name = _nameController.text.trim().toLowerCase().replaceAll(' ', '');
    final email = _emailController.text.trim().toLowerCase().replaceAll(' ', '');
    final college = widget.collegeName.toLowerCase().replaceAll(' ', '');
    if (name.isNotEmpty && email.isNotEmpty && college.isNotEmpty) {
      return '$name-$email@$college';
    }
    return '';
  }

  Future<void> _addCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    final customer = Customer(
      id: _generatedId,
      name: _nameController.text.trim(),
      password: _passwordController.text.trim(),
      collegeId: widget.collegeName,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    await Provider.of<CustomerProvider>(context, listen: false).addCustomer(customer);
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    await _fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final customers = Provider.of<CustomerProvider>(context).customers
        .where((c) => c.collegeId == widget.collegeName).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Customers'),
        elevation: 0,
      ),
      body: ManagementListWidget(
        items: customers
            .map(
              (c) => ManagementListItem(
                id: c.id,
                title: c.name,
                subtitle: '${c.phone} • ${c.email}',
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
                          title: 'Customer Details',
                          details: [
                            DetailRow(label: 'Name', value: c.name),
                            DetailRow(label: 'ID', value: c.id),
                            DetailRow(label: 'Phone', value: c.phone ?? '-'),
                            DetailRow(label: 'Email', value: c.email ?? '-'),
                            DetailRow(label: 'College', value: c.collegeId),
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
                      final updatedCustomer =
                          await Navigator.of(context).push<Customer>(
                        MaterialPageRoute(
                          builder: (context) => AddEditCustomerScreen(
                            customer: c,
                            collegeId: widget.collegeName,
                          ),
                        ),
                      );
                      if (updatedCustomer != null) {
                        await Provider.of<CustomerProvider>(context,
                                listen: false)
                            .updateCustomer(updatedCustomer.id, updatedCustomer);
                        await _fetchCustomers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Customer updated successfully.')),
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
                          title: const Text('Delete Customer'),
                          content: const Text(
                              'Are you sure you want to delete this customer?'),
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
                        await Provider.of<CustomerProvider>(context,
                                listen: false)
                            .deleteCustomer(c.id);
                        await _fetchCustomers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Customer deleted.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            )
            .toList(),
        emptyMessage: 'No customers found',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add Customer'),
              content: SingleChildScrollView(
                child: _buildCustomerForm(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _addCustomer();
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customer added successfully.')),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        tooltip: 'Add Customer',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomerForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
          ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (v) => v == null || v.length < 8 ? 'Min 8 chars' : null,
          ),
          const SizedBox(height: 8),
          Text('Generated ID: $_generatedId'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

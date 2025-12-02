import 'package:flutter/material.dart';
import 'package:supreme_institution/models/customer.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer;
  final String collegeId;

  const AddEditCustomerScreen({
    super.key,
    this.customer,
    required this.collegeId,
  });

  @override
  _AddEditCustomerScreenState createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _passwordController.text = widget.customer!.password;
      _emailController.text = widget.customer!.email ?? '';
      _phoneController.text = widget.customer!.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _generatedId {
    final name = _nameController.text.trim().toLowerCase().replaceAll(' ', '');
    final email = _emailController.text.trim().toLowerCase().replaceAll(' ', '');
    final college = widget.collegeId.toLowerCase().replaceAll(' ', '');
    if (name.isNotEmpty && email.isNotEmpty && college.isNotEmpty) {
      return '$name-$email@$college';
    }
    return '';
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      final customerId = widget.customer?.id ?? _generatedId;

      final newCustomer = Customer(
        id: customerId,
        name: _nameController.text.trim(),
        password: _passwordController.text.trim(),
        collegeId: widget.collegeId,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      Navigator.of(context).pop(newCustomer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the customer name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveCustomer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.customer == null ? 'Add Customer' : 'Update Customer',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

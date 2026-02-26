import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Not directly used in this screen, but often part of Flutter setups
import 'package:supreme_institution/models/visitor.dart'; // Updated import
import 'dart:math'; // Added for Random class
import 'package:english_words/english_words.dart' as english_words; // Added for meaningful words

class AddEditVisitorScreen extends StatefulWidget { // Renamed class
  final Visitor? visitor; // Renamed variable
  final String collegeId;

  const AddEditVisitorScreen({
    super.key,
    this.visitor, // Renamed variable
    required this.collegeId,
  });

  @override
  _AddEditVisitorScreenState createState() => _AddEditVisitorScreenState(); // Renamed state class
}

class _AddEditVisitorScreenState extends State<AddEditVisitorScreen> { // Renamed state class
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true; // Added for password visibility toggle

  @override
  void initState() {
    super.initState();
    if (widget.visitor != null) { // Renamed variable
      _nameController.text = widget.visitor!.name; // Renamed variable
      _passwordController.text = widget.visitor!.password; // Renamed variable
      _emailController.text = widget.visitor!.email ?? ''; // Renamed variable
      _phoneController.text = widget.visitor!.phone ?? ''; // Renamed variable
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

  String _generatePassword() {
    final random = Random();
    String word = "";
    // Keep picking until we find a word with 6-10 letters
    while (word.length < 6 || word.length > 10) {
      word = english_words.all.elementAt(random.nextInt(english_words.all.length));
    }
    return word;
  }

  String get _generatedId {
    final name = _nameController.text.trim().toLowerCase().replaceAll(' ', '');
    final email = _emailController.text.trim().toLowerCase().replaceAll(' ', '');
    final college = widget.collegeId.trim().toLowerCase().replaceAll(' ', '');
    if (name.isNotEmpty && college.isNotEmpty) {
      if (email.isNotEmpty) {
        return '$name-$email@$college';
      } else {
        return '$name@$college';
      }
    }
    return '';
  }

  void _saveVisitor() { // Renamed method
    if (_formKey.currentState!.validate()) {
      final visitorId = widget.visitor?.id ?? _generatedId; // Renamed variable
      
      if (visitorId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot generate a valid ID. Make sure Name is provided.')),
        );
        return;
      }

      final newVisitor = Visitor( // Using Visitor model
        id: visitorId,
        name: _nameController.text.trim(),
        password: _passwordController.text.trim(),
        collegeId: widget.collegeId,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      Navigator.of(context).pop(newVisitor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visitor == null ? 'Add Visitor' : 'Edit Visitor'), // Updated UI text
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
                onChanged: (_) => setState(() {}), // Trigger rebuild for generated ID preview
                decoration: const InputDecoration(labelText: 'Visitor Name'), // Updated UI text
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the visitor name.'; // Updated UI text
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                onChanged: (_) => setState(() {}), // Trigger rebuild for generated ID preview
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword, // Use the state variable
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
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
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _passwordController.text = _generatePassword();
                      });
                    },
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Generate'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.visitor == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Generated Login ID: $_generatedId',
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveVisitor, // Renamed method
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.visitor == null ? 'Add Visitor' : 'Update Visitor', // Updated UI text
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

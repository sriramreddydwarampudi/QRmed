import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Added for image picking
import 'package:firebase_storage/firebase_storage.dart'; // Added for Firebase Storage
import 'dart:io'; // For File

import '../models/college.dart';

class AddEditCollegeScreen extends StatefulWidget {
  final College? college;
  const AddEditCollegeScreen({super.key, this.college});

  @override
  State<AddEditCollegeScreen> createState() => _AddEditCollegeScreenState();
}

class _AddEditCollegeScreenState extends State<AddEditCollegeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _type = 'Dental';
  String _seats = '40';
  bool _obscurePassword = true;
  final TextEditingController _cityController = TextEditingController();

  File? _pickedImage; // New: to store the picked image file
  String? _logoUrl; // New: to store the URL of the uploaded logo

  @override
  void initState() {
    super.initState();
    if (widget.college != null) {
      _nameController.text = widget.college!.name;
      _type = widget.college!.type;
      _seats = widget.college!.seats;
      _passwordController.text = widget.college!.password;
      _cityController.text = widget.college!.city;
      _logoUrl = widget.college!.logoUrl; // New: Initialize logoUrl if college has one
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _generatedId {
    final name = _nameController.text.trim().toLowerCase().replaceAll(' ', '');
    final city = _cityController.text.trim().toLowerCase().replaceAll(' ', '');
    final type = _type.toLowerCase();
    if (name.isNotEmpty && city.isNotEmpty && type.isNotEmpty) {
      return '$name-$type@$city.in';
    }
    return '';
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // New: Function to pick an image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); // Image quality reduced

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // New: Function to upload image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (_pickedImage == null) {
      return _logoUrl; // If no new image picked, return existing URL
    }

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('college_logos')
          .child('${_generatedId}_${DateTime.now().toIso8601String()}.jpg'); // Unique name

      await ref.putFile(_pickedImage!);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  void _saveCollege() async {
    if (!_formKey.currentState!.validate()) return;

    String? finalLogoUrl = _logoUrl; // Start with existing logo URL
    if (_pickedImage != null) { // If a new image is picked
      finalLogoUrl = await _uploadImage(); // Upload and get new URL
      if (finalLogoUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload logo.')),
          );
        }
        return;
      }
    }

    final college = College(
      id: _generatedId,
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      type: _type,
      seats: _seats,
      password: _passwordController.text.trim(),
      logoUrl: finalLogoUrl, // New: Pass the logo URL
    );
    Navigator.of(context).pop(college);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.college == null ? 'Add College' : 'Edit College')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // New: Logo Upload Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (_logoUrl != null ? NetworkImage(_logoUrl!) : null),
                      child: _pickedImage == null && _logoUrl == null
                          ? Icon(Icons.school, size: 60, color: Colors.grey.shade600)
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_pickedImage != null || _logoUrl != null ? 'Change Logo' : 'Add Logo'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'College Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter college name' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => v == null || v.isEmpty ? 'Enter city' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      items: const [
                        DropdownMenuItem(value: 'Dental', child: Text('Dental')),
                        DropdownMenuItem(value: 'MBBS', child: Text('MBBS')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _type = val!;
                          _seats = _type == 'Dental' ? '40' : '100'; // Default seats based on type
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _seats,
                      items: _type == 'Dental'
                          ? const [
                              DropdownMenuItem(value: '40', child: Text('40')),
                              DropdownMenuItem(value: '50', child: Text('50')),
                              DropdownMenuItem(value: '60', child: Text('60')),
                              DropdownMenuItem(value: '100', child: Text('100')),
                            ]
                          : const [
                              DropdownMenuItem(value: '100', child: Text('100')),
                              DropdownMenuItem(value: '200', child: Text('200')),
                            ],
                      onChanged: (val) {
                        setState(() {
                          _seats = val!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Seats'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter password';
                  if (v.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text('Auto-generated ID:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade100,
                ),
                child: Text(_generatedId.isEmpty ? 'Will be generated based on name and city' : _generatedId,
                  style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCollege,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.college == null ? 'Add College' : 'Update College',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
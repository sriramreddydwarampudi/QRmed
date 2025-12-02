import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';
import '../providers/employee_provider.dart';
import '../models/college.dart';
import '../providers/college_provider.dart';
import '../data/requirements_data.dart';
import '../widgets/management_list_widget.dart';
import '../widgets/modern_details_dialog.dart';

class ManageEquipmentsScreen extends StatefulWidget { // Changed from ManageProductsScreen
  final String collegeName;
  const ManageEquipmentsScreen({super.key, required this.collegeName}); // Changed from ManageProductsScreen

  @override
  _ManageEquipmentsScreenState createState() => _ManageEquipmentsScreenState(); // Changed from _ManageProductsScreenState
}

class _ManageEquipmentsScreenState extends State<ManageEquipmentsScreen> { // Changed from _ManageProductsScreenState
  // Controllers
  final _equipmentNameController = TextEditingController();
  final _equipmentTypeController = TextEditingController();
  final _equipmentGroupController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _serialNoController = TextEditingController();
  final _departmentController = TextEditingController();
  final _statusController = TextEditingController();
  final _serviceStatusController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _purchasedValueController = TextEditingController();
  final _employeeAssignedController = TextEditingController();
  final _verifiedByController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  DateTime? _purchasedDate;
  DateTime? _verifiedDate;
  String _generatedId = '';
  final Map<String, GlobalKey> _stickerKeys = {};

  List<String> _equipmentNames = []; // Added for dropdown
  String? _selectedEquipment; // Added for dropdown
  College? _college; // Added to store college data

  Future<void> _exportStickerAsPng(Equipment equipment) async {
    try {
      debugPrint('🎨 [STICKER] Starting export for equipment: ${equipment.id} - ${equipment.name}');
      
      if (!_stickerKeys.containsKey(equipment.id)) {
        debugPrint('❌ [STICKER] Key not found for equipment: ${equipment.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Sticker not found. Please refresh and try again.')),
        );
        return;
      }

      debugPrint('✅ [STICKER] Key found for equipment: ${equipment.id}');
      final key = _stickerKeys[equipment.id]!;
      
      debugPrint('⏳ [STICKER] Waiting for widget to fully render...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) {
        debugPrint('❌ [STICKER] Widget not mounted');
        return;
      }
      
      if (key.currentContext == null) {
        debugPrint('❌ [STICKER] Current context is null for equipment: ${equipment.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Sticker not ready. Please try again.')),
        );
        return;
      }

      debugPrint('✅ [STICKER] Current context found');
      final RenderObject? renderObject = key.currentContext!.findRenderObject();
      
      if (renderObject == null) {
        debugPrint('❌ [STICKER] RenderObject is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not find render object.')),
        );
        return;
      }

      final boundary = renderObject as RenderRepaintBoundary?;
      
      if (boundary == null) {
        debugPrint('❌ [STICKER] RenderRepaintBoundary is null');
        debugPrint('📊 [STICKER] Render object type: ${renderObject.runtimeType}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not render sticker. Please try again.')),
        );
        return;
      }

      debugPrint('✅ [STICKER] RenderRepaintBoundary found');
      debugPrint('📐 [STICKER] Converting to image with 2x pixelRatio...');
      
      // Use a more aggressive wait strategy
      ui.Image? image;
      int attempts = 0;
      const maxAttempts = 5;
      
      while (image == null && attempts < maxAttempts) {
        try {
          debugPrint('🔄 [STICKER] Attempt ${attempts + 1}/$maxAttempts to capture image');
          
          // Wait for frame and extra time
          await WidgetsBinding.instance.endOfFrame;
          await Future.delayed(const Duration(milliseconds: 150));
          
          if (!mounted) {
            debugPrint('❌ [STICKER] Widget unmounted');
            return;
          }
          
          // Check if boundary is in a valid state
          debugPrint('✅ [STICKER] Boundary state: size=${boundary.size}, hasSize=${boundary.hasSize}');
          
          image = await boundary.toImage(pixelRatio: 2.0);
          debugPrint('✅ [STICKER] Image created: ${image.width}x${image.height}');
          break;
        } catch (e) {
          attempts++;
          debugPrint('⚠️ [STICKER] Attempt $attempts failed: $e');
          
          if (attempts >= maxAttempts) {
            debugPrint('❌ [STICKER] All attempts failed');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: Could not export sticker after multiple attempts.')),
              );
            }
            return;
          }
          
          // Wait longer before retry
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      
      if (image == null) {
        debugPrint('❌ [STICKER] Failed to create image');
        return;
      }
      
      debugPrint('🔄 [STICKER] Converting image to bytes...');
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint('❌ [STICKER] ByteData conversion failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not process image. Please try again.')),
        );
        return;
      }

      debugPrint('✅ [STICKER] ByteData created: ${byteData.lengthInBytes} bytes');

      final bytes = byteData.buffer.asUint8List();
      final fileName = 'equipment_${equipment.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      
      if (kIsWeb) {
        debugPrint('🌐 [STICKER] Web platform detected - triggering download...');
        _downloadFileWeb(bytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded: $fileName')),
          );
        }
        return;
      }

      if (io.Platform.isAndroid || io.Platform.isIOS) {
        debugPrint('📱 [STICKER] Mobile platform detected - saving to gallery...');
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          name: fileName.replaceAll('.png', ''),
          quality: 100,
        );
        
        debugPrint('📌 [STICKER] Save result: $result');
        
        if (mounted) {
          final success = result['isSuccess'] == true;
          debugPrint('${success ? '✅' : '❌'} [STICKER] Export ${success ? 'succeeded' : 'failed'}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success 
                ? 'Sticker exported to gallery successfully!' 
                : 'Failed to export sticker.'),
            ),
          );
        }
      } else {
        debugPrint('🖥️ [STICKER] Desktop platform detected - saving to file...');
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Equipment Sticker',
          fileName: fileName,
          type: FileType.image,
          allowedExtensions: ['png'],
        );
        
        if (savePath != null) {
          debugPrint('💾 [STICKER] Saving to: $savePath');
          final file = io.File(savePath);
          await file.writeAsBytes(bytes);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sticker saved to: $savePath')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Save cancelled.')),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [STICKER] EXCEPTION: $e');
      debugPrint('📍 [STICKER] STACK TRACE:\n$stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting sticker: $e')),
        );
      }
    }
  }

  void _downloadFileWeb(Uint8List bytes, String fileName) {
    debugPrint('🌐 [STICKER] Downloading on web: $fileName');
    
    if (!kIsWeb) {
      debugPrint('⚠️ [STICKER] Web download only supported on web platform');
      return;
    }
    
    // Web download using base64 data URL
    try {
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:image/png;base64,$base64String';
      debugPrint('✅ [STICKER] Web download initiated: $fileName');
    } catch (e) {
      debugPrint('❌ [STICKER] Web download failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEquipments();
      _loadCollegeDataAndEquipmentNames(); // NEW: Load college data and equipment names
    });
  }

  // NEW: Method to load college data and populate _equipmentNames
  Future<void> _loadCollegeDataAndEquipmentNames() async {
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    print('ManageEquipmentsScreen: Accessed CollegeProvider to load equipment names.');
    try {
      _college = collegeProvider.colleges.firstWhere((c) => c.id == widget.collegeName);
      print('ManageEquipmentsScreen: College found: ${_college!.name}, type: ${_college!.type}, seats: ${_college!.seats}');
      
      // Normalize college type and seats to match keys in requirements data
      String normalizedCollegeType = '';
      final trimmedCollegeType = _college!.type.trim().toUpperCase();
      if (trimmedCollegeType == 'DENTAL' || trimmedCollegeType == 'BDS') {
        normalizedCollegeType = 'BDS';
      } else if (trimmedCollegeType == 'MEDICAL' || trimmedCollegeType == 'MBBS') {
        normalizedCollegeType = 'MBBS';
      }

      final normalizedSeats = _college!.seats.trim();

      final Set<String> equipmentSet = {};
      if (requirements.containsKey(normalizedCollegeType)) {
        print('ManageEquipmentsScreen: requirements contains collegeType: "$normalizedCollegeType"');
        if (requirements[normalizedCollegeType]!.containsKey(normalizedSeats)) {
          print('ManageEquipmentsScreen: requirements["$normalizedCollegeType"] contains seats: "$normalizedSeats"');
          final seatData = requirements[normalizedCollegeType]![normalizedSeats]!;
          seatData.forEach((department, deptData) {
            if (deptData.containsKey('equipments')) {
              if (deptData['equipments'] is Map<String, dynamic>) {
                (deptData['equipments'] as Map<String, dynamic>).forEach((equipment, count) {
                  equipmentSet.add(equipment);
                });
              } else {
                print('ManageEquipmentsScreen: Warning: equipments for department "$department" is not a Map<String, dynamic>. Found type: ${deptData['equipments'].runtimeType}');
              }
            }
          });
        } else {
          print('ManageEquipmentsScreen: requirements["$normalizedCollegeType"] DOES NOT contain seats: "$normalizedSeats". Available seats keys: ${requirements[normalizedCollegeType]!.keys}');
        }
      } else {
        print('ManageEquipmentsScreen: requirements DOES NOT contain collegeType: "$normalizedCollegeType". Available collegeType keys: ${requirements.keys}');
      }
      setState(() {
        _equipmentNames = equipmentSet.toList();
        _equipmentNames.sort(); // Sort for consistent order
        print('ManageEquipmentsScreen: Final loaded equipment names (count: ${equipmentSet.length}): $_equipmentNames');
        if (_equipmentNames.isEmpty) {
          print('ManageEquipmentsScreen: Warning: _equipmentNames list is EMPTY. This might be why the dropdown is not visible or has no items.');
        }
      });

    } catch (e) {
      print('ManageEquipmentsScreen: College not found for name: ${widget.collegeName}. Error: $e');
      _college = null; // Ensure _college is null if not found
    }
  }

  Future<void> _fetchEquipments() async { // Changed from _fetchProducts
    await Provider.of<EquipmentProvider>(context, listen: false).fetchEquipments(); // Changed from ProductProvider and fetchProducts
    setState(() {});
  }

  @override
  void dispose() {
    _equipmentNameController.dispose();
    _equipmentTypeController.dispose();
    _equipmentGroupController.dispose();
    _deviceTypeController.dispose();
    _manufacturerController.dispose();
    _serialNoController.dispose();
    _departmentController.dispose();
    _statusController.dispose();
    _serviceStatusController.dispose();
    _warrantyController.dispose();
    _purchasedValueController.dispose();
    _employeeAssignedController.dispose();
    _verifiedByController.dispose();
    super.dispose();
  }

  void _fillFormWithEquipment(Equipment equipment) {
    _selectedEquipment = equipment.name; // Set the selected equipment for the dropdown
    _equipmentNameController.text = equipment.name;
    _equipmentTypeController.text = equipment.type;
    _equipmentGroupController.text = equipment.group;
    _deviceTypeController.text = equipment.mode;
    _manufacturerController.text = equipment.manufacturer;
    _serialNoController.text = equipment.serialNo;
    _departmentController.text = equipment.department;
    _statusController.text = equipment.status;
    _serviceStatusController.text = equipment.service;
    _warrantyController.text = equipment.warrantyUpto != null ? DateFormat('yyyy-MM-dd').format(equipment.warrantyUpto!) : '';
    _purchasedValueController.text = equipment.purchasedCost.toString();
    _purchasedDate = equipment.installationDate;
    _employeeAssignedController.text = equipment.assignedEmployeeId ?? '';
    _generatedId = equipment.id;
  }

  void _clearForm() {
    _equipmentNameController.clear();
    _equipmentTypeController.clear();
    _equipmentGroupController.clear();
    _deviceTypeController.clear();
    _manufacturerController.clear();
    _serialNoController.clear();
    _departmentController.clear();
    _statusController.clear();
    _serviceStatusController.clear();
    _warrantyController.clear();
    _purchasedValueController.clear();
    _employeeAssignedController.clear();
    _verifiedByController.clear();
    _purchasedDate = null;
    _verifiedDate = null;
    _generatedId = '';
    _selectedEquipment = null; // Clear selected equipment
  }

  Future<void> _showAddEquipmentDialog() async { // Changed from _showAddProductDialog
    // Check if employees exist (handle both null and empty)
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final employees = employeeProvider.employees.where((e) => e.collegeId == widget.collegeName).toList();
    
    if (employees == null || employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Create employees first! Equipment must be assigned to employees.'),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _clearForm();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Equipment'), // Changed from Add Product
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: _buildEquipmentForm(), // Changed from _buildProductForm
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final newEquipment = Equipment( // Changed from newProduct = Product
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                qrcode: 'temp_qr_${DateTime.now().millisecondsSinceEpoch}', // Placeholder
                name: _equipmentNameController.text.trim(),
                type: _equipmentTypeController.text.trim(),
                group: _equipmentGroupController.text.trim(),
                mode: _deviceTypeController.text.trim(),
                manufacturer: _manufacturerController.text.trim(),
                serialNo: _serialNoController.text.trim(),
                department: _departmentController.text.trim(),
                status: _statusController.text.trim(),
                service: _serviceStatusController.text.trim(),
                warrantyUpto: _warrantyController.text.isNotEmpty ? DateTime.tryParse(_warrantyController.text) : null,
                purchasedCost: double.tryParse(_purchasedValueController.text) ?? 0.0,
                installationDate: _purchasedDate ?? DateTime.now(),
                assignedEmployeeId: _employeeAssignedController.text.trim(),
                hasWarranty: _warrantyController.text.isNotEmpty,
                collegeId: widget.collegeName,
              );
              await Provider.of<EquipmentProvider>(context, listen: false).addEquipment(newEquipment); // Changed from ProductProvider and addProduct
              setState(() {});
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Equipment added successfully.')), // Changed from Product added successfully
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editEquipment(Equipment oldEquipment) async { // Changed from _editProduct(Product oldProduct)
    _fillFormWithEquipment(oldEquipment); // Changed from _fillFormWithProduct
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Equipment'), // Changed from Edit Product
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: _buildEquipmentForm(), // Changed from _buildProductForm
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final updatedEquipment = Equipment( // Changed from updatedProduct = Product
                id: oldEquipment.id,
                qrcode: oldEquipment.qrcode,
                name: _equipmentNameController.text.trim(),
                type: _equipmentTypeController.text.trim(),
                group: _equipmentGroupController.text.trim(),
                mode: _deviceTypeController.text.trim(),
                manufacturer: _manufacturerController.text.trim(),
                serialNo: _serialNoController.text.trim(),
                department: _departmentController.text.trim(),
                status: _statusController.text.trim(),
                service: _serviceStatusController.text.trim(),
                warrantyUpto: _warrantyController.text.isNotEmpty ? DateTime.tryParse(_warrantyController.text) : null,
                purchasedCost: double.tryParse(_purchasedValueController.text) ?? 0.0,
                installationDate: _purchasedDate ?? DateTime.now(),
                assignedEmployeeId: _employeeAssignedController.text.trim(),
                hasWarranty: _warrantyController.text.isNotEmpty,
                collegeId: widget.collegeName,
              );
              await Provider.of<EquipmentProvider>(context, listen: false).updateEquipment(oldEquipment.id, updatedEquipment); // Changed from ProductProvider and updateProduct
              setState(() {});
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Equipment updated successfully.')), // Changed from Product updated successfully
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEquipment(String id) async { // Changed from _deleteProduct(String id)
    await Provider.of<EquipmentProvider>(context, listen: false).deleteEquipment(id); // Changed from ProductProvider and deleteProduct
    setState(() {});
  }

  Future<void> _uploadExcel() async {
    try {
      // Show warning dialog before proceeding to file picker
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excel Upload Guidelines'),
          content: const Text(
            'Your Excel file should have the following columns for equipment data:\n\n'
            '- "equipment name" (required)\n'
            '- "department" (required)\n'
            '- "status" (required)\n'
            '- "type" (optional)\n'
            '- "manufacturer" (optional)\n'
            '- "serial no" (optional)\n'
            '\nOther columns are also optional.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        // User cancelled the operation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel upload cancelled.')),
        );
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.bytes != null) {
        Uint8List bytes = result.files.single.bytes!;
        var excel = Excel.decodeBytes(bytes);

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;

          // Assuming first row is header
          List<String> headers = sheet.rows.first.map((cell) => cell?.value?.toString().toLowerCase().trim() ?? '').toList();

          int nameIndex = headers.indexOf('equipment name');
          int departmentIndex = headers.indexOf('department');
          int statusIndex = headers.indexOf('status');

          if (nameIndex == -1 || departmentIndex == -1 || statusIndex == -1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Excel file must contain "Equipment Name", "Department", and "Status" columns.')),
            );
            return;
          }

          List<Equipment> newEquipments = [];
          for (int i = 1; i < sheet.rows.length; i++) {
            var row = sheet.rows[i];
            if (row.every((cell) => cell?.value == null)) continue; // Skip empty rows

            String name = row[nameIndex]?.value?.toString().trim() ?? '';
            String department = row[departmentIndex]?.value?.toString().trim() ?? '';
            String status = row[statusIndex]?.value?.toString().trim() ?? '';

            if (name.isEmpty || department.isEmpty || status.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Skipping row ${i + 1}: Missing required data.')),
              );
              continue;
            }

            newEquipments.add(Equipment(
              id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(), // Unique ID
              qrcode: 'temp_qr_${DateTime.now().millisecondsSinceEpoch}_$i', // Placeholder
              name: name,
              type: '', // Optional, set default or parse if available
              group: '', // Optional
              mode: '', // Optional
              manufacturer: '', // Optional
              serialNo: '', // Optional
              department: department,
              status: status,
              service: '', // Optional
              warrantyUpto: null, // Optional
              purchasedCost: 0.0, // Optional
              installationDate: DateTime.now(), // Default to now
              assignedEmployeeId: '', // Optional
              hasWarranty: false, // Optional
              collegeId: widget.collegeName,
            ));
          }

          if (newEquipments.isNotEmpty) {
            final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
            for (var equipment in newEquipments) {
              await equipmentProvider.addEquipment(equipment);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${newEquipments.length} equipments added successfully!')),
            );
            _fetchEquipments(); // Refresh the list
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No valid equipments found in the Excel file.')),
            );
          }
          break; // Process only the first sheet
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File picking cancelled or no file selected.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading Excel: $e')),
        );
      }
    }
  }

  Widget _buildEquipmentForm() { // Changed from _buildProductForm
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedEquipment,
            decoration: const InputDecoration(labelText: 'Equipment Name*'),
            hint: const Text('Select Equipment'),
            items: _equipmentNames.map((String equipmentName) {
              return DropdownMenuItem<String>(
                value: equipmentName,
                child: Text(equipmentName),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedEquipment = newValue;
                // When an equipment is selected, also update the text controller
                _equipmentNameController.text = newValue ?? ''; 
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an equipment name.';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _equipmentTypeController,
            decoration: const InputDecoration(labelText: 'Equipment Type'),
          ),
          TextFormField(
            controller: _equipmentGroupController,
            decoration: const InputDecoration(labelText: 'Equipment Group'),
          ),
          TextFormField(
            controller: _deviceTypeController,
            decoration: const InputDecoration(labelText: 'Device Type'),
          ),
          TextFormField(
            controller: _manufacturerController,
            decoration: const InputDecoration(labelText: 'Manufacturer'),
          ),
          TextFormField(
            controller: _serialNoController,
            decoration: const InputDecoration(labelText: 'Serial No'),
          ),
          TextFormField(
            controller: _departmentController,
            decoration: const InputDecoration(labelText: 'Department'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _statusController.text.isNotEmpty ? _statusController.text : null,
            decoration: const InputDecoration(labelText: 'Status*'),
            hint: const Text('Select Status'),
            items: ['Working', 'Not Working', 'Under Maintenance', 'Standby']
                .map((String status) {
              return DropdownMenuItem<String>(value: status, child: Text(status));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() => _statusController.text = newValue ?? '');
            },
            validator: (value) => (value == null || value.isEmpty) ? 'Please select a status.' : null,
          ),
          TextFormField(
            controller: _serviceStatusController,
            decoration: const InputDecoration(labelText: 'Service Status'),
          ),
          TextFormField(
            controller: _warrantyController,
            decoration: const InputDecoration(labelText: 'Warranty (YYYY-MM-DD)'),
          ),
          TextFormField(
            controller: _purchasedValueController,
            decoration: const InputDecoration(labelText: 'Purchased Value'),
            keyboardType: TextInputType.number,
          ),
          ListTile(
            title: Text(_purchasedDate == null ? 'Purchased Date' : 'Purchased: ${DateFormat('yyyy-MM-dd').format(_purchasedDate!)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _purchasedDate = date);
            },
          ),
          TextFormField(
            controller: _employeeAssignedController,
            decoration: const InputDecoration(labelText: 'Employee Assigned'),
          ),
          ListTile(
            title: Text(_verifiedDate == null ? 'Verified Date' : 'Verified: ${DateFormat('yyyy-MM-dd').format(_verifiedDate!)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _verifiedDate = date);
            },
          ),
          TextFormField(
            controller: _verifiedByController,
            decoration: const InputDecoration(labelText: 'Verified By'),
          ),
          const SizedBox(height: 16),
          if (_generatedId.isNotEmpty) ...[
            Text(
              'Generated ID: $_generatedId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: _generatedId,
                version: QrVersions.auto,
                size: 100,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Function to delete all equipments for the college
  Future<void> _deleteAllEquipments() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Equipments'),
        content: Text('Are you sure you want to delete ALL equipments for ${widget.collegeName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
        // This method will need to be implemented in equipment_provider.dart
        await equipmentProvider.deleteAllEquipmentsForCollege(widget.collegeName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All equipments for ${widget.collegeName} deleted successfully!')),
        );
        _fetchEquipments(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting all equipments: $e')),
        );
      }
    }
  }

  // NEW: Function to export equipments to Excel
  Future<void> _exportEquipmentsToExcel() async {
    try {
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      final equipmentsToExport = equipmentProvider.equipments
          .where((e) => e.collegeId == widget.collegeName)
          .toList();

      if (equipmentsToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No equipments to export.')),
        );
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Equipments'];

      // Add headers
      List<String> headers = [
        'ID', 'Name', 'Type', 'Group', 'Mode', 'Manufacturer', 'Serial No',
        'Department', 'Status', 'Service Status', 'Warranty Upto',
        'Purchased Cost', 'Installation Date', 'Assigned Employee ID',
        'Has Warranty', 'College ID',
      ];
      sheetObject.insertRowIterables(headers.map((e) => TextCellValue(e)).toList(), 0);

      // Add data rows
      for (int i = 0; i < equipmentsToExport.length; i++) {
        final equipment = equipmentsToExport[i];
        List<CellValue?> rowData = [
          TextCellValue(equipment.id),
          TextCellValue(equipment.name),
          TextCellValue(equipment.type),
          TextCellValue(equipment.group),
          TextCellValue(equipment.mode),
          TextCellValue(equipment.manufacturer),
          TextCellValue(equipment.serialNo),
          TextCellValue(equipment.department),
          TextCellValue(equipment.status),
          TextCellValue(equipment.service),
          TextCellValue(equipment.warrantyUpto != null ? DateFormat('yyyy-MM-dd').format(equipment.warrantyUpto!) : ''),
          DoubleCellValue(equipment.purchasedCost), // Assuming purchasedCost is double
          TextCellValue(DateFormat('yyyy-MM-dd').format(equipment.installationDate)),
          TextCellValue(equipment.assignedEmployeeId ?? ''),
          BoolCellValue(equipment.hasWarranty), // Assuming hasWarranty is bool
          TextCellValue(equipment.collegeId),
        ];
        sheetObject.insertRowIterables(rowData, i + 1);
      }

      List<int>? excelBytes = excel.encode();
      if (excelBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to encode Excel file.')),
        );
        return;
      }

      if (kIsWeb) {
        // For web, FilePicker.platform.saveFile directly triggers a download.
        // It's designed to take bytes parameter on web.
        final fileName = 'equipments_${widget.collegeName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        final savedFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Equipments Excel File',
          fileName: fileName,
          bytes: Uint8List.fromList(excelBytes), // Provide bytes for web download
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        
        if (savedFile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Equipments exported to $fileName successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel export cancelled or failed.')),
          );
        }
      } else {
        // For non-web platforms (mobile/desktop)
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Equipments Excel File',
          fileName: 'equipments_${widget.collegeName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile != null) {
          final file = io.File(outputFile);
          await file.writeAsBytes(excelBytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Equipments exported to $outputFile successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel export cancelled or failed.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting Excel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipments = Provider.of<EquipmentProvider>(context).equipments
        .where((p) => p.collegeId == widget.collegeName).toList();
    
    for (var p in equipments) {
      if (!_stickerKeys.containsKey(p.id)) {
        _stickerKeys[p.id] = GlobalKey();
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Equipments'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload Equipments from Excel',
            onPressed: _uploadExcel,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Equipments to Excel',
            onPressed: _exportEquipmentsToExcel,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Delete All Equipments',
            onPressed: _deleteAllEquipments,
          ),
        ],
      ),
      body: Stack(
        children: [
          ManagementListWidget(
            items: equipments.map((e) => ManagementListItem(
              id: e.id,
              title: e.name,
              subtitle: '${e.serialNo} • ${e.department}',
              icon: Icons.devices_other,
              iconColor: const Color(0xFF2563EB),
              badge: e.status,
              badgeColor: e.status == 'Working' ? Colors.green : (e.status == 'Under Maintenance' ? Colors.orange : Colors.red),
              actions: [
                ManagementAction(
                  label: 'View',
                  icon: Icons.remove_red_eye,
                  color: const Color(0xFF2563EB),
                  onPressed: () => _showEquipmentDetails(e),
                ),
                ManagementAction(
                  label: 'Download',
                  icon: Icons.download,
                  color: const Color(0xFF059669),
                  onPressed: () => _exportStickerAsPng(e),
                ),
                ManagementAction(
                  label: 'Edit',
                  icon: Icons.edit,
                  color: const Color(0xFF16A34A),
                  onPressed: () async => await _editEquipment(e),
                ),
                ManagementAction(
                  label: 'Delete',
                  icon: Icons.delete,
                  color: const Color(0xFFDC2626),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Equipment'),
                        content: const Text('Are you sure you want to delete this equipment?'),
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
                      await _deleteEquipment(e.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Equipment deleted.')),
                      );
                    }
                  },
                ),
              ],
            )).toList(),
            emptyMessage: 'No equipments found. Add one to get started!',
          ),
          ...equipments.map((p) {
            // Ensure the key exists
            if (!_stickerKeys.containsKey(p.id)) {
              debugPrint('🔑 [STICKER] Creating new GlobalKey for equipment: ${p.id}');
              _stickerKeys[p.id] = GlobalKey();
            }
            debugPrint('📌 [STICKER] Using key for equipment: ${p.id}');
            return Positioned(
              top: -9999,
              left: -9999,
              child: RepaintBoundary(
                key: _stickerKeys[p.id],
                child: _buildStickerWidget(p),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEquipmentDialog,
        tooltip: 'Add Equipment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEquipmentDetails(Equipment p) {
    showDialog(
      context: context,
      builder: (ctx) => ModernDetailsDialog(
        title: 'Equipment Details',
        details: [
          DetailRow(label: 'ID', value: p.id),
          DetailRow(label: 'Name', value: p.name),
          DetailRow(label: 'Type', value: p.type),
          DetailRow(label: 'Group', value: p.group),
          DetailRow(label: 'Mode', value: p.mode),
          DetailRow(label: 'Manufacturer', value: p.manufacturer),
          DetailRow(label: 'Serial Number', value: p.serialNo),
          DetailRow(label: 'Department', value: p.department),
          DetailRow(label: 'Status', value: p.status),
          DetailRow(label: 'Service Status', value: p.service),
          DetailRow(
            label: 'Warranty Upto',
            value: p.warrantyUpto != null ? DateFormat('yyyy-MM-dd').format(p.warrantyUpto!) : '-',
          ),
          DetailRow(label: 'Purchased Cost', value: '₹${p.purchasedCost.toString()}'),
          DetailRow(
            label: 'Installation Date',
            value: DateFormat('yyyy-MM-dd').format(p.installationDate),
          ),
          DetailRow(label: 'Employee Assigned', value: p.assignedEmployeeId ?? '-'),
          DetailRow(label: 'College', value: p.collegeId),
        ],
        qrCodeWidget: QrImageView(
          data: p.id,
          version: QrVersions.auto,
          size: 150,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }


  Widget _buildStickerWidget(Equipment p) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'QRmed',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1976D2),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.collegeName,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            p.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${p.id}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: QrImageView(
              data: p.id,
              version: QrVersions.auto,
              size: 120,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan with QRmed app',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const Text(
            'for equipment details',
            style: TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

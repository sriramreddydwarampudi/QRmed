import 'package:flutter/material.dart';
import 'package:supreme_institution/screens/qr_scanner_screen.dart';

class FindEquipmentWidget extends StatefulWidget {
  const FindEquipmentWidget({super.key});

  @override
  State<FindEquipmentWidget> createState() => _FindEquipmentWidgetState();
}

class _FindEquipmentWidgetState extends State<FindEquipmentWidget> {
  String? _foundEquipmentId;

  Future<void> _scanQrCode() async {
    final scannedCode = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
    if (scannedCode != null && scannedCode is String) {
      setState(() {
        _foundEquipmentId = scannedCode;
      });
      _viewEquipmentDetails(scannedCode);
    }
  }

  Future<void> _manualIdEntry() async {
    String? enteredId = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        TextEditingController idController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Equipment ID'),
          content: TextField(
            controller: idController,
            decoration: const InputDecoration(hintText: 'Equipment ID'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Find'),
              onPressed: () {
                Navigator.of(dialogContext).pop(idController.text);
              },
            ),
          ],
        );
      },
    );

    if (enteredId != null && enteredId.isNotEmpty) {
      setState(() {
        _foundEquipmentId = enteredId;
      });
      _viewEquipmentDetails(enteredId);
    }
  }

  void _viewEquipmentDetails(String equipmentId) {
    // Placeholder for navigating to or displaying equipment details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for Equipment ID: $equipmentId')),
    );
    // In a real application, you would navigate to a detailed screen:
    // Navigator.of(context).push(MaterialPageRoute(builder: (context) => EquipmentDetailScreen(equipmentId: equipmentId)));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Code'),
            onPressed: _scanQrCode,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.input),
            label: const Text('Enter ID Manually'),
            onPressed: _manualIdEntry,
          ),
          if (_foundEquipmentId != null) ...[
            const SizedBox(height: 24),
            Text(
              'Last Found Equipment: $_foundEquipmentId',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ],
      ),
    );
  }
}
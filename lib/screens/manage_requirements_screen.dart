import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/requirements_provider.dart';

class ManageRequirementsScreen extends StatefulWidget {
  const ManageRequirementsScreen({super.key});

  @override
  _ManageRequirementsScreenState createState() =>
      _ManageRequirementsScreenState();
}

class _ManageRequirementsScreenState extends State<ManageRequirementsScreen> {
  late Map<String, Map<String, Map<String, Map<String, dynamic>>>>
      _requirements;

  @override
  void initState() {
    super.initState();
    _requirements =
        Provider.of<RequirementsProvider>(context, listen: false).requirements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Requirements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Provider.of<RequirementsProvider>(context, listen: false)
                  .updateRequirements(_requirements);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _requirements.length,
        itemBuilder: (context, courseIndex) {
          String courseName = _requirements.keys.elementAt(courseIndex);
          Map<String, Map<String, Map<String, dynamic>>> courseData =
              _requirements[courseName]!;

          return ExpansionTile(
            title: Text(courseName),
            children: courseData.keys.map((capacity) {
              Map<String, Map<String, dynamic>> capacityData =
                  courseData[capacity]!;

              return ExpansionTile(
                title: Text('Capacity: $capacity'),
                children: capacityData.keys.map((department) {
                  Map<String, dynamic> departmentData =
                      capacityData[department]!;

                  return ExpansionTile(
                    title: Text(department),
                    children: [
                      _buildItemList(
                        'Equipments',
                        Map<String, dynamic>.from(departmentData['equipments']),
                      ),
                      _buildItemList(
                        'Employees',
                        Map<String, dynamic>.from(departmentData['employees']),
                      ),
                    ],
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildItemList(String title, Map<String, dynamic> items) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          ...items.keys.map((item) {
            return Row(
              children: [
                Expanded(child: Text(item)),
                SizedBox(
                  width: 50,
                  child: TextFormField(
                    initialValue: items[item].toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        items[item] = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
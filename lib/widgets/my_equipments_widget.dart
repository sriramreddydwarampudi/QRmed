import 'package:flutter/material.dart';
import 'package:supreme_institution/screens/my_equipments_screen.dart';

class MyEquipmentsWidget extends StatelessWidget {
  final String employeeName;
  final String collegeName;

  const MyEquipmentsWidget({super.key, required this.employeeName, required this.collegeName});

  @override
  Widget build(BuildContext context) {
    // This widget now acts as a wrapper that directly presents the MyEquipmentsScreen logic.
    return MyEquipmentsScreen(employeeName: employeeName, collegeName: collegeName);
  }
}
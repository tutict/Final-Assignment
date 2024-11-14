import 'dart:convert';
import 'dart:developer' as develop;

import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListPage();
}

class _VehicleListPage extends State<VehicleList> {
  List<dynamic> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    try {
      final response = await http.get(Uri.parse(
          '${AppConfig.baseUrl}${AppConfig.vehicleInformationEndpoint}'));
      if (response.statusCode == 200) {
        setState(() {
          _vehicles = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      // Handle error here
      develop.log('Error: $e');
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      final response = await http.delete(Uri.parse(
          '${AppConfig.baseUrl}${AppConfig
              .vehicleInformationEndpoint}/$vehicleId'));
      if (response.statusCode == 204) {
        setState(() {
          _vehicles.removeWhere((vehicle) => vehicle['vehicleId'] == vehicleId);
        });
      } else {
        throw Exception('Failed to delete vehicle');
      }
    } catch (e) {
      // Handle error here
      develop.log('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆信息列表'),
      ),
      body: ListView.builder(
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return ListTile(
            title:
            Text('${vehicle['licensePlate']} - ${vehicle['vehicleType']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _deleteVehicle(vehicle['vehicleId']);
              },
            ),
          );
        },
      ),
    );
  }
}

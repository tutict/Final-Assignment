import 'package:final_assignment_front/features/model/elastic/vehicle_information_document.dart';

class VehiclePagedResponse {
  final List<VehicleInformationDocument> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  VehiclePagedResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory VehiclePagedResponse.fromJson(Map<String, dynamic> json) {
    return VehiclePagedResponse(
      content: (json['content'] as List)
          .map((item) => VehicleInformationDocument.fromJson(item))
          .toList(),
      page: json['page'],
      size: json['size'],
      totalElements: json['totalElements'],
      totalPages: json['totalPages'],
    );
  }
}
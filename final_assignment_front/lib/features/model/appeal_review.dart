class AppealReviewModel {
  final int? reviewId;
  final int? appealId;
  final String? reviewLevel;
  final DateTime? reviewTime;
  final String? reviewer;
  final String? reviewerDept;
  final String? reviewResult;
  final String? reviewOpinion;
  final String? suggestedAction;
  final double? suggestedFineAmount;
  final int? suggestedPoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppealReviewModel({
    this.reviewId,
    this.appealId,
    this.reviewLevel,
    this.reviewTime,
    this.reviewer,
    this.reviewerDept,
    this.reviewResult,
    this.reviewOpinion,
    this.suggestedAction,
    this.suggestedFineAmount,
    this.suggestedPoints,
    this.createdAt,
    this.updatedAt,
  });

  factory AppealReviewModel.fromJson(Map<String, dynamic> json) {
    return AppealReviewModel(
      reviewId: json['reviewId'],
      appealId: json['appealId'],
      reviewLevel: json['reviewLevel'],
      reviewTime:
          json['reviewTime'] != null ? DateTime.tryParse(json['reviewTime']) : null,
      reviewer: json['reviewer'],
      reviewerDept: json['reviewerDept'],
      reviewResult: json['reviewResult'],
      reviewOpinion: json['reviewOpinion'],
      suggestedAction: json['suggestedAction'],
      suggestedFineAmount: (json['suggestedFineAmount'] as num?)?.toDouble(),
      suggestedPoints: json['suggestedPoints'],
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'reviewId': reviewId,
        'appealId': appealId,
        'reviewLevel': reviewLevel,
        'reviewTime': reviewTime?.toIso8601String(),
        'reviewer': reviewer,
        'reviewerDept': reviewerDept,
        'reviewResult': reviewResult,
        'reviewOpinion': reviewOpinion,
        'suggestedAction': suggestedAction,
        'suggestedFineAmount': suggestedFineAmount,
        'suggestedPoints': suggestedPoints,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

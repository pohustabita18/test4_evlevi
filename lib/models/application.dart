class CampaignApplication {
  final String id;
  final String campaignId;
  final String creatorId;
  final String message;
  final String status;
  final DateTime createdAt;

  CampaignApplication({
    required this.id,
    required this.campaignId,
    required this.creatorId,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory CampaignApplication.fromMap(Map<String, dynamic> data, String id) {
    return CampaignApplication(
      id: id,
      campaignId: data['campaignId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] != null)
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'creatorId': creatorId,
      'message': message,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

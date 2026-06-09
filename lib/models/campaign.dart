class Campaign {
  final String id;
  final String brandId;
  final String title;
  final String description;
  final double budget;
  final String criteria;
  final String deadline;
  final String status; // 'active', 'closed'

  Campaign({
    required this.id,
    required this.brandId,
    required this.title,
    required this.description,
    required this.budget,
    required this.criteria,
    required this.deadline,
    required this.status,
  });

  factory Campaign.fromMap(Map<String, dynamic> data, String id) {
    return Campaign(
      id: id,
      brandId: data['brandId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      criteria: data['criteria'] ?? '',
      deadline: data['deadline'] ?? '',
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brandId': brandId,
      'title': title,
      'description': description,
      'budget': budget,
      'criteria': criteria,
      'deadline': deadline,
      'status': status,
    };
  }
}

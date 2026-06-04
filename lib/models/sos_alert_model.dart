class SOSAlertModel {
  final String alertId;
  final String user;
  final String userName;
  final String phone;
  final String status;
  final double latitude;
  final double longitude;
  final String nearestLight;
  final double distance;
  final String timestamp;

  SOSAlertModel({
    required this.alertId,
    required this.user,
    required this.userName,
    required this.phone,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.nearestLight = 'NONE',
    this.distance = 0.0,
    required this.timestamp,
  });

  factory SOSAlertModel.fromJson(Map<dynamic, dynamic> json) {
    return SOSAlertModel(
      alertId: json['alertId'] as String? ?? '',
      user: json['user'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'INACTIVE',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      nearestLight: json['nearestLight'] as String? ?? 'NONE',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'user': user,
      'userName': userName,
      'phone': phone,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'nearestLight': nearestLight,
      'distance': distance,
      'timestamp': timestamp,
    };
  }

  Map<String, dynamic> toHistoryJson() {
    return {
      'alertId': alertId,
      'user': user,
      'userName': userName,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'status': status,
    };
  }
}

class Records {
  final String recordId;
  final String componentId;
  final String name;
  final double score;
  final double total;

  Records({
    required this.name,
    required this.score,
    required this.total,
    required this.recordId,
    required this.componentId,
  });

  factory Records.fromMap(Map<String, dynamic> map) => Records(
        recordId: map['recordId'] ?? '',
        componentId: map['componentId'] ?? '',
        name: map['name'] ?? '',
        score: (map['score'] is int)
            ? (map['score'] as int).toDouble()
            : (map['score'] ?? 0.0),
        total: (map['total'] is int)
            ? (map['total'] as int).toDouble()
            : (map['total'] ?? 0.0),
      );

  Map<String, dynamic> toMap() => {
        'recordId': recordId,
        'componentId': componentId,
        'name': name,
        'score': score,
        'total': total,
      };
}
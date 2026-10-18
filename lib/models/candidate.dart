class Candidate {
  final int id;
  final int orderNo;
  final String examId;
  final String maskedId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String position;
  final String region;
  final String jobField;
  final String province;
  final String score;
  final String status;
  final String agency;

  const Candidate({
    required this.id,
    required this.orderNo,
    required this.examId,
    required this.maskedId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.position,
    required this.region,
    required this.jobField,
    required this.province,
    required this.score,
    required this.status,
    required this.agency,
  });

  factory Candidate.fromMap(Map<String, dynamic> map) {
    return Candidate(
      id: (map['id'] as num?)?.toInt() ?? 0,
      orderNo: (map['order_no'] as num?)?.toInt() ?? 0,
      examId: map['exam_id']?.toString() ?? '-',
      maskedId: map['masked_id']?.toString() ?? '-',
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '-',
      position: map['position']?.toString() ?? '-',
      region: map['region']?.toString() ?? '-',
      jobField: map['job_field']?.toString() ?? '-',
      province: map['province']?.toString() ?? '-',
      score: map['score']?.toString() ?? '-',
      status: map['status']?.toString() ?? '-',
      agency: map['agency']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'order_no': orderNo,
        'exam_id': examId,
        'masked_id': maskedId,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'position': position,
        'region': region,
        'job_field': jobField,
        'province': province,
        'score': score,
        'status': status,
        'agency': agency,
      };

  String get scoreDisplay {
    if (score.isEmpty || score == '-' || score == 'null') return '-';
    return score;
  }

}

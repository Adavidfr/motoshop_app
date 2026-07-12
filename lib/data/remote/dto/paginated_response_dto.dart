class PaginatedResponseDto<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponseDto({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawResults = json['results'] as List<dynamic>? ?? <dynamic>[];

    return PaginatedResponseDto<T>(
      count: int.tryParse(
            json['count']?.toString() ?? '',
          ) ??
          0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults.map<T>(
        (dynamic item) {
          final itemJson = Map<String, dynamic>.from(
            item as Map,
          );

          return fromJsonT(itemJson);
        },
      ).toList(),
    );
  }
}
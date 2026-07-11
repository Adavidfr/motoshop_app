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
    final rawResults = json['results'] as List<dynamic>? ?? [];

    return PaginatedResponseDto<T>(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: rawResults
          .map(
            (item) => fromJsonT(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
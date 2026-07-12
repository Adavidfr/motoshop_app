class PaginatedResult<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResult({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  bool get hasNextPage => next != null;

  bool get hasPreviousPage => previous != null;
}
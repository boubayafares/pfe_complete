class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNextPage => page < totalPages;
  int? get nextPage => hasNextPage ? page + 1 : null;
}

class Paginated<T> {
  const Paginated({required this.items, this.meta});
  final List<T> items;
  final PaginationMeta? meta;

  bool get hasNextPage => meta?.hasNextPage ?? false;
}

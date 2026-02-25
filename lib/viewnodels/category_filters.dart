class CategoryFilterGroup {
  final String name;
  final List<String> options;

  CategoryFilterGroup({required this.name, required this.options});

  factory CategoryFilterGroup.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    final rawList = json['list'];
    final options = (rawList is List)
        ? rawList.map((e) => (e ?? '').toString()).toList(growable: false)
        : const <String>[];
    return CategoryFilterGroup(name: name, options: options);
  }
}

class CategoryType {
  final int id;
  final String name;
  final List<CategoryFilterGroup> filterGroups;

  CategoryType({
    required this.id,
    required this.name,
    required this.filterGroups,
  });

  factory CategoryType.fromJson(Map<String, dynamic> json) {
    final idRaw = json['type_id'];
    final id = idRaw is int ? idRaw : int.tryParse((idRaw ?? '').toString()) ?? 0;
    final name = (json['type_name'] ?? '').toString();
    final rawFilters = json['filter_type_list'];
    final filters = (rawFilters is List)
        ? rawFilters
            .whereType<Map>()
            .map((e) => CategoryFilterGroup.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <CategoryFilterGroup>[];
    return CategoryType(id: id, name: name, filterGroups: filters);
  }
}


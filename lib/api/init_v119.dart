import 'package:app/contants/index.dart';
import 'package:app/utils/DioRequest.dart';
import 'package:app/viewnodels/category_filters.dart';

Future<List<CategoryType>> getInitV119CategoryTypesAPI() async {
  final decoded = await diorequest.get(
    '${HttpConstants.Prefix}.index/${HttpConstants.BANNER_LIST}',
  );
  final raw = decoded['type_list'];
  if (raw is! List) return const <CategoryType>[];
  return raw
      .whereType<Map>()
      .map((e) => CategoryType.fromJson(e.cast<String, dynamic>()))
      .where((e) => e.id != 0 && e.name.isNotEmpty)
      .toList(growable: false);
}


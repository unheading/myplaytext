import 'package:app/contants/index.dart';
import 'package:app/utils/DioRequest.dart';
import 'package:app/viewnodels/category.dart';

Future<List<CategoryVod>> getCategoryListAPI({
  required int typeId,
  required int page,
  String? className,
  String? area,
  String? lang,
  String? year,
  String? sort,
}) async {
  Map<String, dynamic> params = {
    'type_id': typeId,
    'page': page,
  };
  void putIfValid(String key, String? value) {
    if (value == null) return;
    final v = value.trim();
    if (v.isEmpty || v == '全部') return;
    params[key] = v;
  }

  putIfValid('class', className);
  putIfValid('area', area);
  putIfValid('lang', lang);
  putIfValid('year', year);
  putIfValid('sort', sort);

  final decoded = await diorequest.get(
    '${HttpConstants.Prefix}.index/${HttpConstants.CATEGORY_LIST}',
    params: params,
  );
  final raw = decoded['recommend_list'] ?? decoded['vod_list'] ?? decoded['list'];
  if (raw is! List) return <CategoryVod>[];
  return raw
      .whereType<Map>()
      .map((e) => CategoryVod.fromJson(e.cast<String, dynamic>()))
      .toList(growable: false);
}

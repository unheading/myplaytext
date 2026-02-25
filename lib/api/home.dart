import 'package:app/contants/index.dart';
import 'package:app/utils/DioRequest.dart';
import 'package:app/viewnodels/home.dart';

Future <List<BannerItem>> getBannerListAPI()async{
  final decoded = await diorequest.get(
    '${HttpConstants.Prefix}.index/${HttpConstants.BANNER_LIST}',
    requireBannerListNotEmpty: true,
  );
  final raw = decoded['banner_list'];
  if (raw is! List) {
    return <BannerItem>[];
  }
  return raw
      .whereType<Map>()
      .map((item) => BannerItem.formJSON(item.cast<String, dynamic>()))
      .where((e) => e.id.isNotEmpty && e.imgUrl.isNotEmpty)
      .toList(growable: false);
}

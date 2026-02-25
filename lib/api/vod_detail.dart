import 'package:app/contants/index.dart';
import 'package:app/utils/DioRequest.dart';
import 'package:app/viewnodels/vod_detail.dart';

Future<VodDetailData> getVodDetailAPI({required int vodId}) async {
  final decoded = await diorequest.get(
    '${HttpConstants.Prefix}.index/${HttpConstants.VOD_DETAIL}',
    params: {'vod_id': vodId},
  );
  return VodDetailData.fromJson(decoded);
}


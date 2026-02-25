import 'package:app/contants/index.dart';
import 'package:app/utils/DioRequest.dart';

Future<Map<String, dynamic>> getDanmuListAPI({
  required int vodId,
  required int urlPosition,
}) {
  return diorequest.get(
    '${HttpConstants.Prefix}.index/${HttpConstants.DANMU_LIST}',
    params: {
      'vod_id': vodId,
      'url_position': urlPosition,
    },
  );
}


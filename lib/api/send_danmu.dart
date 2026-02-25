import 'package:app/contants/index.dart';
import 'package:app/utils/DioRequest.dart';

Future<Map<String, dynamic>> sendDanmuAPI({
  required int vodId,
  required int urlPosition,
  required String danmu,
  required String color,
  required String time,
  int position = 0,
}) {
  return diorequest.get(
    '${HttpConstants.Prefix}.index/sendDanmu',
    params: {
      'vod_id': vodId,
      'url_position': urlPosition,
      'danmu': danmu,
      'color': color,
      'time': time,
      'position': position,
    },
  );
}


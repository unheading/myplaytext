import 'package:app/contants/index.dart';
import 'package:app/utils/DioRequest.dart';

Future<Map<String, dynamic>> getCommentListAPI({
  required int vodId,
  required int page,
}) {
  return diorequest.get(
    '${HttpConstants.Prefix}.index/${HttpConstants.COMMENT_LIST}',
    params: {
      'vod_id': vodId,
      'page': page,
    },
  );
}


import 'dart:convert';

import 'package:app/api/vod_parse.dart';
import 'package:dio/dio.dart';

Future<VodParsedResult?> bfqParseAPI({required String pageUrl}) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  final res = await dio.get(
    'https://bfq.123344.xyz/index.php',
    queryParameters: {'url': pageUrl},
    options: Options(
      responseType: ResponseType.plain,
      headers: const {
        'Accept': 'application/json, text/plain, */*',
      },
      validateStatus: (_) => true,
    ),
  );

  if (res.statusCode != null && res.statusCode! >= 400) {
    return null;
  }

  final body = (res.data ?? '').toString().trim();
  if (body.isEmpty) return null;

  dynamic decoded;
  try {
    decoded = jsonDecode(body);
  } catch (_) {
    return null;
  }

  if (decoded is! Map) return null;
  final map = decoded.cast<String, dynamic>();
  final code = map['code'];
  final ok = code == 200 || code == '200';
  if (!ok) return null;

  final url = (map['url'] ?? '').toString().trim();
  if (url.isEmpty) return null;

  final uri = Uri.tryParse(url);
  final origin = (uri != null && uri.hasScheme && uri.host.isNotEmpty)
      ? '${uri.scheme}://${uri.host}/'
      : null;

  return VodParsedResult(
    url: url,
    headers: origin == null
        ? const {}
        : {
            'Referer': origin,
            'Origin': origin.substring(0, origin.length - 1),
          },
  );
}


import 'dart:convert';

import 'package:app/contants/index.dart';
import 'package:app/getapp/getapp_client.dart';
import 'package:app/utils/DioRequest.dart';

class VodParsedResult {
  final String url;
  final Map<String, String> headers;

  const VodParsedResult({required this.url, required this.headers});
}

Future<VodParsedResult?> vodParseAPI({
  required String url,
  required String parseApi,
  String? token,
}) async {
  final encryptedUrl = GetappCrypto(HttpConstants.apiSecretKey).encryptTextToBase64(url);
  final params = <String, dynamic>{
    'url': encryptedUrl,
    'parse_api': parseApi,
  };
  if (token != null && token.trim().isNotEmpty) {
    params['token'] = token.trim();
  }
  final decoded = await diorequest.get(
    '${HttpConstants.Prefix}.index/${HttpConstants.VOD_PARSE}',
    params: params,
  );

  final rawJson = (decoded['json'] ?? '').toString().trim();
  if (rawJson.isEmpty) return null;

  Map<String, String> _mergeHeaders(
    Map<String, String> a,
    Map<String, String> b,
  ) {
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    final merged = <String, String>{...a};
    merged.addAll(b);
    return merged;
  }

  Map<String, String> _parseHeaders(dynamic h) {
    if (h == null) return const <String, String>{};
    if (h is Map) {
      return h.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
    }
    if (h is String) {
      final s = h.trim();
      if (s.isEmpty) return const <String, String>{};
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
        }
      } catch (_) {}

      final lines = s.split(RegExp(r'[\r\n]+'));
      final out = <String, String>{};
      for (final line in lines) {
        final l = line.trim();
        if (l.isEmpty) continue;
        final sep = l.contains(':') ? ':' : (l.contains('=') ? '=' : null);
        if (sep == null) continue;
        final idx = l.indexOf(sep);
        if (idx <= 0) continue;
        final k = l.substring(0, idx).trim();
        final v = l.substring(idx + 1).trim();
        if (k.isEmpty || v.isEmpty) continue;
        out[k] = v;
      }
      return out;
    }
    return const <String, String>{};
  }

  VodParsedResult? findResult(dynamic node) {
    if (node is String) {
      final s = node.trim();
      if (s.startsWith('http://') || s.startsWith('https://')) {
        return VodParsedResult(url: s, headers: const {});
      }
      return null;
    }
    if (node is Map) {
      final header = _mergeHeaders(
        _parseHeaders(node['header'] ?? node['headers']),
        _parseHeaders(node['Header'] ?? node['Headers']),
      );
      final header2 = _mergeHeaders(
        header,
        <String, String>{
          if ((node['referer'] ?? node['referrer']) != null)
            'Referer': (node['referer'] ?? node['referrer']).toString(),
          if ((node['user-agent'] ?? node['user_agent'] ?? node['ua']) != null)
            'User-Agent': (node['user-agent'] ?? node['user_agent'] ?? node['ua']).toString(),
          if (node['origin'] != null) 'Origin': node['origin'].toString(),
          if (node['cookie'] != null) 'Cookie': node['cookie'].toString(),
        },
      );
      for (final key in const ['url', 'play_url', 'playUrl', 'm3u8', 'mp4', 'link']) {
        final v = node[key];
        final got = findResult(v);
        if (got != null) {
          final mergedHeaders = _mergeHeaders(header2, got.headers);
          return VodParsedResult(url: got.url, headers: mergedHeaders);
        }
      }

      for (final v in node.values) {
        final got = findResult(v);
        if (got != null) {
          final mergedHeaders = _mergeHeaders(header2, got.headers);
          return VodParsedResult(url: got.url, headers: mergedHeaders);
        }
      }
    }
    if (node is List) {
      for (final v in node) {
        final got = findResult(v);
        if (got != null) return got;
      }
    }
    return null;
  }

  if (rawJson.startsWith('http://') || rawJson.startsWith('https://')) {
    final uri = Uri.tryParse(rawJson);
    final origin = (uri != null && uri.hasScheme && uri.host.isNotEmpty)
        ? '${uri.scheme}://${uri.host}/'
        : null;
    return VodParsedResult(
      url: rawJson,
      headers: origin == null
          ? const {}
          : {
              'Referer': origin,
              'Origin': origin.substring(0, origin.length - 1),
            },
    );
  }

  try {
    final decodedJson = jsonDecode(rawJson);
    final got = findResult(decodedJson);
    if (got == null) return null;
    final uri = Uri.tryParse(got.url);
    final origin = (uri != null && uri.hasScheme && uri.host.isNotEmpty)
        ? '${uri.scheme}://${uri.host}/'
        : null;
    if (origin == null) return got;
    if (got.headers.containsKey('Referer') || got.headers.containsKey('referer')) {
      return got;
    }
    return VodParsedResult(
      url: got.url,
      headers: {
        ...got.headers,
        'Referer': origin,
        if (!got.headers.containsKey('Origin') && !got.headers.containsKey('origin'))
          'Origin': origin.substring(0, origin.length - 1),
      },
    );
  } catch (_) {
    return null;
  }
}

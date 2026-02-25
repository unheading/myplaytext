import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class GetappApiException implements Exception {
  final String message;

  GetappApiException(this.message);

  @override
  String toString() => 'GetappApiException: $message';
}

class GetappCrypto {
  final String secretKey;
  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  GetappCrypto(this.secretKey) {
    if (secretKey.length != 16) {
      throw ArgumentError.value(secretKey, 'secretKey', '必须是 16 位字符串');
    }
    _key = encrypt.Key.fromUtf8(secretKey);
    _iv = encrypt.IV.fromUtf8(secretKey);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
  }

  String encryptTextToBase64(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  String decryptBase64ToText(String base64CipherText) {
    return _encrypter.decrypt64(base64CipherText, iv: _iv);
  }
}

class GetappBanner {
  final String id;
  final String imgUrl;

  GetappBanner({required this.id, required this.imgUrl});

  factory GetappBanner.fromJson(Map<String, dynamic> json) {
    final vodId = json['vod_id'];
    final vodPic = json['vod_pic'];
    final vodPicSlide = json['vod_pic_slide'];
    final pic = _cleanUrl(vodPic);
    final slide = _cleanUrl(vodPicSlide);
    return GetappBanner(
      id: vodId == null ? '' : '$vodId',
      imgUrl: pic.isNotEmpty ? pic : slide,
    );
  }

  static String _cleanUrl(dynamic value) {
    return (value == null ? '' : '$value').replaceAll('`', '').trim();
  }
}

class GetappInitV119 {
  final List<GetappBanner> bannerList;

  GetappInitV119({required this.bannerList});

  factory GetappInitV119.fromJson(Map<String, dynamic> json) {
    final bannerRaw = json['banner_list'];
    final list = (bannerRaw is List)
        ? bannerRaw
            .whereType<Map>()
            .map((e) => GetappBanner.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <GetappBanner>[];
    return GetappInitV119(bannerList: list);
  }
}

class GetappApiClient {
  final Dio _dio;
  final GetappCrypto? _crypto;
  final String appOs;
  final int appVersionCode;
  String? userToken;

  GetappApiClient({
    Dio? dio,
    String baseUrl = 'https://123344.xyz/api.php/',
    String? apiSecretKey,
    this.appOs = 'android',
    this.appVersionCode = 1,
    this.userToken,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 20),
              ),
            ),
        _crypto = (apiSecretKey == null || apiSecretKey.isEmpty)
            ? null
            : GetappCrypto(apiSecretKey) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          options.headers['app-os'] = appOs;
          options.headers['app-version-code'] = '$appVersionCode';
          if (_crypto != null) {
            options.headers['app-api-verify-time'] = '$nowSeconds';
            options.headers['app-api-verify-sign'] =
                _crypto.encryptTextToBase64('$nowSeconds');
          }
          if (userToken != null && userToken!.isNotEmpty) {
            options.headers['app-user-token'] = userToken!;
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<GetappInitV119> initV119() async {
    final response = await _dio.get('getappapi.index/initV119');
    final json = _normalizeJson(response.data);
    final code = json['code'];
    if (code != 1) {
      throw GetappApiException('${json['msg'] ?? '请求失败'}');
    }
    final data = _decodeDataField(json['data']);
    return GetappInitV119.fromJson(data);
  }

  Map<String, dynamic> _decodeDataField(dynamic dataField) {
    if (dataField is Map<String, dynamic>) {
      return dataField;
    }
    if (dataField is String) {
      if (dataField.isEmpty) {
        return <String, dynamic>{};
      }
      if (_crypto == null) {
        throw GetappApiException('接口返回为加密 data，但未配置 apiSecretKey');
      }
      final plainText = _crypto.decryptBase64ToText(dataField);
      final decoded = jsonDecode(plainText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
      throw GetappApiException('解密后的 data 不是对象结构');
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _normalizeJson(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return body.cast<String, dynamic>();
    }
    if (body is String) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    }
    throw GetappApiException('响应不是 JSON 对象');
  }
}

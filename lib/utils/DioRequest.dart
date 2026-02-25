import 'package:app/contants/index.dart';
import 'package:app/getapp/getapp_client.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class DioRequest {
  final Dio _dio;
  final GetappCrypto? _crypto;

  DioRequest({String? apiSecretKey})
    : _dio = Dio(
        BaseOptions(
          baseUrl: _normalizeBaseUrl(GlobalConstants.BASE_URL),
          connectTimeout: Duration(seconds: GlobalConstants.TIME_OUT),
          sendTimeout: Duration(seconds: GlobalConstants.TIME_OUT),
          receiveTimeout: Duration(seconds: GlobalConstants.TIME_OUT),
        ),
      ),
      _crypto = (apiSecretKey == null || apiSecretKey.isEmpty)
          ? null
          : GetappCrypto(apiSecretKey) {
    _addIntercepter();
  }

  void _addIntercepter() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          options.headers['app-os'] = 'android';
          options.headers['app-version-code'] = '1';
          if (_crypto != null) {
            options.headers['app-api-verify-time'] = '$nowSeconds';
            options.headers['app-api-verify-sign'] = _crypto
                .encryptTextToBase64('$nowSeconds');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            handler.next(response);
            return;
          }
          handler.reject(DioException(requestOptions: response.requestOptions));
        },
        onError: (error, handler) {
          handler.reject(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? params,
    bool requireBannerListNotEmpty = false,
  }) {
    return _handleResponse(
      _dio.get(url, queryParameters: params),
      requireBannerListNotEmpty: requireBannerListNotEmpty,
    );
  }

  Future<Map<String, dynamic>> _handleResponse(
    Future<Response<dynamic>> task, {
    required bool requireBannerListNotEmpty,
  }) async {
    final res = await task;
    final body = res.data;
    final json = _normalizeJson(body);
    final code = json['code'];
    if (code != 1 && code != '1') {
      throw GetappApiException('${json['msg'] ?? '请求失败'}');
    }

    final decodedData = _decodeDataField(json['data']);

    if (requireBannerListNotEmpty) {
      final bannerList = decodedData['banner_list'];
      final ok = bannerList is List && bannerList.isNotEmpty;
      if (!ok) {
        throw GetappApiException('banner_list 为空');
      }
    }

    return decodedData;
  }

  Map<String, dynamic> _decodeDataField(dynamic dataField) {
    if (dataField is Map<String, dynamic>) {
      return dataField;
    }
    if (dataField is Map) {
      return dataField.cast<String, dynamic>();
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

  static String _normalizeBaseUrl(String baseUrl) {
    if (baseUrl.endsWith('/')) {
      return baseUrl;
    }
    return '$baseUrl/';
  }
}

final diorequest = DioRequest(apiSecretKey: HttpConstants.apiSecretKey);

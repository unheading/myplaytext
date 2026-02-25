class VodInfo {
  final int id;
  final String name;
  final String pic;
  final String remarks;
  final String year;
  final String area;
  final String lang;
  final String clazz;
  final String blurb;

  VodInfo({
    required this.id,
    required this.name,
    required this.pic,
    required this.remarks,
    required this.year,
    required this.area,
    required this.lang,
    required this.clazz,
    required this.blurb,
  });

  factory VodInfo.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    String toStr(dynamic v) => (v ?? '').toString();
    String cleanUrl(dynamic v) {
      var s = toStr(v).trim();
      s = s.replaceAll('&amp;', '&');
      s = s.replaceAll('`', '');
      s = s.replaceAll(RegExp(r'^[`"\u2018\u2019\u201C\u201D]+'), '');
      s = s.replaceAll(RegExp(r'[`"\u2018\u2019\u201C\u201D]+$'), '');
      return s.trim();
    }

    final pic = cleanUrl(json['vod_pic']);
    final slide = cleanUrl(json['vod_pic_slide']);

    return VodInfo(
      id: toInt(json['vod_id']),
      name: toStr(json['vod_name']),
      pic: pic.isNotEmpty ? pic : slide,
      remarks: toStr(json['vod_remarks']),
      year: toStr(json['vod_year']),
      area: toStr(json['vod_area']),
      lang: toStr(json['vod_lang']),
      clazz: toStr(json['vod_class']),
      blurb: toStr(json['vod_blurb']),
    );
  }
}

class VodPlayUrl {
  final String name;
  final String url;
  final int nid;
  final String token;
  final String parseApiUrl;

  VodPlayUrl({
    required this.name,
    required this.url,
    required this.nid,
    required this.token,
    required this.parseApiUrl,
  });

  factory VodPlayUrl.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    String toStr(dynamic v) => (v ?? '').toString();
    return VodPlayUrl(
      name: toStr(json['name']),
      url: toStr(json['url']),
      nid: toInt(json['nid']),
      token: toStr(json['token']),
      parseApiUrl: toStr(json['parse_api_url']),
    );
  }
}

class VodPlayLine {
  final String show;
  final String parseApi;
  final int urlCount;
  final List<VodPlayUrl> urls;

  VodPlayLine({
    required this.show,
    required this.parseApi,
    required this.urlCount,
    required this.urls,
  });

  factory VodPlayLine.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic v) => (v ?? '').toString();
    int toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
    final playerInfo = json['player_info'];
    final show = playerInfo is Map ? toStr(playerInfo['show']) : '';
    final parseApi = playerInfo is Map ? toStr(playerInfo['parse']) : '';
    final rawUrls = json['urls'];
    final urls = (rawUrls is List)
        ? rawUrls
            .whereType<Map>()
            .map((e) => VodPlayUrl.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <VodPlayUrl>[];
    return VodPlayLine(
      show: show,
      parseApi: parseApi,
      urlCount: toInt(json['url_count']),
      urls: urls,
    );
  }
}

class VodDetailData {
  final VodInfo vod;
  final List<VodPlayLine> playLines;

  VodDetailData({required this.vod, required this.playLines});

  factory VodDetailData.fromJson(Map<String, dynamic> json) {
    final vodRaw = json['vod'];
    final vod = (vodRaw is Map)
        ? VodInfo.fromJson(vodRaw.cast<String, dynamic>())
        : VodInfo(
            id: 0,
            name: '',
            pic: '',
            remarks: '',
            year: '',
            area: '',
            lang: '',
            clazz: '',
            blurb: '',
          );
    final rawPlay = json['vod_play_list'];
    final lines = (rawPlay is List)
        ? rawPlay
            .whereType<Map>()
            .map((e) => VodPlayLine.fromJson(e.cast<String, dynamic>()))
            .where((e) => e.show.isNotEmpty && e.urls.isNotEmpty)
            .toList(growable: false)
        : const <VodPlayLine>[];
    return VodDetailData(vod: vod, playLines: lines);
  }
}

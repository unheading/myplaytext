

class BannerItem{
  String id;
  String imgUrl;
  String title;
  BannerItem({required this.id,required this.imgUrl,required this.title});
  factory BannerItem.formJSON(Map<String,dynamic> json){
    final rawId = json["vod_id"];
    final rawPic = json["vod_pic"];
    final rawSlide = json["vod_pic_slide"];
    final rawName = json["vod_name"];
    final id = rawId == null ? "" : "$rawId";
    final pic = _cleanUrl(rawPic);
    final slide = _cleanUrl(rawSlide);
    final title = _cleanText(rawName);
    return BannerItem(id: id, imgUrl: pic.isNotEmpty ? pic : slide, title: title);
  }

  static String _cleanUrl(dynamic value){
    var s = (value == null ? "" : "$value").trim();
    s = s.replaceAll(RegExp(r'^[`"\u2018\u2019\u201C\u201D]+'), '');
    s = s.replaceAll(RegExp(r'[`"\u2018\u2019\u201C\u201D]+$'), '');
    s = s.replaceAll('`', '');
    s = s.replaceAll('&amp;', '&');
    return s.trim();
  }

  static String _cleanText(dynamic value) {
    var s = (value == null ? "" : "$value").trim();
    s = s.replaceAll(RegExp(r'^[`"\u2018\u2019\u201C\u201D]+'), '');
    s = s.replaceAll(RegExp(r'[`"\u2018\u2019\u201C\u201D]+$'), '');
    s = s.replaceAll('`', '');
    return s.trim();
  }
}




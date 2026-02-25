class CategoryVod {
  final String id;
  final String name;
  final String pic;
  final String remarks;

  CategoryVod({
    required this.id,
    required this.name,
    required this.pic,
    required this.remarks,
  });

  factory CategoryVod.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : '$v';
    String cleanUrl(dynamic v) {
      var str = s(v).trim();
      str = str.replaceAll('&amp;', '&');
      str = str.replaceAll('`', '');
      str = str.replaceAll(RegExp(r'^[`"\u2018\u2019\u201C\u201D]+'), '');
      str = str.replaceAll(RegExp(r'[`"\u2018\u2019\u201C\u201D]+$'), '');
      return str.trim();
    }

    return CategoryVod(
      id: s(json['vod_id']),
      name: s(json['vod_name']),
      pic: cleanUrl(json['vod_pic'].toString().isNotEmpty
          ? json['vod_pic']
          : json['vod_pic_slide']),
      remarks: s(json['vod_remarks']),
    );
  }
}

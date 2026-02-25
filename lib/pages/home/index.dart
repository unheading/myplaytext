import 'package:app/api/home.dart';
import 'package:app/components/home/HmSlider.dart';
import 'package:app/components/home/HomeCategorySection.dart';
import 'package:app/api/init_v119.dart';
import 'package:app/api/category.dart';
import 'package:app/pages/category/index.dart';
import 'package:app/pages/detail/index.dart';
import 'package:app/viewnodels/category.dart';
import 'package:app/viewnodels/home.dart';
import 'package:flutter/material.dart';

class homeView extends StatefulWidget {
  final void Function(int typeId)? onOpenCategory;
  homeView({Key? key, this.onOpenCategory}) : super(key: key);

  @override
  _homeViewState createState() => _homeViewState();
}

class _homeViewState extends State<homeView> {
  List<BannerItem> _bannerList = [
    // BannerItem(
    //   id:"1" , 
    //   imgUrl: "https://ceshijp.123344.xyz/image/7.png"
    //   ),
    //       BannerItem(
    //   id:"2" , 
    //   imgUrl: "https://ceshijp.123344.xyz/image/1.jpg"
    //   ),
    //       BannerItem(
    //   id:"3" , 
    //   imgUrl: "https://ceshijp.123344.xyz/image/2.jpg"
    //   ),
  ];
  final Map<String, List<CategoryVod>> _sectionItems = {
    '日番': const <CategoryVod>[],
    '欧美': const <CategoryVod>[],
    '电影': const <CategoryVod>[],
    '国漫': const <CategoryVod>[],
  };

  final Map<String, int> _sectionTypeIds = {
    '日番': 1,
    '欧美': 2,
    '电影': 3,
    '国漫': 4,
  };

  @override
  void initState() {
    super.initState();
    _getbannerList();
    _loadHomeSections();
  }

  void _getbannerList()async{
    final list = await getBannerListAPI();
    if (!mounted || list.isEmpty) {
      return;
    }
    _bannerList = list;
    setState(() {
      
    });
  }

  Future<void> _loadHomeSections() async {
    try {
      final types = await getInitV119CategoryTypesAPI();
      int? findTypeId(List<String> keywords) {
        for (final k in keywords) {
          for (final t in types) {
            if (t.name.contains(k)) {
              return t.id;
            }
          }
        }
        return null;
      }

      if (types.isNotEmpty) {
        _sectionTypeIds['日番'] = findTypeId(['日番', '日漫', '番组', 'TV']) ?? 1;
        _sectionTypeIds['欧美'] = findTypeId(['欧美', '美番']) ?? 2;
        _sectionTypeIds['电影'] = findTypeId(['电影']) ?? 3;
        _sectionTypeIds['国漫'] = findTypeId(['国漫']) ?? 4;
      }

      final futures = <Future<void>>[];
      for (final entry in _sectionTypeIds.entries) {
        futures.add(() async {
          final data = await getCategoryListAPI(
            typeId: entry.value,
            page: 1,
            sort: '最新',
          );
          _sectionItems[entry.key] = data;
        }());
      }
      await Future.wait(futures);

      if (mounted) setState(() {});
    } catch (_) {}
  }

  List<Widget> _getScrollView(){
    return[
      SliverToBoxAdapter(
        child: HmSlider(bannerList: _bannerList,),
      ),
       SliverToBoxAdapter(
        child: SizedBox(height: 10,),
      ),
       SliverToBoxAdapter(
        child: HomeCategorySection(
          title: '日番',
          items: _sectionItems['日番'] ?? const <CategoryVod>[],
          onMore: () {
            final id = _sectionTypeIds['日番'] ?? 1;
            if (widget.onOpenCategory != null) {
              widget.onOpenCategory!(id);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => categoryView(typeId: id)),
            );
          },
          onTapItem: (item) {
            final id = int.tryParse(item.id);
            if (id == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VodDetailPage(vodId: id)),
            );
          },
        ),
      ),
             SliverToBoxAdapter(
        child: SizedBox(height: 10,),
      ),
             SliverToBoxAdapter(
        child: HomeCategorySection(
          title: '欧美',
          items: _sectionItems['欧美'] ?? const <CategoryVod>[],
          onMore: () {
            final id = _sectionTypeIds['欧美'] ?? 2;
            if (widget.onOpenCategory != null) {
              widget.onOpenCategory!(id);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => categoryView(typeId: id)),
            );
          },
          onTapItem: (item) {
            final id = int.tryParse(item.id);
            if (id == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VodDetailPage(vodId: id)),
            );
          },
        ),
      ),
             SliverToBoxAdapter(
        child: SizedBox(height: 10,),
      ),
             SliverToBoxAdapter(
        child: HomeCategorySection(
          title: '电影',
          items: _sectionItems['电影'] ?? const <CategoryVod>[],
          onMore: () {
            final id = _sectionTypeIds['电影'] ?? 3;
            if (widget.onOpenCategory != null) {
              widget.onOpenCategory!(id);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => categoryView(typeId: id)),
            );
          },
          onTapItem: (item) {
            final id = int.tryParse(item.id);
            if (id == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VodDetailPage(vodId: id)),
            );
          },
        ),
      ),
             SliverToBoxAdapter(
        child: SizedBox(height: 10,),
      ),
             SliverToBoxAdapter(
        child: HomeCategorySection(
          title: '国漫',
          items: _sectionItems['国漫'] ?? const <CategoryVod>[],
          onMore: () {
            final id = _sectionTypeIds['国漫'] ?? 4;
            if (widget.onOpenCategory != null) {
              widget.onOpenCategory!(id);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => categoryView(typeId: id)),
            );
          },
          onTapItem: (item) {
            final id = int.tryParse(item.id);
            if (id == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VodDetailPage(vodId: id)),
            );
          },
        ),
      ),
    ];
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 18, 18, 18),
      child: CustomScrollView(slivers: _getScrollView(),),
    );
  }
}

import 'package:app/api/category.dart';
import 'package:app/api/init_v119.dart';
import 'package:app/components/common/LoadingGif.dart';
import 'package:app/pages/category/controller.dart';
import 'package:app/pages/detail/index.dart';
import 'package:app/viewnodels/category.dart';
import 'package:app/viewnodels/category_filters.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class categoryView extends StatefulWidget {
  final int typeId;
  final int initialPage;
  final CategoryViewController? controller;
  categoryView({Key? key, this.typeId = 1, this.initialPage = 1, this.controller})
      : super(key: key);

  @override
  _categoryViewState createState() => _categoryViewState();
}

class _categoryViewState extends State<categoryView> {
  static const int _pageSize = 30;
  static const Color _pageBg = Color.fromARGB(255, 18, 18, 18);
  static const Color _textActive = Colors.white;
  static const Color _textInactive = Color.fromARGB(160, 255, 255, 255);
  static const Color _textMuted = Color.fromARGB(120, 255, 255, 255);

  List<CategoryType> _types = const <CategoryType>[];
  late int _typeId;
  late int _page;
  bool _loading = false;
  bool _hasMore = true;
  final List<CategoryVod> _list = [];
  final Map<String, String> _selected = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _typeId = widget.typeId;
    _page = widget.initialPage;
    widget.controller?.targetTypeId.addListener(_onTargetTypeChanged);
    _onTargetTypeChanged();
    _init();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasMore) {
        _fetch();
      }
    });
  }

  void _onTargetTypeChanged() {
    final typeId = widget.controller?.targetTypeId.value;
    if (typeId == null) return;
    _setType(typeId);
  }

  void _setType(int typeId) {
    if (typeId == _typeId) return;
    setState(() {
      _typeId = typeId;
      _applyDefaultFiltersForType(_typeId);
    });
    _fetch(reset: true);
  }

  Future<void> _init() async {
    try {
      final types = await getInitV119CategoryTypesAPI();
      if (!mounted) return;
      _types = types;
      if (_types.isNotEmpty) {
        final exists = _types.any((e) => e.id == _typeId);
        _typeId = exists ? _typeId : _types.first.id;
        _applyDefaultFiltersForType(_typeId);
      }
    } catch (_) {}
    if (mounted) setState(() {});
    await _fetch(reset: true);
  }

  void _applyDefaultFiltersForType(int typeId) {
    _selected.clear();
    final t = _types.firstWhere(
      (e) => e.id == typeId,
      orElse: () => CategoryType(id: typeId, name: '', filterGroups: const []),
    );
    for (final g in t.filterGroups) {
      if (g.options.isEmpty) continue;
      _selected[g.name] = g.options.first;
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (reset) {
        _page = widget.initialPage;
        _hasMore = true;
      }
      final data = await getCategoryListAPI(
        typeId: _typeId,
        page: _page,
        className: _selected['class'],
        area: _selected['area'],
        lang: _selected['lang'],
        year: _selected['year'],
        sort: _selected['sort'],
      );
      if (reset) _list.clear();
      _list.addAll(data);
      _hasMore = data.length >= _pageSize;
      if (_hasMore) _page += 1;
    } catch (_) {
      // ignore, keep current state
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 46,
              decoration: BoxDecoration(
                color: const Color.fromARGB(60, 0, 0, 0),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color.fromARGB(80, 255, 255, 255),
                  width: 1,
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.white70, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "搜索你想看的动漫吧",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textInactive,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(60, 0, 0, 0),
              border: Border.all(
                color: const Color.fromARGB(80, 255, 255, 255),
                width: 1,
              ),
            ),
            child: const Icon(Icons.notifications_none, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final t = _types[index];
          final active = t.id == _typeId;
          return GestureDetector(
            onTap: () {
              if (t.id == _typeId) return;
              setState(() {
                _typeId = t.id;
                _applyDefaultFiltersForType(_typeId);
              });
              _fetch(reset: true);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  t.name,
                  style: TextStyle(
                    color: active ? _textActive : _textInactive,
                    fontSize: active ? 16 : 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 26 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color.fromARGB(255, 255, 128, 128)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _labelForGroup(String name) {
    switch (name) {
      case 'sort':
        return '排序';
      case 'year':
        return '年份';
      case 'class':
        return '类型';
      case 'area':
        return '地区';
      case 'lang':
        return '语言';
      default:
        return name;
    }
  }

  Widget _buildFilterRow(CategoryFilterGroup group) {
    final selected = _selected[group.name] ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _labelForGroup(group.name),
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: group.options.map((opt) {
                  final active = opt == selected;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        if (_selected[group.name] == opt) return;
                        setState(() => _selected[group.name] = opt);
                        _fetch(reset: true);
                      },
                      child: active
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(40, 255, 128, 128),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 255, 128, 128),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                opt,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 160, 160),
                                  fontSize: 12,
                                  height: 1.0,
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              child: Text(
                                opt,
                                style: const TextStyle(
                                  color: _textInactive,
                                  fontSize: 12,
                                  height: 1.0,
                                ),
                              ),
                            ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final t = _types.firstWhere(
      (e) => e.id == _typeId,
      orElse: () => CategoryType(id: _typeId, name: '', filterGroups: const []),
    );
    if (t.filterGroups.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: t.filterGroups.map(_buildFilterRow).toList(growable: false),
    );
  }

  @override
  void dispose() {
    widget.controller?.targetTypeId.removeListener(_onTargetTypeChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCard(CategoryVod item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            final id = int.tryParse(item.id);
            if (id == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VodDetailPage(vodId: id)),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 3 / 4.2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      item.pic,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color.fromARGB(24, 255, 255, 255),
                          alignment: Alignment.center,
                          child: const LoadingGif(size: 40),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color.fromARGB(30, 0, 0, 0),
                          alignment: Alignment.center,
                          child: const Text(
                            '暂无封面',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            final id = int.tryParse(item.id);
            if (id == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VodDetailPage(vodId: id)),
            );
          },
          child: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textActive,
            ),
          ),
        ),
        if (item.remarks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              item.remarks,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: _textMuted,
                height: 1.0,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: RefreshIndicator(
        onRefresh: () => _fetch(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchBar(),
                  if (_types.isNotEmpty) _buildTopTabs(),
                  const SizedBox(height: 6),
                  if (_types.isNotEmpty) _buildFilters(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (_list.isEmpty && _loading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: LoadingGif(size: 56),
                ),
              )
            else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3 / 5.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCard(_list[index]),
                  childCount: _list.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (!_hasMore
                          ? const Text(
                              '没有更多了',
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 12,
                              ),
                            )
                          : const SizedBox.shrink()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

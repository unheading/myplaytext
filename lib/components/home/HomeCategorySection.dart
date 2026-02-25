import 'package:app/components/common/LoadingGif.dart';
import 'package:app/viewnodels/category.dart';
import 'package:flutter/material.dart';

class HomeCategorySection extends StatelessWidget {
  final String title;
  final List<CategoryVod> items;
  final VoidCallback? onMore;
  final void Function(CategoryVod item)? onTapItem;

  const HomeCategorySection({
    super.key,
    required this.title,
    required this.items,
    this.onMore,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final showItems = items.length > 3 ? items.sublist(0, 3) : items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: onMore,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    '更多 >',
                    style: TextStyle(
                      color: Color.fromARGB(160, 255, 255, 255),
                      fontSize: 13,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (index) {
              if (items.isEmpty) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 3 / 4.2,
                        child: Container(
                          color: const Color.fromARGB(24, 255, 255, 255),
                          alignment: Alignment.center,
                          child: const LoadingGif(size: 40),
                        ),
                      ),
                    ),
                  ),
                );
              }
              if (index >= showItems.length) {
                return const Expanded(child: SizedBox.shrink());
              }
              final item = showItems[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
                  child: _Card(item: item, onTap: onTapItem),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final CategoryVod item;
  final void Function(CategoryVod item)? onTap;

  const _Card({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(item),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 3 / 4.2,
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
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
                  fontSize: 11,
                  color: Color.fromARGB(120, 255, 255, 255),
                  height: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


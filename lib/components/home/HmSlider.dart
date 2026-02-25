import 'package:app/components/common/LoadingGif.dart';
import 'package:app/viewnodels/home.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HmSlider extends StatefulWidget {
  final List<BannerItem> bannerList;
  HmSlider({Key? key, required this.bannerList}) : super(key: key);

  @override
  _HmSliderState createState() => _HmSliderState();
}

class _HmSliderState extends State<HmSlider> {
  CarouselSliderController _controller = CarouselSliderController();
  int _currentIndex = 0;
  Widget _getSlider() {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (widget.bannerList.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: const Color.fromARGB(24, 255, 255, 255),
            alignment: Alignment.center,
            child: const LoadingGif(size: 56),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: CarouselSlider(
        carouselController: _controller,
        items: List.generate(widget.bannerList.length, (int index) {
          final item = widget.bannerList[index];
          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  item.imgUrl,
                  fit: BoxFit.cover,
                  width: screenWidth,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color.fromARGB(24, 255, 255, 255),
                      alignment: Alignment.center,
                      child: const LoadingGif(size: 56),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color.fromARGB(40, 0, 0, 0),
                      alignment: Alignment.center,
                      child: const Text(
                        '暂无封面',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (item.title.isNotEmpty)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(140, 0, 0, 0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: BoxConstraints(maxWidth: screenWidth - 20),
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
        options: CarouselOptions(
          viewportFraction: 1,
          autoPlay: true,
          onPageChanged: (int index, reason) {
            _currentIndex = index;
            setState(() {});
          },
          //autoPlayInterval: Duration(seconds: 5)
        ),
      ),
    );
  }

  Widget _getSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 16),
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
                children: [
                  Icon(Icons.search, color: Colors.white70, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "搜索你想看的动漫吧",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
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
            child: Icon(Icons.notifications_none, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _getDots() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: List.generate(widget.bannerList.length, (int index) {
            return GestureDetector(
              onTap: () {
                _controller.jumpToPage(index);
              },
              child: AnimatedContainer(
                duration: Duration(seconds: 1),
                height: 6,
                width: index == _currentIndex ? 30 : 10,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? Colors.white
                      : const Color.fromARGB(100, 0, 0, 0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _getSearchBar(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Stack(
            children: [
              _getSlider(),
              _getDots(),
            ],
          ),
        ),
      ],
    );
  }
}

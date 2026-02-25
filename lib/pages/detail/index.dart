import 'package:app/api/comment.dart';
import 'package:app/api/danmu.dart';
import 'package:app/api/send_danmu.dart';
import 'package:app/api/bfq_parse.dart';
import 'package:app/api/vod_parse.dart';
import 'package:app/api/vod_detail.dart';
import 'package:app/components/common/LoadingGif.dart';
import 'package:app/viewnodels/vod_detail.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VodDetailPage extends StatefulWidget {
  final int vodId;

  const VodDetailPage({super.key, required this.vodId});

  @override
  State<VodDetailPage> createState() => _VodDetailPageState();
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Future<void> Function() onTap;

  const _RoundIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onTap() : null,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color.fromARGB(120, 0, 0, 0),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: enabled
                ? const Color.fromARGB(60, 255, 255, 255)
                : const Color.fromARGB(20, 255, 255, 255),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: enabled
              ? Colors.white
              : const Color.fromARGB(100, 255, 255, 255),
          size: 28,
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(18, 255, 255, 255),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromARGB(30, 255, 255, 255),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _MiniTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _MiniTextButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(18, 255, 255, 255),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromARGB(30, 255, 255, 255),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FullscreenPlayerPage extends StatefulWidget {
  final ValueListenable<VideoPlayerController?> controllerListenable;
  final int vodId;
  final String title;
  final String episodeName;
  final VoidCallback onCast;
  final String Function(Duration d) formatDuration;
  final List<VodPlayLine> lines;
  final int initialLineIndex;
  final int initialEpisodeIndex;
  final Future<void> Function(int lineIndex) onSelectLine;
  final Future<void> Function(int episodeIndex) onSelectEpisode;

  const _FullscreenPlayerPage({
    required this.controllerListenable,
    required this.vodId,
    required this.title,
    required this.episodeName,
    required this.onCast,
    required this.formatDuration,
    required this.lines,
    required this.initialLineIndex,
    required this.initialEpisodeIndex,
    required this.onSelectLine,
    required this.onSelectEpisode,
  });

  @override
  State<_FullscreenPlayerPage> createState() => _FullscreenPlayerPageState();
}

class _FullscreenPlayerPageState extends State<_FullscreenPlayerPage> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _locked = false;
  bool _scrubbing = false;
  bool _drawerOpen = false;
  _SidePanel _panel = _SidePanel.menu;
  int _jumpSeconds = 90;
  _AspectMode _aspectMode = _AspectMode.fit;
  bool _anime4kEnabled = false;
  int _lineIndex = 0;
  int _episodeIndex = 0;
  bool _danmuEnabled = true;
  double _danmuOpacity = 0.9;
  double _danmuFontScale = 1.0;
  double _danmuAreaFraction = 1.0;
  bool _danmuHideScroll = false;
  bool _danmuHideTop = false;
  bool _danmuHideBottom = false;
  bool _danmuHideColor = false;
  Timer? _danmuTicker;
  List<Map<String, dynamic>> _danmuSource = const [];
  final Set<int> _danmuFired = <int>{};
  final List<_ActiveDanmu> _danmuActive = <_ActiveDanmu>[];
  final TextEditingController _danmuController = TextEditingController();
  String _danmuColor = '#ffffff';

  @override
  void initState() {
    super.initState();
    _lineIndex = widget.initialLineIndex;
    _episodeIndex = widget.initialEpisodeIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadDanmu();
    _showControlsTemporarily();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _danmuTicker?.cancel();
    _danmuController.dispose();
    for (final d in _danmuActive) {
      d.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _showControlsTemporarily() {
    _hideTimer?.cancel();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    final c = widget.controllerListenable.value;
    if (c == null) return;
    if (!c.value.isInitialized) return;
    if (!c.value.isPlaying) return;
    if (_scrubbing) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_scrubbing) return;
      if (_locked) return;
      if (_drawerOpen) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _openDrawer([_SidePanel panel = _SidePanel.menu]) {
    setState(() {
      _drawerOpen = true;
      _panel = panel;
      _controlsVisible = true;
    });
    _hideTimer?.cancel();
  }

  void _closeDrawer() {
    setState(() => _drawerOpen = false);
    _showControlsTemporarily();
  }

  List<VodPlayUrl> get _episodes {
    if (widget.lines.isEmpty) return const <VodPlayUrl>[];
    final idx = _lineIndex.clamp(0, widget.lines.length - 1);
    return widget.lines[idx].urls;
  }

  bool get _hasPrev => _episodeIndex > 0;
  bool get _hasNext => _episodeIndex < _episodes.length - 1;

  Future<void> _selectLine(int index) async {
    if (index < 0 || index >= widget.lines.length) return;
    setState(() {
      _lineIndex = index;
      _episodeIndex = 0;
    });
    await widget.onSelectLine(index);
    await _loadDanmu();
  }

  Future<void> _selectEpisode(int index) async {
    if (index < 0 || index >= _episodes.length) return;
    setState(() => _episodeIndex = index);
    await widget.onSelectEpisode(index);
    await _loadDanmu();
  }

  Future<void> _loadDanmu() async {
    if (!_danmuEnabled) return;
    try {
      final data = await getDanmuListAPI(
        vodId: widget.vodId,
        urlPosition: _episodeIndex,
      );
      final raw = data['danmu_list'];
      final list = raw is List
          ? raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
          : <Map<String, dynamic>>[];
      for (final d in _danmuActive) {
        d.dispose();
      }
      _danmuActive.clear();
      _danmuFired.clear();
      setState(() => _danmuSource = list);
      _ensureDanmuTicker();
    } catch (_) {}
  }

  void _ensureDanmuTicker() {
    _danmuTicker?.cancel();
    if (!_danmuEnabled) return;
    _danmuTicker = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final c = widget.controllerListenable.value;
      if (!mounted || c == null) return;
      if (!c.value.isInitialized) return;
      final posMs = c.value.position.inMilliseconds;
      _tickDanmu(posMs);
    });
  }

  void _tickDanmu(int posMs) {
    for (var i = 0; i < _danmuSource.length; i++) {
      if (_danmuFired.contains(i)) continue;
      final m = _danmuSource[i];
      final tRaw = m['time'];
      final tSec = double.tryParse((tRaw ?? '').toString()) ?? 0.0;
      final tMs = (tSec * 1000).round();
      if (tMs <= 0) continue;
      if (posMs >= tMs) {
        _danmuFired.add(i);
        _spawnDanmu(m);
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _danmuActive.removeWhere((d) => d.isExpired(now));
    if (mounted && _danmuEnabled) setState(() {});
  }

  void _spawnDanmu(Map<String, dynamic> m) {
    final text = (m['text'] ?? '').toString();
    if (text.trim().isEmpty) return;
    final position = int.tryParse((m['position'] ?? '0').toString()) ?? 0;
    final colorHex = (m['color'] ?? '').toString();

    if (position == 1 && _danmuHideTop) return;
    if (position == 2 && _danmuHideBottom) return;
    if (position == 0 && _danmuHideScroll) return;

    final c = _parseColor(_danmuHideColor ? '#ffffff' : colorHex);
    final now = DateTime.now().millisecondsSinceEpoch;
    final type = position == 1
        ? _DanmuType.top
        : (position == 2 ? _DanmuType.bottom : _DanmuType.scroll);
    _danmuActive.add(
      _ActiveDanmu(
        text: text,
        color: c.withValues(alpha: _danmuOpacity),
        type: type,
        bornAtMs: now,
        durationMs: type == _DanmuType.scroll ? 9000 : 4500,
        lane: (_danmuActive.length % 12),
      ),
    );
  }

  Color _parseColor(String hex) {
    var h = hex.trim().toLowerCase();
    if (!h.startsWith('#')) h = '#$h';
    if (h.length == 4) {
      h = '#${h[1]}${h[1]}${h[2]}${h[2]}${h[3]}${h[3]}';
    }
    if (h.length != 7) return Colors.white;
    final v = int.tryParse(h.substring(1), radix: 16);
    if (v == null) return Colors.white;
    return Color(0xFF000000 | v);
  }

  Future<void> _openDanmuSendDialog() async {
    final c = widget.controllerListenable.value;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position;
    final sec = (pos.inMilliseconds / 1000.0).toStringAsFixed(1);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: double.infinity,
                color: const Color.fromARGB(220, 28, 28, 28),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: _DanmuSendPanel(
                  controller: _danmuController,
                  initialColor: _danmuColor,
                  onColorChanged: (c) => _danmuColor = c,
                  onSend: () async {
                    final text = _danmuController.text.trim();
                    if (text.isEmpty) return;
                    try {
                      await sendDanmuAPI(
                        vodId: widget.vodId,
                        urlPosition: _episodeIndex,
                        danmu: text,
                        color: _danmuColor,
                        time: sec,
                        position: 0,
                      );
                      _danmuController.clear();
                      _spawnDanmu({
                        'text': text,
                        'color': _danmuColor,
                        'time': sec,
                        'position': 0,
                      });
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _seekBy(VideoPlayerController c, int seconds) async {
    final d = c.value.duration;
    final p = c.value.position;
    if (d == Duration.zero) return;
    final target = p + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > d ? d : target);
    await c.seekTo(clamped);
  }

  Widget _buildVideo(VideoPlayerController c) {
    final v = c.value;
    final ar = v.isInitialized ? v.aspectRatio : 16 / 9;
    Widget child = VideoPlayer(c);
    if (_aspectMode == _AspectMode.fit) {
      return AspectRatio(aspectRatio: ar, child: child);
    }
    if (_aspectMode == _AspectMode.fill) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: 1000,
          height: 1000 / ar,
          child: child,
        ),
      );
    }
    if (_aspectMode == _AspectMode.stretch) {
      return SizedBox.expand(child: child);
    }
    final fixed = _aspectMode.fixedAspectRatio;
    if (fixed != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: fixed,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: 1000,
              height: 1000 / ar,
              child: child,
            ),
          ),
        ),
      );
    }
    return AspectRatio(aspectRatio: ar, child: child);
  }

  Widget _buildDrawer() {
    Widget header(String title) {
      return Row(
        children: [
          if (_panel != _SidePanel.menu)
            InkWell(
              onTap: () => setState(() => _panel = _SidePanel.menu),
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
            ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        ],
      );
    }

    Widget menuItem({
      required String title,
      required VoidCallback onTap,
      String? trailing,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(24, 255, 255, 255),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color.fromARGB(30, 255, 255, 255),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color.fromARGB(220, 255, 255, 255),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: const TextStyle(
                    color: Color.fromARGB(140, 255, 255, 255),
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: Color.fromARGB(170, 255, 255, 255),
                size: 18,
              ),
            ],
          ),
        ),
      );
    }

    Widget body;
    if (_panel == _SidePanel.menu) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header('设置'),
          const SizedBox(height: 12),
          menuItem(
            title: '快进',
            trailing: '${_jumpSeconds}s',
            onTap: () => setState(() => _panel = _SidePanel.forward),
          ),
          const SizedBox(height: 10),
          menuItem(
            title: '画面比例',
            trailing: _aspectMode.label,
            onTap: () => setState(() => _panel = _SidePanel.aspect),
          ),
          const SizedBox(height: 10),
          menuItem(
            title: '倍速',
            trailing: '${widget.controllerListenable.value?.value.playbackSpeed ?? 1.0}x',
            onTap: () => setState(() => _panel = _SidePanel.speed),
          ),
          const SizedBox(height: 10),
          menuItem(
            title: '选集',
            trailing: (_episodes.isNotEmpty && _episodeIndex < _episodes.length)
                ? _episodes[_episodeIndex].name
                : '',
            onTap: () => setState(() => _panel = _SidePanel.episodes),
          ),
          const SizedBox(height: 10),
          menuItem(
            title: '换源',
            trailing: widget.lines.isNotEmpty && _lineIndex < widget.lines.length
                ? widget.lines[_lineIndex].show
                : '',
            onTap: () => setState(() => _panel = _SidePanel.lines),
          ),
          const SizedBox(height: 10),
          menuItem(
            title: '弹幕设置',
            trailing: _danmuEnabled ? '开启' : '关闭',
            onTap: () => setState(() => _panel = _SidePanel.danmuSettings),
          ),
          const SizedBox(height: 10),
          menuItem(
            title: 'Anime4K',
            trailing: _anime4kEnabled ? '开启' : '关闭',
            onTap: () => setState(() => _panel = _SidePanel.anime4k),
          ),
        ],
      );
    } else if (_panel == _SidePanel.forward) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header('快进'),
          const SizedBox(height: 12),
          const Text(
            '设置每次快进的时长，并快速跳过当前视频',
            style: TextStyle(
              color: Color.fromARGB(140, 255, 255, 255),
              fontSize: 12,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _jumpSeconds = (_jumpSeconds - 5).clamp(5, 180)),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(24, 255, 255, 255),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color.fromARGB(30, 255, 255, 255),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Slider(
                  min: 5,
                  max: 180,
                  divisions: 35,
                  value: _jumpSeconds.toDouble(),
                  onChanged: (v) => setState(() => _jumpSeconds = v.round()),
                  activeColor: const Color.fromARGB(255, 255, 128, 128),
                  inactiveColor: const Color.fromARGB(70, 255, 255, 255),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => setState(() => _jumpSeconds = (_jumpSeconds + 5).clamp(5, 180)),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(24, 255, 255, 255),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color.fromARGB(30, 255, 255, 255),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '跳过时长  $_jumpSeconds 秒',
            style: const TextStyle(
              color: Color.fromARGB(200, 255, 255, 255),
              fontSize: 13,
              height: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () async {
              final c = widget.controllerListenable.value;
              if (c == null) return;
              await _seekBy(c, _jumpSeconds);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 128, 128),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '立即快进  $_jumpSeconds 秒',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_panel == _SidePanel.speed) {
      final c = widget.controllerListenable.value;
      const speeds = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
      final current = c?.value.playbackSpeed ?? 1.0;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header('倍速'),
          const SizedBox(height: 12),
          ...speeds.map((s) {
            final active = s == current;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () async {
                  final c2 = widget.controllerListenable.value;
                  if (c2 == null) return;
                  await c2.setPlaybackSpeed(s);
                  if (mounted) setState(() {});
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color.fromARGB(40, 255, 128, 128)
                        : const Color.fromARGB(24, 255, 255, 255),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active
                          ? const Color.fromARGB(255, 255, 128, 128)
                          : const Color.fromARGB(30, 255, 255, 255),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${s}x',
                    style: TextStyle(
                      color: active
                          ? const Color.fromARGB(255, 255, 160, 160)
                          : const Color.fromARGB(220, 255, 255, 255),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    } else if (_panel == _SidePanel.aspect) {
      Widget chip(_AspectMode mode, String label) {
        final active = _aspectMode == mode;
        return InkWell(
          onTap: () => setState(() => _aspectMode = mode),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? const Color.fromARGB(40, 255, 128, 128)
                  : const Color.fromARGB(24, 255, 255, 255),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? const Color.fromARGB(255, 255, 128, 128)
                    : const Color.fromARGB(30, 255, 255, 255),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color.fromARGB(255, 255, 160, 160)
                    : const Color.fromARGB(200, 255, 255, 255),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        );
      }

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header('画面比例'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              chip(_AspectMode.fit, '适应'),
              chip(_AspectMode.fill, '填充'),
              chip(_AspectMode.stretch, '拉伸'),
              chip(_AspectMode.r16_9, '16:9'),
              chip(_AspectMode.r4_3, '4:3'),
              chip(_AspectMode.r21_9, '21:9'),
            ],
          ),
        ],
      );
    } else if (_panel == _SidePanel.lines) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header('换源'),
          const SizedBox(height: 12),
          ...List.generate(widget.lines.length, (i) {
            final active = i == _lineIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _selectLine(i),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 48,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color.fromARGB(40, 255, 128, 128)
                        : const Color.fromARGB(24, 255, 255, 255),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active
                          ? const Color.fromARGB(255, 255, 128, 128)
                          : const Color.fromARGB(30, 255, 255, 255),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.lines[i].show,
                    style: TextStyle(
                      color: active
                          ? const Color.fromARGB(255, 255, 160, 160)
                          : const Color.fromARGB(220, 255, 255, 255),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    } else if (_panel == _SidePanel.episodes) {
      final urls = _episodes;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header('选集'),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              itemCount: urls.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.2,
              ),
              itemBuilder: (context, i) {
                final active = i == _episodeIndex;
                return InkWell(
                  onTap: () => _selectEpisode(i),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color.fromARGB(40, 255, 128, 128)
                          : const Color.fromARGB(18, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active
                            ? const Color.fromARGB(255, 255, 128, 128)
                            : const Color.fromARGB(30, 255, 255, 255),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      urls[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? const Color.fromARGB(255, 255, 160, 160)
                            : const Color.fromARGB(220, 255, 255, 255),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else if (_panel == _SidePanel.danmuSettings) {
      Widget areaChip(double frac, String label) {
        final active = _danmuAreaFraction == frac;
        return InkWell(
          onTap: () => setState(() => _danmuAreaFraction = frac),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? const Color.fromARGB(40, 255, 128, 128)
                  : const Color.fromARGB(24, 255, 255, 255),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? const Color.fromARGB(255, 255, 128, 128)
                    : const Color.fromARGB(30, 255, 255, 255),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color.fromARGB(255, 255, 160, 160)
                    : const Color.fromARGB(200, 255, 255, 255),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        );
      }

      Widget toggleItem({
        required bool value,
        required String label,
        required VoidCallback onTap,
      }) {
        final active = value;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? const Color.fromARGB(40, 255, 128, 128)
                  : const Color.fromARGB(24, 255, 255, 255),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? const Color.fromARGB(255, 255, 128, 128)
                    : const Color.fromARGB(30, 255, 255, 255),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color.fromARGB(255, 255, 160, 160)
                    : const Color.fromARGB(180, 255, 255, 255),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        );
      }

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header('弹幕设置'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: toggleItem(
                  value: _danmuEnabled,
                  label: _danmuEnabled ? '已开启' : '已关闭',
                  onTap: () {
                    setState(() => _danmuEnabled = !_danmuEnabled);
                    if (_danmuEnabled) {
                      _loadDanmu();
                    } else {
                      _danmuTicker?.cancel();
                      for (final d in _danmuActive) {
                        d.dispose();
                      }
                      _danmuActive.clear();
                      _danmuFired.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _danmuAreaFraction = 1.0;
                      _danmuFontScale = 1.0;
                      _danmuOpacity = 0.9;
                      _danmuHideScroll = false;
                      _danmuHideTop = false;
                      _danmuHideBottom = false;
                      _danmuHideColor = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(24, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromARGB(30, 255, 255, 255),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '恢复默认设置',
                      style: TextStyle(
                        color: Color.fromARGB(200, 255, 255, 255),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '显示区域',
            style: TextStyle(
              color: Color.fromARGB(160, 255, 255, 255),
              fontSize: 12,
              height: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              areaChip(1.0, '全屏'),
              areaChip(0.75, '3/4'),
              areaChip(0.5, '半屏'),
              areaChip(0.25, '1/4'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '字号大小',
                  style: TextStyle(
                    color: Color.fromARGB(160, 255, 255, 255),
                    fontSize: 12,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(_danmuFontScale * 100).round()}%',
                style: const TextStyle(
                  color: Color.fromARGB(160, 255, 255, 255),
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
            ],
          ),
          Slider(
            min: 0.6,
            max: 1.6,
            value: _danmuFontScale,
            onChanged: (v) => setState(() => _danmuFontScale = v),
            activeColor: const Color.fromARGB(255, 255, 128, 128),
            inactiveColor: const Color.fromARGB(70, 255, 255, 255),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '不透明度',
                  style: TextStyle(
                    color: Color.fromARGB(160, 255, 255, 255),
                    fontSize: 12,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(_danmuOpacity * 100).round()}%',
                style: const TextStyle(
                  color: Color.fromARGB(160, 255, 255, 255),
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
            ],
          ),
          Slider(
            min: 0.1,
            max: 1.0,
            value: _danmuOpacity,
            onChanged: (v) => setState(() => _danmuOpacity = v),
            activeColor: const Color.fromARGB(255, 255, 128, 128),
            inactiveColor: const Color.fromARGB(70, 255, 255, 255),
          ),
          const SizedBox(height: 10),
          const Text(
            '屏蔽弹幕类型',
            style: TextStyle(
              color: Color.fromARGB(160, 255, 255, 255),
              fontSize: 12,
              height: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              toggleItem(
                value: _danmuHideBottom,
                label: '屏蔽底部',
                onTap: () => setState(() => _danmuHideBottom = !_danmuHideBottom),
              ),
              toggleItem(
                value: _danmuHideTop,
                label: '屏蔽顶部',
                onTap: () => setState(() => _danmuHideTop = !_danmuHideTop),
              ),
              toggleItem(
                value: _danmuHideScroll,
                label: '屏蔽滚动',
                onTap: () => setState(() => _danmuHideScroll = !_danmuHideScroll),
              ),
              toggleItem(
                value: _danmuHideColor,
                label: '屏蔽彩色',
                onTap: () => setState(() => _danmuHideColor = !_danmuHideColor),
              ),
            ],
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header('Anime4K'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 120,
              color: const Color.fromARGB(24, 255, 255, 255),
              alignment: Alignment.center,
              child: const Text(
                'Anime4K 预览',
                style: TextStyle(
                  color: Color.fromARGB(160, 255, 255, 255),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '启用 Anime4K 实时超分辨率\n此功能对配置要求较高，且可能发热严重\n老旧设备启用后可能出现黑屏',
            style: TextStyle(
              color: Color.fromARGB(140, 255, 255, 255),
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() => _anime4kEnabled = !_anime4kEnabled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_anime4kEnabled ? 'Anime4K 已开启' : 'Anime4K 已关闭'),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _anime4kEnabled
                    ? const Color.fromARGB(255, 255, 128, 128)
                    : const Color.fromARGB(24, 255, 255, 255),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _anime4kEnabled
                      ? const Color.fromARGB(255, 255, 128, 128)
                      : const Color.fromARGB(30, 255, 255, 255),
                  width: 1,
                ),
              ),
              child: Text(
                _anime4kEnabled ? '关闭' : '开启',
                style: TextStyle(
                  color: _anime4kEnabled
                      ? Colors.white
                      : const Color.fromARGB(220, 255, 255, 255),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      right: _drawerOpen ? 0 : -320,
      top: 0,
      bottom: 0,
      width: 320,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              color: const Color.fromARGB(220, 28, 28, 28),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: body,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: widget.controllerListenable,
      builder: (context, c, _) {
        final value = c?.value;
        final position = value?.position ?? Duration.zero;
        final duration = value?.duration ?? Duration.zero;
        final playing = value?.isPlaying ?? false;
        final sliderMax = duration.inMilliseconds
            .toDouble()
            .clamp(1.0, double.infinity)
            .toDouble();
        final sliderValue =
            position.inMilliseconds.toDouble().clamp(0.0, sliderMax).toDouble();

        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () {
              if (_locked) return;
              if (_drawerOpen) {
                _closeDrawer();
                return;
              }
              setState(() => _controlsVisible = !_controlsVisible);
              if (_controlsVisible) _showControlsTemporarily();
            },
            onPanDown: (_) => _showControlsTemporarily(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: c == null ? const SizedBox.shrink() : _buildVideo(c),
                  ),
                ),
                if (c != null && _danmuEnabled)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          final regionH = h * _danmuAreaFraction;
                          final fontSize = 18.0 * _danmuFontScale;
                          final lineH = fontSize + 6;
                          final now = DateTime.now().millisecondsSinceEpoch;
                          final items = _danmuActive.toList(growable: false);
                          return Stack(
                            children: items.map((d) {
                              final elapsed = now - d.bornAtMs;
                              final progress = (elapsed / d.durationMs)
                                  .clamp(0.0, 1.0)
                                  .toDouble();
                              final textW =
                                  (d.text.length * (fontSize * 0.62)).clamp(
                                40.0,
                                w,
                              );
                              double x;
                              double y;
                              if (d.type == _DanmuType.scroll) {
                                x = w - progress * (w + textW);
                                final maxY =
                                    (regionH - lineH - 8).clamp(0.0, double.infinity);
                                y = maxY <= 0
                                    ? 12
                                    : 8 + ((d.lane * lineH) % maxY);
                              } else if (d.type == _DanmuType.top) {
                                x = (w - textW) / 2;
                                y = 12;
                              } else {
                                x = (w - textW) / 2;
                                y = (regionH - lineH - 12)
                                    .clamp(12.0, h - lineH - 12);
                              }
                              return Positioned(
                                left: x,
                                top: y,
                                child: Text(
                                  d.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: d.color,
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                    shadows: const [
                                      Shadow(
                                        color: Color.fromARGB(190, 0, 0, 0),
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                          );
                        },
                      ),
                    ),
                  ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_controlsVisible || _locked,
                child: AnimatedOpacity(
                  opacity: _controlsVisible && !_locked ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromARGB(140, 0, 0, 0),
                          Colors.transparent,
                          Color.fromARGB(160, 0, 0, 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!_locked)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: AnimatedOpacity(
                    opacity: _controlsVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RoundIconButton(
                            icon: Icons.skip_previous,
                            enabled: _hasPrev,
                            onTap: () => _selectEpisode(_episodeIndex - 1),
                          ),
                          const SizedBox(width: 18),
                          InkWell(
                            onTap: () async {
                              if (c == null) return;
                              if (playing) {
                                await c.pause();
                              } else {
                                await c.play();
                              }
                              if (mounted) setState(() {});
                              _showControlsTemporarily();
                            },
                            borderRadius: BorderRadius.circular(40),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(120, 0, 0, 0),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(60, 255, 255, 255),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          _RoundIconButton(
                            icon: Icons.skip_next,
                            enabled: _hasNext,
                            onTap: () => _selectEpisode(_episodeIndex + 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _locked = !_locked;
                        _controlsVisible = !_locked;
                      });
                      if (!_locked) _showControlsTemporarily();
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(120, 0, 0, 0),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color.fromARGB(60, 255, 255, 255),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _locked ? Icons.lock : Icons.lock_open,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!_locked)
              Positioned(
                left: 10,
                right: 10,
                top: 10,
                child: SafeArea(
                  bottom: false,
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: AnimatedOpacity(
                      opacity: _controlsVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(120, 0, 0, 0),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(60, 255, 255, 255),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${widget.title}${(_episodes.isNotEmpty && _episodeIndex < _episodes.length) ? '  ${_episodes[_episodeIndex].name}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                          ),
                          _MiniIconButton(icon: Icons.cast, onTap: widget.onCast),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!_locked)
              Positioned(
                left: 10,
                right: 10,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: AnimatedOpacity(
                      opacity: _controlsVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: const Color.fromARGB(120, 0, 0, 0),
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _openDanmuSendDialog,
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(18, 255, 255, 255),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color.fromARGB(30, 255, 255, 255),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.comment_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '发条弹幕参与一下吧',
                                        style: TextStyle(
                                          color: Color.fromARGB(220, 255, 255, 255),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    widget.formatDuration(position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 2.5,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        overlayShape: const RoundSliderOverlayShape(
                                          overlayRadius: 14,
                                        ),
                                      ),
                                      child: Slider(
                                        min: 0,
                                        max: sliderMax,
                                        value: sliderValue,
                                        onChangeStart: (_) {
                                          _scrubbing = true;
                                          _hideTimer?.cancel();
                                        },
                                        onChanged: (v) async {
                                          if (c == null) return;
                                          final target =
                                              Duration(milliseconds: v.round());
                                          await c.seekTo(target);
                                          if (mounted) setState(() {});
                                        },
                                        onChangeEnd: (_) {
                                          _scrubbing = false;
                                          _showControlsTemporarily();
                                        },
                                        activeColor:
                                            const Color.fromARGB(255, 255, 128, 128),
                                        inactiveColor:
                                            const Color.fromARGB(70, 255, 255, 255),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.formatDuration(duration),
                                    style: const TextStyle(
                                      color: Color.fromARGB(200, 255, 255, 255),
                                      fontSize: 12,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _MiniIconButton(
                                    icon: _danmuEnabled
                                        ? Icons.subtitles
                                        : Icons.subtitles_off,
                                    onTap: () {
                                      setState(() => _danmuEnabled = !_danmuEnabled);
                                      if (_danmuEnabled) {
                                        _loadDanmu();
                                      } else {
                                        _danmuTicker?.cancel();
                                        for (final d in _danmuActive) {
                                          d.dispose();
                                        }
                                        _danmuActive.clear();
                                        _danmuFired.clear();
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  _MiniIconButton(
                                    icon: Icons.tune,
                                    onTap: () => _openDrawer(_SidePanel.danmuSettings),
                                  ),
                                  const SizedBox(width: 10),
                                  _MiniTextButton(
                                    text: '${c?.value.playbackSpeed ?? 1.0}x',
                                    onTap: () => _openDrawer(_SidePanel.speed),
                                  ),
                                  const SizedBox(width: 10),
                                  _MiniTextButton(
                                    text: '选集',
                                    onTap: () => _openDrawer(_SidePanel.episodes),
                                  ),
                                  const SizedBox(width: 10),
                                  _MiniTextButton(
                                    text: '换源',
                                    onTap: () => _openDrawer(_SidePanel.lines),
                                  ),
                                  const SizedBox(width: 10),
                                  _MiniTextButton(
                                    text: _anime4kEnabled ? '4K' : '4K',
                                    onTap: () => _openDrawer(_SidePanel.anime4k),
                                  ),
                                  const SizedBox(width: 10),
                                  _MiniIconButton(
                                    icon: Icons.fullscreen_exit,
                                    onTap: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_drawerOpen)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(color: Colors.transparent),
                ),
              ),
            _buildDrawer(),
          ],
        ),
      ),
        );
      },
    );
  }
}

enum _SidePanel {
  menu,
  forward,
  aspect,
  speed,
  episodes,
  lines,
  danmuSettings,
  anime4k
}

enum _DanmuType { scroll, top, bottom }

class _ActiveDanmu {
  final String text;
  final Color color;
  final _DanmuType type;
  final int bornAtMs;
  final int durationMs;
  final int lane;

  _ActiveDanmu({
    required this.text,
    required this.color,
    required this.type,
    required this.bornAtMs,
    required this.durationMs,
    required this.lane,
  });

  bool isExpired(int nowMs) => nowMs - bornAtMs >= durationMs;

  void dispose() {}
}

class _DanmuSendPanel extends StatefulWidget {
  final TextEditingController controller;
  final String initialColor;
  final void Function(String color) onColorChanged;
  final Future<void> Function() onSend;

  const _DanmuSendPanel({
    required this.controller,
    required this.initialColor,
    required this.onColorChanged,
    required this.onSend,
  });

  @override
  State<_DanmuSendPanel> createState() => _DanmuSendPanelState();
}

class _DanmuSendPanelState extends State<_DanmuSendPanel> {
  late String _color;
  bool _sending = false;

  static const _colors = <String>[
    '#ffffff',
    '#ff3b30',
    '#ff9500',
    '#ffd60a',
    '#34c759',
    '#00c7be',
    '#0a84ff',
    '#bf5af2',
    '#ff2d55',
    '#a2845e',
    '#64d2ff',
  ];

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.controller.text.trim().isNotEmpty && !_sending;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _colors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final c = _colors[index];
              final active = c == _color;
              final color = Color(
                0xFF000000 | (int.tryParse(c.substring(1), radix: 16) ?? 0),
              );
              return InkWell(
                onTap: () {
                  setState(() => _color = c);
                  widget.onColorChanged(c);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: active
                          ? const Color.fromARGB(255, 255, 128, 128)
                          : const Color.fromARGB(60, 255, 255, 255),
                      width: active ? 2 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 44,
                  color: const Color.fromARGB(24, 255, 255, 255),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: widget.controller,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.1,
                    ),
                    decoration: const InputDecoration(
                      hintText: '发送一条友好的弹幕吧',
                      hintStyle: TextStyle(
                        color: Color.fromARGB(120, 255, 255, 255),
                        fontSize: 13,
                        height: 1.1,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: !canSend
                  ? null
                  : () async {
                      setState(() => _sending = true);
                      try {
                        await widget.onSend();
                      } finally {
                        if (mounted) setState(() => _sending = false);
                      }
                    },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 44,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: canSend
                      ? const Color.fromARGB(255, 255, 128, 128)
                      : const Color.fromARGB(40, 255, 255, 255),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: canSend
                        ? const Color.fromARGB(255, 255, 128, 128)
                        : const Color.fromARGB(30, 255, 255, 255),
                    width: 1,
                  ),
                ),
                child: Text(
                  _sending ? '发送中' : '发送',
                  style: TextStyle(
                    color: canSend
                        ? Colors.white
                        : const Color.fromARGB(120, 255, 255, 255),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _AspectMode {
  fit,
  fill,
  stretch,
  r16_9,
  r4_3,
  r21_9;

  String get label {
    switch (this) {
      case _AspectMode.fit:
        return '适应';
      case _AspectMode.fill:
        return '填充';
      case _AspectMode.stretch:
        return '拉伸';
      case _AspectMode.r16_9:
        return '16:9';
      case _AspectMode.r4_3:
        return '4:3';
      case _AspectMode.r21_9:
        return '21:9';
    }
  }

  double? get fixedAspectRatio {
    switch (this) {
      case _AspectMode.r16_9:
        return 16 / 9;
      case _AspectMode.r4_3:
        return 4 / 3;
      case _AspectMode.r21_9:
        return 21 / 9;
      default:
        return null;
    }
  }
}

class _VodDetailPageState extends State<VodDetailPage> {
  VodDetailData? _data;
  bool _loading = false;
  bool _parsing = false;
  int _lineIndex = 0;
  int _episodeIndex = 0;
  String? _playUrl;
  VideoPlayerController? _videoController;
  final ValueNotifier<VideoPlayerController?> _videoControllerListenable =
      ValueNotifier<VideoPlayerController?>(null);
  bool _videoReady = false;
  String? _videoError;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _scrubbing = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _videoController?.dispose();
    _videoControllerListenable.dispose();
    super.dispose();
  }

  void _showControlsTemporarily() {
    _hideTimer?.cancel();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    final c = _videoController;
    if (c == null) return;
    if (!c.value.isInitialized) return;
    if (!c.value.isPlaying) return;
    if (_scrubbing) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_scrubbing) return;
      setState(() => _controlsVisible = false);
    });
  }

  String _formatDuration(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
    return '${two(m)}:${two(s)}';
  }

  bool get _hasPrevEpisode {
    final urls = _currentLine?.urls ?? const <VodPlayUrl>[];
    return urls.isNotEmpty && _episodeIndex > 0;
  }

  bool get _hasNextEpisode {
    final urls = _currentLine?.urls ?? const <VodPlayUrl>[];
    return urls.isNotEmpty && _episodeIndex < urls.length - 1;
  }

  Future<void> _prevEpisode() async {
    if (!_hasPrevEpisode) return;
    setState(() {
      _episodeIndex -= 1;
      _playUrl = null;
      _videoError = null;
    });
    await _parseAndPlayCurrent();
  }

  Future<void> _nextEpisode() async {
    if (!_hasNextEpisode) return;
    setState(() {
      _episodeIndex += 1;
      _playUrl = null;
      _videoError = null;
    });
    await _parseAndPlayCurrent();
  }

  void _showCastTip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('暂不支持投屏')),
    );
  }

  void _showTodoTip(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openDanmuSheet() async {
    final urlPosition = _episodeIndex;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      isScrollControlled: true,
      builder: (context) {
        return _DanmuSheet(
          vodId: widget.vodId,
          urlPosition: urlPosition,
        );
      },
    );
  }

  Future<void> _openCommentSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      isScrollControlled: true,
      builder: (context) {
        return _CommentSheet(vodId: widget.vodId);
      },
    );
  }

  Future<void> _showSpeedSheet() async {
    final c = _videoController;
    if (c == null) return;
    const speeds = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '倍速',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: speeds.map((s) {
                    final active = s == _playbackSpeed;
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(s),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color.fromARGB(40, 255, 128, 128)
                              : const Color.fromARGB(24, 255, 255, 255),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? const Color.fromARGB(255, 255, 128, 128)
                                : const Color.fromARGB(40, 255, 255, 255),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          s == 1.0 ? '1.0x' : '${s}x',
                          style: TextStyle(
                            color: active
                                ? const Color.fromARGB(255, 255, 160, 160)
                                : const Color.fromARGB(200, 255, 255, 255),
                            fontSize: 14,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    _playbackSpeed = selected;
    await c.setPlaybackSpeed(selected);
    if (mounted) setState(() {});
  }

  Future<void> _showLineSheet() async {
    final lines = _data?.playLines ?? const <VodPlayLine>[];
    if (lines.isEmpty) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            itemCount: lines.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Text(
                  '换源',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }
              final i = index - 1;
              final active = i == _lineIndex;
              return InkWell(
                onTap: () => Navigator.of(context).pop(i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color.fromARGB(40, 255, 128, 128)
                        : const Color.fromARGB(24, 255, 255, 255),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? const Color.fromARGB(255, 255, 128, 128)
                          : const Color.fromARGB(40, 255, 255, 255),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    lines[i].show,
                    style: TextStyle(
                      color: active
                          ? const Color.fromARGB(255, 255, 160, 160)
                          : const Color.fromARGB(200, 255, 255, 255),
                      fontSize: 14,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    if (selected == null) return;
    if (selected == _lineIndex) return;
    setState(() {
      _lineIndex = selected;
      _episodeIndex = 0;
      _playUrl = null;
      _videoError = null;
    });
    await _parseAndPlayCurrent();
  }

  Future<void> _showEpisodeSheet() async {
    final urls = _currentLine?.urls ?? const <VodPlayUrl>[];
    if (urls.isEmpty) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选集',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: urls.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3.0,
                    ),
                    itemBuilder: (context, index) {
                      final active = index == _episodeIndex;
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(index),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active
                                ? const Color.fromARGB(40, 255, 128, 128)
                                : const Color.fromARGB(18, 255, 255, 255),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active
                                  ? const Color.fromARGB(255, 255, 128, 128)
                                  : const Color.fromARGB(30, 255, 255, 255),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            urls[index].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active
                                  ? const Color.fromARGB(255, 255, 160, 160)
                                  : const Color.fromARGB(
                                      200,
                                      255,
                                      255,
                                      255,
                                    ),
                              fontSize: 13,
                              height: 1.0,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    if (selected == _episodeIndex) return;
    setState(() {
      _episodeIndex = selected;
      _playUrl = null;
      _videoError = null;
    });
    await _parseAndPlayCurrent();
  }

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final data = await getVodDetailAPI(vodId: widget.vodId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _lineIndex = 0;
        _episodeIndex = 0;
        _playUrl = null;
        _videoError = null;
      });
      await _parseAndPlayCurrent();
    } catch (_) {
      if (!mounted) return;
      if (_data == null) {
        setState(() => _data = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载失败')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  VodPlayLine? get _currentLine {
    final lines = _data?.playLines ?? const <VodPlayLine>[];
    if (lines.isEmpty) return null;
    final idx = _lineIndex.clamp(0, lines.length - 1);
    return lines[idx];
  }

  VodPlayUrl? get _currentEpisode {
    final urls = _currentLine?.urls ?? const <VodPlayUrl>[];
    if (urls.isEmpty) return null;
    final idx = _episodeIndex.clamp(0, urls.length - 1);
    return urls[idx];
  }

  Future<void> _parseAndPlayCurrent() async {
    final line = _currentLine;
    final ep = _currentEpisode;
    if (line == null || ep == null) return;
    if (_parsing) return;
    setState(() => _parsing = true);
    try {
      VodParsedResult? resolved;
      try {
        resolved = await bfqParseAPI(pageUrl: ep.url);
      } catch (_) {}
      resolved ??= await vodParseAPI(
        url: ep.url,
        parseApi: line.parseApi,
        token: ep.token,
      );
      if (!mounted) return;
      if (resolved == null || resolved.url.isEmpty) {
        setState(() {
          _playUrl = null;
          _videoError = '解析失败';
        });
        return;
      }
      _playUrl = resolved.url;
      _videoReady = false;
      _videoError = null;
      _videoControllerListenable.value = null;
      await _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(resolved.url),
        httpHeaders: resolved.headers,
      );
      _videoControllerListenable.value = _videoController;
      await _videoController!.initialize();
      await _videoController!.setPlaybackSpeed(_playbackSpeed);
      _videoController!.addListener(() {
        final c = _videoController;
        if (!mounted || c == null) return;
        if (_controlsVisible) {
          setState(() {});
        }
        if (c.value.hasError) {
          final err = c.value.errorDescription ?? '播放失败';
          if (_videoError != err) setState(() => _videoError = err);
        }
      });
      await _videoController!.play();
      if (!mounted) return;
      setState(() {
        _videoReady = true;
        _controlsVisible = true;
      });
      _showControlsTemporarily();
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  Future<void> _enterFullscreen() async {
    final c = _videoController;
    final vod = _data?.vod;
    if (c == null || vod == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenPlayerPage(
          vodId: widget.vodId,
          title: vod.name,
          episodeName: _currentEpisode?.name ?? '',
          onCast: _showCastTip,
          formatDuration: _formatDuration,
          controllerListenable: _videoControllerListenable,
          lines: _data?.playLines ?? const <VodPlayLine>[],
          initialLineIndex: _lineIndex,
          initialEpisodeIndex: _episodeIndex,
          onSelectLine: (lineIndex) async {
            if (!mounted) return;
            setState(() {
              _lineIndex = lineIndex;
              _episodeIndex = 0;
              _playUrl = null;
              _videoError = null;
            });
            await _parseAndPlayCurrent();
          },
          onSelectEpisode: (episodeIndex) async {
            if (!mounted) return;
            setState(() {
              _episodeIndex = episodeIndex;
              _playUrl = null;
              _videoError = null;
            });
            await _parseAndPlayCurrent();
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _buildPlayerHeader(VodInfo vod) {
    final c = _videoController;
    final value = c?.value;
    final position = value?.position ?? Duration.zero;
    final duration = value?.duration ?? Duration.zero;
    final playing = value?.isPlaying ?? false;
    final canPlay = c != null && _videoReady && value?.isInitialized == true;
    final sliderMax = duration.inMilliseconds
        .toDouble()
        .clamp(1.0, double.infinity)
        .toDouble();
    final sliderValue = _scrubbing
        ? position.inMilliseconds.toDouble().clamp(0.0, sliderMax).toDouble()
        : position.inMilliseconds.toDouble().clamp(0.0, sliderMax).toDouble();

    Widget videoChild;
    if (canPlay) {
      videoChild = GestureDetector(
        onTap: () {
          setState(() => _controlsVisible = !_controlsVisible);
          if (_controlsVisible) _showControlsTemporarily();
        },
        onPanDown: (_) => _showControlsTemporarily(),
        child: Stack(
          children: [
            Positioned.fill(child: VideoPlayer(c)),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromARGB(120, 0, 0, 0),
                          Colors.transparent,
                          Color.fromARGB(160, 0, 0, 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_videoError != null)
              Positioned.fill(
                child: Container(
                  color: const Color.fromARGB(90, 0, 0, 0),
                  alignment: Alignment.center,
                  child: InkWell(
                    onTap: _parseAndPlayCurrent,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(120, 0, 0, 0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color.fromARGB(60, 255, 255, 255),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '播放失败，点击重试',
                            style: TextStyle(
                              color: Color.fromARGB(200, 255, 255, 255),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _videoError!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color.fromARGB(140, 255, 255, 255),
                              fontSize: 12,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_parsing)
              const Positioned.fill(
                child: Center(child: LoadingGif(size: 56)),
              ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_controlsVisible || _videoError != null,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RoundIconButton(
                          icon: Icons.skip_previous,
                          enabled: _hasPrevEpisode,
                          onTap: _prevEpisode,
                        ),
                        const SizedBox(width: 18),
                        InkWell(
                          onTap: () async {
                            if (_videoError != null) return;
                            if (playing) {
                              await c.pause();
                            } else {
                              await c.play();
                            }
                            if (mounted) setState(() {});
                            _showControlsTemporarily();
                          },
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(120, 0, 0, 0),
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                color: const Color.fromARGB(60, 255, 255, 255),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        _RoundIconButton(
                          icon: Icons.skip_next,
                          enabled: _hasNextEpisode,
                          onTap: _nextEpisode,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: IgnorePointer(
                ignoring: !_controlsVisible || _videoError != null,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color.fromARGB(130, 0, 0, 0),
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2.5,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: sliderMax,
                                    value: sliderValue,
                                    onChangeStart: (_) {
                                      _scrubbing = true;
                                      _hideTimer?.cancel();
                                      if (!_controlsVisible) {
                                        setState(() => _controlsVisible = true);
                                      }
                                    },
                                    onChanged: (v) async {
                                      if (c.value.duration == Duration.zero) return;
                                      final target =
                                          Duration(milliseconds: v.round());
                                      await c.seekTo(target);
                                      if (mounted) setState(() {});
                                    },
                                    onChangeEnd: (_) {
                                      _scrubbing = false;
                                      _showControlsTemporarily();
                                    },
                                    activeColor:
                                        const Color.fromARGB(255, 255, 128, 128),
                                    inactiveColor:
                                        const Color.fromARGB(70, 255, 255, 255),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  color: Color.fromARGB(200, 255, 255, 255),
                                  fontSize: 12,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _MiniTextButton(
                                text: '${_playbackSpeed}x',
                                onTap: _showSpeedSheet,
                              ),
                              const SizedBox(width: 10),
                              _MiniIconButton(
                                icon: Icons.cast,
                                onTap: _showCastTip,
                              ),
                              const SizedBox(width: 10),
                              _MiniTextButton(
                                text: '选集',
                                onTap: _showEpisodeSheet,
                              ),
                              const SizedBox(width: 10),
                              _MiniTextButton(
                                text: '换源',
                                onTap: _showLineSheet,
                              ),
                              const Spacer(),
                              _MiniIconButton(
                                icon: Icons.fullscreen,
                                onTap: _enterFullscreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(120, 0, 0, 0),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    const Color.fromARGB(40, 255, 255, 255),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            '${vod.name}${_currentEpisode?.name.isNotEmpty == true ? '  ${_currentEpisode!.name}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      videoChild = Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              vod.pic,
              fit: BoxFit.cover,
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
                  color: const Color.fromARGB(24, 255, 255, 255),
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
          Positioned.fill(
            child: Container(
              color: const Color.fromARGB(60, 0, 0, 0),
              alignment: Alignment.center,
              child: InkWell(
                onTap: _parseAndPlayCurrent,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(140, 0, 0, 0),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color.fromARGB(60, 255, 255, 255),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          if (_parsing)
            const Positioned.fill(
              child: Center(child: LoadingGif(size: 56)),
            ),
          Positioned(
            left: 10,
            top: 10,
            child: SafeArea(
              bottom: false,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(120, 0, 0, 0),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color.fromARGB(40, 255, 255, 255),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: AnimatedBuilder(
        animation: _videoController ?? Listenable.merge(const []),
        builder: (context, _) {
          return videoChild;
        },
      ),
    );
  }

  Widget _buildMeta(VodInfo vod) {
    final metaParts = <String>[
      if (vod.year.isNotEmpty) vod.year,
      if (vod.area.isNotEmpty) vod.area,
      if (vod.lang.isNotEmpty) vod.lang,
    ];
    final meta = metaParts.join(' | ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta.isNotEmpty)
            Text(
              meta,
              style: const TextStyle(
                color: Color.fromARGB(160, 255, 255, 255),
                fontSize: 13,
                height: 1.2,
              ),
            ),
          if (vod.remarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                vod.remarks,
                style: const TextStyle(
                  color: Color.fromARGB(120, 255, 255, 255),
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
          if (vod.blurb.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                vod.blurb,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color.fromARGB(160, 255, 255, 255),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    Widget item({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: const Color.fromARGB(180, 255, 255, 255),
                  size: 22,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color.fromARGB(160, 255, 255, 255),
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: const Color.fromARGB(24, 255, 255, 255),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              item(
                icon: Icons.swap_horiz,
                label: '换源',
                onTap: () => _showLineSheet(),
              ),
              item(
                icon: Icons.download_outlined,
                label: '缓存',
                onTap: () => _showTodoTip('暂未实现缓存'),
              ),
              item(
                icon: Icons.favorite_border,
                label: '追番',
                onTap: () => _showTodoTip('暂未实现追番'),
              ),
              item(
                icon: Icons.subtitles_outlined,
                label: '弹幕',
                onTap: _openDanmuSheet,
              ),
              item(
                icon: Icons.comment_outlined,
                label: '评论',
                onTap: _openCommentSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLines(List<VodPlayLine> lines) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        scrollDirection: Axis.horizontal,
        itemCount: lines.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final active = index == _lineIndex;
          return InkWell(
            onTap: () {
              setState(() {
                _lineIndex = index;
                _episodeIndex = 0;
                _playUrl = null;
              });
              _parseAndPlayCurrent();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? const Color.fromARGB(40, 255, 128, 128)
                    : const Color.fromARGB(24, 255, 255, 255),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? const Color.fromARGB(255, 255, 128, 128)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                lines[index].show,
                style: TextStyle(
                  color: active
                      ? const Color.fromARGB(255, 255, 160, 160)
                      : const Color.fromARGB(160, 255, 255, 255),
                  fontSize: 13,
                  height: 1.0,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodes(List<VodPlayUrl> urls) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: urls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.1,
        ),
        itemBuilder: (context, index) {
          final active = index == _episodeIndex;
          return InkWell(
            onTap: () {
              setState(() {
                _episodeIndex = index;
                _playUrl = null;
              });
              _parseAndPlayCurrent();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? const Color.fromARGB(40, 255, 128, 128)
                    : const Color.fromARGB(18, 255, 255, 255),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? const Color.fromARGB(255, 255, 128, 128)
                      : const Color.fromARGB(30, 255, 255, 255),
                  width: 1,
                ),
              ),
              child: Text(
                urls[index].name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active
                      ? const Color.fromARGB(255, 255, 160, 160)
                      : const Color.fromARGB(160, 255, 255, 255),
                  fontSize: 13,
                  height: 1.0,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: SafeArea(
        bottom: false,
        child: data == null
            ? ListView(
                padding: EdgeInsets.zero,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            alignment: Alignment.center,
                            child: _loading
                                ? const LoadingGif(size: 64)
                                : InkWell(
                                    onTap: _fetch,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            24, 255, 255, 255),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                              40, 255, 255, 255),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '加载失败，点击重试',
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                              160, 255, 255, 255),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: SafeArea(
                            bottom: false,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(120, 0, 0, 0),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                        40, 255, 255, 255),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              )
            : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildPlayerHeader(data.vod),
                    _buildMeta(data.vod),
                    _buildActions(),
                    const SizedBox(height: 14),
                    if (data.playLines.isNotEmpty) _buildLines(data.playLines),
                    if ((_currentLine?.urls ?? const <VodPlayUrl>[]).isNotEmpty)
                      _buildEpisodes(_currentLine!.urls),
                    if (_playUrl != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
                        child: Text(
                          _playUrl!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color.fromARGB(90, 255, 255, 255),
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DanmuSheet extends StatefulWidget {
  final int vodId;
  final int urlPosition;

  const _DanmuSheet({required this.vodId, required this.urlPosition});

  @override
  State<_DanmuSheet> createState() => _DanmuSheetState();
}

class _DanmuSheetState extends State<_DanmuSheet> {
  bool _loading = true;
  String? _error;
  List<dynamic> _list = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getDanmuListAPI(
        vodId: widget.vodId,
        urlPosition: widget.urlPosition,
      );
      final list = data['danmu_list'];
      setState(() {
        _list = list is List ? list : const [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '弹幕',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _fetch,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        '刷新',
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
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_loading) {
                      return const Center(child: LoadingGif(size: 56));
                    }
                    if (_error != null) {
                      return const Center(
                        child: Text(
                          '加载失败',
                          style: TextStyle(
                            color: Color.fromARGB(160, 255, 255, 255),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    if (_list.isEmpty) {
                      return const Center(
                        child: Text(
                          '暂无弹幕',
                          style: TextStyle(
                            color: Color.fromARGB(160, 255, 255, 255),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: _list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _list[index];
                        if (item is! Map) {
                          return const SizedBox.shrink();
                        }
                        final m = item.cast<String, dynamic>();
                        final text = (m['text'] ?? '').toString();
                        final time = (m['time'] ?? '').toString();
                        final position = (m['position'] ?? '').toString();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(18, 255, 255, 255),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color.fromARGB(30, 255, 255, 255),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(24, 255, 255, 255),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  time.isEmpty ? '--' : time,
                                  style: const TextStyle(
                                    color:
                                        Color.fromARGB(200, 255, 255, 255),
                                    fontSize: 12,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    color: Color.fromARGB(220, 255, 255, 255),
                                    fontSize: 13,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              if (position.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    position,
                                    style: const TextStyle(
                                      color: Color.fromARGB(
                                          120, 255, 255, 255),
                                      fontSize: 12,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  final int vodId;

  const _CommentSheet({required this.vodId});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  bool _loading = true;
  bool _moreLoading = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  List<Map<String, dynamic>> _comments = const [];
  Map<String, dynamic>? _official;

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  Future<void> _fetch({required bool reset}) async {
    if (_loading || _moreLoading) return;
    if (!reset && !_hasMore) return;
    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      } else {
        _moreLoading = true;
      }
    });
    try {
      final data = await getCommentListAPI(vodId: widget.vodId, page: _page);
      final list = data['comment_list'];
      final official = data['official_comment'];
      final items = list is List
          ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
          : <Map<String, dynamic>>[];
      setState(() {
        if (reset) {
          _comments = items;
        } else {
          _comments = [..._comments, ...items];
        }
        _official = official is Map ? official.cast<String, dynamic>() : null;
        _hasMore = items.isNotEmpty;
        if (_hasMore) _page += 1;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _loading = false;
        _moreLoading = false;
      });
    }
  }

  Widget _buildCommentItem(Map<String, dynamic> m, {required bool official}) {
    final user = (m['user_name'] ?? (official ? '官方' : '')).toString();
    final content = (m['comment'] ?? m['comment_content'] ?? '').toString();
    final time = (m['create_time'] ?? '').toString();
    final child = (m['child_comment_content'] ?? '').toString();
    final childUser = (m['child_user_name'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(18, 255, 255, 255),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromARGB(30, 255, 255, 255),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  user,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: official
                        ? const Color.fromARGB(255, 255, 160, 160)
                        : const Color.fromARGB(220, 255, 255, 255),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
              if (time.isNotEmpty)
                Text(
                  time,
                  style: const TextStyle(
                    color: Color.fromARGB(120, 255, 255, 255),
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Color.fromARGB(220, 255, 255, 255),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (child.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: const Color.fromARGB(20, 0, 0, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Text(
                    childUser.isEmpty ? child : '$childUser：$child',
                    style: const TextStyle(
                      color: Color.fromARGB(170, 255, 255, 255),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '评论',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _fetch(reset: true),
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        '刷新',
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
              Expanded(
                child: _loading
                    ? const Center(child: LoadingGif(size: 56))
                    : (_error != null
                        ? const Center(
                            child: Text(
                              '加载失败',
                              style: TextStyle(
                                color: Color.fromARGB(160, 255, 255, 255),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : (_official == null && _comments.isEmpty
                            ? const Center(
                                child: Text(
                                  '暂无评论',
                                  style: TextStyle(
                                    color: Color.fromARGB(160, 255, 255, 255),
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : NotificationListener<ScrollNotification>(
                                onNotification: (n) {
                                  if (n.metrics.pixels >=
                                          n.metrics.maxScrollExtent - 120 &&
                                      !_moreLoading &&
                                      _hasMore) {
                                    _fetch(reset: false);
                                  }
                                  return false;
                                },
                                child: ListView(
                                  children: [
                                    if (_official != null)
                                      _buildCommentItem(
                                        _official!,
                                        official: true,
                                      ),
                                    if (_official != null)
                                      const SizedBox(height: 10),
                                    ..._comments.map((m) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: _buildCommentItem(
                                          m,
                                          official: false,
                                        ),
                                      );
                                    }),
                                    if (_moreLoading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Center(
                                          child: LoadingGif(size: 40),
                                        ),
                                      ),
                                    if (!_hasMore && _comments.isNotEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '没有更多了',
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  120, 255, 255, 255),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

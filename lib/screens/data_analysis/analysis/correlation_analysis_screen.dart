import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/analysis_data_provider.dart';
import 'package:serial_lab/services/analysis/correlation_service.dart';

class CorrelationAnalysisScreen extends StatefulWidget {
  const CorrelationAnalysisScreen({super.key});

  @override
  State<CorrelationAnalysisScreen> createState() => _CorrelationAnalysisScreenState();
}

class _CorrelationAnalysisScreenState extends State<CorrelationAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 1:1 상세 탭 상태
  String? _xSeries;
  String? _ySeries;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisDataProvider>(
      builder: (context, analysisData, _) {
        final keys = analysisData.chartData.keys.toList();

        if (keys.length < 2) {
          return const Center(
            child: Text('Need at least 2 numeric series to compute correlation.'),
          );
        }

        _xSeries ??= keys.first;
        _ySeries ??= keys.length > 1 ? keys[1] : keys.first;
        if (!analysisData.chartData.containsKey(_xSeries)) _xSeries = keys.first;
        if (!analysisData.chartData.containsKey(_ySeries)) {
          _ySeries = keys.length > 1 ? keys[1] : keys.first;
        }

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on), text: 'Heatmap'),
                Tab(icon: Icon(Icons.compare_arrows), text: 'Pair Detail'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _HeatmapView(
                    keys: keys,
                    chartData: analysisData.chartData,
                  ),
                  _PairDetailView(
                    keys: keys,
                    chartData: analysisData.chartData,
                    xSeries: _xSeries!,
                    ySeries: _ySeries!,
                    onXChanged: (v) => setState(() => _xSeries = v),
                    onYChanged: (v) => setState(() => _ySeries = v),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── 히트맵 뷰 ───────────────────────────────────────────────

class _HeatmapView extends StatelessWidget {
  final List<String> keys;
  final Map<String, dynamic> chartData;

  const _HeatmapView({required this.keys, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final matrix = CorrelationService.correlationMatrix(
      Map.from(chartData),
    );
    final n = keys.length;
    // 레이블 최대 길이 추정용 (셀 크기 결정)
    const cellSize = 56.0;
    const labelWidth = 90.0;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 상단 컬럼 레이블
            Row(
              children: [
                const SizedBox(width: labelWidth), // 왼쪽 행 레이블 공간
                ...List.generate(n, (j) {
                  return SizedBox(
                    width: cellSize,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          keys[j],
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 4),
            // 행 레이블 + 셀
            ...List.generate(n, (i) {
              return Row(
                children: [
                  // 행 레이블
                  SizedBox(
                    width: labelWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        keys[i],
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  // 셀들
                  ...List.generate(n, (j) {
                    final val = matrix[i][j];
                    return _HeatmapCell(
                      value: val,
                      size: cellSize,
                    );
                  }),
                ],
              );
            }),
            const SizedBox(height: 20),
            // 범례
            _ColorLegend(),
          ],
        ),
      ),
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final double? value;
  final double size;

  const _HeatmapCell({required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    final v = value;
    final bg = v == null ? Colors.grey.shade200 : _heatColor(v);
    final fg = v == null
        ? Colors.grey
        : (bg.computeLuminance() > 0.4 ? Colors.black87 : Colors.white);

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(1.5),
      color: bg,
      alignment: Alignment.center,
      child: Text(
        v == null ? '–' : v.toStringAsFixed(2),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  static Color _heatColor(double v) {
    // -1 → 진한 파랑, 0 → 흰색, +1 → 진한 빨강
    v = v.clamp(-1.0, 1.0);
    if (v >= 0) {
      return Color.lerp(Colors.white, const Color(0xFFB71C1C), v)!;
    } else {
      return Color.lerp(Colors.white, const Color(0xFF0D47A1), -v)!;
    }
  }
}

class _ColorLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('-1', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Container(
          width: 160,
          height: 12,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Colors.white, Color(0xFFB71C1C)],
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text('+1', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 16),
        _legendDot(Colors.blue.shade800, 'Negative'),
        const SizedBox(width: 8),
        _legendDot(Colors.white, 'None'),
        const SizedBox(width: 8),
        _legendDot(Colors.red.shade800, 'Positive'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ─── 1:1 상세 뷰 ─────────────────────────────────────────────

class _PairDetailView extends StatelessWidget {
  final List<String> keys;
  final Map<String, dynamic> chartData;
  final String xSeries;
  final String ySeries;
  final ValueChanged<String?> onXChanged;
  final ValueChanged<String?> onYChanged;

  const _PairDetailView({
    required this.keys,
    required this.chartData,
    required this.xSeries,
    required this.ySeries,
    required this.onXChanged,
    required this.onYChanged,
  });

  @override
  Widget build(BuildContext context) {
    final result = CorrelationService.pearson(
      xSeries, chartData[xSeries]!,
      ySeries, chartData[ySeries]!,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 56, child: Text('X')),
                  Expanded(child: _buildDropdown(context, keys, xSeries, onXChanged)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 56, child: Text('Y')),
                  Expanded(child: _buildDropdown(context, keys, ySeries, onYChanged)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: result == null
                ? const Text(
                    'Unable to calculate\n(need aligned timestamps and enough points).',
                    textAlign: TextAlign.center,
                  )
                : _ResultCard(result: result),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    List<String> keys,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButton<String>(
      value: selected,
      isExpanded: true,
      items: keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
      onChanged: onChanged,
    );
  }
}

class _ResultCard extends StatelessWidget {
  final CorrelationResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final c = result.coefficient;
    final color = _corrColor(c);
    return Card(
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${result.seriesX}  ↔  ${result.seriesY}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Pearson Correlation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            // 시각적 게이지
            _CorrelationGauge(value: c),
            const SizedBox(height: 16),
            Text(
              c.toStringAsFixed(4),
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 8),
            Text('Pairs used: ${result.pairCount}'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _corrLabel(c),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get ySeries => result.seriesY;

  String _corrLabel(double c) {
    final ac = c.abs();
    if (ac >= 0.8) return c > 0 ? 'Strong positive' : 'Strong negative';
    if (ac >= 0.5) return c > 0 ? 'Moderate positive' : 'Moderate negative';
    if (ac >= 0.3) return c > 0 ? 'Weak positive' : 'Weak negative';
    return 'Very weak / no correlation';
  }

  Color _corrColor(double c) {
    if (c > 0.5) return Colors.red.shade700;
    if (c < -0.5) return Colors.blue.shade700;
    return Colors.blueGrey;
  }
}

/// -1 ~ +1 상관계수를 선형 게이지로 표시
class _CorrelationGauge extends StatelessWidget {
  final double value;
  const _CorrelationGauge({required this.value});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(-1.0, 1.0);
    // 0이 중간, clamped 위치에 포인터
    final fraction = (clamped + 1) / 2; // 0~1 범위

    return SizedBox(
      height: 28,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // 배경 그라디언트 바
            Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Colors.white, Color(0xFFB71C1C)],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // 중앙 구분선
            Positioned(
              left: width / 2 - 0.5,
              child: Container(width: 1, height: 14, color: Colors.grey.shade500),
            ),
            // 포인터
            Positioned(
              left: (width * fraction - 6).clamp(0, width - 12),
              child: const Icon(Icons.arrow_drop_down, size: 22, color: Colors.black87),
            ),
          ],
        );
      }),
    );
  }
}


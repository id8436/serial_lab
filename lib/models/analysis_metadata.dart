import 'package:flutter/foundation.dart';

enum AnalysisErrorValueMode {
  none,
  fixedAbsolute,
  percentage,
}

@immutable
class AnalysisErrorBarConfig {
  final bool enabled;
  final AnalysisErrorValueMode xMode;
  final AnalysisErrorValueMode yMode;
  final double xValue;
  final double yValue;

  const AnalysisErrorBarConfig({
    this.enabled = false,
    this.xMode = AnalysisErrorValueMode.none,
    this.yMode = AnalysisErrorValueMode.none,
    this.xValue = 0,
    this.yValue = 0,
  });

  static const disabled = AnalysisErrorBarConfig();

  AnalysisErrorBarConfig copyWith({
    bool? enabled,
    AnalysisErrorValueMode? xMode,
    AnalysisErrorValueMode? yMode,
    double? xValue,
    double? yValue,
  }) {
    return AnalysisErrorBarConfig(
      enabled: enabled ?? this.enabled,
      xMode: xMode ?? this.xMode,
      yMode: yMode ?? this.yMode,
      xValue: xValue ?? this.xValue,
      yValue: yValue ?? this.yValue,
    );
  }
}

@immutable
class AnalysisSeriesMetadata {
  final String? unit;
  final String? note;
  final AnalysisErrorBarConfig errorBars;

  const AnalysisSeriesMetadata({
    this.unit,
    this.note,
    this.errorBars = AnalysisErrorBarConfig.disabled,
  });

  static const empty = AnalysisSeriesMetadata();

  AnalysisSeriesMetadata copyWith({
    String? unit,
    bool clearUnit = false,
    String? note,
    bool clearNote = false,
    AnalysisErrorBarConfig? errorBars,
  }) {
    return AnalysisSeriesMetadata(
      unit: clearUnit ? null : (unit ?? this.unit),
      note: clearNote ? null : (note ?? this.note),
      errorBars: errorBars ?? this.errorBars,
    );
  }
}
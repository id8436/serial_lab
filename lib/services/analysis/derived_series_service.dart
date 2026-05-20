import 'package:serial_lab/models/chart_data.dart';

enum DerivedSeriesMode {
  raw,
  derivative,
  integral,
}

enum BinarySeriesOperation {
  none,
  add,
  subtract,
  multiply,
  divide,
}

class DerivedSeriesService {
  const DerivedSeriesService._();

  static const double _kDivisionEpsilon = 1e-12;

  static ChartSeries buildSeries(
    ChartSeries source,
    DerivedSeriesMode mode,
  ) {
    return switch (mode) {
      DerivedSeriesMode.raw => ChartSeries(
          name: source.name,
          dataPoints: List<ChartDataPoint>.from(source.dataPoints),
        ),
      DerivedSeriesMode.derivative => _derivative(source),
      DerivedSeriesMode.integral => _integral(source),
    };
  }

  static ChartSeries _derivative(ChartSeries source) {
    final sourcePoints = source.dataPoints;
    if (sourcePoints.isEmpty) {
      return ChartSeries(name: '${source.name}_d_dt');
    }

    final derived = <ChartDataPoint>[];
    derived.add(
      ChartDataPoint(
        time: sourcePoints.first.time,
        value: 0,
        label: sourcePoints.first.label,
      ),
    );

    for (var i = 1; i < sourcePoints.length; i++) {
      final current = sourcePoints[i];
      final previous = sourcePoints[i - 1];
      final dtMs = current.time.millisecondsSinceEpoch - previous.time.millisecondsSinceEpoch;
      final dt = dtMs / 1000;
      final slope = dt <= 0 ? 0.0 : (current.value - previous.value) / dt;
      derived.add(
        ChartDataPoint(
          time: current.time,
          value: slope,
          label: current.label,
        ),
      );
    }

    return ChartSeries(
      name: '${source.name}_d_dt',
      dataPoints: derived,
    );
  }

  static ChartSeries _integral(ChartSeries source) {
    final sourcePoints = source.dataPoints;
    if (sourcePoints.isEmpty) {
      return ChartSeries(name: '${source.name}_integral');
    }

    final derived = <ChartDataPoint>[];
    var accumulated = 0.0;
    derived.add(
      ChartDataPoint(
        time: sourcePoints.first.time,
        value: accumulated,
        label: sourcePoints.first.label,
      ),
    );

    for (var i = 1; i < sourcePoints.length; i++) {
      final current = sourcePoints[i];
      final previous = sourcePoints[i - 1];
      final dtMs = current.time.millisecondsSinceEpoch - previous.time.millisecondsSinceEpoch;
      final dt = dtMs / 1000;
      if (dt > 0) {
        accumulated += ((previous.value + current.value) / 2) * dt;
      }
      derived.add(
        ChartDataPoint(
          time: current.time,
          value: accumulated,
          label: current.label,
        ),
      );
    }

    return ChartSeries(
      name: '${source.name}_integral',
      dataPoints: derived,
    );
  }

  static ChartSeries applyBinaryOperation(
    ChartSeries primary,
    ChartSeries secondary,
    BinarySeriesOperation operation,
  ) {
    if (operation == BinarySeriesOperation.none) {
      return ChartSeries(
        name: primary.name,
        dataPoints: List<ChartDataPoint>.from(primary.dataPoints),
      );
    }

    final length = primary.dataPoints.length < secondary.dataPoints.length
        ? primary.dataPoints.length
        : secondary.dataPoints.length;
    if (length <= 0) {
      return ChartSeries(name: '${primary.name}_${_operationSuffix(operation)}_${secondary.name}');
    }

    final resultPoints = <ChartDataPoint>[];
    for (var i = 0; i < length; i++) {
      final left = primary.dataPoints[i];
      final right = secondary.dataPoints[i];
      resultPoints.add(
        ChartDataPoint(
          time: left.time,
          value: _operate(left.value, right.value, operation),
          label: left.label,
        ),
      );
    }

    return ChartSeries(
      name: '${primary.name}_${_operationSuffix(operation)}_${secondary.name}',
      dataPoints: resultPoints,
    );
  }

  static double _operate(double left, double right, BinarySeriesOperation operation) {
    return switch (operation) {
      BinarySeriesOperation.none => left,
      BinarySeriesOperation.add => left + right,
      BinarySeriesOperation.subtract => left - right,
      BinarySeriesOperation.multiply => left * right,
      BinarySeriesOperation.divide => right.abs() <= _kDivisionEpsilon ? 0 : left / right,
    };
  }

  static String _operationSuffix(BinarySeriesOperation operation) {
    return switch (operation) {
      BinarySeriesOperation.none => 'raw',
      BinarySeriesOperation.add => 'plus',
      BinarySeriesOperation.subtract => 'minus',
      BinarySeriesOperation.multiply => 'mul',
      BinarySeriesOperation.divide => 'div',
    };
  }
}
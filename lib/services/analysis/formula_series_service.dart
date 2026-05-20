import 'dart:math' as math;

import 'package:serial_lab/models/chart_data.dart';

enum FormulaSecondaryAlignmentMode {
  byIndex,
  timeNearest,
}

enum FormulaOutOfRangePolicy {
  zero,
  holdLast,
  interpolate,
}

enum FormulaInterpolationMode {
  linear,
  step,
}

class FormulaSeriesResult {
  final ChartSeries series;
  final String? error;

  const FormulaSeriesResult({
    required this.series,
    this.error,
  });

  bool get hasError => error != null;
}

class FormulaSeriesService {
  const FormulaSeriesService._();

  static const Set<String> _functions = {
    'sin',
    'cos',
    'tan',
    'sqrt',
    'abs',
    'ln',
    'log',
    'exp',
  };

  static String? validateFormula(String formula) {
    final expression = formula.trim();
    if (expression.isEmpty) {
      return 'Formula is empty';
    }
    try {
      final tokens = _tokenize(expression);
      _toRpn(tokens);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('FormatException: ', '');
    }
  }

  static FormulaSeriesResult applyFormula(
    ChartSeries source,
    String formula,
    ChartSeries? secondary,
    FormulaSecondaryAlignmentMode secondaryAlignmentMode,
    int? nearestMaxDeltaMs,
    FormulaOutOfRangePolicy outOfRangePolicy,
    FormulaInterpolationMode interpolationMode,
  ) {
    final expression = formula.trim();
    final validationError = validateFormula(expression);
    if (validationError != null) {
      return FormulaSeriesResult(
        series: source,
        error: validationError,
      );
    }

    try {
      final tokens = _tokenize(expression);
      final rpn = _toRpn(tokens);
      final points = source.dataPoints;
      final secondaryPoints = secondary?.dataPoints;
      final alignedSecondaryValues = _alignedSecondaryValues(
        points,
        secondaryPoints,
        secondaryAlignmentMode,
        nearestMaxDeltaMs,
        outOfRangePolicy,
        interpolationMode,
      );
      if (points.isEmpty) {
        return FormulaSeriesResult(
          series: ChartSeries(name: '${source.name}_f($expression)'),
        );
      }

      final startMs = points.first.time.millisecondsSinceEpoch;
      final transformed = <ChartDataPoint>[];
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        final t = (point.time.millisecondsSinceEpoch - startMs) / 1000;
        final y = alignedSecondaryValues[i];
        final value = _evaluateRpn(rpn, x: point.value, y: y, t: t);
        transformed.add(
          ChartDataPoint(
            time: point.time,
            value: value.isFinite ? value : 0,
            label: point.label,
          ),
        );
      }

      return FormulaSeriesResult(
        series: ChartSeries(
          name: '${source.name}_f($expression)',
          dataPoints: transformed,
        ),
      );
    } catch (e) {
      return FormulaSeriesResult(
        series: source,
        error: e.toString().replaceFirst('FormatException: ', ''),
      );
    }
  }

  static List<double> _alignedSecondaryValues(
    List<ChartDataPoint> primary,
    List<ChartDataPoint>? secondary,
    FormulaSecondaryAlignmentMode mode,
    int? nearestMaxDeltaMs,
    FormulaOutOfRangePolicy outOfRangePolicy,
    FormulaInterpolationMode interpolationMode,
  ) {
    if (primary.isEmpty) {
      return const <double>[];
    }
    if (secondary == null || secondary.isEmpty) {
      return List<double>.filled(primary.length, 0.0);
    }

    if (mode == FormulaSecondaryAlignmentMode.byIndex) {
      final aligned = List<double>.filled(primary.length, 0.0);
      for (var i = 0; i < primary.length; i++) {
        if (i < secondary.length) {
          aligned[i] = secondary[i].value;
        } else {
          aligned[i] = _fallbackValue(
            aligned: aligned,
            index: i,
            policy: outOfRangePolicy,
            secondary: secondary,
            targetMs: primary[i].time.millisecondsSinceEpoch,
            leftIndex: secondary.length - 1,
            rightIndex: null,
            interpolationMode: interpolationMode,
          );
        }
      }
      return aligned;
    }

    final aligned = List<double>.filled(primary.length, 0.0);
    var secIndex = 0;
    final maxDeltaMs = nearestMaxDeltaMs ?? 0;
    for (var i = 0; i < primary.length; i++) {
      final targetMs = primary[i].time.millisecondsSinceEpoch;

      while (secIndex + 1 < secondary.length &&
          secondary[secIndex + 1].time.millisecondsSinceEpoch <= targetMs) {
        secIndex++;
      }

      final leftIndex = secIndex;
      final rightIndex = leftIndex + 1 < secondary.length ? leftIndex + 1 : null;

      final leftDiff =
          (secondary[leftIndex].time.millisecondsSinceEpoch - targetMs).abs();
      final rightDiff = rightIndex == null
          ? double.infinity
          : (secondary[rightIndex].time.millisecondsSinceEpoch - targetMs).abs().toDouble();

      final nearestIndex = rightDiff < leftDiff ? rightIndex! : leftIndex;
      final nearestDiffMs = (secondary[nearestIndex].time.millisecondsSinceEpoch - targetMs).abs();

      if (maxDeltaMs > 0 && nearestDiffMs > maxDeltaMs) {
        aligned[i] = _fallbackValue(
          aligned: aligned,
          index: i,
          policy: outOfRangePolicy,
          secondary: secondary,
          targetMs: targetMs,
          leftIndex: leftIndex,
          rightIndex: rightIndex,
          interpolationMode: interpolationMode,
        );
      } else {
        aligned[i] = secondary[nearestIndex].value;
      }
    }
    return aligned;
  }

  static double _fallbackValue({
    required List<double> aligned,
    required int index,
    required FormulaOutOfRangePolicy policy,
    required List<ChartDataPoint> secondary,
    required int targetMs,
    required int leftIndex,
    required int? rightIndex,
    required FormulaInterpolationMode interpolationMode,
  }) {
    return switch (policy) {
      FormulaOutOfRangePolicy.zero => 0.0,
      FormulaOutOfRangePolicy.holdLast => index > 0 ? aligned[index - 1] : 0.0,
      FormulaOutOfRangePolicy.interpolate => _interpolateOrFallback(
          aligned: aligned,
          index: index,
          secondary: secondary,
          targetMs: targetMs,
          leftIndex: leftIndex,
          rightIndex: rightIndex,
          interpolationMode: interpolationMode,
        ),
    };
  }

  static double _interpolateOrFallback({
    required List<double> aligned,
    required int index,
    required List<ChartDataPoint> secondary,
    required int targetMs,
    required int leftIndex,
    required int? rightIndex,
    required FormulaInterpolationMode interpolationMode,
  }) {
    if (rightIndex == null) {
      return index > 0 ? aligned[index - 1] : secondary[leftIndex].value;
    }

    final left = secondary[leftIndex];
    final right = secondary[rightIndex];
    final leftMs = left.time.millisecondsSinceEpoch;
    final rightMs = right.time.millisecondsSinceEpoch;
    if (rightMs == leftMs) {
      return left.value;
    }

    if (interpolationMode == FormulaInterpolationMode.step) {
      return left.value;
    }

    final ratio = (targetMs - leftMs) / (rightMs - leftMs);
    final clampedRatio = ratio.clamp(0.0, 1.0);
    return left.value + ((right.value - left.value) * clampedRatio);
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    var i = 0;
    while (i < input.length) {
      final ch = input[i];
      if (ch.trim().isEmpty) {
        i++;
        continue;
      }

      if (_isDigit(ch) || ch == '.') {
        final start = i;
        i++;
        while (i < input.length && (_isDigit(input[i]) || input[i] == '.')) {
          i++;
        }
        tokens.add(input.substring(start, i));
        continue;
      }

      if (_isAlpha(ch)) {
        final start = i;
        i++;
        while (i < input.length && (_isAlpha(input[i]) || _isDigit(input[i]))) {
          i++;
        }
        tokens.add(input.substring(start, i).toLowerCase());
        continue;
      }

      if ('+-*/^()'.contains(ch)) {
        tokens.add(ch);
        i++;
        continue;
      }

      throw FormatException('Invalid character: $ch');
    }

    return tokens;
  }

  static List<String> _toRpn(List<String> tokens) {
    final output = <String>[];
    final operators = <String>[];
    String? previous;

    for (final token in tokens) {
      if (_isNumber(token) || _isVariableOrConstant(token)) {
        output.add(token);
      } else if (_functions.contains(token)) {
        operators.add(token);
      } else if (token == '(') {
        operators.add(token);
      } else if (token == ')') {
        while (operators.isNotEmpty && operators.last != '(') {
          output.add(operators.removeLast());
        }
        if (operators.isEmpty || operators.last != '(') {
          throw const FormatException('Mismatched parentheses');
        }
        operators.removeLast();
        if (operators.isNotEmpty && _functions.contains(operators.last)) {
          output.add(operators.removeLast());
        }
      } else if (_isOperator(token)) {
        final op = (token == '-' &&
                (previous == null || previous == '(' || _isOperator(previous)))
            ? 'u-'
            : token;

        while (operators.isNotEmpty &&
            _isOperator(operators.last) &&
            ((_isRightAssociative(op) && _precedence(op) < _precedence(operators.last)) ||
                (!_isRightAssociative(op) && _precedence(op) <= _precedence(operators.last)))) {
          output.add(operators.removeLast());
        }
        operators.add(op);
      } else {
        throw FormatException('Unsupported token: $token');
      }

      previous = token;
    }

    while (operators.isNotEmpty) {
      final op = operators.removeLast();
      if (op == '(' || op == ')') {
        throw const FormatException('Mismatched parentheses');
      }
      output.add(op);
    }

    return output;
  }

  static double _evaluateRpn(
    List<String> rpn, {
    required double x,
    required double y,
    required double t,
  }) {
    final stack = <double>[];

    for (final token in rpn) {
      if (_isNumber(token)) {
        stack.add(double.parse(token));
      } else if (_isVariableOrConstant(token)) {
        stack.add(
          switch (token) {
            'x' => x,
            'y' => y,
            't' => t,
            'pi' => math.pi,
            'e' => math.e,
            _ => throw FormatException('Unknown symbol: $token'),
          },
        );
      } else if (_functions.contains(token)) {
        if (stack.isEmpty) {
          throw const FormatException('Function missing argument');
        }
        final v = stack.removeLast();
        stack.add(_applyFunction(token, v));
      } else if (_isOperator(token)) {
        if (token == 'u-') {
          if (stack.isEmpty) {
            throw const FormatException('Unary minus missing argument');
          }
          stack.add(-stack.removeLast());
          continue;
        }
        if (stack.length < 2) {
          throw const FormatException('Operator missing argument');
        }
        final right = stack.removeLast();
        final left = stack.removeLast();
        stack.add(
          switch (token) {
            '+' => left + right,
            '-' => left - right,
            '*' => left * right,
            '/' => right.abs() <= 1e-12 ? 0 : left / right,
            '^' => math.pow(left, right).toDouble(),
            _ => throw FormatException('Unknown operator: $token'),
          },
        );
      } else {
        throw FormatException('Unknown token during evaluation: $token');
      }
    }

    if (stack.length != 1) {
      throw const FormatException('Invalid expression');
    }
    return stack.single;
  }

  static double _applyFunction(String function, double value) {
    return switch (function) {
      'sin' => math.sin(value),
      'cos' => math.cos(value),
      'tan' => math.tan(value),
      'sqrt' => value < 0 ? 0 : math.sqrt(value),
      'abs' => value.abs(),
      'ln' => value <= 0 ? 0 : math.log(value),
      'log' => value <= 0 ? 0 : math.log(value) / math.ln10,
      'exp' => math.exp(value),
      _ => throw FormatException('Unknown function: $function'),
    };
  }

  static bool _isDigit(String s) => s.codeUnitAt(0) >= 48 && s.codeUnitAt(0) <= 57;
  static bool _isAlpha(String s) {
    final code = s.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || s == '_';
  }

  static bool _isNumber(String token) => double.tryParse(token) != null;
  static bool _isVariableOrConstant(String token) =>
      token == 'x' || token == 'y' || token == 't' || token == 'pi' || token == 'e';

  static bool _isOperator(String token) =>
      token == '+' || token == '-' || token == '*' || token == '/' || token == '^' || token == 'u-';

  static int _precedence(String operator) {
    return switch (operator) {
      'u-' => 4,
      '^' => 3,
      '*' || '/' => 2,
      '+' || '-' => 1,
      _ => 0,
    };
  }

  static bool _isRightAssociative(String operator) {
    return operator == '^' || operator == 'u-';
  }
}
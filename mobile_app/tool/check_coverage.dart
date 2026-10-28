import 'dart:io';

/// Script to verify that test coverage meets or exceeds a minimum threshold.
///
/// Usage:
///   dart run tool/check_coverage.dart [minimum_percentage]
///
/// Example:
///   dart run tool/check_coverage.dart
///   dart run tool/check_coverage.dart 15.0
void main(List<String> args) {
  const double defaultFloor = 15.0;
  final double minCoverage = args.isNotEmpty
      ? double.parse(args[0])
      : defaultFloor;

  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    stderr.writeln(
      'Error: coverage/lcov.info not found.\n'
      'Run "flutter test --coverage" before running this check.',
    );
    exit(1);
  }

  int totalLines = 0;
  int hitLines = 0;

  for (final line in lcovFile.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      totalLines += int.parse(line.substring(3).trim());
    } else if (line.startsWith('LH:')) {
      hitLines += int.parse(line.substring(3).trim());
    }
  }

  if (totalLines == 0) {
    stderr.writeln('Error: No executable lines found in coverage report.');
    exit(1);
  }

  final double coverage = (hitLines / totalLines) * 100.0;
  final String formattedCoverage = coverage.toStringAsFixed(2);
  final String formattedMin = minCoverage.toStringAsFixed(2);

  stdout.writeln('========================================');
  stdout.writeln(
    'Line Coverage: $formattedCoverage% ($hitLines / $totalLines lines hit)',
  );
  stdout.writeln('Coverage Floor: $formattedMin%');
  stdout.writeln('========================================');

  if (coverage < minCoverage) {
    stderr.writeln(
      'FAILURE: Code coverage ($formattedCoverage%) is below the minimum floor of $formattedMin%.',
    );
    exit(1);
  }

  stdout.writeln(
    'SUCCESS: Code coverage ($formattedCoverage%) meets the required minimum floor of $formattedMin%.',
  );
}

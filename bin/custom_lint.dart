// ignore_for_file: depend_on_referenced_packages

import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

void main(List<String> args, SendPort sendPort) {
  startPlugin(sendPort, _CustomLints());
}

bool _isStreamController(DartType type) {
  final element = type.element! as ClassElement;
  final source = element.librarySource.uri;
  final isStreamController = source.scheme == 'dart' &&
      source.path == 'async' &&
      element.name == 'StreamController';
  return isStreamController || element.allSupertypes.any(_isStreamController);
}

class _CustomLints extends PluginBase {
  @override
  Stream<Lint> getLints(ResolvedUnitResult result) async* {
    final library = result.libraryElement;
    final classes = library.topLevelElements.whereType<ClassElement>();
    for (final classInstance in classes) {
      final variables = classInstance.fields
          .whereType<VariableElement>()
          .where((e) => _isStreamController(e.type))
          .toList();

      final hasDisposeMethod = classInstance.getMethod('dispose') != null;

      if (variables.isNotEmpty && !hasDisposeMethod) {
        for (final variable in variables) {
          final location = variable.nameLintLocation!;
          // final a = classInstance.nameLintLocation!;

          yield Lint(
            severity: LintSeverity.warning,
            code: 'close_stream_controllers',
            message:
                'StreamControllers should be closed in the dispose method. ',
            correction: 'Add a dispose method',
            location: result.lintLocationFromLines(
              startLine: location.startLine,
              endLine: location.endLine,
              startColumn: location.startColumn,
              endColumn: location.endColumn,
            ),
            getAnalysisErrorFixes: (lint) async* {
              final filePath = library.source.fullName;
              final changeBuilder = ChangeBuilder(session: result.session);
              await changeBuilder.addDartFileEdit(
                filePath,
                (builder) {
                  builder.addInsertion(
                    1, // change this
                    (builder) {
                      builder.write(
                        '''
                      void dispose() {
                          ${variable.name}.close();
                        }''',
                      );
                    },
                  );
                },
              );
              final prioritizedSourceChange = PrioritizedSourceChange(
                0,
                changeBuilder.sourceChange..message = 'Add a dispose method',
              );
              yield AnalysisErrorFixes(
                lint.asAnalysisError(),
                fixes: [prioritizedSourceChange],
              );
            },
          );
        }
      }
    }
  }
}

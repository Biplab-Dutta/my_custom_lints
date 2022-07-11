import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

void main(List<String> args, SendPort sendPort) {
  startPlugin(sendPort, _CustomLints());
}

bool _isStreamSubscription(DartType type) {
  final element = type.element! as ClassElement;
  final source = element.librarySource.uri;
  final isStreamSubscription = source.scheme == 'dart' &&
      source.path == 'async' &&
      element.name == 'StreamSubscription';
  return isStreamSubscription ||
      element.allSupertypes.any(_isStreamSubscription);
}

class _CustomLints extends PluginBase {
  @override
  Stream<Lint> getLints(ResolvedUnitResult result) async* {
    final library = result.libraryElement;
    final classes = library.topLevelElements.whereType<ClassElement>();
    for (final classInstance in classes) {
      final variable = classInstance.fields
          .whereType<VariableElement>()
          .where((e) => _isStreamSubscription(e.type));
      print(variable.first.name);
    }
  }
}

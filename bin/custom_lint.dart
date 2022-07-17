import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
// import 'package:linter/src/util/leak_detector_visitor.dart';

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
          .where((e) => _isStreamController(e.type));
    }
    yield Lint(
      code: '',
      message: '',
      location: result.lintLocationFromOffset(42, length: 100),
    );
  }
}

// class _Visitor extends LeakDetectorProcessors {
//   static const _closeMethodName = 'close';

//   @override
//   Map<DartTypePredicate, String> get predicates => {
//         _isStreamController: _closeMethodName,
//       };

//   _Visitor(super.rule);
// }

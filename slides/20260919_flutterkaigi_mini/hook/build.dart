import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // Reference photos stay local; only authored models enter the asset build.
    buildScenes(
      buildInput: input,
      buildOutput: output,
      discoveryRoot: 'assets/models/',
    );
  });
}

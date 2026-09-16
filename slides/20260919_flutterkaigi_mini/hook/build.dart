import 'dart:io';

import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final model = File.fromUri(
      input.packageRoot.resolve('assets/models/dashmaru.glb'),
    );
    if (!model.existsSync()) {
      throw StateError(
        'Dashmaru assets are missing. From the repository root, run '
        'python3 tool/private_assets.py restore with '
        'DASHMARU_ASSET_PASSPHRASE set before building.',
      );
    }
    // Reference photos stay local; only authored models enter the asset build.
    buildScenes(
      buildInput: input,
      buildOutput: output,
      discoveryRoot: 'assets/models/',
    );
  });
}

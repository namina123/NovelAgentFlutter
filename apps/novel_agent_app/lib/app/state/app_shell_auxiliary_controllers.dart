import 'package:flutter/foundation.dart';

import '../../features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import '../../features/inspiration_workbench/application/controllers/inspiration_workbench_controller.dart';
import '../../features/project_assets/application/controllers/project_assets_controller.dart';

class AppShellAuxiliaryControllers {
  AppShellAuxiliaryControllers({
    required ProjectAssetsController Function() createProjectAssetsController,
    required BookDeconstructionController Function()
    createBookDeconstructionController,
    required InspirationWorkbenchController Function()
    createInspirationWorkbenchController,
  }) : _projectAssetsControllerSlot = LazyChangeNotifierSlot(
         createProjectAssetsController,
       ),
       _bookDeconstructionControllerSlot = LazyChangeNotifierSlot(
         createBookDeconstructionController,
       ),
       _inspirationWorkbenchControllerSlot = LazyChangeNotifierSlot(
         createInspirationWorkbenchController,
       );

  final LazyChangeNotifierSlot<ProjectAssetsController>
  _projectAssetsControllerSlot;
  final LazyChangeNotifierSlot<BookDeconstructionController>
  _bookDeconstructionControllerSlot;
  final LazyChangeNotifierSlot<InspirationWorkbenchController>
  _inspirationWorkbenchControllerSlot;

  ProjectAssetsController get projectAssetsController =>
      _projectAssetsControllerSlot.instance;

  BookDeconstructionController get bookDeconstructionController =>
      _bookDeconstructionControllerSlot.instance;

  InspirationWorkbenchController get inspirationWorkbenchController =>
      _inspirationWorkbenchControllerSlot.instance;

  bool get hasDormantControllers =>
      _projectAssetsControllerSlot.hasInstance ||
      _bookDeconstructionControllerSlot.hasInstance ||
      _inspirationWorkbenchControllerSlot.hasInstance;

  void dispose() {
    _projectAssetsControllerSlot.dispose();
    _bookDeconstructionControllerSlot.dispose();
    _inspirationWorkbenchControllerSlot.dispose();
  }
}

class LazyChangeNotifierSlot<T extends ChangeNotifier> {
  LazyChangeNotifierSlot(this._create);

  final T Function() _create;
  T? _instance;

  bool get hasInstance => _instance != null;

  T get instance => _instance ??= _create();

  void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}

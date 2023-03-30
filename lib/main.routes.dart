part of 'main.dart';

List<GoRoute> rootRoutes = [
  _startRoute,
  _chooseCaptureModeRoute,
  _captureRoute,
];

GoRoute _startRoute = GoRoute(
  path: '/',
  pageBuilder: (context, state) {
    BuildContextAccessor contextAccessor = BuildContextAccessor();
    StartScreenViewModel viewModel = StartScreenViewModel(contextAccessor: contextAccessor);
    StartScreenController controller = StartScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
    return FadeTransitionPage(
      key: state.pageKey,
      child: StartScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor),
    );
  },
);

GoRoute _chooseCaptureModeRoute = GoRoute(
  path: '/choose_capture_mode',
  pageBuilder: (context, state) {
    BuildContextAccessor contextAccessor = BuildContextAccessor();
    ChooseCaptureModeScreenViewModel viewModel = ChooseCaptureModeScreenViewModel(contextAccessor: contextAccessor);
    ChooseCaptureModeScreenController controller = ChooseCaptureModeScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
    return FadeTransitionPage(
      key: state.pageKey,
      child: ChooseCaptureModeScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor),
    );
  },
);

GoRoute _captureRoute = GoRoute(
  path: '/capture',
  pageBuilder: (context, state) {
    BuildContextAccessor contextAccessor = BuildContextAccessor();
    CaptureScreenViewModel viewModel = CaptureScreenViewModel(contextAccessor: contextAccessor);
    CaptureScreenController controller = CaptureScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
    return FadeTransitionPage(
      key: state.pageKey,
      child: CaptureScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor),
    );
  },
);

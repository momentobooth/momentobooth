# Widget overview

This page catalogs every reusable Flutter widget in `lib/`, grouped by folder. **Check this list before adding a new widget** — a similar one may already exist.

There is no `lib/widgets/` directory. Widgets live under `lib/views/`, either in the generic, app-wide `lib/views/components/` tree, or in a screen-local `components/` subfolder next to the screen that uses them.

Each line follows the format `path` — `WidgetClassName` — description, to keep this page easy to `grep`.

## Folders

- `lib/views/`
  - [components/](#lib-views-components) — generic, app-wide widgets with no screen-specific dependency.
    - [animations/](#lib-views-components-animations) — reusable fade/rotate/Lottie animation wrappers.
    - [buttons/](#lib-views-components-buttons) — generic dialog-style buttons.
    - [config/](#lib-views-components-config) — widgets that adapt behavior to app configuration/settings.
    - [content/](#lib-views-components-content) — widgets that render document content such as Markdown.
    - [dialogs/](#lib-views-components-dialogs) — generic modal dialogs used across the app.
    - [imaging/](#lib-views-components-imaging) — image/camera rendering and transform widgets.
    - [indicators/](#lib-views-components-indicators) — small status/progress indicator widgets.
    - [transitions/](#lib-views-components-transitions) — page-transition animation widgets.
  - [base/](#lib-views-base) — MVVM screen base classes and routing-page infrastructure.
  - [onboarding_screen/components/](#lib-views-onboarding-screen-components) — chrome for the first-run onboarding wizard.
  - `photo_booth_screen/`
    - [components/](#lib-views-photo-booth-screen-components) — top-level wrappers for the main booth screen (activity tracking, scaling, FPS overlay).
    - `screens/`
      - [components/buttons/](#lib-views-photo-booth-screen-screens-components-buttons) — themed booth action/navigation button.
      - [components/text/](#lib-views-photo-booth-screen-screens-components-text) — auto-sizing themed title/subtitle text.
      - [gallery_screen/components/](#lib-views-photo-booth-screen-screens-gallery-screen-components) — gallery-screen-local toolbar widgets.
    - [theme/*/components/](#lib-views-photo-booth-screen-theme-components) — decorative widgets specific to one visual theme.
  - `settings_overlay/`
    - [components/](#lib-views-settings-overlay-components) — chrome for the settings overlay (pages, sections, dialogs).
    - [components/settings/](#lib-views-settings-overlay-components-settings) — one row-widget per setting type, plus the "quick actions" grid buttons.
- [Menus / app-level widgets](#menus-app-level-widgets) — top-level `lib/` widgets outside the `views/` tree.
- [Known near-duplicates / naming overlaps](#known-near-duplicates-naming-overlaps) — intentional or confusable look-alike widgets to check before adding a new one.

<a id="lib-views-components"></a>

## lib/views/components/

Generic, app-wide widgets with no screen-specific dependency.

- `lib/views/components/qr_code.dart` — `QrCode` — renders a QR code of given `data`/`size`.
- `lib/views/components/cvs_simulation_filter.dart` — `CvsSimulationFilter` — wraps `child` in color filters to simulate color-vision deficiency.

<a id="lib-views-components-animations"></a>

### lib/views/components/animations/

Reusable fade/rotate/Lottie animation wrappers.

- `animated_delayed_fade_in.dart` — `AnimatedDelayedFadeIn` — fades in `child` after a configurable delay.
- `fading_text_swticher.dart` — `FadingTextSwitcher` — cycles through a list of strings with a fade + auto-resize animation.
- `lottie_animation_wrapper.dart` — `LottieAnimationWrapper` — overlays positioned/rotated Lottie animations on top of `child`.
- `repeating_indicator.dart` — `RepeatingIndicator` — periodically shows a Lottie animation at a random position (idle attention-grabber).
- `rotating_collage_box.dart` — `RotatingCollageBox` — animates rotation of a collage widget when the `turns` prop changes.

<a id="lib-views-components-buttons"></a>

### lib/views/components/buttons/

Generic dialog-style buttons.

- `photo_booth_filled_button.dart` — `PhotoBoothFilledButton` — dialog-style filled button with optional icon + title.
- `photo_booth_outlined_button.dart` — `PhotoBoothOutlinedButton` — outlined variant of `PhotoBoothFilledButton`.

> Note: these are **generic dialog buttons**, not the same as `PhotoBoothButton` in `photo_booth_screen/screens/components/buttons/` (themed booth action/nav button). Three "PhotoBooth*Button" widgets exist across the codebase — pick carefully.

<a id="lib-views-components-config"></a>

### lib/views/components/config/

Widgets that adapt behavior to app configuration/settings.

- `set_scroll_configuration.dart` — `SetScrollConfiguration` — wraps `child` in a `ScrollConfiguration` that conditionally allows mouse-drag scrolling.

<a id="lib-views-components-content"></a>

### lib/views/components/content/

Widgets that render document content.

- `markdown_view.dart` — `MarkdownView` — renders parsed Markdown blocks (headings, paragraphs, bullets, inline bold/italic/code/links) with Fluent UI typography, opening links in the browser.

<a id="lib-views-components-dialogs"></a>

### lib/views/components/dialogs/

Generic modal dialogs used across the app.

- `enter_pin_dialog.dart` — `EnterPinDialog` — numeric keypad dialog for entering a PIN code.
- `find_face_dialog.dart` — `FindFaceDialog` — live view + countdown to capture a face photo for face-recognition lookup.
- `language_choice_dialog.dart` — `LanguageChoiceDialog` — dialog listing available languages to pick.
- `loading_dialog.dart` — `LoadingDialog` — generic loading dialog (`.generic()` spinner, `.cameraDownload()` Lottie).
- `modal_dialog.dart` — `ModalDialog` — base styled modal container (title, body, type icon, actions), builds on `PhotoBoothDialog`. Used by most other dialogs.
- `no_project_open_dialog.dart` — `NoProjectOpenDialog` — shown when no project is open, lists recent projects.
- `photo_booth_dialog.dart` — `PhotoBoothDialog` — lower-level rounded-card dialog shell (width/height/title/indicator/body/actions), used underneath `ModalDialog`.
- `printer_issue_dialog.dart` — `PrinterIssueDialog` — reports a stuck/failed printer with stuck-job list and resume/ignore actions.
- `printing_error_dialog.dart` — `PrintingErrorDialog` — generic printing error dialog with Lottie animation.
- `print_dialog.dart` — `PrintDialog` — choose print size and copy count; also exports `PrintSizeChoice`.
- `qr_share_dialog.dart` — `QrShareDialog` — upload progress + QR code for sharing photos.
- `retake_dialog.dart` — `RetakeDialog` — confirm delete/keep a photo before retaking.
- `settings_import_dialog.dart` — `SettingsImportDialog` — preview settings-import diffs before applying.

> Note: `ModalDialog` vs `PhotoBoothDialog` — two layered generic dialog shells. `ModalDialog` is the one most feature dialogs should build on; `PhotoBoothDialog` is the lower-level shell it wraps.

<a id="lib-views-components-imaging"></a>

### lib/views/components/imaging/

Image/camera rendering and transform widgets.

- `image_with_loader_fallback.dart` — `ImageWithLoaderFallback` — image loader with placeholder/fallback while decoding, `.memory()`/`.file()` constructors, optional rotate/flip/crop.
- `live_view.dart` — `LiveView` — renders the live camera-preview texture with rotate/flip/crop, overlay image and filter settings.
- `live_view_background.dart` — `LiveViewBackground` — conditionally shows a blurred/live camera feed as a full-screen background depending on route/settings.
- `photo_collage.dart` — `PhotoCollage` — renders a full photo collage (background/middle/foreground layers, logo, layout) from captured photos.
- `rotate_flip_crop.dart` — `RotateFlipCrop` — applies rotate/flip/aspect-ratio crop transforms to a `child`.

<a id="lib-views-components-indicators"></a>

### lib/views/components/indicators/

Small status/progress indicator widgets.

- `capture_counter.dart` — `CaptureCounter` — animated countdown-number display before/during capture.
- `connection_state_indicator.dart` — `MqttConnectionStateIndicator` — small colored dot for MQTT connection state.
- `onboarding_version_info.dart` — `OnboardingVersionInfo` — app/Flutter/Rust version info footer.
- `subsystem_status_display.dart` — `SubsystemStatusDisplay` — expandable tile with a subsystem's status/message/recovery actions.
- `subsystem_status_icon.dart` — `SubsystemStatusIcon` — maps a `SubsystemStatus` to a colored icon.
- `subsystem_status_list.dart` — `SubsystemStatusList` — observable list of `SubsystemStatusDisplay` tiles.

<a id="lib-views-components-transitions"></a>

### lib/views/components/transitions/

Page-transition animation widgets.

- `fade_and_scale_transition.dart` — `FadeAndScaleTransition` — page-transition: fade + scale in/out.
- `fade_and_slide_transition.dart` — `FadeAndSlideTransition` — page-transition: fade + horizontal slide in/out.

Both are theme-selectable variants consumed by `transition_page.dart`.

<a id="lib-views-base"></a>

## lib/views/base/

MVVM screen base classes and routing-page infrastructure.

- `full_screen_dialog.dart` — `FullScreenPopup` — rounded, shadowed container used as full-screen popup chrome.
- `screen_base.dart` — `ScreenBase<TViewModel, TController, TView>` — abstract base `StatefulWidget` for the app's MVVM screen pattern.
- `photo_booth_dialog_page.dart` — `PhotoBoothDialogPage<T>` — routing page with blur+fade+scale transition for dialog routes.
- `transition_page.dart` — `TransitionPage` — routing page providing themed screen-transition animations (delegates to the two `FadeAnd*Transition` widgets above).

<a id="lib-views-onboarding-screen-components"></a>

## lib/views/onboarding_screen/components/

Chrome for the first-run onboarding wizard.

- `onboarding_wizard.dart` — `OnboardingWizard` — acrylic-panel chrome wrapper for onboarding wizard content.
- `wizard_page.dart` — `WizardPage` — standard onboarding wizard page layout with back/next navigation.

<a id="lib-views-photo-booth-screen-components"></a>

## lib/views/photo_booth_screen/components/

Top-level wrappers for the main booth screen (activity tracking, scaling, FPS overlay).

- `activity_monitor.dart` — `ActivityMonitor` — tracks user (in)activity, triggers timeout/return-to-home navigation.
- `app_scaler.dart` — `AppScaler` — scales `child` uniformly to fit the window relative to a fixed 1920x1080 target resolution.
- `framerate_monitor.dart` — `FramerateMonitor` — conditionally overlays an on-screen FPS counter based on debug settings.

<a id="lib-views-photo-booth-screen-screens-components-buttons"></a>

### lib/views/photo_booth_screen/screens/components/buttons/

Themed booth action/navigation button.

- `photo_booth_button.dart` — `PhotoBoothButton` — themed booth action/navigation button, `.action()`/`.navigation()` constructors, wraps `AutoSizeTextAndIcon`.

<a id="lib-views-photo-booth-screen-screens-components-text"></a>

### lib/views/photo_booth_screen/screens/components/text/

Auto-sizing themed title/subtitle text.

- `auto_size_text_and_icon.dart` — `AutoSizeTextAndIcon` — text (optionally with icon) that auto-sizes to fit its box.
- `photo_booth_subtitle.dart` — `PhotoBoothSubtitle` — themed subtitle text using `AutoSizeTextAndIcon`.
- `photo_booth_title.dart` — `PhotoBoothTitle` — themed title text using `AutoSizeTextAndIcon`.

<a id="lib-views-photo-booth-screen-screens-gallery-screen-components"></a>

### lib/views/photo_booth_screen/screens/gallery_screen/components/

Gallery-screen-local toolbar widgets.

- `filter_bar.dart` — `FilterBar` — gallery toolbar with sort-order chooser and "find my face"/clear-filter buttons.
- `filter_choice.dart` — `FilterChoice` — segmented button to choose gallery sort order.

<a id="lib-views-photo-booth-screen-theme-components"></a>

### lib/views/photo_booth_screen/theme/*/components/

Decorative widgets specific to one visual theme.

- `theme/hollywood/components/hollywood_stars.dart` — `HollywoodStars` — animated twinkling-stars background.
- `theme/wedding/components/wedding_wreath.dart` — `WeddingWreath` — animated rotating Lottie wreath decoration.

<a id="lib-views-settings-overlay-components"></a>

## lib/views/settings_overlay/components/

Chrome for the settings overlay (pages, sections, dialogs).

- `aspect_ratio_preview.dart` — `AspectRatioPreview` — small bordered box previewing a given aspect ratio.
- `external_system_check_edit_dialog.dart` — `ExternalSystemCheckEditDialog` — create/edit an external system health check.
- `external_system_check_tile.dart` — `ExternalSystemCheckTile` — expandable tile for an external system health check.
- `import_field.dart` — `MyDropRegion` — drag-and-drop / clipboard-paste region for importing a TOML settings file. *(Placeholder-style name — actually settings-import specific, not a generic drop region.)*
- `settings_list_page.dart` — `SettingsListPage` — settings page variant rendering a scrollable list of setting "blocks".
- `settings_page.dart` — `SettingsPage` — base settings-page chrome (title, scroll-shadowed body, "auto-saved" info bar).
- `settings_section.dart` — `SettingsSection` — titled vertical group wrapper for a list of setting widgets.
- `update_secret_dialog.dart` — `UpdateSecretDialog` — enter/save a new secret value (API key/password).

<a id="lib-views-settings-overlay-components-settings"></a>

### lib/views/settings_overlay/components/settings/

One row-widget per setting type, plus the "quick actions" grid buttons.

All settings tiles are built on `settings_tile.dart` — `SettingsTile` (base card row: icon, title, subtitle, trailing control):

- `settings_action_tile.dart` — `SettingsActionTile` — button that triggers an action.
- `settings_color_pick_tile.dart` — `SettingsColorPickTile` — color swatch that opens a color picker.
- `settings_combo_box_tile.dart` — `SettingsComboBoxTile<TValue>` — dropdown/combo-box selector.
- `settings_file_select_tile.dart` — `SettingsFileSelectTile` — file-picker field (optionally clearable).
- `settings_folder_select_tile.dart` — `SettingsFolderSelectTile` — folder-picker field.
- `settings_number_edit_tile.dart` — `SettingsNumberEditTile<T extends num>` — numeric stepper/edit field.
- `settings_password_edit_tile.dart` — `SettingsPasswordEditTile` — password-style masked text field.
- `settings_secret_edit_tile.dart` — `SettingsSecretEditTile` — button opening `UpdateSecretDialog` to set a secure-storage secret.
- `settings_text_display_tile.dart` — `SettingsTextDisplayTile` — read-only pill/badge-styled text value, built on `settings_value_chip.dart`.
- `settings_text_edit_tile.dart` — `SettingsTextEditTile` — plain text edit field.
- `settings_toggle_tile.dart` — `SettingsToggleTile` — boolean on/off toggle switch.
- `settings_tree_view_tile.dart` — `SettingsTreeViewTile<TValue>` — multi-select tree view of items.

Standalone (no `SettingsTile` wrapper), used to display a read-only value, e.g. by `settings_text_display_tile.dart` or directly for multi-value rows like the statistics page:

- `settings_value_chip.dart` — `SettingsValueChip` — read-only pill/badge-styled text value, with an optional override for its (default accent-colored) background color.

Outside the tile family (no `SettingsTile` wrapper), for the "quick actions" grid:

- `quick_action.dart` — `QuickAction` — large icon+label outlined button.
- `quick_toggle.dart` — `QuickToggle` — large icon+label toggle button.

<a id="menus-app-level-widgets"></a>

## Menus / app-level widgets

Top-level `lib/` widgets outside the `views/` tree.

- `lib/views/photo_booth_screen/photo_booth.menu.dart` — `MomentoMenuBar` — top application menu bar (File/recent projects/etc.).
- `lib/widgetbook.dart` — `WidgetbookApp` — root widget for the separate Widgetbook component-catalog dev tool (not part of the main app UI).

<a id="known-near-duplicates-naming-overlaps"></a>

## Known near-duplicates / naming overlaps

These exist on purpose but are easy to confuse — read the note before adding a new one:

1. `PhotoBoothFilledButton` / `PhotoBoothOutlinedButton` (generic dialog buttons) vs `PhotoBoothButton` (themed booth-screen action/nav button) — three different "PhotoBooth*Button" widgets, not interchangeable.
2. `ModalDialog` vs `PhotoBoothDialog` — `ModalDialog` is the higher-level shell most dialogs should use; `PhotoBoothDialog` is the lower-level shell it wraps.
3. `FadeAndScaleTransition` vs `FadeAndSlideTransition` — parallel theme-selectable page-transition effects, same constructor shape.
4. `PhotoBoothTitle` vs `PhotoBoothSubtitle` — intentional theme-driven pair, same shape.
5. `QuickAction` vs `QuickToggle` — intentional button/toggle pair, same visual shape.
6. `MyDropRegion` (`settings_overlay/components/import_field.dart`) has a generic/placeholder name but is specific to TOML settings import — don't assume it's a general-purpose drop target.

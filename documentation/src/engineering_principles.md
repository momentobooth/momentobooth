# Engineering principles

This page describes how we make design decisions in MomentoBooth and which principles guide them. It is meant for contributors and for reviewers (human or AI) who judge whether a change goes in the right direction, not only whether the code is correct.

## Context

Most principles on this page follow from a few facts about the project:

- **Small team**: we have a test device for every platform, but not the time to test and tune every feature on each of them
- **Reference hardware**: a typical event PC, such as an Intel Core i7-6700K without a dedicated GPU. The base of the app has to run well on hardware like that
- **Platforms**: Windows, Linux and macOS. Mobile and a (limited) web demo are not planned, but a change should not rule them out
- **Photo quality first**: the photos are the reason to use a photo booth, so a real camera (through gPhoto2) is the main capture path. The webcam is a fallback, but a first-class one for users without a camera
- **License**: MomentoBooth is MPL-2.0
- **Before 1.0**: settings and file formats can still change without a lot of ceremony

## How principles are weighted

Not every principle weighs the same. Each one below is marked with one of three weights:

| Weight | Meaning | What a reviewer does |
|---|---|---|
| Rule | Deviating requires explicit agreement beforehand | Reports a deviation as an issue |
| Strong | Deviating is fine, with a reason | Asks for the reason when the pull request does not give it |
| Default | The usual starting point | Only asks when another choice seems clearly better, or when the choice is not obvious |

A principle is a starting point for a discussion, not a replacement for it. When a principle does not fit a situation, say so in the pull request.

## How we make decisions

- **Understand the problem before choosing a solution** (strong). A design choice starts with the situation, its effect and who it affects, in terms of the photo booth rather than the code. Take, for example, print sizes that can only reach a printer through a split node: the question is not "which flag is wrong" but "a guest sees a print button that always fails". Only then do we compare options
- **Make open decisions explicit** (strong). When there is more than one reasonable way, the pull request or issue lists the options, what each means in practice, and a recommendation. A recommendation is not a decision; the maintainers decide
- **Measure when numbers decide** (strong). When a choice depends on performance, memory or size, we measure instead of estimating. Caching the license data costs about 4 MB, for example, so it is cached. A change that claims to improve something without a way to show it (such as swapping the memory allocator) is not merged
- **Not chosen is not rejected** (default). We write down why an option was not picked (OpenCV was heavier and not Rust-native), so it can be reconsidered when the situation changes
- **Discuss larger contributions first** (strong). A new feature or a change to an existing design is easier to get right in an issue or on Discord than in a finished pull request

### Scrutiny depends on importance and reversibility

Some decisions are hard to undo, others are cheap to swap later. Who owns the frame pipeline (our Rust code or a framework such as GStreamer) is hard to reverse, so we decide it up front, based on the principles on this page. Which media library an adapter uses is easy to reverse when it sits behind a trait, so we decide it with a time-boxed spike.

The importance of the system counts as well. The design of the vision pipeline deserves much more thought than the way photos are uploaded. A non-core feature (such as the license overview) may be a bit slow, as long as it does not affect the rest of the app.

The decision rules and thresholds for a spike are agreed on **before** it starts, so the result is not read in favour of an existing preference. A library is judged on how it behaves in our use case, not on its feature list. When nobody in the team knows the options well, learnability counts as a criterion too.

## Design principles

### Scope and direction

- **Merge working increments** (strong). Work that is valuable but separate is recorded as a follow-up instead of growing the current pull request. A large feature may be split into phases
- **Small fixes get their own pull request** (default). A small, unrelated fix found on a feature branch goes into its own pull request from `main`
- **Merge long-running branches early** (strong). Repeated rebases of a long-running branch have silently dropped working code before
- **Work towards planned features** (strong). A change in an area should at least not block a known planned feature there, and preferably move towards it
- **Features serve the general photo booth user** (strong). A feature that is tailored to one specific use case does not belong in the app as is. It either needs a more general design, or it can live in `main` as an experimental feature (see below)
- **Fix the cause, upstream when needed** (strong). When a dependency lacks something, we report it or contribute the fix rather than reimplementing that part. Once the fix is released, our own workaround is removed again. A temporary hack is acceptable when it is named as such and contained
- **Do not solve other people's problems** (default). When a third-party package has a problem that is not ours to fix (such as a missing license text), we accept the limitation instead of maintaining patches for it
- **Simple, explicit rules over clever behaviour** (default). Print jobs only fan out at an explicit node, and print sizes only come together at a printer. When a configuration would be confusing (one round-robin node serving several print sizes), we rather make it impossible than add logic to handle it

### Experimental features

A feature that is not ready for general use (such as video messages) can be merged as an experimental feature. It is opt-in through the Experimental settings tab, and it does not change the behaviour of the rest of the app when it is disabled. Being in `main` means it is not broken by other changes, while it matures. An experimental feature still has to fit the direction of the project and follow the patterns on this page.

### Generalising

Two things are easily confused here:

- **Keeping options open** is cheap: we avoid baking in assumptions that are likely to change, such as the aspect ratio of a print, or desktop-only APIs in core logic (default)
- **Building something general** (a model, an abstraction, an extension point) is expensive, and only pays off when it actually gets a second user (strong)

A new feature is first expressed in existing concepts (strong). A print on plain paper, for example, is a cell of a grid, sized by the paper and orientation, like a tile layout. When a pull request introduces a general mechanism, it names the second user it is meant for (an OpenAI-compatible endpoint used for both transcription and summarization, for example).

Whether generalising is worth it is a trade-off, not a rule. It weighs the effort of the general approach now against rebuilding later, how important the system is, and how likely the second user really is. For future platforms, a change only has to avoid making them impossible; it does not have to support them.

### Guests and operators

- **Guests never lose a result and are never surprised** (strong). A guest is warned before the booth returns to the start screen with their QR code still showing, and a retake asks whether to keep the previous photo
- **Every guest action gets visible feedback** (strong). A transition should never look like something went wrong
- **Operator workflows stay quick** (strong). Opening and closing the settings, or setting up a new event, should not be slowed down or interrupted by automation meant for guests
- **Degrade instead of blocking, and never fail silently** (rule). A broken connection or an unavailable printer is skipped and reported, while the rest keeps working. Every failure ends in a message, and an operation never just hangs. A hardware failure never freezes the booth
- **Status is honest** (rule). A status indicator never suggests that a problem is solved when it is not
- **Errors are logged** (rule). An error shown in the UI is also written to the log
- **Effort matches importance** (default). Performance work is done where the user notices it. In the hot path, we avoid unnecessary frame copies and slow resizing, and work goes where it is cheapest (scaling the live view on the GPU in Flutter is fine)

### Settings

- **Configurable when it makes sense** (default). When a value sensibly differs per event, venue or hardware, it becomes a setting. When it can be determined reliably, it becomes "Auto" with a fixed fallback order, and the diagnostics show what was chosen
- **Simple presentation, full control behind it** (strong). A simple choice covers the common case (most users), and the full set of settings stays reachable, for example behind a "Custom" option. A group of settings that grows large probably needs such a simple selection
- **Tuning knobs stay out of the way** (default). Settings for debugging or fine-tuning belong on the Debug or Experimental tab
- **Event-specific settings belong to the project** (default)
- **Choose the default of a new setting deliberately** (default). Usually, that is the existing behaviour. When another default is better, the pull request says why
- **A setting validates what its label promises** (strong). A field that says "digits only" only accepts digits

### Compatibility

- **Breaking changes are acceptable before 1.0** (default). Settings, projects and templates may change without a migration, when a migration is not worth the effort. We do not build compatibility for states that nobody has, such as an unreleased branch
- **Breaking changes are announced** (rule). Every breaking change gets a line under `### Breaking changes` in the changelog. The app shows the changelog of new versions during onboarding, so operators see it before their next event

### Platforms, dependencies and licenses

- **One portable path over a native path per OS** (strong). We pick a cross-platform library (Rust-native where possible) instead of maintaining separate implementations for, for example, Media Foundation, AVFoundation and V4L2
- **The base runs on the reference hardware** (strong). Heavier features, such as machine learning or hardware encoding, are optional and stay behind a setting or a Cargo feature
- **Performance-critical and native work goes to Rust** (default). Image processing, camera control and native integrations live in Rust, especially when a Dart package causes trouble
- **License-compatible by default** (rule). LGPL components are only shipped as dynamically linked libraries, and GPL builds and models with a non-commercial license are never a default
- **Dependencies are maintained** (strong). An unmaintained package is replaced. Built-in Flutter functionality is preferred over an extra package
- **Try a dependency before committing to it** (default). When more than one library could fit, they are tried in a spike on the same task

### Testing

- **Pull requests state what was tested** (rule). Including what was not tested, and on which platforms and hardware
- **Test in proportion to the cost of manual verification** (strong). Automated tests are most valuable where checking by hand is expensive or error-prone, such as printing through CUPS. They test behaviour at stable boundaries, not the implementation, so that a small change does not require updating many tests
- **Hardware tests are opt-in** (default). Tests that need hardware or Docker are skipped when their environment is not configured, so a plain `cargo test` keeps working
- **Fake sources stay available** (default). Simulated cameras and live view sources make it possible to develop and test without hardware

### Code

- **The diff shows the real change** (strong). Reformatting unrelated code makes a review harder and belongs in a separate pull request
- **No dead code** (strong). No commented-out code, unused widgets or unused parameters. Something that is kept on purpose gets a `TODO` with the reason
- **Comments explain why** (strong). Especially for behaviour of a framework or device that is not obvious, so nobody has to find out the same thing twice
- **No duplication of logic** (strong). Logic that more than one screen needs moves into a shared place, usually a manager
- **Explicit over terse** (default). When the longer form reads clearer, it is preferred

## Repository patterns

The structure of the code base is described in the [developer setup](dev_setup.md) and the [widget overview](widget_overview.md). The patterns below are the ones that reviews come back to:

- **View, view model, controller** (strong). Screens follow the MVVM base classes in `lib/views/base/`. The view model holds what a single screen needs to show, including derived data. Logic that more than one screen needs, or that continues when the screen is gone (such as generating a collage), belongs in a manager
- **The framework's own way** (strong). We use the mechanisms of Flutter and our libraries rather than our own: navigation with `go_router`'s `go`, theming through `ThemeExtension`s, dialogs that return their result through `pop`, MobX `autorun` to react to settings changes (see `MqttManager`), and `addPostFrameCallback` for work that depends on the widget tree. We only build our own mechanism when the idiomatic one breaks behaviour
- **UI components** (strong). The settings, onboarding and other operator screens use Fluent UI. The photo booth screens for guests use their own themed widgets through `PhotoBoothTheme`, and may use a Material widget where Fluent UI lacks one (such as `SegmentedButton`). Icons come from Lucide
- **Subsystems** (strong). A manager that talks to the outside world (a printer, a camera, OS audio, an external service) is a `Subsystem`: its status is visible in the settings, and it can recover while the app runs. When an internal manager fails, that is a bug, and stopping the app is acceptable
- **Defensive around the file system and OS** (default). We do not assume that a folder or device from earlier is still there
- **Dialog or notification** (default). A dialog is for when the user has to decide something now, or the current action cannot continue. A notification or subsystem status is for something that keeps working but needs attention later
- **Persistence** (strong). Loading and saving lives in `lib/repositories/`; models stay plain data
- **Localisation** (default). Text that guests see is localised. Translations for new text are welcome, also when generated, but stay marked as unverified until a native speaker has checked them. The settings screens are English for now
- **Logging** (rule). Through the logger, never with `print()`
- **Generate, don't commit** (rule). Generated code and derived data (bindings, Freezed and MobX code, the license overview) are produced by a `just` recipe and in CI. A fast path that skips unchanged input is preferred over making every build slower
- **Reuse the CI pipeline** (default). New checks run as a step in the existing workflows, instead of a separate workflow that repeats the setup

## Known debts

These are places where the code does not (yet) follow the principles above. A change that reduces one of them is welcome; a change that extends one should say why.

- View models have no access to the controller, which makes it awkward to decide where some logic belongs
- The share screen and the photo details screen duplicate code, and so do the single and multi-capture collage flows

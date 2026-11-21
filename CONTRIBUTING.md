# Contributing to MomentoBooth

Contributions to MomentoBooth are welcome! This page explains how to propose a change so that it has a good chance of being merged.

## Before you start

- **Bug fixes and small improvements**: open a pull request directly
- **New features, or changes to an existing design**: open an issue or ask on [Discord](https://discord.gg/mCMEv2fHSN) first

When you propose a feature, start with the problem: the situation, what goes wrong or is missing, and who runs into it (guests, operators setting up an event, developers). A finished pull request that does not fit the direction of the project is hard to merge, however well it works. Discussing the approach first saves work on both sides.

## Where the project is heading

MomentoBooth is a photo booth app for many kinds of events and set-ups. A feature should ideally serve or be an extension of that general use, not only one specific set-up. When your use case is specific, we would rather discuss how it can fit in a more general way than merge it as is.

How we make design decisions, and which principles a change is reviewed against, is described in the [engineering principles](documentation/src/engineering_principles.md). It is worth a read before working on anything larger than a bug fix.

## Getting started

The [developer setup](documentation/src/dev_setup.md) describes the tools you need and how to build and run the app on Windows, Linux and macOS.

## Pull requests

- **One change per pull request**. A small, unrelated fix you find along the way gets its own pull request, and unrelated reformatting stays out of the diff
- **Describe the problem and the change** in the description, and state what you tested and what not, including the platforms and hardware (camera, printer) you used
- **Add a changelog line** under `## Unreleased` in `CHANGELOG.md` for every change a user can notice. A change that breaks existing settings, projects or templates goes under `### Breaking changes`
- **Put text that guests see in the localization files** (`lib/l10n/`), not in the code. Ideally, it is translated into all supported languages; generated translations are fine, as long as you mention it in the pull request, and missing translations can be filled in later
- **Run `just check`** before opening the pull request. It runs the same checks as the CI: it regenerates code, then runs the analyzer and the tests. While working, `just check-quick` gives quicker feedback (analyzer and Flutter tests only)
- **Keep the [widget overview](documentation/src/widget_overview.md) up to date** when you add, rename or remove a widget

## Using AI tools

Using AI tools (such as Claude Code, Codex or Copilot) is fine. The repository contains instructions for them in `AGENTS.md`, and a few skills in `.agents/skills/`.

A contribution made with AI help is reviewed like any other. You are expected to understand the change, to be able to explain why it is done this way, and to have reviewed the diff yourself (to the extent that the code structure and patterns are what you expect them to be) before opening the pull request.

## What to expect

MomentoBooth is maintained by a small team in their spare time, so a review can take a while. A review does not only look at whether the code works, but also at whether the approach fits the project. Sometimes the outcome is that we take over the idea and implement it differently; in this case, you are credited of course.

---
name: review-direction
description: Review whether a change to MomentoBooth goes in the right direction, rather than whether its code is correct. Checks the problem framing, alternative approaches, fit with the engineering principles and repository patterns, and whether a new pattern is justified. Use when asked to review the direction, design or approach of a pull request or branch, or alongside /code-review before merging. Takes a PR number, a branch name, or nothing (the current branch against main).
---

# Direction review

`/code-review` finds defects in the code. This review answers different questions:

- Is this the right problem to solve, and is it solved at the right level?
- Is there a simpler or better way, possibly one the author did not consider?
- Does the change follow the patterns of the repository, or is a new pattern justified here?
- Does it fit the principles of the project, given how much each principle weighs?

Do not report correctness bugs, style nits or naming, unless they point to a direction problem. Do not edit code and do not post anything to GitHub unless asked.

## Step 0: load the principles

Read `documentation/src/engineering_principles.md` completely. It is the yardstick for this review. Note the weight of each principle (rule, strong, default); the weight decides how you respond to a deviation (see step 6).

## Step 1: gather the intent, without the diff

Collect what the change is meant to do **before** reading the code, so the chosen solution does not anchor your own thinking.

- **PR target**: `gh pr view <n> --json title,body,author,labels,closingIssuesReferences,files,commits`, plus linked issues and the existing discussion: conversation comments (`gh pr view <n> --comments`), reviews (`gh api repos/{owner}/{repo}/pulls/<n>/reviews`) and inline review comments (`gh api repos/{owner}/{repo}/pulls/<n>/comments`)
- **Branch target** (default: current branch against `main`): `git log --format='%s%n%b' main..<branch>` and `git diff --stat main...<branch>`
- The lines the change adds to `CHANGELOG.md`

Only use the commit messages and the list of changed files here, not the diff itself. From the PR description, read the problem, motivation and linked issues now; leave sections that describe the solution (design decisions, implementation notes, diagrams) for step 5. When the description mixes the two, anchoring cannot be avoided completely; just be aware of it in step 4.

## Step 2: classify the change

Decide how central and how reversible the change is, and set the depth of the review accordingly. State the classification at the top of the output.

| | Examples |
|---|---|
| **Central** | Capture and live view pipeline, image processing and vision, print routing, the settings model, project and template formats, the Rust-Dart boundary, subsystems, build and CI |
| **Peripheral** | A single screen, visuals, documentation, a non-core feature (such as the license overview) |
| **Hard to reverse** | File and settings formats, data models, ownership of a pipeline, a new (native) dependency, a new architectural pattern, removed behaviour |
| **Easy to reverse** | An implementation behind an existing interface, UI layout, internal refactors |

- **Light** (peripheral and easy to reverse): only check for an obviously simpler alternative and for rule deviations. At most three findings
- **Normal** (central but easy to reverse, or peripheral but hard to reverse): all steps, at most six findings
- **Deep** (central and hard to reverse): all steps thoroughly, including searching the code base for existing mechanisms, at most ten findings. Also consider whether the decision deserved discussion before the implementation started; for a PR that is already finished, that becomes a question when the approach can still change, and is left out otherwise

For a large diff, do not read everything with the same attention. Read the data model, persistence, runtime behaviour and public interfaces fully, and skim UI code and generated or mechanical changes.

## Step 3: state the problem

Write down the problem in terms of the photo booth: the situation, its effect, and who it affects (guest, operator, developer, contributor). If the PR does not make the problem clear, that is the first question to ask, and the rest of the review is provisional.

## Step 4: think of alternatives

Still before reading the diff, sketch two or three plausible approaches. Always consider:

- **Doing less**: a smaller change, or not doing it at all
- **Using what exists**: an existing manager, subsystem, widget (check `documentation/src/widget_overview.md`), setting or concept that could carry the feature. Search the code base for it
- **Fixing it elsewhere**: upstream in a dependency, or at the cause instead of the symptom

Search the target branch for mechanisms the change could use. When the change replaces or removes an existing mechanism, also look at how `main` did it (`git show origin/main:<path>`): the old behaviour is part of the comparison, and behaviour that silently disappears (such as skipping an unavailable device) is a direction question.

For a light review, one quick alternative is enough.

## Step 5: read the diff and compare

Now read the diff (`gh pr diff <n>` or `git diff main...<branch>`). Determine the approach the author chose and compare it with your alternatives:

- Does it match one of them? If it is different, is it better, and what does it give up?
- Does it introduce a new pattern (a new kind of manager, state handling, navigation, theming, error handling, persistence)? Then check whether an existing pattern covers the need. If the new pattern is better, ask whether existing code should move to it, and whether that belongs in this PR or in a follow-up
- Does it touch one of the **known debts** in the principles? Reducing a debt is a plus; extending it (such as a third copy of duplicated code) needs a reason

## Step 6: check the principles

Go through the principles that are relevant to this change. Respond to a deviation according to its weight:

- **Rule**: report it as an issue
- **Strong**: when the PR gives a reason, accept it or discuss the reason; when it gives none, ask for it
- **Default**: only raise it when another choice is clearly better, or when the choice is not obvious and the PR does not explain it

Specific situations that always deserve a question:

- **New setting**: is it sensible to make this configurable, could it be "Auto", does it make the common path heavier, should it sit behind a simple selection, should it be a project setting, and is its default chosen deliberately?
- **Changed format** (settings, project, template, data model) **or removed behaviour**: what happens to an existing project after the upgrade, and what does the operator see?
- **Changelog**: are the user-visible changes listed under `## Unreleased` (not under a version that is already released), under the right heading, with breaking changes under `### Breaking changes`?
- **New abstraction or general mechanism with a single user**: which second user does the PR name, and does the effort now outweigh rebuilding later, given how central the system is? "Keeping future platforms possible" alone does not justify an abstraction; it only requires not making them impossible
- **New dependency**: is it maintained, license-compatible, portable across platforms (Rust-native where possible), and was it tried against alternatives on our use case?
- **Narrowly tailored feature** (often from an outside contributor): does it serve the general photo booth user, can it become more general, or should it be an experimental feature? Was the approach discussed beforehand?
- **Claimed improvement** (performance, reliability): was it measured?
- **Workaround**: is there an upstream issue or fix, and is the workaround named and contained?
- **Tests**: are they in proportion to the cost of manual verification, and do they test behaviour at a stable boundary rather than the implementation? Ask about missing tests for pure logic, and about tests that will break on every small change

## Context on how decisions are made

- Many decisions are made in conversations between the maintainers that are not on GitHub. When a choice has no visible rationale, **ask** about it instead of assuming it is wrong
- Maintainers review outside their own area of expertise too. An approval there says little about the direction, so do not treat an existing approval as an endorsement
- Build, CI and packaging changes are often written with AI help and get little human review. Review those thoroughly yourself
- When a principle seems wrong for the case at hand, say so. That is feedback for the principles document, not a finding against the PR
- Some examples in the principles document come from earlier pull requests. When the PR under review is the origin of an example, that example is not independent support for the PR's approach

## Output

Write in the language of the conversation; use English when the result is meant for GitHub. Keep it short.

1. **Verdict**, one of:
   - *On track*
   - *On track, with questions*
   - *Reconsider the approach*: a clearly better approach exists, worth changing before merging
   - *Take the concept, not the code*: the idea is useful, but reworking the implementation would cost more than starting again from the concept

   Follow it with one sentence on why. The verdict is about the approach: rule deviations that can be fixed locally do not change it, and are listed as issues.
2. **Classification**: central or peripheral, hard or easy to reverse, and the resulting depth
3. **Problem as understood**: two or three sentences
4. **Alternatives considered**: a table with each approach (including the PR's), what it means in practice, and how it compares
5. **Fits well** (optional): at most three short points where the change follows the principles in a way worth keeping
6. **Findings**, grouped as issues (rule deviations), questions and suggestions. Each one names the principle or pattern it relates to, the location, and a concrete alternative. An objection to the direction without a concrete alternative is phrased as a question
7. **Follow-ups**: valuable work that is out of scope for this PR

Leave out empty sections. Do not pad the review: "On track" with no findings is a valid result.

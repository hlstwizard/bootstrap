# TAOUP for OpenCode

Source: *The Art of Unix Programming* by Eric S. Raymond, distilled for day-to-day work in this repo.

## One Lesson

Apply KISS relentlessly: prefer small, simple, composable, inspectable solutions over clever, opaque, or overbuilt ones.

## Core Rules

1. **Modularity**: write simple parts connected by clean interfaces.
2. **Clarity**: clarity is better than cleverness.
3. **Composition**: design programs and modules to work with other programs and modules.
4. **Separation**: separate policy from mechanism; separate interfaces from engines.
5. **Simplicity**: add complexity only where it is strictly necessary.
6. **Parsimony**: do not build a big system when a smaller one will do.
7. **Transparency**: design for visibility so inspection and debugging are easy.
8. **Robustness**: robustness comes from transparency and simplicity.
9. **Representation**: put knowledge into data so logic stays simple and durable.
10. **Least Surprise**: choose behavior and interfaces that match user expectation.
11. **Silence**: when nothing surprising happened, do not add noisy output.
12. **Repair**: when failure is unavoidable, fail noisily and early.
13. **Economy**: conserve programmer time before machine time unless measurement proves otherwise.
14. **Generation**: automate repetitive work; write programs to write programs when useful.
15. **Optimization**: get it working first, then measure, then optimize.
16. **Diversity**: distrust claims of one true way; use the simplest suitable approach.
17. **Extensibility**: leave room for future change without speculative overengineering.

## OpenCode Practice

- Make each change solve one clear problem well.
- Prefer plain text, readable config, and inspectable outputs.
- Prefer simple algorithms and simple data structures.
- Keep outputs machine-friendly and easy to pipe, parse, diff, and review.
- Avoid mixing unrelated concerns in one function, file, or commit.
- Prototype quickly, verify early, and replace clumsy code instead of preserving bad structure.
- Reuse existing tools and conventions before inventing new abstractions.
- Do not optimize for performance without measurement.
- Do the minimum necessary change when the right long-term design is not yet clear.

## Decision Rule

When several implementations are possible, choose the one that is easiest to understand, easiest to inspect, easiest to combine with existing tools, and easiest to change later.

# Principle: Reduce waste

## Context

Work that does not deliver value to the end result is waste. It consumes time, attention, and capacity
without contributing to the outcome. Waste is often invisible because it is embedded in processes
that feel productive — handoffs, reviews, approvals, extra features, rework — but each of these
is a symptom of a system that could be designed better.

## Principle

Identify and eliminate work that does not contribute to the desired outcome.

Lean manufacturing identified seven categories of waste. Adapted to software [^1], they are:

1. **Partially done work.** Unfinished features, branches not merged, work in progress that delivers no value.
   Partially done work ties up capacity, creates merge risk, and decays as the codebase moves on.

2. **Extra features.** Functionality nobody asked for or needs. Every feature carries ongoing cost —
   maintenance, testing, documentation, cognitive load. Code that is not needed is not an asset; it is a liability.

3. **Relearning.** Rediscovering something that was already known but not captured or communicated.
   When knowledge exists only in someone's head, every absence triggers relearning.
   When conventions are implicit, every new contributor relearns them through trial and error.

4. **Handoffs.** Transferring work between people or teams, losing context at each boundary.
   Each handoff is a lossy compression — assumptions are dropped, intent is simplified,
   and the receiving side fills the gaps with guesses.

5. **Task switching.** Context-switching between multiple concurrent tasks.
   The cost is not the switch itself but the reload time — rebuilding the mental model of the work
   that was interrupted. Small tasks interleaved with large tasks destroy throughput on the large tasks.

6. **Delays.** Waiting for decisions, approvals, reviews, dependencies, environments.
   Delays are the most common waste and the hardest to see because they look like idle time, not active cost.
   But every delay extends the feedback loop, and long feedback loops produce stale assumptions.

7. **Defects.** Bugs and errors, especially those that travel far from their point of origin before detection.
   The cost of a defect is proportional to the distance it travels — a typo caught by a linter costs nothing;
   the same typo discovered in production costs an incident.

## Why

Waste compounds. A handoff introduces a delay. The delay causes task switching. The task switching causes relearning.
The relearning introduces a defect. The defect requires partially done work to be revisited.
Eliminating waste at any point in this chain breaks the cascade.

The goal is not to optimize individual steps but to remove the steps that should not exist.
A faster approval process is still slower than no approval process.
A better handoff template still loses more context than no handoff.

## How to apply

When evaluating a process or design, ask: *if I could deliver the same outcome without this step, would I keep it?*
If the answer is no, the step is waste. Either eliminate it or understand what structural constraint makes it necessary —
then address the constraint.

Prefer automation over manual steps. Prefer convention over configuration.
Prefer self-service over approvals. Prefer small batches over large batches.
Prefer fast feedback over deferred validation.

This principle is technology-agnostic. It applies to code, processes, organizational structures,
and any system where human effort is a finite resource.

## References

[^1]: Mary and Tom Poppendieck, *Lean Software Development: An Agile Toolkit* (2003) — Mapped the seven manufacturing wastes (Taiichi Ohno, Toyota Production System) to software development. The seven wastes provide a taxonomy for identifying non-value-adding work in any software delivery process.

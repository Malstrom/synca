<!-- Agent prompt comment — post this on the task issue before adding label:agent.
     Read by the model during async execution together with a subset of .calvin/*.
     Rules:
       - Do NOT repeat content already in the issue body verbatim.
       - Do NOT serialize entire .calvin/* files.
       - Max 5 entry points. If more are needed, the task is too wide.
       - Every sentence must carry information needed to implement the task.
         If it can be cut without loss, cut it.
       - Examples must reference existing code with a one-line summary, never paste full blocks.
-->

## Goal

<!-- only if it adds precision beyond the issue Goal — otherwise omit -->

## Entry points

- `path/to/file.rb` — [role in this task]
- `path/to/other.rb` — [role in this task]

## Constraints

<!-- only rules from .calvin/conventions.yml that directly apply to this task -->

- [constraint 1]
- [constraint 2]

## Tests

<!-- what to test and how, from .calvin/testing.yml, specific to this task -->

- [test case 1: condition → expected result]
- [test case 2]

## Depends on

<!-- #N must be merged before starting | none -->

## Context

<!-- only information NOT already in the issue body but critical to avoid mistakes -->

## Examples

<!-- precise references to existing code with a one-line summary of what to replicate -->

- `path/to/existing.rb` — [what pattern to follow]

@README.md

## Design and grammar
Matsuri is designed with patterns following the ideas of Roy Fielding and
Christopher Alexander. Specifically, patterns are developed as a *grammar*.
Properties are identified, and constraints that induces those properties are
derived. The grammar allows the pattern to be used and extended while staying
coherent. The grammars are found in docs/design/*. Golden paths are developed
from the grammar.

Anti-patterns are defined as violation of constraints. When constraints are
violated, the induced properties disappear. While this may result in fighting
against the architecture, guardrails are rarely implemented. This allows users
to use underlying primitives and algeabras to form a grammar more suitable for
their use-case.

It is highly recommended that the coding agent discuss usage or extensions
using the grammar with its human partner.

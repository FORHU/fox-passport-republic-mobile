# FoxPassport Republic Mobile Rules

## 1. Mandatory Branching & Checkpoints
- **Always Create a Branch for New Features/Tasks**: Before modifying or creating code for any new feature, bug fix, or optimization, **always create and checkout a dedicated Git branch** (e.g. `feat/<feature-name>`, `fix/<bug-name>`, `perf/<topic>`). Never develop directly on `main` or `master`.
- **Establish Baseline Checkpoints**: Always commit and/or tag a clean baseline checkpoint before starting risky or multi-step changes so work can be rolled back safely.

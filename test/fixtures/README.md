# Test fixtures

## web_validation_vectors.json

Ground truth for `test/core/utils/validators_test.dart`: the web app's **real**
zod schemas (`fox-passport-republic-app/src/shared/lib/schema.ts`) run over a
set of inputs, recording the first error message per field (or `null`).

Regenerate whenever the web schema changes, from this repo's root:

    node --no-warnings test/fixtures/generate_web_validation_vectors.mjs

(Node 22+, which strips TypeScript types; the web repo must be checked out at
`../fox-passport-republic-app` with its dependencies installed.) Then update
`lib/core/utils/validators.dart` until `flutter test` passes again.

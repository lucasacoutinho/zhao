# Zhao

Zhao targets Bend 2.0.16. Read `bend guide` before editing Bend code. Use the
pinned `.tools/bend/bin/bend` installation (`make setup`) or set `BEND`.

Keep public constructors, builders, parsing, and dispatch in `src/zhao.bend`;
`src/text.bend` holds token and text helpers. Match existing affine annotations
and declaration ordering. Keep parsing pure. Preserve token order; parallelize
independent computations when their cost is comparable.

Publish only the modules in `src/`. Keep `src/LAWS.bend` and `src/PROOF.bend`
with the library. Runtime imports must stay inside Zhao and Bend Base.
Bootstrap CI and publishing must work with Zhao checked out on its own.
The optional local parser suite imports the adjacent `../best` Bend library
through `tests/main.bend`. Keep it outside the package until Best has a stable
published release. Keep process checks in POSIX shell without Python.

Run `make check`, `make cli-check`, and `make native-cli-check` for releases.
For parser changes, also run `make test` and `make native-test` when the adjacent
Best checkout is available. Run `bend src/PROOF.bend` before committing.
Keep laws aligned with explicit requirements and prove their claims.
Report unavailable checks.

Document public behavior and Commander differences in `README.md`.
Keep `.build/` and `.tools/` out of source packages and commits.
`make publish` uploads to Bendhub; local verification targets do not publish.

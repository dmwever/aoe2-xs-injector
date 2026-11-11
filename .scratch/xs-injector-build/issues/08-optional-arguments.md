# 08: Optional arguments

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent may leave out a function's optional parameters, and XS applies its own defaults exactly as hand-written code would.

**Blocked by:** 05: Run one int call

**Status:** resolved

- [x] Driver accepts any argument count within `min_param_count..param_count` and sends that count
- [x] Module dispatches to the call site for that count
- [x] Driver-seam tests cover the count range for a function with optional parameters
- [x] Live: `round` with one argument equals `round` with its default given explicitly

## Answer

2026-11-11. The driver range check (`_validate`), the per-count call sites (`_case` in the generator) and the core's `BadArgCount` check landed with earlier slices; this slice adds the driver-seam coverage and the live proof.

- Driver seam: `tests/test_optional_arguments.py` sends `xsClearInstructions` with 0, 1 and 2 arguments and `round` with 1 and 2, checking the exact count on the wire; out-of-range counts stay covered by `test_too_few/too_many_arguments_is_invalid` in `tests/test_run.py`.
- Generator seam: `test_dispatch_has_one_case_per_function_and_one_call_site_per_allowed_argument_count` (already present). This slice adds no new test for module-side dispatch by count; that rests on this generator test plus the live run below.
- Live (request 42, XsTesting): `round(2.71828)` = `round(2.71828, 2)` = 2.72, while `places` 0 and 4 give 3.0 and 2.7183, so XS applied its own default of 2. A zero-argument `xsClearInstructions` (0..2) returned `true`.

# 08: Optional arguments

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** An agent may leave out a function's optional parameters, and XS applies its own defaults exactly as hand-written code would.

**Blocked by:** 05: Run one int call

**Status:** ready-for-agent

- [ ] Driver accepts any argument count within `min_param_count..param_count` and sends that count
- [ ] Module dispatches to the call site for that count
- [ ] Driver-seam tests cover the count range for a function with optional parameters
- [ ] Live: `round` with one argument equals `round` with its default given explicitly

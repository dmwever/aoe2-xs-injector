# 03: Generator: pinned ids, signatures.json, dispatch

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** The maintainer runs the generator over the KB function catalog, the KB renames file and the pinned name-to-id table, and gets a checked-in `signatures.json`, an updated pinned table, and a generated XS dispatch (with its per-function parameter-type table) that the core module will include. Id stability is enforced at generation time.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `signatures.json` holds, per function: name, function id, parameter types, argument-count range (`min_param_count..param_count`), return type
- [ ] Every catalog function gets an id, File IO, `xsUnsync*` and side-effecting functions included
- [ ] New functions take the next free id; ids are never reused; a rename listed in the renames file keeps its id; a removed function's id is retired
- [ ] The generator fails, naming the function, when a pinned function leaves the catalog without a rename entry
- [ ] The dispatch has one case per function id and one XS call site per allowed argument count, so XS applies its own defaults; arguments come from the staged typed values; non-void results go to the result slot of the function's return type at the call's index
- [ ] The generator emits the parameter-type table the module's parser uses
- [ ] Generator-seam tests on small fixture catalogs cover each id rule, the failure on an unexplained removal, and call sites per argument count

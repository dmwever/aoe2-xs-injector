# XS function injector

An includable XS module that runs function calls an outside agent asks for during a live AoE2:DE match, and hands the results back.

## Language

**Call**:
One XS function invocation the agent asks for: a function id plus its arguments, at a numbered position.
_Avoid_: Injection, command

**Result slot**:
The place a call's return value is kept, identified by that call's number; its type is the called function's return type.
_Avoid_: Register, current injected value

**Literal argument**:
An argument whose value the agent writes out in full.

**Reference argument**:
An argument that names an earlier call in the same request and takes that call's result.
_Avoid_: Pointer, register

**Driver**:
The program on the agent's side that turns calls into a request and a response back into values.
_Avoid_: Client, bridge, agent tool

**Function id**:
The pinned integer that names one catalog function in a call.
_Avoid_: Function index, opcode

# XS function injector

An includable XS module that runs function calls an outside agent asks for during a live AoE2:DE match, and hands the results back.

## Language

**Request**:
An ordered list of calls the agent hands the module in one go, identified by a request id; it runs at most once.
_Avoid_: Batch, command file

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

**Response**:
What the module hands back for one request: the request id it answers, a request status, and one entry per call in call order.
_Avoid_: Result file, output

**Entry**:
One call's part of a response: its status, and its value when the call succeeded and returns something.
_Avoid_: Result row

**Response section**:
The response as it sits in the game's own `.xsdat`, at the end of the file, findable from the end without knowing what precedes it.
_Avoid_: Injector block, footer

**Host**:
A scenario or mod that already writes the game's own `.xsdat` and has opted in to carry the response section in each of its writes.
_Avoid_: Owner, parent mod

**Standalone**:
The module's mode with no host, where it writes the game's own `.xsdat` itself.

**Driver status**:
An outcome the driver reports on its own, never carried on the wire, as distinct from the request status the module sends back.
_Avoid_: Client error, local status

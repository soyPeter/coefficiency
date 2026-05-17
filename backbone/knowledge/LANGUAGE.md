# Language

Shared vocabulary for architecture discussions. Use these terms exactly — don't substitute "component," "service," "API," or "boundary." Consistent language is the whole point.

## Terms

**Module**
Anything with an interface and an implementation. Scale-agnostic — applies to a function, class, package, or tier-spanning slice.
_Avoid_: unit, component, service.

**Interface**
Everything a caller must know to use the module correctly. Includes type signature, invariants, ordering constraints, error modes, required config, and performance characteristics.
_Avoid_: API, signature (too narrow).

**Implementation**
What's inside a module — its body of code. Distinct from **Adapter**.

**Depth**
Leverage at the interface — the amount of behaviour a caller (or test) can exercise per unit of interface they have to learn. A module is **deep** when a large amount of behaviour sits behind a small interface. **Shallow** when the interface is nearly as complex as the implementation.

**Seam** _(from Michael Feathers)_
A place where you can alter behaviour without editing in that place. The *location* at which a module's interface lives.
_Avoid_: boundary (overloaded with DDD's bounded context).

**Adapter**
A concrete thing that satisfies an interface at a seam. Describes *role* (what slot it fills), not substance.

**Leverage**
What callers get from depth. More capability per unit of interface.

**Locality**
What maintainers get from depth. Change, bugs, knowledge, and verification concentrate at one place.

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be internally composed of small parts — they just aren't part of the interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't introduce a seam unless something actually varies across it.

## Relationships

- A **Module** has exactly one **Interface**.
- **Depth** is a property of a **Module**, measured against its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam** and satisfies the **Interface**.
- **Depth** produces **Leverage** for callers and **Locality** for maintainers.

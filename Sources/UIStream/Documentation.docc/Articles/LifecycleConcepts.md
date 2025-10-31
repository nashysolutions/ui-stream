# Lifecycle Concepts
Understand the events emitted by the stream.

`UIStream` publishes ``Lifecycle`` values, pairing a `member` with a ``LifecyclePhase``:

- ``LifecyclePhase/animateIn`` — begin showing.
- *(Middle)* — either waits ``QueueMember/restDuration`` (`.timed`) or for ``UIStream/unblock()`` (`.blocker`).
- ``LifecyclePhase/animateOut`` — begin hiding.
- ``LifecyclePhase/hidden`` — fully removed.
- ``LifecyclePhase/reject`` — the item was cancelled before it could start showing.

> Note: On cancellation during any awaited phase, the stream ensures a clean termination by emitting `.animateOut` (if necessary) followed by `.hidden` for the currently showing item.

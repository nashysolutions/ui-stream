# ``UIStream``

Serialised UI lifecycle events for queued items, driven by an actor and published via AsyncStream.

`UIStream` manages a FIFO queue of members conforming to ``QueueMember``. Each member progresses through phases defined by ``LifecyclePhase`` (animate-in, optional middle, animate-out, hidden). The stream emits ``Lifecycle`` values for observers to react to in UI code.

## Overview

- ``UIStream`` is an `actor` that serialises work and emits events.
- ``QueueMember`` describes timing and behaviour of each queued item.
- ``QueueMemberType`` distinguishes *timed* vs *blocker* items.
- ``Lifecycle`` wraps a member and its current ``LifecyclePhase``.
- Observers consume ``UIStream/stream`` as an `AsyncStream`.

> Tip: Use ``UIStream/enqueue(_:)-(Member)`` to add items, and ``UIStream/unblock()`` to progress a blocker-style item.

### Concurrency
The `UIStream` actor provides single-threaded access to its internal queue and coordinates blocker continuations using `withCheckedContinuation`.

## Topics

### Essentials
- <doc:UsingUIStream>
- <doc:QueueMemberProtocol>
- <doc:LifecycleConcepts>

### Types
- ``UIStream``
- ``QueueMember``
- ``QueueMemberType``
- ``Lifecycle``
- ``LifecyclePhase``

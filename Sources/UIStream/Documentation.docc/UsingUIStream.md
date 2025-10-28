# Using UIStream
Manage queued UI presentations with serialised lifecycle events.

## Add the stream

Create a stream instance in a long‑lived scope (e.g. a view model). Subscribe to ``UIStream/stream`` to render changes.

```swift
import Foundation

// Example member type
struct Toast: QueueMember {
    struct ToastID: Hashable, Sendable { let rawValue: UUID }
    var id: ToastID
    var memberType: QueueMemberType
    var transitionDuration: Duration
    var restDuration: Duration
    var endDelay: Duration
}

// Create a UIStream for Toast
let stream = UIStream<Toast>()

// Observe events (e.g. in a Task)
Task {
    for await event in stream.stream {
        let duration = event.member.transitionDuration
        switch event.phase {
        case .animateIn:
            // show the toast
            break
        case .animateOut:
            // start hiding animation
            break
        case .hidden:
            // remove from view hierarchy
            break
        case .reject:
            // item was cancelled before showing
            break
        }
    }
}
```

## Enqueue items

Timed items auto‑complete after ``QueueMember/restDuration``. Blockers wait for an explicit ``UIStream/unblock()``.

```swift
// Timed example
let timed = Toast(
    id: .init(rawValue: UUID()),
    memberType: .timed,
    transitionDuration: .milliseconds(250),
    restDuration: .seconds(2),
    endDelay: .milliseconds(100)
)
await stream.enqueue(timed)

// Blocker example
let blocker = Toast(
    id: .init(rawValue: UUID()),
    memberType: .blocker,
    transitionDuration: .milliseconds(300),
    restDuration: .zero, // ignored for blockers
    endDelay: .milliseconds(100)
)
await stream.enqueue(blocker)

// Later, progress the blocker
await stream.unblock()
```

## Exclusivity & Cancellation

Use ``UIStream/enqueueExclusively(_:)`` to flush pending work and show a single item next. Call ``UIStream/cancelAll()`` to stop the runner, clear the queue, and ensure currently showing items emit a final ``LifecyclePhase/hidden``.

```swift
await stream.enqueueExclusively(timed)
await stream.cancelAll()
```

## Rendering hints

- Treat events as *hints* to drive animations; your view state should remain the source of truth.
- The same member instance will emit a sequence: `.animateIn` → *(middle)* → `.animateOut` → `.hidden`.
- On cancellation mid‑show, you may receive `.animateOut` immediately followed by `.hidden`.

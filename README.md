# UIStream

> Serialised UI lifecycle events for queued items, driven by an actor and published via `AsyncStream`.

## Overview

`UIStream` is a small Swift package that helps you **sequence and coordinate transient UI elements** (toasts, banners, alerts, etc.) in a clean, actor-based way.

It serially processes items conforming to ``QueueMember`` and emits ``Lifecycle`` events through an `AsyncStream`.  
Each item progresses through a predictable sequence of phases:

```swift
.animateIn → (middle phase) → .animateOut → .hidden
```

Timed items auto-complete after a rest duration, while blocker-style items wait to be explicitly unblocked before continuing.

---

## Example

```swift
import UIStream
import Foundation

// 1. Define a QueueMember
struct Toast: QueueMember {
    struct ID: Hashable, Sendable { let rawValue = UUID() }
    let id: ID
    let memberType: QueueMemberType
    let transitionDuration: Duration
    let restDuration: Duration
    let endDelay: Duration
}

// 2. Create and observe the stream
let stream = UIStream<Toast>()

Task {
    for await event in stream.stream {
        let duration = event.member.transitionDuration
        switch event.phase {
        case .animateIn:
            print("Show \(event.member.id)")
        case .animateOut:
            print("Hide \(event.member.id)")
        case .hidden:
            print("Removed \(event.member.id)")
        case .reject:
            print("Cancelled \(event.member.id)")
        }
    }
}

// 3. Enqueue a toast
await stream.enqueue(
    Toast(
        id: .init(),
        memberType: .timed,
        transitionDuration: .milliseconds(250),
        restDuration: .seconds(2),
        endDelay: .milliseconds(100)
    )
)

![](https://github.com/user-attachments/assets/95c794d3-b245-4827-ab26-2dff4bc1f728)

## Overview
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnashysolutions%2Fui-stream%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/nashysolutions/ui-stream)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnashysolutions%2Fui-stream%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/nashysolutions/ui-stream)

`UIStream` is a small Swift package that helps you **sequence and coordinate transient UI elements** (toasts, banners, alerts, etc.) in a clean, actor-based way.

It serially processes items conforming to ``QueueMember`` and emits ``Lifecycle`` events through an `AsyncStream`.  
Each item progresses through a predictable sequence of phases:

```swift
.animateIn → (middle phase) → .animateOut → .hidden
```

Timed items auto-complete after a rest duration, while blocker-style items wait to be explicitly unblocked before continuing.

### 🎥 Video Demonstration

A short demonstration of the queuing concept is available on YouTube:  
[🎥 Watch the demo on YouTube](https://youtu.be/NwNMM_SQhDY)

> *The video showcases an earlier implementation using `NSOperation` and Combine, but the lifecycle sequencing remains identical.* The new actor-based design provides improved concurrency safety, simpler composition, and cleaner cancellation handling — while preserving the same lifecycle semantics demonstrated in the video.

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

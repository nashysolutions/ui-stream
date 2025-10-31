# QueueMember Protocol
Define items that participate in a queued lifecycle.

A ``QueueMember`` provides:

- A stable ``QueueMember/ID`` and ``QueueMember/id`` for identity.
- Behaviour via ``QueueMember/memberType`` (``QueueMemberType/blocker`` or ``QueueMemberType/timed``).
- Timing via ``QueueMember/transitionDuration``, ``QueueMember/restDuration``, and ``QueueMember/endDelay``.

```swift
public protocol QueueMember: Sendable, Hashable {
    associatedtype ID: Hashable & Sendable
    var id: ID { get }
    var memberType: QueueMemberType { get }
    var transitionDuration: Duration { get }
    var restDuration: Duration { get }
    var endDelay: Duration { get }
}
```

### Choosing a type
- Use ``QueueMemberType/timed`` for transient UI (toasts, banners).
- Use ``QueueMemberType/blocker`` for flows that require user action (alerts, permission prompts).

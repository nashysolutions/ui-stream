//
//  QueueMember.swift
//  ui-stream
//
//  Created by Robert Nash on 27/10/2025.
//

import Foundation

/// A unit of work or presentation that participates in a queued lifecycle.
///
/// Conforming types represent items that can be enqueued, transitioned in,
/// optionally rest, and transitioned out. The protocol models the timing
/// characteristics for these phases and requires stable identity so instances
/// can be tracked in collections and lifecycles.
///
/// Conformance to `Sendable` indicates instances are safe to pass across
/// concurrency domains, and `Hashable` supports efficient diffing and
/// de-duplication in queues.
///
/// Typical lifecycle phases are described by ``LifecyclePhase`` and are
/// reported via ``Lifecycle`` events.
public protocol QueueMember: Sendable, Hashable {
    /// A stable identifier type for the member.
    ///
    /// Use an identifier that uniquely distinguishes the member among items
    /// in the queue. The identifier must be both `Hashable` and `Sendable`.
    associatedtype ID: Hashable & Sendable
    
    /// The unique identifier for this member.
    var id: ID { get }
    
    /// The behavior classification for this member within the queue.
    ///
    /// Use ``QueueMemberType/blocker`` for items that should prevent subsequent
    /// items from entering until they complete, and ``QueueMemberType/timed`` for
    /// items that auto-complete after a rest period.
    var memberType: QueueMemberType { get }
    
    /// The duration for each transition animation.
    ///
    /// This value should represent the time to animate into view and to animate
    /// out of view. Implementations may apply this symmetrically or
    /// distinguish between phases if needed.
    var transitionDuration: Duration { get }
    
    /// The time to remain visible after animating in, before animating out.
    ///
    /// Used only for ``QueueMemberType/timed`` members. For ``QueueMemberType/blocker``
    /// members, this value is typically ignored.
    var restDuration: Duration { get }
    
    /// An additional delay after the animate-out transition completes, before hiding.
    ///
    /// Use this to provide a small buffer for compositing or to coordinate with
    /// subsequent items in the queue.
    var endDelay: Duration { get }
}

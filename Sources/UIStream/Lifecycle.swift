//
//  Lifecycle.swift
//  ui-stream
//
//  Created by Robert Nash on 28/10/2025.
//

import Foundation

/// A value describing a member and its current lifecycle phase.
///
/// Emitted by systems that manage queues to report state changes for a
/// particular ``QueueMember``.
public struct Lifecycle<Member: QueueMember>: Sendable {
    /// The member whose lifecycle is being reported.
    public let member: Member
    /// The current phase for the member.
    public let phase: LifecyclePhase
}

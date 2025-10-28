//
//  QueueMemberType.swift
//  ui-stream
//
//  Created by Robert Nash on 28/10/2025.
//

import Foundation

/// The behavior classification for items in a queue.
///
/// These cases influence scheduling and visibility semantics.
public enum QueueMemberType: Sendable {
    /// Blocks subsequent items from entering until this item finishes.
    case blocker
    /// Auto-completes after ``QueueMember/restDuration`` and then transitions out.
    case timed
}

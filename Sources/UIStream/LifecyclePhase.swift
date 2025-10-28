//
//  LifecyclePhase.swift
//  ui-stream
//
//  Created by Robert Nash on 28/10/2025.
//

import Foundation

/// The phases a queued member can progress through.
public enum LifecyclePhase: Sendable {
    /// The item was queued but cancelled before its animate-in began.
    case reject
    /// The item is animating into view.
    case animateIn
    /// The item is animating out of view.
    case animateOut
    /// The item is not visible and no longer active in the queue.
    case hidden
}

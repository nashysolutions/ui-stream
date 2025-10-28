//
//  UIStream.swift
//  ui-stream
//
//  Created by Robert Nash on 27/10/2025.
//

import Foundation

/// An actor that serially processes ``QueueMember`` items and emits lifecycle events.
///
/// `UIStream` manages a FIFO queue of members and drives their lifecycle by
/// emitting ``Lifecycle`` events via an `AsyncStream`. Each member progresses
/// through phases defined by ``LifecyclePhase`` (animate-in, optional middle
/// phase, animate-out, then hidden). The actor ensures serialized execution
/// and provides coordination for blocker-style members that must be explicitly
/// unblocked before proceeding.
///
/// Access the read-only event stream via ``UIStream/stream`` and enqueue work
/// with ``UIStream/enqueue(_:)-(Member)`` or ``UIStream/enqueueExclusively(_:)``.
public actor UIStream<Member: QueueMember> {
    
    /// Represents the current state of the member.
    public typealias MemberLifecycleState = Lifecycle<Member>

    /// The immutable channel that carries ``MemberLifecycleState`` events to observers.
    private let channel = AsyncStream<MemberLifecycleState>.makeStream()

    /// A nonisolated, read-only event stream of lifecycle updates.
    ///
    /// This is safe to access from any concurrency domain because the underlying
    /// stream reference is immutable and `Sendable`.
    public nonisolated var stream: AsyncStream<Lifecycle<Member>> { channel.stream }

    /// Creates a new, empty stream with no queued members.
    public init() {}

    /// Emit a lifecycle value to observers.
    private func send(_ value: Lifecycle<Member>) {
        channel.continuation.yield(value)
    }

    /// Convenience to emit a ``Lifecycle`` for a given member and phase.
    private func emit(_ member: Member, phase: LifecyclePhase) {
        send(.init(member: member, phase: phase))
    }

    /// The FIFO of pending members awaiting execution.
    private var queue: [Member] = []

    /// The currently running task that drains the queue in FIFO order.
    ///
    /// When `nil`, no work is in progress and a new runner will be started on
    /// the next enqueue.
    private var runner: Task<Void, Never>? = nil

    /// Coordination state for blocker-style members.
    ///
    /// When the current member is a blocker, execution suspends until
    /// ``UIStream/unblock()`` is invoked, resuming via this continuation.
    private var blockerContinuation: CheckedContinuation<Void, Never>? = nil
    private var currentlyShowing: Member? = nil

    /// Enqueue a single member for processing.
    ///
    /// If no runner is active, this starts the runner to drain the queue.
    /// - Parameter member: The member to enqueue.
    public func enqueue(_ member: Member) {
        queue.append(member)
        startRunnerIfNeeded()
    }

    /// Enqueue multiple members for processing in the order provided.
    ///
    /// If no runner is active, this starts the runner to drain the queue.
    /// - Parameter members: The members to enqueue.
    public func enqueue(_ members: [Member]) {
        queue.append(contentsOf: members)
        startRunnerIfNeeded()
    }

    /// Cancel any in-flight and pending work, then enqueue only this member.
    ///
    /// This clears the queue and cancels the current runner (if any), ensuring
    /// that the provided member becomes the next and only item to process.
    /// - Parameter member: The exclusive member to enqueue.
    public func enqueueExclusively(_ member: Member) {
        cancelAllInternal()
        queue = [member]
        startRunnerIfNeeded()
    }

    /// Progress the current blocker, if one is waiting.
    ///
    /// If the currently executing member is of type ``QueueMemberType/blocker``,
    /// calling this method resumes execution so the member can animate out and the
    /// queue can continue.
    public func unblock() {
        blockerContinuation?.resume()
        blockerContinuation = nil
    }

    /// Cancel all in-flight and pending work.
    ///
    /// If a blocker is currently showing, this ensures a final ``LifecyclePhase/hidden``
    /// event is emitted for a clean lifecycle termination.
    public func cancelAll() {
        cancelAllInternal()
    }

    /// Start the queue-draining runner task if it is not already running.
    private func startRunnerIfNeeded() {
        guard runner == nil else { return }
        runner = Task { await runLoop() } // capture strongly; we nil it on exit
    }

    /// Drain the queue in FIFO order, respecting cancellation and emitting
    /// appropriate lifecycle events.
    private func runLoop() async {
        defer { runner = nil }
        while let member = queue.first {
            queue.removeFirst()

            if Task.isCancelled {
                emit(member, phase: .reject)
                continue
            }
            await run(member)
        }
    }

    /// Execute the full lifecycle for a single member.
    ///
    /// The sequence is:
    /// 1. Emit ``LifecyclePhase/animateIn`` and wait ``QueueMember/transitionDuration``.
    /// 2. Middle phase:
    ///    - For ``QueueMemberType/timed``: wait ``QueueMember/restDuration``.
    ///    - For ``QueueMemberType/blocker``: suspend until ``UIStream/unblock()``.
    /// 3. Emit ``LifecyclePhase/animateOut`` and wait ``QueueMember/transitionDuration``.
    /// 4. Wait ``QueueMember/endDelay`` and emit ``LifecyclePhase/hidden``.
    ///
    /// If cancelled during any wait, ensures a clean end via ``ensureHiddenIfNeeded(for:)``.
    private func run(_ member: Member) async {
        currentlyShowing = member

        // animateIn
        emit(member, phase: .animateIn)
        do { try await Task.sleep(for: member.transitionDuration) }
        catch { await ensureHiddenIfNeeded(for: member); return }

        // middle phase
        switch member.memberType {
        case .timed:
            do { try await Task.sleep(for: member.restDuration) }
            catch { await ensureHiddenIfNeeded(for: member); return }

        case .blocker:
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                blockerContinuation = cont
            }
        }

        // animateOut
        emit(member, phase: .animateOut)
        do { try await Task.sleep(for: member.transitionDuration) }
        catch { await ensureHiddenIfNeeded(for: member); return }

        // endDelay + hidden
        do { try await Task.sleep(for: member.endDelay) } catch { /* ignore */ }

        emit(member, phase: .hidden)
        currentlyShowing = nil
    }

    /// Ensure a clean lifecycle termination for a member when cancelled mid-show.
    ///
    /// If the provided member is currently showing, this emits
    /// ``LifecyclePhase/animateOut`` followed by ``LifecyclePhase/hidden``.
    private func ensureHiddenIfNeeded(for member: Member) async {
        guard currentlyShowing == member else { return }
        emit(member, phase: .animateOut)
        emit(member, phase: .hidden)
        currentlyShowing = nil
    }

    /// Internal implementation for ``UIStream/cancelAll()``.
    ///
    /// Cancels the runner, clears the queue, and resumes any blocker continuation
    /// so that the current member can finish and emit a final
    /// ``LifecyclePhase/hidden``.
    private func cancelAllInternal() {
        runner?.cancel()
        runner = nil
        queue.removeAll()

        // If a blocker is waiting, resume it so run(_:) can finish and emit `.hidden`.
        blockerContinuation?.resume()
        blockerContinuation = nil
    }
}

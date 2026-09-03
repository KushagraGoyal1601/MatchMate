//
//  NetworkMonitor.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation
import Network

protocol NetworkMonitoring: Sendable {
    var isConnected: Bool { get }
    func connectionUpdates() -> AsyncStream<Bool>
}

final class NetworkMonitor: NetworkMonitoring, @unchecked Sendable {

    private struct State {
        var isConnected = true
        var subscribers: [UUID: AsyncStream<Bool>.Continuation] = [:]
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.kushagra.MatchMate.network-monitor")
    private let lock = NSLock()
    private var state = State()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.update(isConnected: path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
        let subscribers = lock.withLock { state.subscribers.values }
        subscribers.forEach { $0.finish() }
    }

    var isConnected: Bool {
        lock.withLock { state.isConnected }
    }

    func connectionUpdates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()

            let current = lock.withLock { () -> Bool in
                state.subscribers[id] = continuation
                return state.isConnected
            }
            continuation.yield(current)

            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.state.subscribers.removeValue(forKey: id) }
            }
        }
    }

    private func update(isConnected: Bool) {
        let subscribers = lock.withLock { () -> [AsyncStream<Bool>.Continuation] in
            guard state.isConnected != isConnected else { return [] }
            state.isConnected = isConnected
            return Array(state.subscribers.values)
        }
        subscribers.forEach { $0.yield(isConnected) }
    }
}

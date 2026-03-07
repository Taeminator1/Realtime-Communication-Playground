//
//  NetworkUDPClient.swift
//  NetworkSocket
//
//  Created by Taemin Yun on 2026-03-05.
//

import Foundation
import Network
import SocketClient

// MARK: - Network UDP Client
// Network 프레임워크 기반 UDP 클라이언트.
// NWConnection(.udp)은 내부적으로 비연결형이지만 엔드포인트 경로를 관리한다.
// 주의: NWConnection 콜백 큐(queue)에서 호출하면 데드락이 발생한다.

final public class NetworkUDPClient {
    private var connection: NWConnection?
    private var isReceiving: Bool = false
    private let host: String
    private let port: UInt16
    private let queue = DispatchQueue(label: "NetworkUDPClient")

    public init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }

    deinit {
        stopReceiving()
        close()
    }
}

// MARK: - UDPClientMakable
extension NetworkUDPClient: UDPClientMakable {

    public func close() {
        connection?.cancel()
        connection = nil
    }

    public func send(string: String) -> Int {
        guard let data = string.data(using: .utf8), !data.isEmpty else { return -1 }

        if connection == nil {
            guard let nwPort = NWEndpoint.Port(rawValue: port) else { return -1 }
            let newConnection = NWConnection(
                host: NWEndpoint.Host(host),
                port: nwPort,
                using: .udp
            )
            self.connection = newConnection

            let semaphore = DispatchSemaphore(value: 0)
            var ready = false

            newConnection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    ready = true
                    semaphore.signal()
                case .failed, .cancelled:
                    semaphore.signal()
                default:
                    break
                }
            }

            newConnection.start(queue: queue)
            semaphore.wait()

            guard ready else {
                self.connection = nil
                return -1
            }
        }

        guard let connection else { return -1 }

        let semaphore = DispatchSemaphore(value: 0)
        var sentBytes = -1

        connection.send(content: data, completion: .contentProcessed { error in
            if error == nil {
                sentBytes = data.count
            }
            semaphore.signal()
        })

        semaphore.wait()
        return sentBytes
    }

    public func receive(maxLength: Int) -> String? {
        guard let connection else { return nil }

        let semaphore = DispatchSemaphore(value: 0)
        var received: String?

        connection.receive(minimumIncompleteLength: 1, maximumLength: maxLength) { data, _, _, _ in
            if let data {
                received = String(data: data, encoding: .utf8)
            }
            semaphore.signal()
        }

        let waitResult = semaphore.wait(timeout: .now() + 3)
        if waitResult == .timedOut {
            return nil
        }
        return received
    }

    public func startReceiving(maxLength: Int, onReceive: @escaping (String) -> Void) {
        guard connection != nil, !isReceiving else { return }
        isReceiving = true
        receiveLoop(maxLength: maxLength, onReceive: onReceive)
    }

    public func stopReceiving() {
        isReceiving = false
    }

    private func receiveLoop(maxLength: Int, onReceive: @escaping (String) -> Void) {
        guard let connection, isReceiving else { return }

        connection.receive(minimumIncompleteLength: 1, maximumLength: maxLength) { [weak self] data, _, _, error in
            guard let self, self.isReceiving else { return }
            if let data, let message = String(data: data, encoding: .utf8) {
                onReceive(message)
            }
            if error == nil {
                self.receiveLoop(maxLength: maxLength, onReceive: onReceive)
            }
        }
    }
}

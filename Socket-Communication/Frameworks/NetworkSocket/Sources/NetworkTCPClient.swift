//
//  NetworkTCPClient.swift
//  NetworkSocket
//
//  Created by Taemin Yun on 2026-03-05.
//

import Foundation
import Network
import SocketClient

// MARK: - Network TCP Client
// Network 프레임워크 기반 TCP 클라이언트.
// 프로토콜 메서드는 동기 API이므로 내부적으로 세마포어를 사용한다.
// 주의: NWConnection 콜백 큐(queue)에서 호출하면 데드락이 발생한다.

final public class NetworkTCPClient {
    private var connection: NWConnection?
    private let host: String
    private let port: UInt16
    private let queue = DispatchQueue(label: "NetworkTCPClient")

    public init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }

    deinit {
        close()
    }
}

// MARK: - TCPClientMakable
extension NetworkTCPClient: TCPClientMakable {

    public func close() {
        connection?.cancel()
        connection = nil
    }

    public func send(string: String) -> Int {
        guard let connection,
              let data = string.data(using: .utf8),
              !data.isEmpty else { return -1 }

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

        semaphore.wait()
        return received
    }

    public func connect() -> Result<Void, TCPConnectionError> {
        close()

        let nwHost = NWEndpoint.Host(host)
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            return .failure(.socketCreationFailed(0))
        }

        let connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)
        self.connection = connection

        let semaphore = DispatchSemaphore(value: 0)
        var connectResult: Result<Void, TCPConnectionError> = .failure(.connectionFailed(0))

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connectResult = .success(())
                semaphore.signal()
            case .failed(let error):
                connectResult = .failure(Self.mapError(error))
                semaphore.signal()
            case .waiting(let error):
                connection.cancel()
                connectResult = .failure(Self.mapError(error))
                semaphore.signal()
            default:
                break
            }
        }

        connection.start(queue: queue)
        semaphore.wait()

        return connectResult
    }

    private static func mapError(_ error: NWError) -> TCPConnectionError {
        switch error {
        case .dns(let dnsError):
            return .hostResolutionFailed("\(dnsError)")
        case .posix(let posixError):
            return .connectionFailed(posixError.rawValue)
        default:
            return .connectionFailed(0)
        }
    }
}

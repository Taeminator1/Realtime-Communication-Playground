//
//  BSDTCPClient.swift
//  BSDTCPClient
//
//  Created by Taemin Yun on 2026-03-01.
//

import Foundation
import Darwin
import SocketClient

// MARK: - BSD TCP Client
// 주의: socketFD는 스레드 세이프하지 않습니다. 동시 접근 시 외부에서 직렬화하세요.

final public class BSDTCPClient {
    private var socketFD: Int32 = -1
    private let host: String
    private let port: UInt16

    public init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }

    deinit {
        close()
    }
}

// MARK: - TCPClientMakable
extension BSDTCPClient: TCPClientMakable {

    public func close() {
        if socketFD >= 0 {
            Darwin.close(socketFD)
            socketFD = -1
        }
    }

    public func send(string: String) -> Int {
        guard socketFD >= 0,
              let data = string.data(using: .utf8),
              !data.isEmpty else { return -1 }
        return data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return -1 }
            var totalSent = 0
            while totalSent < data.count {
                let sent = Darwin.send(socketFD, baseAddress + totalSent, data.count - totalSent, 0)
                if sent <= 0 { return -1 }
                totalSent += sent
            }
            return totalSent
        }
    }

    public func receive(maxLength: Int) -> String? {
        guard socketFD >= 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: maxLength)
        let bytesRead = Darwin.recv(socketFD, &buffer, maxLength, 0)
        if bytesRead == 0 { return nil }
        if bytesRead < 0 { return nil }
        let data = Data(bytes: buffer, count: bytesRead)
        return String(data: data, encoding: .utf8)
    }
    
    public func connect() -> Result<Void, TCPConnectionError> {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        hints.ai_protocol = IPPROTO_TCP

        var result: UnsafeMutablePointer<addrinfo>?
        let portStr = String(port)
        let status = getaddrinfo(host, portStr, &hints, &result)
        guard status == 0, let result = result else {
            let errMsg = (status != 0) ? String(cString: gai_strerror(status)) : "nil result"
            return .failure(.hostResolutionFailed("\(host), \(errMsg)"))
        }
        defer { freeaddrinfo(result) }

        var lastError: TCPConnectionError = .connectionFailed(0)
        var info: UnsafeMutablePointer<addrinfo>? = result
        while let current = info {
            socketFD = Darwin.socket(current.pointee.ai_family, current.pointee.ai_socktype, current.pointee.ai_protocol)
            if socketFD >= 0 {
                let connectResult = Darwin.connect(socketFD, current.pointee.ai_addr, current.pointee.ai_addrlen)
                if connectResult == 0 {
                    return .success(())
                }
                lastError = .connectionFailed(errno)
                Darwin.close(socketFD)
                socketFD = -1
            } else {
                lastError = .socketCreationFailed(errno)
            }
            info = current.pointee.ai_next
        }
        return .failure(lastError)
    }
}

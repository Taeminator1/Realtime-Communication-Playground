//
//  BSDUDPClient.swift
//  BSDSockets
//
//  Created by Taemin Yun on 2026-03-01.
//

import Foundation
import Darwin

// MARK: - BSD UDP Client
// UDP는 비연결형이지만 connect()로 기본 상대를 지정하면 send/recv 사용 가능.
// 주의: socketFD는 스레드 세이프하지 않습니다. 동시 접근 시 외부에서 직렬화하세요.

final public class BSDUDPClient {
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

// MARK: - BSDClientMakable
extension BSDUDPClient: BSDClientMakable {
    
    public func close() {
        if socketFD >= 0 {
            Darwin.close(socketFD)
            socketFD = -1
        }
    }

    public func send(string: String) -> Int {
        guard let data = string.data(using: .utf8), !data.isEmpty else { return -1 }

        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_DGRAM
        hints.ai_protocol = IPPROTO_UDP

        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, String(port), &hints, &result)
        guard status == 0, let resolved = result else { return -1 }
        defer { freeaddrinfo(resolved) }

        var info: UnsafeMutablePointer<addrinfo>? = resolved
        while let current = info {
            let tempFD = Darwin.socket(current.pointee.ai_family, current.pointee.ai_socktype, current.pointee.ai_protocol)
            guard tempFD >= 0 else {
                info = current.pointee.ai_next
                continue
            }
            defer { Darwin.close(tempFD) }

            let sent = data.withUnsafeBytes { buffer -> Int in
                guard let base = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return -1 }
                return Darwin.sendto(tempFD, base, data.count, 0, current.pointee.ai_addr, current.pointee.ai_addrlen)
            }
            return sent >= 0 ? sent : -1
        }
        return -1
    }

    public func receive(maxLength: Int) -> String? {
        guard socketFD >= 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: maxLength)
        let bytesRead = Darwin.recv(socketFD, &buffer, maxLength, 0)
        if bytesRead < 0 { return nil }
        let data = Data(bytes: buffer, count: bytesRead)
        return String(data: data, encoding: .utf8)
    }
}

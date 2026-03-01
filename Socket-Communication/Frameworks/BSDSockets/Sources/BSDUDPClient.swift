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

final public class BSDUDPClient: BSDClientMakable {
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

    public private(set) var lastConnectError: Int32 = 0

    public func connect() -> Bool {
        lastConnectError = 0
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_DGRAM
        hints.ai_protocol = IPPROTO_UDP

        var result: UnsafeMutablePointer<addrinfo>?
        let portStr = String(port)
        let status = getaddrinfo(host, portStr, &hints, &result)
        guard status == 0, let result = result else {
            let errMsg = (status != 0) ? String(cString: gai_strerror(status)) : "nil result"
            print("호스트 조회 실패: \(host), \(errMsg)")
            return false
        }
        defer { freeaddrinfo(result) }

        var info: UnsafeMutablePointer<addrinfo>? = result
        while let current = info {
            socketFD = Darwin.socket(current.pointee.ai_family, current.pointee.ai_socktype, current.pointee.ai_protocol)
            if socketFD >= 0 {
                let connectResult = Darwin.connect(socketFD, current.pointee.ai_addr, current.pointee.ai_addrlen)
                if connectResult == 0 {
                    return true
                }
                lastConnectError = errno
                let errMsg = String(cString: strerror(errno))
                print("UDP connect 실패: \(errMsg) (errno=\(errno))")
                Darwin.close(socketFD)
                socketFD = -1
            } else {
                lastConnectError = errno
                print("소켓 생성 실패: \(String(cString: strerror(errno)))")
            }
            info = current.pointee.ai_next
        }
        return false
    }
    
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
            let sent = Darwin.send(socketFD, baseAddress, data.count, 0)
            return sent >= 0 ? sent : -1
        }
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

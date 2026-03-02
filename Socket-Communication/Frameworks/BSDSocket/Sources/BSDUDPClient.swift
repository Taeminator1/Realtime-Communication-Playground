//
//  BSDUDPClient.swift
//  BSDSocket
//
//  Created by Taemin Yun on 2026-03-01.
//

import Foundation
import Darwin
import SocketClient

// MARK: - BSD UDP Client
// UDP는 비연결형(connectionless) 프로토콜.
// 소켓 FD를 유지하는 것은 OS 엔드포인트 관리이며, 커널 레벨 연결 상태와는 무관하다.
// 주의: socketFD는 스레드 세이프하지 않습니다. 동시 접근 시 외부에서 직렬화하세요.

final public class BSDUDPClient {
    private var socketFD: Int32 = -1
    private var isReceiving: Bool = false
    private let host: String
    private let port: UInt16

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
extension BSDUDPClient: UDPClientMakable {
    
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

        close()

        var info: UnsafeMutablePointer<addrinfo>? = resolved
        while let current = info {
            let fd = Darwin.socket(current.pointee.ai_family, current.pointee.ai_socktype, current.pointee.ai_protocol)
            guard fd >= 0 else {
                info = current.pointee.ai_next
                continue
            }

            var timeout = timeval(tv_sec: 3, tv_usec: 0)
            setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

            let sent = data.withUnsafeBytes { buffer -> Int in
                guard let base = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return -1 }
                return Darwin.sendto(fd, base, data.count, 0, current.pointee.ai_addr, current.pointee.ai_addrlen)
            }

            if sent >= 0 {
                socketFD = fd
                return sent
            }

            Darwin.close(fd)
            info = current.pointee.ai_next
        }
        return -1
    }

    public func receive(maxLength: Int) -> String? {
        guard socketFD >= 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: maxLength)
        let bytesRead = Darwin.recvfrom(socketFD, &buffer, maxLength, 0, nil, nil)
        guard bytesRead > 0 else { return nil }
        let data = Data(bytes: buffer, count: bytesRead)
        return String(data: data, encoding: .utf8)
    }

    /// 백그라운드에서 recvfrom을 반복 호출하여 서버가 보내는 데이터를 지속 수신한다.
    /// send(string:)로 소켓이 생성된 뒤 호출해야 한다.
    public func startReceiving(maxLength: Int = 4096, onReceive: @escaping (String) -> Void) {
        guard socketFD >= 0, !isReceiving else { return }
        isReceiving = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var buffer = [UInt8](repeating: 0, count: maxLength)

            while let self, self.isReceiving, self.socketFD >= 0 {
                let bytesRead = Darwin.recvfrom(self.socketFD, &buffer, maxLength, 0, nil, nil)
                if bytesRead > 0 {
                    let data = Data(bytes: buffer, count: bytesRead)
                    if let message = String(data: data, encoding: .utf8) {
                        onReceive(message)
                    }
                }
            }
        }
    }

    public func stopReceiving() {
        isReceiving = false
    }
}

//
//  TCPConnectionError.swift
//  SocketClient
//
//  Created by Taemin Yun on 2026-03-02.
//

import Foundation

public enum TCPConnectionError: Error {
    case hostResolutionFailed(String)
    case socketCreationFailed(Int32)
    case connectionFailed(Int32)

    public var message: String? {
        switch self {
        case .hostResolutionFailed(let detail):
            return "호스트 조회 실패: \(detail)"
        case .socketCreationFailed(let errno):
            return "소켓 생성 실패: \(String(cString: strerror(errno)))"
        case .connectionFailed(let errno):
            return "연결 실패: \(String(cString: strerror(errno)))"
        }
    }
}

//
//  TCPClientMakable.swift
//  SocketClient
//
//  Created by Taemin Yun on 2026-03-02.
//

import Foundation

public protocol TCPClientMakable: SocketClientMakable {

    var lastConnectError: Int32 { get }
    func connect() -> Bool
}

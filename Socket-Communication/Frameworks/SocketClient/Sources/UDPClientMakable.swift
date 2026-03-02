//
//  UDPClientMakable.swift
//  SocketClient
//
//  Created by Taemin Yun on 2026-03-02.
//

import Foundation

public protocol UDPClientMakable: SocketClientMakable {

    func startReceiving(maxLength: Int, onReceive: @escaping (String) -> Void)
    func stopReceiving()
}

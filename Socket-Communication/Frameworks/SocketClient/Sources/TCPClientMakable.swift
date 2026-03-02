//
//  TCPClientMakable.swift
//  SocketClient
//
//  Created by Taemin Yun on 2026-03-02.
//

import Foundation

public protocol TCPClientMakable: SocketClientMakable {

    func connect() -> Result<Void, TCPConnectionError>
}

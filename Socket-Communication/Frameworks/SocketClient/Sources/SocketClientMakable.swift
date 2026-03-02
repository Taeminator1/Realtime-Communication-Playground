//
//  SocketClientMakable.swift
//  SocketClient
//
//  Created by Taemin Yun on 2026-03-01.
//

import Foundation

public protocol SocketClientMakable: AnyObject {

    func close()
    
    func send(string: String) -> Int
    func receive(maxLength: Int) -> String?
}

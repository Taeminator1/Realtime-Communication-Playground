//
//  ContentView.swift
//  Socket-Communications
//
//  Created by Taemin Yun on 2026-02-28.
//

import SwiftUI
import Darwin
import BSDSockets

struct ContentView: View {
    
    @State private var statusMessage: String = ""

    private let tcpClient = BSDTCPClient(host: "127.0.0.1", port: 8080)
    private let udpClient = BSDUDPClient(host: "127.0.0.1", port: 8080)

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                HStack(alignment: .top) {
                    Spacer()
                    tcpColumn
                    Spacer()
                    udpColumn
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    Text("Result")
                        .font(.headline)
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("BSD Sockets")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Subviews
private extension ContentView {
    var tcpColumn: some View {
        VStack(spacing: 12) {
            Text("TCP")
                .font(.headline)
            
            Button("Connect") {
                connectTCP()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Send") {
                sendMessage(client: tcpClient, label: "TCP") { message in
                    statusMessage = message
                }
            }
            .buttonStyle(.bordered)
        }
    }

    var udpColumn: some View {
        VStack(spacing: 12) {
            Text("UDP")
                .font(.headline)

            Button("Send") {
                sendMessage(client: udpClient, label: "UDP") { message in
                    statusMessage = message
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Private
private extension ContentView {
    func connectTCP() {
        DispatchQueue.global(qos: .userInitiated).async {
            let success = tcpClient.connect()
            let message: String
            if success {
                message = "TCP 연결 성공"
            } else {
                let errMsg = tcpClient.lastConnectError != 0
                    ? String(cString: strerror(tcpClient.lastConnectError))
                    : "알 수 없음"
                message = "TCP 연결 실패: \(errMsg)"
            }
            DispatchQueue.main.async {
                statusMessage = message
            }
        }
    }

    func sendMessage(
        client: BSDClientMakable,
        label: String,
        completion: @escaping (String) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let sent = client.send(string: "Hello, \(label) Server!")
            let message: String
            if sent > 0 {
                if let response = client.receive(maxLength: 4096) {
                    message = "\(label) 서버 응답: \(response)"
                } else {
                    message = "\(label) 전송 완료 (응답 없음)"
                }
            } else {
                message = "\(label) 전송 실패"
            }
            DispatchQueue.main.async {
                completion(message)
            }
        }
    }
}

#Preview {
    ContentView()
}

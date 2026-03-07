//
//  ContentView.swift
//  Socket-Communications
//
//  Created by Taemin Yun on 2026-02-28.
//

import SwiftUI
import NetworkSocket
import SocketClient

struct ContentView: View {

    @State private var statusMessage: String = ""
    @State private var isTCPConnected: Bool = false
    @State private var isUDPReceiving: Bool = false
    @State private var receivedMessages: [String] = []

    private let tcpClient: TCPClientMakable
    private let udpClient: UDPClientMakable

    init(tcpClient: TCPClientMakable, udpClient: UDPClientMakable) {
        self.tcpClient = tcpClient
        self.udpClient = udpClient
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Button("TCP Client 연결") {
                        connectTCP()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTCPConnected)

                    Button("TCP Client 해제") {
                        disconnectTCP()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isTCPConnected)

                    Button("데이터 전송") {
                        let client: SocketClientMakable = isTCPConnected ? tcpClient : udpClient
                        let label = isTCPConnected ? "TCP" : "UDP"
                        sendMessage(client: client, label: label)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isTCPConnected ? .blue : .orange)

                    Button(isUDPReceiving ? "UDP 수신 중지" : "UDP 수신 시작") {
                        if isUDPReceiving {
                            stopUDPReceiving()
                        } else {
                            startUDPReceiving()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isUDPReceiving ? .red : .green)
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if !receivedMessages.isEmpty {
                    List(receivedMessages.indices, id: \.self) { index in
                        Text(receivedMessages[index])
                            .font(.caption)
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("Network Sockets")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Private
private extension ContentView {
    
    func sendMessage(client: SocketClientMakable, label: String) {
        DispatchQueue.global(qos: .userInitiated).async(execute: {
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
                statusMessage = message
            }
        })
    }
    
    // MARK: - TCP
    func connectTCP() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = tcpClient.connect()
            DispatchQueue.main.async {
                switch result {
                    case .success:
                        isTCPConnected = true
                        statusMessage = "TCP 연결 성공"
                    case .failure(let error):
                        isTCPConnected = false
                        statusMessage = "TCP 연결 실패: \(error.message ?? error.localizedDescription)"
                }
            }
        }
    }

    func disconnectTCP() {
        tcpClient.close()
        isTCPConnected = false
        statusMessage = "TCP 연결 해제"
    }

    // MARK: - UDP
    func startUDPReceiving() {
        DispatchQueue.global(qos: .userInitiated).async {
            let sent = udpClient.send(string: "subscribe")
            guard sent > 0 else {
                DispatchQueue.main.async {
                    statusMessage = "UDP 서버 등록 실패"
                }
                return
            }
            DispatchQueue.main.async {
                receivedMessages = []
                isUDPReceiving = true
                statusMessage = "UDP 수신 대기 중..."
            }
            udpClient.startReceiving(maxLength: 4096) { message in
                DispatchQueue.main.async {
                    receivedMessages.append(message)
                }
            }
        }
    }

    func stopUDPReceiving() {
        udpClient.stopReceiving()
        udpClient.close()
        isUDPReceiving = false
        statusMessage = "UDP 수신 중지"
    }
}

#Preview {
    ContentView(
        tcpClient: NetworkTCPClient(host: "127.0.0.1", port: 8080),
        udpClient: NetworkUDPClient(host: "127.0.0.1", port: 8080)
    )
}

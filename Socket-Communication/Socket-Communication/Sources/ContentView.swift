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

    var body: some View {
        VStack {
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            Spacer()
            HStack(spacing: 12) {
                Button("TCP 서버 확인") {
                    checkServerResponse()
                }
                .buttonStyle(.borderedProminent)
                Button("UDP 서버 확인") {
                    checkUDPServerResponse()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer()
        }
        .padding()
    }
}

// MARK: - private
private extension ContentView {
    func checkServerResponse() {
        checkResponse(client: BSDTCPClient(host: "127.0.0.1", port: 8080), label: "TCP", greeting: "Hello, TCP Server!")
    }

    func checkUDPServerResponse() {
        checkResponse(client: BSDUDPClient(host: "127.0.0.1", port: 8080), label: "UDP", greeting: "Hello, UDP Server!")
    }

    func checkResponse(client: BSDClientMakable, label: String, greeting: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var message: String = ""
            if client.connect() {
                _ = client.send(string: greeting)
                if let response = client.receive(maxLength: 4096) {
                    message = label.isEmpty ? "서버 응답: \(response)" : "\(label) 서버 응답: \(response)"
                } else {
                    message = label.isEmpty ? "응답 수신 실패" : "\(label) 응답 수신 실패"
                }
                print(message)
                client.close()
            } else {
                let errMsg = client.lastConnectError != 0
                    ? String(cString: strerror(client.lastConnectError))
                    : "알 수 없음"
                message = label.isEmpty ? "연결 실패: \(errMsg)" : "\(label) 연결 실패: \(errMsg)"
                print("연결에 실패했습니다. (\(errMsg))")
            }
            DispatchQueue.main.async {
                statusMessage = message
            }
        }
    }
}

#Preview {
    ContentView()
}

import SwiftUI
import NetworkSocket

@main
struct SocketCommunicationApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView(
                tcpClient: NetworkTCPClient(host: "127.0.0.1", port: 8080),
                udpClient: NetworkUDPClient(host: "127.0.0.1", port: 8080)
            )
        }
    }
}

import SwiftUI
import BSDSocket

@main
struct SocketCommunicationApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView(
                tcpClient: BSDTCPClient(host: "127.0.0.1", port: 8080),
                udpClient: BSDUDPClient(host: "127.0.0.1", port: 8080)
            )
        }
    }
}

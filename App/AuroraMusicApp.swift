import SwiftUI

@main
struct AuroraMusicApp: App {
    @StateObject private var router = Router()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}
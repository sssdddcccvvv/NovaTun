import SwiftUI

@main
struct NovaTunApp: App {
    @StateObject private var store = ProfileStore.shared
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

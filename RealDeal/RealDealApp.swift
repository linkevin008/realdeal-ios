import SwiftUI

@available(iOS 17.0, macOS 11.0, *)
@main
struct RealDealApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

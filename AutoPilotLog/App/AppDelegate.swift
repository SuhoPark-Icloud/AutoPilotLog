import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let locationsHandler = LocationsHandler.shared

        // If location updates were previously active, restart them after the background launch.
        if locationsHandler.updatesStarted {
            locationsHandler.startLocationUpdates()
        }
        // If a background activity session was previously active, reinstantiate it after the background launch.
        if locationsHandler.backgroundActivity {
            locationsHandler.backgroundActivity = true
        }
        return true
    }
}

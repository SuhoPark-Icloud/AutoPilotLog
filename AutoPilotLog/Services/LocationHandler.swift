import CoreLocation
import os
import SwiftUI

// Shared state that manages the `CLLocationManager` and `CLBackgroundActivitySession`.
@MainActor class LocationsHandler: ObservableObject {
    static let shared = LocationsHandler() // Create a single, shared instance of the object.
    private let manager: CLLocationManager
    private var background: CLBackgroundActivitySession?

    private let logger = Logger(
        subsystem: "SuhoPark-Icloud.com.github.AutoPilotLog", category: "LocationsHandler")

    @Published var lastLocation = CLLocation()
    @Published var isStationary = false
    @Published var count = 0

    @Published
    var updatesStarted: Bool = UserDefaults.standard.bool(forKey: "liveUpdatesStarted") {
        didSet { UserDefaults.standard.set(self.updatesStarted, forKey: "liveUpdatesStarted") }
    }

    @Published
    var backgroundActivity: Bool = UserDefaults.standard.bool(forKey: "BGActivitySessionStarted") {
        didSet {
            self.backgroundActivity
                ? self.background = CLBackgroundActivitySession() : self.background?.invalidate()
            UserDefaults.standard.set(self.backgroundActivity, forKey: "BGActivitySessionStarted")
        }
    }

    private init() {
        self.manager = CLLocationManager() // Creating a location manager instance is safe to call here in `MainActor`.
    }

    func startLocationUpdates() {
        if self.manager.authorizationStatus == .notDetermined {
            self.manager.requestWhenInUseAuthorization()
        }
        self.logger.info("Starting location updates")
        Task {
            do {
                self.updatesStarted = true
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    if !self.updatesStarted { break } // End location updates by breaking out of the loop.
                    if let loc = update.location {
                        self.lastLocation = loc
                        self.isStationary = update.stationary
                        self.count += 1
                        print("Location \(self.count): \(self.lastLocation)")
                        self.logger.debug("Location \(self.count): \(self.lastLocation)")
                    }
                }
            } catch {
                print("Could not start location updates")
                self.logger.error("Could not start location updates: \(error.localizedDescription)")
            }
        }
    }

    func stopLocationUpdates() {
        print("Stopping location updates")
        self.logger.info("Stopping location updates")
        self.updatesStarted = false
    }
}

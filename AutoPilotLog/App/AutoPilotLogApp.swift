//
//  AutoPilotLogApp.swift
//  AutoPilotLog
//
//  Created by Suho Park on 3/16/25.
//

import SwiftData
import SwiftUI

@main
struct AutoPilotLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Issue.self)
    }
}

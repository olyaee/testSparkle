//
//  testSparkleApp.swift
//  testSparkle
//
//  Created by ehsan olyaee on 05.09.25.
//

import SwiftUI
import Sparkle

@main
struct testSparkleApp: App {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}

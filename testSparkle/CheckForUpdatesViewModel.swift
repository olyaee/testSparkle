//
//  CheckForUpdatesViewModel.swift
//  testSparkle
//
//  Created by ehsan olyaee on 05.09.25.
//

import SwiftUI
import Sparkle
import Combine

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

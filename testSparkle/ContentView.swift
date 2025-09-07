 //
//  ContentView.swift
//  testSparkle
//
//  Created by ehsan olyaee on 05.09.25.
//

import SwiftUI
import Sparkle


extension Bundle {
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }
}

struct ContentView: View {
    var body: some View {
        Text("\(Bundle.main.buildNumber)")
            .padding()
            .frame(width: 300, height: 200)
    }
}

#Preview {
    ContentView()
}

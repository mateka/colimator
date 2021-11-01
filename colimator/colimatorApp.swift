//
//  colimatorApp.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 30/10/2021.
//

import SwiftUI

@main
struct colimatorApp: App {
    @StateObject var colimaStatusPublisher = ColimaStatusPublisher()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(self.colimaStatusPublisher)
                .task {
                    await self.colimaStatusPublisher.updateStatus()
                }
        }
    }
}

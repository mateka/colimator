//
//  ColimaStatusPublisher.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 31/10/2021.
//

import Foundation
import Combine

class ColimaStatusPublisher : ObservableObject {
    @Published var status: ColimaStatus? = nil

    private var subscription: AnyCancellable?

    init() {
        self.subscription = Timer.publish(every: 30, on: RunLoop.main, in: .common)
            .autoconnect()
            .receive(on: RunLoop.main)
            .sink {_ in
                Task.init {
                    await self.updateStatus()
                }
            }
    }

    init(fromStatus status: ColimaStatus) {
        self.status = status
        self.subscription = nil
    }

    @MainActor public func updateStatus() async {
        do {
            self.status = try await ColimaStatus()
        }
        catch {
            self.status = nil
        }
    }
}

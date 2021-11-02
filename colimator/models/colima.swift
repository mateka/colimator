//
//  colima.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 30/10/2021.
//

import Foundation


func createDate(from: String) -> Date? {
    let RFC3339DateFormatter = DateFormatter()
    RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return RFC3339DateFormatter.date(from: from)
}

struct ColimaStatus {
    let updated: Date
    let running: Bool
    let runtime: String
    let kubernetesEnabled: Bool

    init() async throws {
        try await self.init(from_lines: execCommand(
            command: "/opt/homebrew/bin/colima", "status"  // TODO Homebrew path to settings
        ).errorLines)
    }

    init(updated: Date, running: Bool, runtime: String, kubernetesEnabled: Bool) {
        self.updated = updated
        self.running = running
        self.runtime = runtime
        self.kubernetesEnabled = kubernetesEnabled
    }

    init<T: AsyncSequence>(from_lines lines: T) async throws where T.Element == String {
        var updated = Date.now
        var running = false
        var runtime = ""
        var kubernetesEnabled = false

        for try await line in lines {
            for fragment in line.split(separator: " ", maxSplits: 2) {
                let keyValue = fragment.split(separator: "=")
                    .map {String($0).replacingOccurrences(of: "\"", with: "")}
                switch keyValue[0] {
                case "time":
                    updated = createDate(from: keyValue[1]) ?? Date.now
                case "msg":
                    if keyValue[1] == "colima is running" {
                        running = true
                    }
                    else if keyValue[1].contains(":") {
                        let parts = keyValue[1]
                            .split(separator: ":", maxSplits: 1)
                            .map { word in
                                word.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        switch parts[0] {
                        case "runtime":
                            runtime = String(parts[1])
                        case "kubernetes":
                            kubernetesEnabled = (String(parts[1]) == "enabled")
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            }
        }

        self.init(
            updated: updated, running: running,
            runtime: runtime, kubernetesEnabled: kubernetesEnabled
        )
    }
}

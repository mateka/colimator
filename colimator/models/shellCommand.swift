//
//  shellCommand.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 30/10/2021.
//

import Foundation


func shellCommand(
    command: String, _ args: String..., shell: String = "/bin/zsh"
) async throws -> FileHandle {
    let task = Task.init { () -> FileHandle in
        let shellProfile: String = [
            "/bin/zsh": "${HOME}/.zprofile",
        ][shell, default: "${HOME}/.profile"]

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: shell)
        proc.arguments = [
            "-c", ". \(shellProfile); \(([command] + args).joined(separator: " "))"
        ]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe

        try proc.run()
        return pipe.fileHandleForReading
    }
    return try await task.value
}

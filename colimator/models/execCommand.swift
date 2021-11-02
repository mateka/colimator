//
//  execCommand.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 30/10/2021.
//

import Foundation


enum CommandError: Error {
    case runError(error: Error)
    case unsuccessful(
        exitCode: Int32, exitReason: Process.TerminationReason,
        output: String?, errorsOutput: String?
    )
}


func readData(pipe: Pipe) async -> String? {
    return try? await pipe.fileHandleForReading.bytes
        .lines.reduce("") {$0 + "\n" + $1}
}

struct CommandResult {
    let outputLines: AsyncLineSequence<FileHandle.AsyncBytes>
    let errorLines: AsyncLineSequence<FileHandle.AsyncBytes>
}


func execCommand(command: String, _ args: String...) async throws -> CommandResult {
    let task = Task.init { () -> CommandResult in
        let subProcess = Process()
        subProcess.executableURL = URL(fileURLWithPath: command)
        subProcess.arguments = args

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/opt/homebrew/bin/"  // TODO: Homebrew path to settings
        subProcess.environment = env

        let stdOut = Pipe()
        let stdErr = Pipe()

        subProcess.standardOutput = stdOut
        subProcess.standardError = stdErr

        do {
            try subProcess.run()
            subProcess.waitUntilExit()
        }
        catch {
            throw CommandError.runError(error: error)
        }

        if subProcess.terminationStatus != 0 {
            async let output: String? = readData(pipe: stdOut)
            async let errors: String? = readData(pipe: stdErr)

            throw await CommandError.unsuccessful(
                exitCode: subProcess.terminationStatus,
                exitReason: subProcess.terminationReason,
                output: output,
                errorsOutput: errors
            )
        }
        return CommandResult(
            outputLines: stdOut.fileHandleForReading.bytes.lines,
            errorLines: stdErr.fileHandleForReading.bytes.lines
        )
    }
    return try await task.value
}

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
        output: AsyncLineSequence<FileHandle.AsyncBytes>,
        errorsOutput: AsyncLineSequence<FileHandle.AsyncBytes>
    )
}


struct CommandResult: ExecutorResult {
    typealias Sequence = AsyncLineSequence<FileHandle.AsyncBytes>
    let outputLines: Sequence
    let errorLines: Sequence
}


func execCommand(command: URL, args: [String]) async throws -> CommandResult {
    let task = Task.init { () -> CommandResult in
        let subProcess = Process()
        subProcess.executableURL = command
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
            throw CommandError.unsuccessful(
                exitCode: subProcess.terminationStatus,
                exitReason: subProcess.terminationReason,
                output: stdOut.fileHandleForReading.bytes.lines,
                errorsOutput: stdErr.fileHandleForReading.bytes.lines
            )
        }
        return CommandResult(
            outputLines: stdOut.fileHandleForReading.bytes.lines,
            errorLines: stdErr.fileHandleForReading.bytes.lines
        )
    }
    return try await task.value
}


func execCommand(command: URL, _ args: String...) async throws -> CommandResult {
    try await execCommand(command: command, args: args)
}

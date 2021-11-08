//
//  colima.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 30/10/2021.
//

import Foundation
import Yaml


func createDate(from: String) -> Date? {
    let RFC3339DateFormatter = DateFormatter()
    RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return RFC3339DateFormatter.date(from: from)
}


protocol ExecutorResult {
    associatedtype Sequence

    var outputLines: Sequence { get }
    var errorLines: Sequence { get }
}


struct ColimaBase<Result: ExecutorResult>
    where Result.Sequence: AsyncSequence, Result.Sequence.Element == String {
    public let executor: (URL, [String]) async throws -> Result

    // TODO: Fields should be changeable in settings
    private let colimaPath = URL(fileURLWithPath: "/opt/homebrew/bin/colima")
    private let colimaProfilePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".colima/colima.yaml")

    public enum ParseError: Error, Equatable {
        case MissingColimaVersion
        case MissingArchitecture
        case MissingSomeRuntimeInformation
        case MissingKubernetesVersion
        case UnknownRuntime(runtime: String)
    }

    public enum Architecture: String, Comparable, CaseIterable {
        case aarch64
        case x86_64

        public static func < (lhs: Architecture, rhs: Architecture) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public struct ComponentVersionInfo: Equatable {
        let clientVersion: String
        let serverVersion: String
    }

    public enum Runtime: Equatable {
        case docker(version: ComponentVersionInfo? = nil)
        case containerd // TODO: Params
    }

    public struct VersionInfo: Equatable {
        let version: String
        let commit: String
        let runtime: Runtime?
        let architecture: Architecture?
        let kubernetes: ComponentVersionInfo?
    }

     public func version() async throws -> VersionInfo {
         return try await self.parseVersion(from_lines:executor(
            self.colimaPath, ["version"]
         ).outputLines)
     }

    public struct StatusInfo {
        let updated: Date
        let running: Bool
        let kubernetesEnabled: Bool
    }

    public func status() async throws -> StatusInfo {
        do {
            return try await self.parseStatus(from_lines:executor(
                self.colimaPath, ["status"]
            ).errorLines)
        }
        catch CommandError.unsuccessful(_, _, _, let errorsOut){
            return try await self.parseStatus(from_lines:errorsOut)
        }
    }

    struct MountInfo: Equatable, CustomStringConvertible {
        let path: URL
        let writeable: Bool

        init(from_string repr: String) {
            let elems = repr.split(separator: ":", maxSplits: 1).map {String($0)}
            self.path = URL(fileURLWithPath: elems[0])
            self.writeable = elems[1] == "w"
        }

        var description: String {
            get {
                if writeable {
                        return "\(path.path):w"
                }
                return path.path
            }
        }
    }

    struct ConfigInfo: Equatable {
        let cpus: Int
        let memory: Int
        let mounts: [MountInfo]
        // TODO: Other fields
    }


    public func config() async throws -> ConfigInfo {
        let contents = try await Yaml.load(
            colimaProfilePath.lines.reduce("") { $0 + "\n" + $1 }
        )
        let vm = contents["vm"]
        return ConfigInfo(
            cpus: vm["cpu"].int!, memory: vm["memory"].int!,
            mounts: vm["mounts"].array?.map {MountInfo(from_string: $0.string!)} ?? []
        )
    }

    public func start(
        cpu: Int? = nil, memory: Int? = nil, disk: Int? = nil,
        runtime: Runtime = .docker(), withKubernetes: Bool = false,
        architecture: Architecture? = nil,
        mounts: [MountInfo] = []
//        dns: [NWEndpoint.IPv4Address] = [],
//        portInterface: NWEndpoint.IPv4Address?
    ) async throws {
        var runtimeName: String
        switch runtime {
        case .docker(_):
            runtimeName = "docker"
        case .containerd:
            runtimeName = "containerd"
        }

        var args: [String] = ["start", "--runtime", runtimeName]

        if cpu != nil {
            args += ["--cpu", cpu!.description]
        }
        if memory != nil {
            args += ["--memory", memory!.description]
        }
        if disk != nil {
            args += ["--disk", disk!.description]
        }
        if withKubernetes {
            args += ["--with-kubernetes"]
        }
        if architecture != nil {
            args += ["--arch", architecture!.rawValue]
        }
        if !mounts.isEmpty {
            args += mounts.flatMap { ["--mount", $0.description] }
        }
//        if !dns.isEmpty {
//            args += []
//        }
//        if portInterface != nil {
//            args += ["--port-interface", portInterface!.description]
//        }

        let _ = try await executor(self.colimaPath, args)
        // TODO: Logs
    }

    public func stop() async throws {
        let _ = try await executor(self.colimaPath, ["stop"])
    }

    public func delete() async throws {
        // TODO: How to confimr?
        let _ = try await executor(self.colimaPath, ["delete"])
    }

    // TODO: kubernetes public struct kubernetes ?
    // TODO: nerdctl install -> install nerdctl alias script on the host
    // TODO: ssh -> open terminal with ssh to colima
    // TODO: colima.yaml

    private func parseVersion(
        from_lines lines: Result.Sequence
    ) async throws -> VersionInfo {
        var colimaVersion: String = ""
        var commit: String = ""
        var runtime: String = ""
        var runtimeClientVersion: String = ""
        var runtimeServerVersion: String = ""
        var arch: Architecture? = nil
        var k8s: Bool = false
        var k8sClientVersion: String = ""
        var k8sServerVersion: String = ""
        for try await line in lines {
            if line.contains(":") {
                let keyVal = line.split(separator: ":", maxSplits: 1).map {
                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                switch keyVal[0] {
                case "git commit":
                    commit = keyVal[1]
                case "runtime":
                    runtime = keyVal[1]
                case "arch":
                    arch = Architecture(rawValue: keyVal[1])
                case "client":
                    runtimeClientVersion = keyVal[1]
                case "server":
                    runtimeServerVersion = keyVal[1]
                case "Client Version":
                    k8sClientVersion = keyVal[1]
                case "Server Version":
                    k8sServerVersion = keyVal[1]
                default:
                    break
                }
            }
            else if line == "kubernetes" { k8s = true }
            else if line.starts(with: "colima version") {
                colimaVersion = String(line.split(separator: " ", maxSplits: 2)[2])
            }
        }

        if colimaVersion.isEmpty { throw ParseError.MissingColimaVersion }

        let runtimeStatuses = [
            runtime.isEmpty, runtimeClientVersion.isEmpty,
            runtimeServerVersion.isEmpty
        ]
        if runtimeStatuses.contains(where: {$0}) && runtimeStatuses.contains(where: {!$0}) {
            throw ParseError.MissingSomeRuntimeInformation
        }
        if k8s && (k8sClientVersion.isEmpty || k8sServerVersion.isEmpty) {
            throw ParseError.MissingKubernetesVersion
        }

        var containerRuntime: Runtime? = nil
        if !runtime.isEmpty && !runtimeClientVersion.isEmpty && !runtimeServerVersion.isEmpty {
            switch runtime {
            case "docker":
                containerRuntime = .docker(version: ComponentVersionInfo(
                    clientVersion: runtimeClientVersion,
                    serverVersion: runtimeServerVersion
                ))
            case "containerd":
                containerRuntime = .containerd
            default:
                throw ParseError.UnknownRuntime(runtime: runtime)
            }
        }

        return VersionInfo(
            version: colimaVersion,
            commit: commit,
            runtime: containerRuntime,
            architecture: arch,
            kubernetes: k8s ? ComponentVersionInfo(
                clientVersion: k8sClientVersion,
                serverVersion: k8sServerVersion
            ) : nil
        )
    }

    private func parseStatus<T: AsyncSequence>(
        from_lines lines: T
    ) async throws -> StatusInfo where T.Element == String {
        var updated: Date = .now
        var running: Bool = false
        var k8sEnabled: Bool = false
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
                        case "kubernetes":
                            k8sEnabled = (String(parts[1]) == "enabled")
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            }
        }
        return StatusInfo(updated: updated, running: running, kubernetesEnabled: k8sEnabled)
    }
}


typealias Colima = ColimaBase<CommandResult>

extension ColimaBase where Result == CommandResult {
    init() {
        self.executor = execCommand
    }
}


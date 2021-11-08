//
//  ColimaStatusParserTests.swift
//  colimatorTests
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import XCTest
@testable import colimator


fileprivate typealias ColimaType = ColimaBase<ExecutorMockResult>


class StatusTests : XCTestCase {
    func testParsingNotRunningStatus() async {
        let input = [
            "time=\"2021-11-01T14:33:02+01:00\" level=fatal msg=\"colima is not running\"",
        ]
        let colima = ColimaType(executor: makeExecutorMock(err: input))
        let status = try! await colima.status()
        XCTAssertEqual(status.updated, createDate(from: "2021-11-01T14:33:02+01:00"))
        XCTAssertFalse(status.running)
        XCTAssertFalse(status.kubernetesEnabled)
    }

    func testParsingRunningStatusWithoutK8s() async {
        let input = [
            "time=\"2021-11-01T14:26:00+01:00\" level=info msg=\"colima is running\"",
            "time=\"2021-11-01T14:26:00+01:00\" level=info msg=\"runtime: podman\"",
            "time=\"2021-11-01T14:28:00+01:00\" level=info msg=\"kubernetes: disabled\"",
        ]
        let colima = ColimaType(executor: makeExecutorMock(err: input))
        let status = try! await colima.status()
        XCTAssertEqual(status.updated, createDate(from: "2021-11-01T14:28:00+01:00"))
        XCTAssertTrue(status.running)
        XCTAssertFalse(status.kubernetesEnabled)
    }

    func testParsingRunningStatusWithK8s() async {
        let input = [
            "time=\"2021-11-01T14:26:00+01:00\" level=info msg=\"colima is running\"",
            "time=\"2021-11-01T14:26:00+01:00\" level=info msg=\"runtime: docker\"",
            "time=\"2021-11-01T14:26:00+01:00\" level=info msg=\"arch: aarch64\"",
            "time=\"2021-11-01T14:27:00+01:00\" level=info msg=\"kubernetes: enabled\"",
        ]
        let colima = ColimaType(executor: makeExecutorMock(err: input))
        let status = try! await colima.status()
        XCTAssertEqual(status.updated, createDate(from: "2021-11-01T14:27:00+01:00"))
        XCTAssertTrue(status.running)
        XCTAssertTrue(status.kubernetesEnabled)
    }
}


class VersionTests : XCTestCase {
    func testMissingVersionError() async {
        let input = [
            "git commit: 519a3722a03807d878dd8ddc21b2d188a982ba42",
            "",
            "runtime: docker",
            "arch: aarch64",
            "client: v20.10.10",
            "server: v20.10.7",
            "",
            "kubernetes",
            "Client Version: v1.22.2+k3s2",
            "Server Version: v1.22.3+k3s2",
        ]
        let colima = ColimaType(executor: makeExecutorMock(out: input))
        do {
            let _ = try await colima.version()
            XCTFail("Should throw")
        }
        catch ColimaType.ParseError.MissingColimaVersion{}
        catch {
            XCTFail("Wrong error")
        }
    }

    func testMissingRuntimeInfo() async {
        let input = [
            "colima version HEAD-519a372",
            "git commit: 519a3722a03807d878dd8ddc21b2d188a982ba42",
            "",
            "runtime: docker",
            "arch: aarch64",
            "server: v20.10.7",
            "",
            "kubernetes",
            "Client Version: v1.22.2+k3s2",
            "Server Version: v1.22.3+k3s2",
        ]
        let colima = ColimaType(executor: makeExecutorMock(out: input))
        do {
            let _ = try await colima.version()
            XCTFail("Should throw")
        }
        catch ColimaType.ParseError.MissingSomeRuntimeInformation{}
        catch {
            XCTFail("Wrong error")
        }
    }

    func testMissingKubernetesVersion() async {
        let input = [
            "colima version HEAD-519a372",
            "git commit: 519a3722a03807d878dd8ddc21b2d188a982ba42",
            "",
            "runtime: docker",
            "arch: aarch64",
            "client: v20.10.10",
            "server: v20.10.7",
            "",
            "kubernetes",
            "Server Version: v1.22.3+k3s2",
        ]
        let colima = ColimaType(executor: makeExecutorMock(out: input))
        do {
            let _ = try await colima.version()
            XCTFail("Should throw")
        }
        catch ColimaType.ParseError.MissingKubernetesVersion{}
        catch {
            XCTFail("Wrong error")
        }
    }

    func testUnknownVersion() async {
        let input = [
            "colima version HEAD-519a372",
            "git commit: 519a3722a03807d878dd8ddc21b2d188a982ba42",
            "",
            "runtime: foobar",
            "arch: aarch64",
            "client: v20.10.10",
            "server: v20.10.7",
            "",
            "kubernetes",
            "Client Version: v1.22.2+k3s2",
            "Server Version: v1.22.3+k3s2",
        ]
        let colima = ColimaType(executor: makeExecutorMock(out: input))
        do {
            let _ = try await colima.version()
            XCTFail("Should throw")
        }
        catch ColimaType.ParseError.UnknownRuntime(let name) {
            XCTAssertEqual(name, "foobar")
        }
        catch {
            XCTFail("Wrong error")
        }
    }

    func testParsingVersionInfoWhenColimaIsStopped() async {
        let input = [
            "colima version HEAD-519a372k",
            "git commit: 519a3722a03807d878dd8ddc21b2d188a982ba42",
            "",
        ]
        let colima = ColimaType(executor: makeExecutorMock(out: input))
        let version = try! await colima.version()
        XCTAssertEqual(version.version, "HEAD-519a372k")
        XCTAssertEqual(version.commit, "519a3722a03807d878dd8ddc21b2d188a982ba42")
        XCTAssertNil(version.runtime)
        XCTAssertNil(version.architecture)
        XCTAssertNil(version.kubernetes)
    }

    func testParsingVersionInfoWithK8sDisabled() async {
        let input = [
            "colima version HEAD-519a372",
            "git commit: 519a3722a03807d878dd8ddc21b2d188a982ba42",
            "",
            "runtime: docker",
            "arch: aarch64",
            "client: v20.10.10",
            "server: v20.10.7",
            // TODO: Check version info without k8s enabled
        ]
        let colima = ColimaType(executor: makeExecutorMock(out: input))
        let version = try! await colima.version()
        XCTAssertEqual(version.version, "HEAD-519a372")
        XCTAssertEqual(version.commit, "519a3722a03807d878dd8ddc21b2d188a982ba42")
        XCTAssertEqual(
            version.runtime,
            ColimaType.Runtime.docker(version: ColimaType.ComponentVersionInfo(
                clientVersion: "v20.10.10", serverVersion: "v20.10.7"
            ))
        )
        XCTAssertEqual(version.architecture, ColimaType.Architecture.aarch64)
        XCTAssertNil(version.kubernetes)
    }

    func testParsingVersionInfoWithK8sEnabled() async {
        let input = [
            "colima version HEAD-519a372",
            "git commit: 519a3722a03807d878dd8ddc21b2d188a982ba42",
            "",
            "runtime: docker",
            "arch: aarch64",
            "client: v20.10.10",
            "server: v20.10.7",
            "",
            "kubernetes",
            "Client Version: v1.22.2+k3s2",
            "Server Version: v1.22.3+k3s2",
        ]
        let colima = ColimaType(executor: makeExecutorMock(out: input))
        let version = try! await colima.version()
        XCTAssertEqual(version.version, "HEAD-519a372")
        XCTAssertEqual(version.commit, "519a3722a03807d878dd8ddc21b2d188a982ba42")
        XCTAssertEqual(
            version.runtime,
            ColimaType.Runtime.docker(version: ColimaType.ComponentVersionInfo(
                clientVersion: "v20.10.10", serverVersion: "v20.10.7"
            ))
        )
        XCTAssertEqual(version.architecture, ColimaType.Architecture.aarch64)
        XCTAssertEqual(
            version.kubernetes,
            ColimaType.ComponentVersionInfo(
                clientVersion: "v1.22.2+k3s2", serverVersion: "v1.22.3+k3s2"
            )
        )
    }
}

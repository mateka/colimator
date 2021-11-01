//
//  ColimaStatusParserTests.swift
//  colimatorTests
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import XCTest
@testable import colimator

class ColimaStatusParserTests: XCTestCase {

    func testParsingNotRunningStatus() async {
        let input = AsyncArrayOfStrings(fromArray: [
            "time=\"2021-11-01T14:33:02+01:00\" level=fatal msg=\"colima is not running\"",
        ])
        let status = try! await ColimaStatus(from_lines: input)
        XCTAssertEqual(status.updated, createDate(from: "2021-11-01T14:33:02+01:00"))
        XCTAssertFalse(status.running)
        XCTAssertEqual(status.runtime, "")
        XCTAssertFalse(status.kubernetesEnabled)
    }

    func testParsingRunningStatusWithoutK8s() async {
        let input = AsyncArrayOfStrings(fromArray: [
            "time=\"2021-11-01T14:26:00+01:00\" level=info msg=\"colima is running\"",
            "time=\"2021-11-01T14:26:00+01:00\" level=info msg=\"runtime: podman\"",
            "time=\"2021-11-01T14:28:00+01:00\" level=info msg=\"kubernetes: disabled\"",
        ])
        let status = try! await ColimaStatus(from_lines: input)
        XCTAssertEqual(status.updated, createDate(from: "2021-11-01T14:28:00+01:00"))
        XCTAssertTrue(status.running)
        XCTAssertEqual(status.runtime, "podman")
        XCTAssertFalse(status.kubernetesEnabled)
    }

    func testParsingRunningStatusWithK8s() async {
        let input = AsyncArrayOfStrings(fromArray: [
            "time=\"2021-11-01T14:26:00+01:00\" level=info msg=\"colima is running\"",
            "time=\"2021-11-01T14:26:00+01:00\" level=info msg=\"runtime: docker\"",
            "time=\"2021-11-01T14:27:00+01:00\" level=info msg=\"kubernetes: enabled\"",
        ])
        let status = try! await ColimaStatus(from_lines: input)
        XCTAssertEqual(status.updated, createDate(from: "2021-11-01T14:27:00+01:00"))
        XCTAssertTrue(status.running)
        XCTAssertEqual(status.runtime, "docker")
        XCTAssertTrue(status.kubernetesEnabled)
    }
}

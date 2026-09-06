import XCTest
import Foundation
@testable import Rebootless

final class RebootlessTests: XCTestCase {
    
    func testUniqueServiceIds() {
        let services = ServiceItem.builtInServices
        let ids = services.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All built-in service IDs should be unique")
    }
    
    func testServiceProperties() {
        for service in ServiceItem.builtInServices {
            XCTAssertFalse(service.id.isEmpty)
            XCTAssertFalse(service.name.isEmpty)
            XCTAssertFalse(service.subtitle.isEmpty)
            XCTAssertFalse(service.command.isEmpty)
            XCTAssertFalse(service.fixesDescription.isEmpty)
            XCTAssertFalse(service.iconName.isEmpty)
        }
    }
    
    func testTroubleshootMappings() {
        let validServiceIds = Set(ServiceItem.builtInServices.map { $0.id })
        for issue in TroubleshootItem.commonIssues {
            XCTAssertTrue(validServiceIds.contains(issue.serviceId), "Issue \(issue.id) maps to missing service \(issue.serviceId)")
            XCTAssertFalse(issue.title.isEmpty)
            XCTAssertFalse(issue.symptom.isEmpty)
            XCTAssertFalse(issue.recommendedActionTitle.isEmpty)
        }
    }
    
    func testServiceRunnerExecution() async {
        let testService = ServiceItem(
            id: "test_echo",
            name: "Echo Test",
            subtitle: "Unit test service",
            category: .system,
            iconName: "terminal",
            fixesDescription: "Tests execution",
            command: "echo 'Rebootless Test Output'",
            requiresAdmin: false,
            isBuiltIn: false
        )
        
        let result = await ServiceRunner.shared.execute(service: testService)
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(result.output.contains("Rebootless Test Output"))
        XCTAssertGreaterThanOrEqual(result.duration, 0)
        XCTAssertEqual(result.serviceId, "test_echo")
    }
    
    func testRestartResultSerialization() throws {
        let result = RestartResult(
            serviceId: "finder",
            serviceName: "Finder",
            command: "killall Finder",
            duration: 0.12,
            isSuccess: true,
            output: "done",
            errorMessage: nil
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RestartResult.self, from: data)
        
        XCTAssertEqual(decoded.serviceId, result.serviceId)
        XCTAssertEqual(decoded.serviceName, result.serviceName)
        XCTAssertEqual(decoded.isSuccess, result.isSuccess)
        XCTAssertEqual(decoded.command, result.command)
    }
}

import Foundation

public struct DiagnosticResult: Sendable, Equatable {
    public let isIssueDetected: Bool
    public let summary: String
    public let technicalDetails: String
    
    public init(isIssueDetected: Bool, summary: String, technicalDetails: String = "") {
        self.isIssueDetected = isIssueDetected
        self.summary = summary
        self.technicalDetails = technicalDetails
    }
}

public protocol DiagnosticCheck: Sendable {
    var name: String { get }
    func diagnose() async -> DiagnosticResult
}

public struct MockDiagnosticCheck: DiagnosticCheck {
    public let name: String
    private let resultGenerator: @Sendable () -> DiagnosticResult
    
    public init(name: String = "Mock Diagnostic", result: DiagnosticResult) {
        self.name = name
        self.resultGenerator = { result }
    }
    
    public init(name: String = "Mock Diagnostic", resultGenerator: @escaping @Sendable () -> DiagnosticResult) {
        self.name = name
        self.resultGenerator = resultGenerator
    }
    
    public func diagnose() async -> DiagnosticResult {
        resultGenerator()
    }
}

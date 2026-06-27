import Testing
@testable import SwiftGuardCore

@Suite("RiskAssessment")
struct RiskAssessmentTests {

    @Test("重大件数>0 なら level に関わらず実効レベルは critical（安全側）")
    func criticalCountOverridesLevel() {
        let a = RiskAssessment(level: .warning, summary: "x", criticalIssueCount: 1)
        #expect(a.effectiveLevel == .critical)
        #expect(a.effectiveLevel.shouldBlockCommit)
    }

    @Test("重大件数0なら報告された level をそのまま使う")
    func zeroCriticalKeepsLevel() {
        #expect(RiskAssessment(level: .safe, summary: "x", criticalIssueCount: 0).effectiveLevel == .safe)
        #expect(RiskAssessment(level: .warning, summary: "x", criticalIssueCount: 0).effectiveLevel == .warning)
    }

    @Test("safe / warning はコミットをブロックしない")
    func nonCriticalDoesNotBlock() {
        #expect(RiskLevel.safe.shouldBlockCommit == false)
        #expect(RiskLevel.warning.shouldBlockCommit == false)
        #expect(RiskLevel.critical.shouldBlockCommit == true)
    }
}

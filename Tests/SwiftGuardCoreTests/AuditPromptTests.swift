import Foundation
import Testing
@testable import SwiftGuardCore

@Suite("AuditPrompt")
struct AuditPromptTests {

    @Test("システム指示に全観点とそのチェックリストが含まれる")
    func instructionsContainAllCategories() {
        let text = AuditPrompt.systemInstructions
        for category in AuditCategory.all {
            #expect(text.contains(category.title))
            for item in category.checklist {
                #expect(text.contains(item))
            }
        }
        // 重大度の基準も含まれていること。
        #expect(text.contains("critical"))
        #expect(text.contains("日本語"))
    }

    @Test("既定の観点一覧（順序固定）")
    func defaultCategories() {
        let ids = AuditCategory.all.map(\.id)
        #expect(ids == ["memory", "concurrency", "performance", "privacy", "crash", "error"])
    }

    @Test("観点の id は一意")
    func categoryIDsAreUnique() {
        let ids = AuditCategory.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("短いソースは切り詰められない")
    func shortSourceNotTruncated() {
        let result = AuditPrompt.reviewPrompt(fileName: "A.swift", source: "let a = 1", maxCharacters: 100)
        #expect(result.truncated == false)
        #expect(result.prompt.contains("A.swift"))
        #expect(result.prompt.contains("let a = 1"))
    }

    @Test("長いソースは切り詰められ注記が付く")
    func longSourceTruncated() {
        let big = String(repeating: "x", count: 500)
        let result = AuditPrompt.reviewPrompt(fileName: "B.swift", source: big, maxCharacters: 100)
        #expect(result.truncated == true)
        #expect(result.prompt.contains("先頭 100 文字"))
    }
}

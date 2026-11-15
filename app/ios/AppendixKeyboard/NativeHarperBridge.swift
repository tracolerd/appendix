import Foundation

public struct LintSuggestion {
    public let start: Int
    public let end: Int
    public let targetWord: String
    public let message: String
    public let replacements: [String]
}

/// Swift bridge to Rust appendix_core library for iOS Custom Keyboard Extension
public final class NativeHarperBridge {
    public static let shared = NativeHarperBridge()

    private var enginePtr: UnsafeMutableRawPointer?
    private var currentDialect: Int32 = 0 // 0 = US, 1 = UK

    private init() {
        initEngine(dialect: 0)
    }

    deinit {
        freeEngine()
    }

    public func setDialect(dialect: Int32) {
        guard dialect != currentDialect else { return }
        currentDialect = dialect
        freeEngine()
        initEngine(dialect: dialect)
    }

    private func initEngine(dialect: Int32) {
        #if canImport(AppendixCore)
        enginePtr = appendix_engine_new(dialect)
        #endif
    }

    private func freeEngine() {
        #if canImport(AppendixCore)
        if let ptr = enginePtr {
            appendix_engine_free(ptr)
            enginePtr = nil
        }
        #endif
    }

    public func checkText(_ text: String) -> [LintSuggestion] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        #if canImport(AppendixCore)
        if let ptr = enginePtr {
            let cText = text.cString(using: .utf8)
            if let resultPtr = appendix_engine_check(ptr, cText) {
                defer { appendix_string_free(resultPtr) }
                let jsonString = String(cString: resultPtr)
                return parseLints(jsonString: jsonString, originalText: text)
            }
        }
        #endif

        // Offline Rule-based Heuristic Fallback
        return runHeuristicCheck(text: text)
    }

    private func parseLints(jsonString: String, originalText: String) -> [LintSuggestion] {
        guard let data = jsonString.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        var results: [LintSuggestion] = []
        for item in jsonArray {
            guard let start = item["start"] as? Int,
                  let end = item["end"] as? Int,
                  let message = item["message"] as? String,
                  let suggestionsRaw = item["suggestions"] as? [[String: Any]] else {
                continue
            }

            var replacements: [String] = []
            for sug in suggestionsRaw {
                if let rep = sug["replacement"] as? String, !rep.isEmpty {
                    replacements.append(rep)
                }
            }

            var targetWord = ""
            if start < originalText.count && end <= originalText.count && start < end {
                let startIndex = originalText.index(originalText.startIndex, offsetBy: start)
                let endIndex = originalText.index(originalText.startIndex, offsetBy: end)
                targetWord = String(originalText[startIndex..<endIndex])
            }

            if !replacements.isEmpty && !targetWord.isEmpty {
                results.append(LintSuggestion(
                    start: start,
                    end: end,
                    targetWord: targetWord,
                    message: message,
                    replacements: replacements
                ))
            }
        }
        return results
    }

    private func runHeuristicCheck(text: String) -> [LintSuggestion] {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard let lastWord = words.last else { return [] }

        let cleanWord = lastWord.lowercased().trimmingCharacters(in: .punctuationCharacters)
        let commonTypos: [String: String] = [
            "teh": "the",
            "recieve": "receive",
            "seperate": "separate",
            "untill": "until",
            "definately": "definitely",
            "occured": "occurred",
            "accomodate": "accommodate",
            "writting": "writing",
            "realy": "really",
            "becuase": "because"
        ]

        if let fix = commonTypos[cleanWord] {
            return [
                LintSuggestion(
                    start: text.count - cleanWord.count,
                    end: text.count,
                    targetWord: cleanWord,
                    message: "Spelling correction",
                    replacements: [fix]
                )
            ]
        }
        return []
    }
}


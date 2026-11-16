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
        if let ptr = enginePtr {
            appendix_engine_set_dialect(ptr, dialect)
        } else {
            initEngine(dialect: dialect)
        }
    }

    private func initEngine(dialect: Int32) {
        #if canImport(AppendixCore)
        enginePtr = appendix_engine_new(dialect)
        #else
        enginePtr = appendix_engine_new(dialect)
        #endif
    }

    private func freeEngine() {
        if let ptr = enginePtr {
            appendix_engine_free(ptr)
            enginePtr = nil
        }
    }

    public func checkText(_ text: String) -> [LintSuggestion] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        if let ptr = enginePtr {
            let cText = text.cString(using: .utf8)
            if let resultPtr = appendix_engine_check(ptr, cText) {
                defer { appendix_string_free(resultPtr) }
                let jsonString = String(cString: resultPtr)
                return parseLints(jsonString: jsonString, originalText: text)
            }
        }

        return []
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
            if let startIndex = originalText.index(originalText.startIndex, offsetBy: start, limitedBy: originalText.endIndex),
               let endIndex = originalText.index(originalText.startIndex, offsetBy: end, limitedBy: originalText.endIndex),
               startIndex < endIndex {
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
}


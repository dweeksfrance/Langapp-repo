import Foundation

/// Matches a wanted language against the keyboards the user has enabled
/// (the `primaryLanguage` values of `UITextInputMode.activeInputModes`).
public enum KeyboardLanguageMatcher {
    /// Exact match first ("en-GB" → "en-GB"), then any keyboard of the same
    /// language ("en-GB" → "en-US"). Returns nil if no keyboard fits.
    public static func bestMatch(for language: String, among available: [String]) -> String? {
        let wanted = normalize(language)
        if let exact = available.first(where: { normalize($0) == wanted }) {
            return exact
        }
        let wantedBase = base(of: language)
        return available.first { base(of: $0) == wantedBase }
    }

    /// The languages to offer when asking the user. Lists the enabled keyboards
    /// (skipping emoji and dictation), and always includes English and French.
    public static func languageOptions(
        from available: [String],
        ensuring required: [String] = ["en-GB", "fr-FR"]
    ) -> [String] {
        var options: [String] = []
        for id in available where isLanguage(id) && !options.contains(id) {
            options.append(id)
        }
        for id in required where !options.contains(where: { base(of: $0) == base(of: id) }) {
            options.append(id)
        }
        return options
    }

    static func normalize(_ id: String) -> String {
        id.replacingOccurrences(of: "_", with: "-").lowercased()
    }

    static func base(of id: String) -> String {
        normalize(id).split(separator: "-").first.map(String.init) ?? ""
    }

    static func isLanguage(_ id: String) -> Bool {
        let b = base(of: id)
        return (2...3).contains(b.count) && b.allSatisfy { $0.isASCII && $0.isLetter }
    }
}

import Foundation

/// Builds links that open a WhatsApp chat with text already filled in.
public enum WhatsAppLink {
    /// A `https://wa.me/<number>?text=<message>` link for the first number of
    /// the contact that can be written in international form, or nil if none can.
    public static func url(phoneNumbers: [String], text: String, defaultRegion: String?) -> URL? {
        guard let number = phoneNumbers.lazy
            .compactMap({ internationalDigits(of: $0, defaultRegion: defaultRegion) })
            .first
        else { return nil }
        return url(internationalDigits: number, text: text)
    }

    public static func url(internationalDigits: String, text: String) -> URL? {
        // Encode everything except unreserved characters, so "+" and "&" in the message survive.
        // ASCII only: CharacterSet.alphanumerics would also let accented letters through unencoded.
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let encoded = text.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        return URL(string: "https://wa.me/\(internationalDigits)?text=\(encoded)")
    }

    /// The number as country code + subscriber number, digits only (e.g. "33612345678"),
    /// which is what wa.me expects. Returns nil if the country can't be worked out.
    public static func internationalDigits(of rawNumber: String, defaultRegion: String?) -> String? {
        let digits = rawNumber.filter { $0.isASCII && $0.isNumber }
        guard digits.count >= 6 else { return nil }

        let firstSignificant = rawNumber.first { $0 == "+" || ($0.isASCII && $0.isNumber) }
        if firstSignificant == "+" { return digits }
        if digits.hasPrefix("00") { return String(digits.dropFirst(2)) }

        let region = defaultRegion?.uppercased()
        if (region == "US" || region == "CA"), digits.hasPrefix("011") {
            return String(digits.dropFirst(3))
        }

        switch region {
        case "FR":
            guard digits.count == 10, digits.hasPrefix("0") else { return nil }
            let national = String(digits.dropFirst())
            // Overseas departments use French national numbers but their own country code.
            if let code = frenchOverseasCode(forNational: national) { return code + national }
            return "33" + national
        case "GB":
            guard digits.hasPrefix("0"), (10...11).contains(digits.count) else { return nil }
            return "44" + digits.dropFirst()
        case "US", "CA":
            if digits.count == 10 { return "1" + digits }
            if digits.count == 11, digits.hasPrefix("1") { return digits }
            return nil
        default:
            return nil
        }
    }

    /// National prefixes (after the leading 0) used by the overseas departments.
    private static let overseasPrefixes: [(prefix: String, countryCode: String)] = [
        ("262", "262"), ("263", "262"), ("692", "262"), ("693", "262"), // Réunion
        ("269", "262"), ("639", "262"),                                 // Mayotte
        ("590", "590"), ("690", "590"), ("691", "590"),                 // Guadeloupe, St-Barth, St-Martin
        ("594", "594"), ("694", "594"),                                 // French Guiana
        ("596", "596"), ("696", "596"), ("697", "596"),                 // Martinique
    ]

    private static func frenchOverseasCode(forNational national: String) -> String? {
        overseasPrefixes.first { national.hasPrefix($0.prefix) }?.countryCode
    }
}

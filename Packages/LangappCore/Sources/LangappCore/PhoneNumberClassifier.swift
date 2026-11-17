import Foundation

/// The countries Langapp cares about when choosing a keyboard language.
public enum PhoneRegion: String, Equatable, Sendable {
    case unitedKingdom
    case unitedStates
    case france
    case other
}

/// Works out which country a phone number belongs to, without any dependencies.
///
/// Numbers written in international form (`+44…`, `0044…`) are classified by
/// their country code. Numbers written in national form (`06 12 34 56 78`) are
/// read using `defaultRegion`, the device's region (an ISO code such as "FR").
public enum PhoneNumberClassifier {
    public static func region(of rawNumber: String, defaultRegion: String?) -> PhoneRegion {
        let digits = rawNumber.filter { $0.isASCII && $0.isNumber }
        guard !digits.isEmpty else { return .other }

        // "+" may be preceded by spaces or an opening bracket, e.g. "(+44) 20…".
        let firstSignificant = rawNumber.first { $0 == "+" || ($0.isASCII && $0.isNumber) }
        if firstSignificant == "+" {
            return regionForInternational(digits)
        }
        if digits.hasPrefix("00") {
            return regionForInternational(String(digits.dropFirst(2)))
        }

        let region = defaultRegion?.uppercased()
        if (region == "US" || region == "CA"), digits.hasPrefix("011") {
            return regionForInternational(String(digits.dropFirst(3)))
        }
        return regionForNational(digits, region: region)
    }

    /// `digits` starts with the country code.
    private static func regionForInternational(_ digits: String) -> PhoneRegion {
        if digits.hasPrefix("44") { return .unitedKingdom }
        if digits.hasPrefix("33") { return .france }
        if digits.hasPrefix("1") { return .unitedStates } // +1 is shared with Canada and the Caribbean.
        return .other
    }

    private static func regionForNational(_ digits: String, region: String?) -> PhoneRegion {
        switch region {
        case "FR":
            // French national numbers: 0 followed by 9 digits, e.g. 06 12 34 56 78.
            return digits.count == 10 && digits.hasPrefix("0") ? .france : .other
        case "GB":
            return digits.hasPrefix("0") && (10...11).contains(digits.count) ? .unitedKingdom : .other
        case "US":
            if digits.count == 10 { return .unitedStates }
            if digits.count == 11, digits.hasPrefix("1") { return .unitedStates }
            return .other
        default:
            return .other
        }
    }
}

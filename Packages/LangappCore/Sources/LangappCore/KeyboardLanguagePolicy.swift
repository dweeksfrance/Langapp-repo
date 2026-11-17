import Foundation

public enum KeyboardDecision: Equatable, Sendable {
    /// Switch the keyboard to this language (a BCP 47 identifier such as "en-GB").
    case useLanguage(String)
    /// French contact with no remembered choice: ask the user, then remember it.
    case askUser
    /// Not a UK, US or French number: keep whatever keyboard is active.
    case leaveUnchanged
}

/// The rules for picking a keyboard language when you start writing to a contact:
/// - UK number → English (en-GB)
/// - US number → English (en-US)
/// - French number → the language you chose last time, or ask you
/// - anything else → the keyboard is left alone
///
/// If a contact has several numbers, the first UK, US or French one in the
/// contact card decides.
public struct KeyboardLanguagePolicy {
    public let store: LanguagePreferenceStore
    public let defaultRegion: String?

    public init(store: LanguagePreferenceStore, defaultRegion: String?) {
        self.store = store
        self.defaultRegion = defaultRegion
    }

    public func primaryRegion(of phoneNumbers: [String]) -> PhoneRegion {
        phoneNumbers
            .lazy
            .map { PhoneNumberClassifier.region(of: $0, defaultRegion: defaultRegion) }
            .first { $0 != .other } ?? .other
    }

    public func decide(contactID: String, phoneNumbers: [String]) -> KeyboardDecision {
        switch primaryRegion(of: phoneNumbers) {
        case .unitedKingdom:
            return .useLanguage("en-GB")
        case .unitedStates:
            return .useLanguage("en-US")
        case .france:
            if let saved = store.language(forContact: contactID) {
                return .useLanguage(saved)
            }
            return .askUser
        case .other:
            return .leaveUnchanged
        }
    }
}

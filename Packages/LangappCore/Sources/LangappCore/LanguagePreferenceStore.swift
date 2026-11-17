import Foundation

/// Remembers the keyboard language chosen for a contact.
public protocol LanguagePreferenceStore: AnyObject {
    func language(forContact contactID: String) -> String?
    func setLanguage(_ language: String, forContact contactID: String)
    func clearLanguage(forContact contactID: String)
}

/// Persists choices in `UserDefaults`, keyed by the contact's identifier.
public final class UserDefaultsLanguagePreferenceStore: LanguagePreferenceStore {
    private let defaults: UserDefaults
    private let keyPrefix = "keyboardLanguage."

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func language(forContact contactID: String) -> String? {
        defaults.string(forKey: keyPrefix + contactID)
    }

    public func setLanguage(_ language: String, forContact contactID: String) {
        defaults.set(language, forKey: keyPrefix + contactID)
    }

    public func clearLanguage(forContact contactID: String) {
        defaults.removeObject(forKey: keyPrefix + contactID)
    }
}

/// Non-persistent store, useful for tests and previews.
public final class InMemoryLanguagePreferenceStore: LanguagePreferenceStore {
    private var values: [String: String] = [:]

    public init() {}

    public func language(forContact contactID: String) -> String? { values[contactID] }
    public func setLanguage(_ language: String, forContact contactID: String) { values[contactID] = language }
    public func clearLanguage(forContact contactID: String) { values[contactID] = nil }
}

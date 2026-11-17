import LangappCore
import SwiftUI
import UIKit

/// Decides which keyboard to show when you start writing to a contact.
@MainActor
final class ComposeController: ObservableObject {
    let contact: Contact
    let isFrenchContact: Bool
    let languageOptions: [String]

    /// The keyboard language the text view should request (nil = system default).
    @Published private(set) var keyboardLanguage: String?
    /// Whether the text view should be focused (keyboard up).
    @Published private(set) var shouldFocus = false
    @Published private(set) var statusNote: String?
    @Published var isAskingForLanguage = false {
        didSet {
            // The dialog closed, whether the user picked a language or cancelled: start writing.
            if oldValue && !isAskingForLanguage { shouldFocus = true }
        }
    }

    private let store: LanguagePreferenceStore
    private let policy: KeyboardLanguagePolicy
    private var started = false

    init(contact: Contact, store: LanguagePreferenceStore = UserDefaultsLanguagePreferenceStore()) {
        self.contact = contact
        self.store = store
        let policy = KeyboardLanguagePolicy(store: store, defaultRegion: Locale.current.region?.identifier)
        self.policy = policy
        self.isFrenchContact = policy.primaryRegion(of: contact.phoneNumbers) == .france
        self.languageOptions = KeyboardLanguageMatcher.languageOptions(from: Self.enabledKeyboardLanguages())
    }

    func start() {
        guard !started else { return }
        started = true

        switch policy.decide(contactID: contact.id, phoneNumbers: contact.phoneNumbers) {
        case .useLanguage(let language):
            setKeyboard(language)
            shouldFocus = true
        case .askUser:
            isAskingForLanguage = true
        case .leaveUnchanged:
            shouldFocus = true
        }
    }

    /// Called from the language dialog. The choice is remembered for this contact.
    func choose(_ language: String) {
        store.setLanguage(language, forContact: contact.id)
        setKeyboard(language)
    }

    /// Lets you change the remembered language for a French contact.
    func askAgain() {
        shouldFocus = false
        isAskingForLanguage = true
    }

    private func setKeyboard(_ language: String) {
        keyboardLanguage = language
        let name = displayName(for: language)
        if KeyboardLanguageMatcher.bestMatch(for: language, among: Self.enabledKeyboardLanguages()) == nil {
            statusNote = "No \(name) keyboard is enabled. Add one in Settings › General › Keyboard › Keyboards."
        } else {
            statusNote = "Keyboard: \(name)"
        }
    }

    static func enabledKeyboardLanguages() -> [String] {
        UITextInputMode.activeInputModes.compactMap(\.primaryLanguage)
    }
}

func displayName(for language: String) -> String {
    Locale.current.localizedString(forIdentifier: language) ?? language
}

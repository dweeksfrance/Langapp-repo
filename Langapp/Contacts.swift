import Contacts
import Foundation

struct Contact: Identifiable, Hashable {
    let id: String          // CNContact.identifier, used to remember the language choice
    let name: String
    let phoneNumbers: [String]
}

@MainActor
final class ContactsViewModel: ObservableObject {
    enum State {
        case loading
        case denied
        case loaded([Contact])
    }

    @Published private(set) var state: State = .loading

    func load() async {
        do {
            guard try await CNContactStore().requestAccess(for: .contacts) else {
                state = .denied
                return
            }
            let contacts = try await Task.detached(priority: .userInitiated) {
                try Self.fetchContactsWithPhoneNumbers()
            }.value
            state = .loaded(contacts)
        } catch {
            state = .denied
        }
    }

    nonisolated private static func fetchContactsWithPhoneNumbers() throws -> [Contact] {
        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor,
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault

        var contacts: [Contact] = []
        try CNContactStore().enumerateContacts(with: request) { cnContact, _ in
            let numbers = cnContact.phoneNumbers.map { $0.value.stringValue }
            guard let firstNumber = numbers.first else { return }
            let name = CNContactFormatter.string(from: cnContact, style: .fullName) ?? firstNumber
            contacts.append(Contact(id: cnContact.identifier, name: name, phoneNumbers: numbers))
        }
        return contacts
    }
}

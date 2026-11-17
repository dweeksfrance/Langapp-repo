import SwiftUI

struct ContactsListView: View {
    @StateObject private var model = ContactsViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Contacts")
                .navigationDestination(for: Contact.self) { contact in
                    ComposeView(contact: contact)
                }
        }
        .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView()
        case .denied:
            ContentUnavailableView(
                "No access to contacts",
                systemImage: "person.crop.circle.badge.xmark",
                description: Text("Allow Langapp to read your contacts in Settings.")
            )
        case .loaded(let contacts):
            List(filtered(contacts)) { contact in
                NavigationLink(value: contact) {
                    VStack(alignment: .leading) {
                        Text(contact.name)
                        Text(contact.phoneNumbers.first ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $searchText)
        }
    }

    private func filtered(_ contacts: [Contact]) -> [Contact] {
        guard !searchText.isEmpty else { return contacts }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

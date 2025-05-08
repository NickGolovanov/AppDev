import SwiftUI

struct PartyPalView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("PartyPal")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 10)
                    
                    // Trending Tonight section
                    SectionHeader(title: "Trending Tonight")
                    
                    EventItem(title: "Home", subtitle: "Hot")
                    EventItem(title: "Neon Dreams", subtitle: "22:00 - Club Matrix")
                    EventItem(title: "Beach Beach Bl", subtitle: "20:00 - 2:01")
                    
                    Divider()
                    
                    // Upcoming Events section
                    SectionHeader(title: "Upcoming Events")
                    
                    EventItem(title: "Amsterdam Student Night", subtitle: "May 3, 2025 - 21:00")
                    TagLabel(text: "Smart Casual")
                    EventItem(title: "TU Delft Spring Party", subtitle: "May 1, 2025 - 22:00")
                    TagLabel(text: "€10")
                    
                    Button(action: {}) {
                        Text("Join")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Divider()
                    
                    // Host section
                    SectionHeader(title: "Host your own party?")
                    
                    Text("Create and manage your event with ease")
                        .foregroundColor(.secondary)
                    
                    Button(action: {}) {
                        Text("Create Party")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
            }
            .toolbar {
                Toolbar()
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title2.bold())
    }
}

struct EventItem: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .foregroundColor(.secondary)
        }
    }
}

struct TagLabel: View {
    let text: String
    
    var body: some View {
        Text(text)
            .foregroundColor(.blue)
            .font(.subheadline)
    }
}

struct Toolbar: View {
    var body: some View {
        HStack {
            TabButton(icon: "house", label: "Home")
            TabButton(icon: "ticket", label: "Tickets")
            TabButton(icon: "calendar", label: "Events")
            TabButton(icon: "message", label: "Chat")
            TabButton(icon: "person", label: "Profile")
        }
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    
    var body: some View {
        Button(action: {}) {
            VStack {
                Image(systemName: icon)
                Text(label)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct PartyPalView_Previews: PreviewProvider {
    static var previews: some View {
        PartyPalView()
    }
}
import SwiftUI

struct ServerListView: View {
    @EnvironmentObject var store: ProfileStore
    @State private var pinging = false

    var body: some View {
        ZStack {
            NovaTheme.bgGradient.ignoresSafeArea()
            List {
                ForEach(store.profiles) { p in
                    ServerRow(profile: p, selected: store.selectedID == p.id) {
                        store.selectedID = p.id
                        store.save()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onDelete { store.remove(at: $0) }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Серверы")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(pinging ? "…" : "Ping все") { pingAll() }.disabled(pinging)
                }
            }
        }
    }

    private func pingAll() {
        pinging = true
        let group = DispatchGroup()
        for p in store.profiles {
            group.enter()
            PingService.ping(profile: p) { ms in
                DispatchQueue.main.async {
                    store.updatePing(id: p.id, ms: ms ?? 9999)
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) { pinging = false }
    }
}

private struct ServerRow: View {
    let profile: ServerProfile
    let selected: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selected ? .green : .white.opacity(0.3)).font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name).font(.headline).foregroundColor(.white).lineLimit(1)
                    Text("\(profile.proto.title) · \(profile.displayAddress)").font(.caption).foregroundColor(.white.opacity(0.55)).lineLimit(1)
                }
                Spacer()
                Text(profile.pingMs.map { "\($0)" } ?? "—").font(.subheadline.weight(.semibold)).foregroundColor(pingColor(profile.pingMs))
                Text("ms").font(.caption2).foregroundColor(.white.opacity(0.4))
            }
            .padding(14)
            .background(selected ? Color.green.opacity(0.10) : NovaTheme.card)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? Color.green.opacity(0.4) : NovaTheme.stroke, lineWidth: 1))
            .cornerRadius(18)
        }.buttonStyle(.plain)
    }
}

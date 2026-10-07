import Foundation
import Combine

/// Хранилище профилей + выбранный сервер + подписки. Персист в UserDefaults (App Group — в Xcode).
final class ProfileStore: ObservableObject {
    static let shared = ProfileStore()
    @Published var profiles: [ServerProfile] = []
    @Published var selectedID: UUID? = nil
    @Published var subscriptions: [String] = []
    @Published var isConnected: Bool = false
    @Published var statusText: String = "Отключено"

    private let key = "novatun.profiles.v1"
    private let selKey = "novatun.selected.v1"
    private let subKey = "novatun.subs.v1"

    var selected: ServerProfile? {
        profiles.first(where: { $0.id == selectedID }) ?? profiles.first
    }

    private init() { load() }

    func add(_ p: ServerProfile) {
        if let i = profiles.firstIndex(where: { $0.displayAddress == p.displayAddress && $0.proto == p.proto }) {
            profiles[i] = p
        } else { profiles.append(p) }
        if selectedID == nil { selectedID = p.id }
        save()
    }

    func add(link: String) -> Bool {
        guard let p = LinkParser.parse(link) else { return false }
        add(p); return true
    }

    func remove(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        if let s = selectedID, !profiles.contains(where: { $0.id == s }) { selectedID = profiles.first?.id }
        save()
    }

    func updatePing(id: UUID, ms: Int) {
        if let i = profiles.firstIndex(where: { $0.id == id }) { profiles[i].pingMs = ms }
    }

    func save() {
        if let d = try? JSONEncoder().encode(profiles) { UserDefaults.standard.set(d, forKey: key) }
        UserDefaults.standard.set(selectedID?.uuidString, forKey: selKey)
        UserDefaults.standard.set(subscriptions, forKey: subKey)
    }

    func load() {
        if let d = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([ServerProfile].self, from: d), !arr.isEmpty {
            profiles = arr
        } else { profiles = ServerProfile.demo }
        if let s = UserDefaults.standard.string(forKey: selKey), let u = UUID(uuidString: s) { selectedID = u }
        else { selectedID = profiles.first?.id }
        subscriptions = UserDefaults.standard.stringArray(forKey: subKey) ?? []
    }

    func updateSubscription(url: String, completion: @escaping (Int) -> Void) {
        guard let u = URL(string: url) else { completion(0); return }
        var request = URLRequest(url: u, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { DispatchQueue.main.async { completion(0) }; return }
            var text = String(data: data, encoding: .utf8) ?? ""
            if !text.contains("://"), let d = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)),
               let dec = String(data: d, encoding: .utf8) { text = dec }
            let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty && !$0.hasPrefix("#") }
            var n = 0
            DispatchQueue.main.async {
                for l in lines { if self.add(link: l) { n += 1 } }
                self.save(); completion(n)
            }
        }.resume()
    }
}

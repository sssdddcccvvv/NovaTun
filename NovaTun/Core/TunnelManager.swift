import Foundation
import NetworkExtension
import Combine

/// Управление PacketTunnel: вкл/выкл, статус. Bundle ID расширения — заменить на свой в Xcode.
final class TunnelManager: ObservableObject {
    static let shared = TunnelManager()
    private let tunnelBundleID = "com.example.NovaTun.NovaTunPacketTunnel"
    @Published var status: NEVPNStatus = .disconnected

    private init() { observe() }

    var manager: NETunnelProviderManager? { nil } // доступ через loadFromPreferences в полной сборке

    /// Переключить в true, когда PacketTunnel свяжется с XrayMobile.xcframework.
    static let coreWired = false

    func connect(profile: ServerProfile) {
        guard Self.coreWired else {
            ProfileStore.shared.isConnected = false
            ProfileStore.shared.statusText = "Ядро Xray подключается в следующей сборке"
            return
        }
        let configJSON = XrayConfigBuilder.jsonString(profile: profile)
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            let m = managers?.first(where: { $0.protocolConfiguration is NETunnelProviderProtocol }) ?? NETunnelProviderManager()
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = self.tunnelBundleID
            proto.serverAddress = profile.displayAddress
            proto.providerConfiguration = ["xray-config": configJSON, "profile-name": profile.name]
            m.protocolConfiguration = proto
            m.localizedDescription = "NovaTun · \(profile.name)"
            m.isEnabled = true
            m.saveToPreferences { err in
                guard err == nil else { return }
                m.loadFromPreferences { _ in
                    try? m.connection.startVPNTunnel()
                }
            }
        }
    }

    func disconnect() {
        NETunnelProviderManager.loadAllFromPreferences { managers, _ in
            managers?.forEach { $0.connection.stopVPNTunnel() }
        }
    }

    private func observe() {
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: .main) { [weak self] n in
            if let c = n.object as? NEVPNConnection { self?.status = c.status }
            self?.syncStore()
        }
    }

    private func syncStore() {
        DispatchQueue.main.async {
            switch self.status {
            case .connected:
                ProfileStore.shared.isConnected = true
                ProfileStore.shared.statusText = "Подключено · Xray 26.9.9"
            case .connecting, .reasserting:
                ProfileStore.shared.isConnected = false
                ProfileStore.shared.statusText = "Подключение…"
            case .disconnecting:
                ProfileStore.shared.isConnected = false
                ProfileStore.shared.statusText = "Отключение…"
            default:
                ProfileStore.shared.isConnected = false
                ProfileStore.shared.statusText = "Отключено"
            }
        }
    }
}

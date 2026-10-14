import Foundation
import NetworkExtension
import Combine

/// Управление PacketTunnel: вкл/выкл, статус.
/// Bundle ID расширения выводится из bundle ID приложения (PRODUCT_BUNDLE_IDENTIFIER + ".NovaTunPacketTunnel"),
/// поэтому при смене bundle ID в Xcode код менять не нужно.
final class TunnelManager: ObservableObject {
    static let shared = TunnelManager()

    @Published var status: NEVPNStatus = .disconnected
    @Published var lastError: String?

    private init() { observe() }

    /// Bundle ID PacketTunnel-расширения: приложение + суффикс из настроек target'а.
    private var tunnelBundleID: String {
        let appID = Bundle.main.bundleIdentifier ?? "com.example.NovaTun"
        return appID + ".NovaTunPacketTunnel"
    }

    /// Текущий сохранённый менеджер VPN (после connect — заполнен).
    private(set) var manager: NETunnelProviderManager?

    func connect(profile: ServerProfile) {
        let configJSON = XrayConfigBuilder.jsonString(profile: profile)
        lastError = nil
        ProfileStore.shared.statusText = "Подключение…"

        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let error = error {
                self.fail("Ошибка чтения настроек VPN: \(error.localizedDescription)")
                return
            }
            let m = managers?.first(where: { $0.protocolConfiguration is NETunnelProviderProtocol })
                ?? NETunnelProviderManager()
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = self.tunnelBundleID
            proto.serverAddress = profile.displayAddress
            proto.providerConfiguration = ["xray-config": configJSON, "profile-name": profile.name]
            m.protocolConfiguration = proto
            m.localizedDescription = "NovaTun · \(profile.name)"
            m.isEnabled = true
            m.saveToPreferences { err in
                if let err = err {
                    self.fail("Ошибка сохранения VPN: \(self.errorText(err))")
                    return
                }
                m.loadFromPreferences { loadErr in
                    if let loadErr = loadErr {
                        self.fail("Ошибка перезагрузки настроек: \(self.errorText(loadErr))")
                        return
                    }
                    self.manager = m
                    do {
                        try m.connection.startVPNTunnel()
                    } catch {
                        self.fail("Ошибка запуска туннеля: \(self.errorText(error))")
                    }
                }
            }
        }
    }

    func disconnect() {
        if let m = manager {
            m.connection.stopVPNTunnel()
        } else {
            NETunnelProviderManager.loadAllFromPreferences { managers, _ in
                managers?.forEach { $0.connection.stopVPNTunnel() }
            }
        }
    }

    private func fail(_ message: String) {
        NSLog("[NovaTun] %@", message)
        DispatchQueue.main.async {
            self.lastError = message
            self.status = .disconnected
            ProfileStore.shared.isConnected = false
            ProfileStore.shared.statusText = message
        }
    }

    private func errorText(_ error: Error) -> String {
        let ns = error as NSError
        return "\(ns.localizedDescription) [\(ns.domain)#\(ns.code)]"
    }

    private func observe() {
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: .main) { [weak self] n in
            guard let self = self else { return }
            if let c = n.object as? NEVPNConnection { self.status = c.status }
            self.syncStore()
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
            case .invalid:
                ProfileStore.shared.isConnected = false
                ProfileStore.shared.statusText = self.lastError ?? "Отключено"
            default:
                ProfileStore.shared.isConnected = false
                ProfileStore.shared.statusText = "Отключено"
            }
        }
    }
}

private func errorText(_ error: Error) -> String {
    let ns = error as NSError
    return "\(ns.localizedDescription) [\(ns.domain)#\(ns.code)]"
}

import NetworkExtension

/// PacketTunnel: принимает JSON Xray-конфига из приложения и поднимает TUN.
/// Xray-core 26.9.9 собирается в XrayMobile.xcframework на CI (см. .github/workflows/ipa.yml).
/// Пока Swift-обёртка не связана со сгенерированным Mobile*-API, старт безопасно
/// завершается ошибкой, чтобы iOS НЕ поднимал VPN с маршрутами в пустоту.
class PacketTunnelProvider: NEPacketTunnelProvider {
    private var xrayHandle: AnyObject?

    override func startTunnel(options: [String : NSObject]? = nil) async throws {
        guard let cfg = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration,
              let json = cfg["xray-config"] as? String,
              let name = cfg["profile-name"] as? String else {
            throw NSError(domain: "NovaTun", code: 1, userInfo: [NSLocalizedDescriptionKey: "Нет конфига Xray"])
        }
        throw NSError(domain: "NovaTun", code: 2, userInfo: [NSLocalizedDescriptionKey: "XrayMobile ещё не связан (см. README, milestone M2)"])
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = 1500
        let v4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
        v4.includedRoutes = [NEIPv4Route.default()]
        v4.excludedRoutes = [NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0")]
        settings.iPv4Settings = v4
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        settings.dnsSettings?.matchDomains = [""]
        try await self.setTunnelNetworkSettings(settings)
        // Запуск Xray-core 26.9.9 (линкуется как xcframework, функция XrayRun):
        // XrayRun(configJSON: json, port: 12334)
        NSLog("[NovaTun] start profile=\(name), xray=\(XrayVersionString), configBytes=\(json.count)")
        _ = json
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        // XrayStop()
        NSLog("[NovaTun] stop")
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? { nil }
}

let XrayVersionString = "26.9.9"

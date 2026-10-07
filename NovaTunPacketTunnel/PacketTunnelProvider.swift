import NetworkExtension

/// PacketTunnel: принимает JSON Xray-конфига из приложения и поднимает TUN.
/// Xray-core 26.9.9 собирается в XrayMobile.xcframework на CI (см. .github/workflows/ipa.yml).
/// Milestone M1: стаб безопасно завершает старт ошибкой, чтобы iOS НЕ поднимал
/// VPN с маршрутами в пустоту. Каркас setTunnelNetworkSettings оставлен
/// закомментированным до связывания Swift <-> сгенерированного Mobile-API (M2).
class PacketTunnelProvider: NEPacketTunnelProvider {

    override func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        guard let cfg = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration,
              let json = cfg["xray-config"] as? String,
              let name = cfg["profile-name"] as? String
        else {
            completionHandler(NSError(domain: "NovaTun", code: 1, userInfo: [NSLocalizedDescriptionKey: "Нет конфига Xray"]))
            return
        }
        NSLog("[NovaTun] start profile=%@, xray=%@, configBytes=%d", name, XrayVersionString, json.count)
        // M2: здесь будет MobileStartXray(json, ...) + setTunnelNetworkSettings(...)
        completionHandler(NSError(domain: "NovaTun", code: 2, userInfo: [NSLocalizedDescriptionKey: "XrayMobile ещё не связан (см. README, milestone M2)"]))
        /*
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = 1500
        let v4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
        v4.includedRoutes = [NEIPv4Route.default()]
        settings.iPv4Settings = v4
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        settings.dnsSettings?.matchDomains = [""]
        setTunnelNetworkSettings(settings) { _ in completionHandler(nil) }
        */
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // M2: MobileStopXray()
        NSLog("[NovaTun] stop")
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        completionHandler?(nil)
    }
}

let XrayVersionString = "26.9.9"

import Darwin
import Foundation
import NetworkExtension
import XrayMobile

/// PacketTunnel: принимает JSON Xray-конфига из приложения, находит fd utun
/// и запускает Xray-core 26.9.9 (XrayMobile.xcframework) прямо на этом fd.
///
/// Схема (см. Xray README, iOS-режим):
///   1. iOS создаёт utun и передаёт его fd в процесс расширения;
///   2. мы находим fd, спрашивая у каждого имя интерфейса (UTUN_OPT_IFNAME);
///   3. ядро Xray читает/пишет IP-пакеты напрямую через этот fd
///      (inbound protocol:"tun" + XRAY_TUN_FD, см. xray-mobile/mobile/mobile.go);
///   4. setTunnelNetworkSettings ставит маршруты, чтобы iOS направлял
///      трафик приложений в utun. packetFlow не используется — пакетами
///      владеет ядро.
class PacketTunnelProvider: NEPacketTunnelProvider {

    override func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        guard let cfg = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration,
              let json = cfg["xray-config"] as? String,
              let name = cfg["profile-name"] as? String
        else {
            completionHandler(makeError("Нет конфига Xray"))
            return
        }
        NSLog("[NovaTun] start profile=%@, xray=%@, configBytes=%d", name, XrayVersionString, json.count)

        // 1. Находим fd utun: перебираем открытые fd и читаем имя интерфейса.
        guard let fd = Self.findUtunFD() else {
            completionHandler(makeError("fd utun не найден"))
            return
        }
        NSLog("[NovaTun] utun fd=%d", fd)

        // 2. Маршруты и DNS — без этого iOS не направит трафик приложений в utun.
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "198.18.0.1")
        settings.mtu = 1500
        let v4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
        v4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = v4
        let dns = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        dns.matchDomains = [""]
        settings.dnsSettings = dns

        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self = self else { completionHandler(nil); return }
            if let error = error {
                NSLog("[NovaTun] setTunnelNetworkSettings error: %@", error.localizedDescription)
                completionHandler(error)
                return
            }
            // 3. Запуск ядра на fd utun. "" — успех, иначе текст ошибки.
            let err = MobileStartXrayFD(json, Int32(fd))
            if err.isEmpty {
                NSLog("[NovaTun] xray started")
                completionHandler(nil)
            } else {
                NSLog("[NovaTun] xray start error: %@", err)
                completionHandler(self.makeError(err))
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        let err = MobileStopXray()
        if !err.isEmpty {
            NSLog("[NovaTun] xray stop error: %@", err)
        }
        NSLog("[NovaTun] stop reason=%d", reason.rawValue)
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        completionHandler?(nil)
    }

    private func makeError(_ message: String) -> NSError {
        NSError(domain: "NovaTun", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    /// Возвращает fd первого открытого utun-интерфейса (0...1024) либо nil.
    /// getsockopt(fd, SYSPROTO_CONTROL=2, UTUN_OPT_IFNAME=2) возвращает имя
    /// utun-интерфейса, если fd принадлежит utun (сниппет из Xray README).
    private static func findUtunFD() -> Int32? {
        var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))
        let utunPrefix = Array("utun".utf8CString.dropLast())
        return (0...1024).first { fd in
            var len = socklen_t(buf.count)
            return getsockopt(fd, 2, 2, &buf, &len) == 0 && buf.starts(with: utunPrefix)
        }
    }
}

let XrayVersionString = "26.9.9"

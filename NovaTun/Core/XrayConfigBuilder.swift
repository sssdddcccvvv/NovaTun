import Foundation

/// Строит JSON-конфиг Xray-core 26.9.9 под выбранный профиль.
/// Совместимо с полями Xray 26.x: reality, xhttp, xtls-rprx-vision, fingerprint (uTLS).
struct XrayConfigBuilder {
    static func build(profile: ServerProfile) -> [String: Any] {
        var outboundSettings: [String: Any] = [:]
        let streamSettings: [String: Any] = baseStream(profile: profile)

        switch profile.proto {
        case .vless:
            var vnextUser: [String: Any] = ["id": profile.uuid, "encryption": "none"]
            if !profile.flow.isEmpty { vnextUser["flow"] = profile.flow }
            outboundSettings = ["vnext": [["address": profile.address, "port": profile.port, "users": [vnextUser]]]]
        case .vmess:
            outboundSettings = ["vnext": [["address": profile.address, "port": profile.port,
                "users": [["id": profile.uuid, "alterId": 0, "security": profile.security.isEmpty ? "auto" : profile.security]]]]]
        case .trojan:
            outboundSettings = ["servers": [["address": profile.address, "port": profile.port, "password": profile.password]]]
        case .shadowsocks:
            outboundSettings = ["servers": [["address": profile.address, "port": profile.port,
                "method": profile.method, "password": profile.password]]]
        }

        let outboundProto: String = {
            switch profile.proto {
            case .vless: return "vless"
            case .vmess: return "vmess"
            case .trojan: return "trojan"
            case .shadowsocks: return "shadowsocks"
            }
        }()

        let config: [String: Any] = [
            "log": ["loglevel": "warning"],
            "inbounds": [[
                "tag": "tun", "port": 12334, "protocol": "dokodemo-door",
                "settings": ["network": "tcp,udp", "address": "0.0.0.0", "port": 0],
                "sniffing": ["enabled": true, "destOverride": ["http", "tls", "quic"]]
            ]],
            "outbounds": [[
                "tag": "proxy", "protocol": outboundProto,
                "settings": outboundSettings,
                "streamSettings": streamSettings
            ], ["tag": "direct", "protocol": "freedom"], ["tag": "block", "protocol": "blackhole"]],
            "routing": ["domainStrategy": "IPIfNonMatch",
                "rules": [["type": "field", "ip": ["geoip:private"], "outboundTag": "direct"]]]
        ]
        return config
    }

    private static func baseStream(profile: ServerProfile) -> [String: Any] {
        var s: [String: Any] = ["network": profile.network.isEmpty ? "tcp" : profile.network]
        let needsTLS = profile.tls || !profile.realityPublicKey.isEmpty || profile.network == "xhttp"
        if needsTLS {
            if !profile.realityPublicKey.isEmpty {
                s["security"] = "reality"
                s["realitySettings"] = [
                    "serverName": profile.sni,
                    "fingerprint": profile.fingerprint.isEmpty ? "chrome" : profile.fingerprint,
                    "publicKey": profile.realityPublicKey,
                    "shortId": profile.realityShortId,
                    "spiderX": profile.realitySpiderX.isEmpty ? "/" : profile.realitySpiderX
                ]
            } else {
                s["security"] = "tls"
                var tls: [String: Any] = [
                    "serverName": profile.sni.isEmpty ? profile.address : profile.sni,
                    "allowInsecure": false,
                    "alpn": profile.alpn.split(separator: ",").map(String.init)
                ]
                if !profile.fingerprint.isEmpty { tls["fingerprint"] = profile.fingerprint }
                s["tlsSettings"] = tls
            }
        } else {
            s["security"] = "none"
        }
        switch profile.network {
        case "ws":
            s["wsSettings"] = ["path": profile.path.isEmpty ? "/" : profile.path,
                               "headers": ["Host": profile.host.isEmpty ? profile.address : profile.host]]
        case "xhttp":
            s["xhttpSettings"] = ["path": profile.path.isEmpty ? "/" : profile.path,
                                  "host": profile.host.isEmpty ? profile.address : profile.host, "mode": "auto"]
        case "grpc":
            s["grpcSettings"] = ["serviceName": profile.path.isEmpty ? "xray" : profile.path]
        default: break
        }
        return s
    }

    static func jsonString(profile: ServerProfile) -> String {
        let dict = build(profile: profile)
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}

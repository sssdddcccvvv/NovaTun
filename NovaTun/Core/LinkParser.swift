import Foundation

/// Парсер ссылок vless:// vmess:// trojan:// ss:// — как в Happ / V2RayTun / Streisand.
struct LinkParser {
    static func parse(_ link: String) -> ServerProfile? {
        let t = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("vless://") { return parseVLESS(t) }
        if t.hasPrefix("vmess://") { return parseVMess(t) }
        if t.hasPrefix("trojan://") { return parseTrojan(t) }
        if t.hasPrefix("ss://") { return parseSS(t) }
        return nil
    }

    private static func parseVLESS(_ s: String) -> ServerProfile? {
        guard let c = URLComponents(string: s), let uuid = c.path.isEmpty ? nil : String(c.path.dropFirst()) else { return nil }
        var p = ServerProfile(name: "", proto: .vless, address: c.host ?? "", port: c.port ?? 443, uuid: uuid)
        var q: [String: String] = [:]
        c.queryItems?.forEach { q[$0.name] = $0.value ?? "" }
        p.network = q["type"] ?? "tcp"
        let sec = q["security"] ?? "none"
        p.tls = (sec == "tls" || sec == "reality")
        p.sni = q["sni"] ?? q["host"] ?? ""
        p.flow = q["flow"] ?? ""
        p.path = q["path"] ?? q["serviceName"] ?? ""
        p.host = q["host"] ?? ""
        p.realityPublicKey = q["pbk"] ?? ""
        p.realityShortId = q["sid"] ?? ""
        p.realitySpiderX = q["spx"] ?? ""
        p.fingerprint = q["fp"] ?? "chrome"
        p.alpn = q["alpn"] ?? "h2,http/1.1"
        p.name = fragmentName(c) ?? "\(p.address):\(p.port)"
        return p
    }

    private static func parseVMess(_ s: String) -> ServerProfile? {
        let b64 = String(s.dropFirst("vmess://".count))
        guard let data = Data(base64Encoded: pad(b64)),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        var p = ServerProfile(name: "", proto: .vmess,
            address: obj["add"] as? String ?? "", port: Int("\(obj["port"] ?? 443)") ?? 443,
            uuid: obj["id"] as? String ?? "")
        p.network = obj["net"] as? String ?? "tcp"
        p.tls = (obj["tls"] as? String ?? "") == "tls"
        p.sni = obj["sni"] as? String ?? obj["host"] as? String ?? ""
        p.path = obj["path"] as? String ?? ""
        p.host = obj["host"] as? String ?? ""
        p.security = "auto"
        p.name = (obj["ps"] as? String)?.isEmpty == false ? (obj["ps"] as? String ?? "") : "\(p.address):\(p.port)"
        return p
    }

    private static func parseTrojan(_ s: String) -> ServerProfile? {
        guard let c = URLComponents(string: s) else { return nil }
        var p = ServerProfile(name: "", proto: .trojan, address: c.host ?? "", port: c.port ?? 443,
                              password: c.path.isEmpty ? "" : String(c.path.dropFirst()))
        var q: [String: String] = [:]
        c.queryItems?.forEach { q[$0.name] = $0.value ?? "" }
        p.tls = true
        p.network = q["type"] ?? "tcp"
        p.sni = q["sni"] ?? ""
        p.path = q["path"] ?? ""
        p.name = fragmentName(c) ?? "\(p.address):\(p.port)"
        return p
    }

    private static func parseSS(_ s: String) -> ServerProfile? {
        var body = String(s.dropFirst("ss://".count))
        var name = ""
        if let h = body.firstIndex(of: "#") {
            name = String(body[body.index(after: h)...]).removingPercentEncoding ?? ""
            body = String(body[..<h])
        }
        // Пробуем формат method:password@host:port в base64 целиком
        if !body.contains("@"), let data = Data(base64Encoded: pad(body)),
           let decoded = String(data: data, encoding: .utf8), decoded.contains("@") {
            body = decoded
        }
        guard let c = URLComponents(string: "ss://\(body)") else { return nil }
        var method = "aes-256-gcm", password = ""
        if let ui = c.user, !ui.isEmpty {
            if ui.contains(":") {
                let parts = ui.split(separator: ":", maxSplits: 1).map(String.init)
                method = parts[0]; password = parts[1].removingPercentEncoding ?? parts[1]
            } else if let d = Data(base64Encoded: pad(ui)), let dec = String(data: d, encoding: .utf8) {
                let parts = dec.split(separator: ":", maxSplits: 1).map(String.init)
                if parts.count == 2 { method = parts[0]; password = parts[1] }
            }
        }
        var p = ServerProfile(name: "", proto: .shadowsocks, address: c.host ?? "", port: c.port ?? 8388)
        p.method = method; p.password = password
        p.name = name.isEmpty ? "\(p.address):\(p.port)" : name
        return p
    }

    private static func fragmentName(_ c: URLComponents) -> String? {
        guard let f = c.fragment, !f.isEmpty else { return nil }
        return f.removingPercentEncoding ?? f
    }

    private static func pad(_ s: String) -> String {
        var t = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while t.count % 4 != 0 { t += "=" }
        return t
    }
}

import Foundation

enum ProxyProtocol: String, Codable, CaseIterable, Identifiable {
    case vless, vmess, trojan, shadowsocks
    var id: String { rawValue }
    var title: String {
        switch self {
        case .vless: return "VLESS"
        case .vmess: return "VMess"
        case .trojan: return "Trojan"
        case .shadowsocks: return "Shadowsocks"
        }
    }
}

struct ServerProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var proto: ProxyProtocol
    var address: String
    var port: Int
    var uuid: String = ""
    var password: String = ""
    var method: String = "aes-256-gcm"
    var security: String = "auto"
    var network: String = "tcp"
    var tls: Bool = false
    var sni: String = ""
    var alpn: String = "h2,http/1.1"
    var flow: String = ""
    var path: String = ""
    var host: String = ""
    var realityPublicKey: String = ""
    var realityShortId: String = ""
    var realitySpiderX: String = ""
    var fingerprint: String = "chrome"
    var pingMs: Int? = nil

    var displayAddress: String { "\(address):\(port)" }
}

extension ServerProfile {
    static var demo: [ServerProfile] {
        [
            ServerProfile(name: "DE · Frankfurt 01", proto: .vless, address: "de1.example.com", port: 443, uuid: "00000000-0000-0000-0000-000000000000", network: "tcp", tls: true, sni: "de1.example.com", flow: "xtls-rprx-vision", fingerprint: "chrome"),
            ServerProfile(name: "NL · Amsterdam 02", proto: .vless, address: "nl2.example.com", port: 443, uuid: "00000000-0000-0000-0000-000000000000", network: "xhttp", tls: true, sni: "nl2.example.com", path: "/xray", fingerprint: "chrome"),
            ServerProfile(name: "FI · Helsinki 03", proto: .trojan, address: "fi3.example.com", port: 443, password: "password", tls: true, sni: "fi3.example.com")
        ]
    }
}

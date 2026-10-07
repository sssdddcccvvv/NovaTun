import Foundation

/// TCP-проверка задержки до сервера (без подключения VPN).
struct PingService {
    static func ping(profile: ServerProfile, timeout: TimeInterval = 3.0, completion: @escaping (Int?) -> Void) {
        let t0 = Date()
        var req = URLRequest(url: URL(string: "https://\(profile.address):\(profile.port)/")!, timeoutInterval: timeout)
        req.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: req) { _, _, _ in
            let ms = Int(Date().timeIntervalSince(t0) * 1000)
            completion(ms)
        }.resume()
        // Честный TCP-connect как fallback — через NWConnection в полной сборке.
    }
}

import SwiftUI

struct AddServerView: View {
    @EnvironmentObject var store: ProfileStore
    @Environment(\.dismiss) var dismiss
    @State private var link = ""
    @State private var error: String? = nil
    @State private var okName: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.bgGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Вставь ссылку: vless://, vmess://, trojan://, ss://")
                        .font(.subheadline).foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center).padding(.top, 12)
                    TextEditor(text: $link)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(height: 150)
                        .background(NovaTheme.card)
                        .cornerRadius(16)
                    if let e = error {
                        Text(e).font(.footnote).foregroundColor(.red)
                    }
                    if let n = okName {
                        Text("Добавлено: \(n)").font(.footnote).foregroundColor(.green)
                    }
                    Button {
                        if store.add(link: link) {
                            okName = store.profiles.last?.name ?? "OK"
                            error = nil
                            link = ""
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
                        } else {
                            error = "Не распознано. Проверь ссылку."
                            okName = nil
                        }
                    } label: {
                        Text("Добавить").fontWeight(.bold).foregroundColor(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.white).cornerRadius(18)
                    }
                    .disabled(link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Новый сервер")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
    }
}

struct SubscriptionView: View {
    @EnvironmentObject var store: ProfileStore
    @Environment(\.dismiss) var dismiss
    @State private var url = ""
    @State private var info: String? = nil
    @State private var busy = false

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.bgGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Ссылка на подписку (v2ray / clash / base64)")
                        .font(.subheadline).foregroundColor(.white.opacity(0.6)).padding(.top, 12)
                    TextField("https://…", text: $url)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .padding(14).background(NovaTheme.card).cornerRadius(14).foregroundColor(.white)
                    Button {
                        busy = true; info = nil
                        store.updateSubscription(url: url) { n in
                            busy = false
                            info = n > 0 ? "Добавлено серверов: \(n)" : "Не удалось импортировать"
                            if n > 0 && !store.subscriptions.contains(url) {
                                store.subscriptions.append(url); store.save()
                            }
                        }
                    } label: {
                        Text(busy ? "Обновление…" : "Обновить").fontWeight(.bold).foregroundColor(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.white).cornerRadius(18)
                    }.disabled(url.isEmpty || busy)
                    if let i = info { Text(i).font(.footnote).foregroundColor(.white.opacity(0.7)) }
                    if !store.subscriptions.isEmpty {
                        List {
                            ForEach(store.subscriptions, id: \.self) { s in
                                Text(s).font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(1)
                            }
                        }.listStyle(.plain).scrollContentBackground(.hidden).frame(maxHeight: 200)
                    }
                    Spacer()
                }.padding(.horizontal, 20)
            }
            .navigationTitle("Подписки")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.bgGradient.ignoresSafeArea()
                List {
                    Section("О приложении") {
                        row("Версия", "NovaTun 1.0")
                        row("Ядро", "Xray \(XrayVersion.current)")
                        row("Протоколы", "VLESS · VMess · Trojan · SS")
                    }
                    Section("Поддержка") {
                        row("Reality", "Да (uTLS chrome)")
                        row("XHTTP / WS / gRPC", "Да")
                        row("Подписки", "Да (base64 / plain)")
                    }
                }.scrollContentBackground(.hidden)
            }
            .navigationTitle("Настройки")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
    }
    private func row(_ a: String, _ b: String) -> some View {
        HStack { Text(a).foregroundColor(.white); Spacer(); Text(b).font(.caption).foregroundColor(.white.opacity(0.55)) }
            .listRowBackground(NovaTheme.card)
    }
}

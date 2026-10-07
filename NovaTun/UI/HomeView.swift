import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ProfileStore
    @State private var showAdd = false
    @State private var showSubs = false
    @State private var showSettings = false
    @State private var powerScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.bgGradient.ignoresSafeArea()
                GlowBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        HeaderRow(showSubs: $showSubs, showSettings: $showSettings)
                        PowerButton(connected: store.isConnected, scale: $powerScale) {
                            toggle()
                        }
                        StatusLine()
                        if let sel = store.selected {
                            GlassCard {
                                SelectedServerCard(profile: sel) {
                                    checkPing(sel)
                                }
                            }
                        }
                        NavigationLink(destination: ServerListView().environmentObject(store)) {
                            GlassCard {
                                HStack {
                                    Image(systemName: "server.rack").foregroundColor(NovaTheme.accent)
                                    Text("Серверы · \(store.profiles.count)")
                                        .foregroundColor(.white).fontWeight(.semibold)
                                    Spacer()
                                    Text("Все").font(.caption).foregroundColor(.white.opacity(0.5))
                                    Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.4))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        TrafficCard()
                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddServerView().environmentObject(store) }
            .sheet(isPresented: $showSubs) { SubscriptionView().environmentObject(store) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button { showAdd = true } label: {
                        Label("Добавить сервер", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
    }

    private func toggle() {
        if store.isConnected {
            TunnelManager.shared.disconnect()
        } else if let p = store.selected {
            TunnelManager.shared.connect(profile: p)
            powerScale = 1.12
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { powerScale = 1.0 }
        }
    }

    private func checkPing(_ p: ServerProfile) {
        PingService.ping(profile: p) { ms in
            DispatchQueue.main.async {
                store.updatePing(id: p.id, ms: ms ?? 9999)
            }
        }
    }
}

private struct GlowBackground: View {
    var body: some View {
        GeometryReader { _ in
            Circle().fill(Color.blue.opacity(0.25)).frame(width: 340, height: 340).offset(x: -110, y: -120).blur(radius: 60)
            Circle().fill(Color.cyan.opacity(0.16)).frame(width: 300, height: 300).offset(x: 180, y: 80).blur(radius: 60)
            Circle().fill(Color.indigo.opacity(0.20)).frame(width: 320, height: 320).offset(x: 40, y: 560).blur(radius: 70)
        }.ignoresSafeArea().allowsHitTesting(false)
    }
}

private struct HeaderRow: View {
    @Binding var showSubs: Bool
    @Binding var showSettings: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("NovaTun").font(.system(size: 26, weight: .800)).foregroundColor(.white)
                Text("Xray 26.9.9 · VLESS · Reality").font(.caption).foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Button { showSubs = true } label: {
                Image(systemName: "arrow.triangle.2.circlepath").font(.title3).foregroundColor(.white.opacity(0.8))
                    .frame(width: 42, height: 42).background(NovaTheme.card).cornerRadius(14)
            }
            Button { showSettings = true } label: {
                Image(systemName: "gearshape").font(.title3).foregroundColor(.white.opacity(0.8))
                    .frame(width: 42, height: 42).background(NovaTheme.card).cornerRadius(14)
            }
        }.padding(.top, 10)
    }
}

private struct PowerButton: View {
    let connected: Bool
    @Binding var scale: CGFloat
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(connected ? Color.green.opacity(0.18) : Color.white.opacity(0.08))
                    .frame(width: 208, height: 208)
                    .overlay(Circle().stroke(connected ? Color.green.opacity(0.6) : Color.white.opacity(0.18), lineWidth: 2))
                    .shadow(color: connected ? .green.opacity(0.4) : .blue.opacity(0.25), radius: 30)
                    .scaleEffect(scale)
                VStack(spacing: 6) {
                    Image(systemName: "power").font(.system(size: 52, weight: .bold))
                        .foregroundColor(connected ? .green : .white)
                    Text(connected ? "ВКЛ" : "ВЫКЛ").font(.headline).foregroundColor(connected ? .green : .white.opacity(0.7))
                }
            }
        }.buttonStyle(.plain).padding(.vertical, 6)
        .accessibilityLabel(connected ? "Отключиться" : "Подключиться")
    }
}

private struct StatusLine: View {
    @EnvironmentObject var store: ProfileStore
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(store.isConnected ? Color.green : Color.orange).frame(width: 9, height: 9)
            Text(store.statusText).font(.subheadline).foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(NovaTheme.card).cornerRadius(30)
    }
}

private struct SelectedServerCard: View {
    let profile: ServerProfile
    let onPing: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(NovaTheme.accent.opacity(0.2)).frame(width: 46, height: 46)
                Text(String(profile.proto.title.prefix(2))).fontWeight(.800).foregroundColor(NovaTheme.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name).font(.headline).foregroundColor(.white).lineLimit(1)
                Text("\(profile.proto.title) · \(profile.displayAddress)").font(.caption).foregroundColor(.white.opacity(0.55)).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(profile.pingMs.map { "\($0) ms" } ?? "—").font(.subheadline.weight(.semibold)).foregroundColor(pingColor(profile.pingMs))
                Button("Ping", action: onPing).font(.caption2).foregroundColor(NovaTheme.accent)
            }
        }
    }
}

private struct TrafficCard: View {
    var body: some View {
        GlassCard {
            HStack(spacing: 0) {
                TrafficCol(icon: "arrow.down", title: "Входящий", value: "—")
                Divider().background(Color.white.opacity(0.12)).padding(.horizontal, 14)
                TrafficCol(icon: "arrow.up", title: "Исходящий", value: "—")
                Divider().background(Color.white.opacity(0.12)).padding(.horizontal, 14)
                TrafficCol(icon: "timer", title: "Сессия", value: "00:00")
            }
        }
    }
}
private struct TrafficCol: View {
    let icon, title, value: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(.white.opacity(0.5)).font(.caption)
            Text(title).font(.caption2).foregroundColor(.white.opacity(0.5))
            Text(value).font(.subheadline.weight(.semibold)).foregroundColor(.white)
        }.frame(maxWidth: .infinity)
    }
}

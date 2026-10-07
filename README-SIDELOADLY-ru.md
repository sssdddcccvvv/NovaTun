# NovaTun — аналог Happ / V2RayTun (Xray 26.9.9) → установка через Sideloadly

## Что это
Нативный iOS VPN-клиент, SwiftUI + PacketTunnel, тёмный дизайн в духе Happ:
- главный экран с большой кнопкой питания, статусом и выбранным сервером;
- список серверов с пингом, выбор тапом;
- добавление по ссылке `vless:// vmess:// trojan:// ss://` (вставка из буфера);
- подписки (plain / base64) с кнопкой «Обновить»;
- генерация конфига Xray-core **26.9.9**: VLESS-Reality, XHTTP, WS, gRPC, Trojan, Shadowsocks, uTLS fingerprint.

## Почему готового .ipa нет прямо здесь
Этот сервер — **Linux**. `xcodebuild` существует только на macOS с Xcode
(проверено: `xcode_project` → `spawn xcodebuild ENOENT`, `swiftc` тоже нет).
Собрать подписанный `.ipa` на Linux технически невозможно — iOS-билды делает
только Xcode. Ниже — два рабочих пути, оба заканчиваются установкой через Sideloadly.

## Путь А — облачная сборка (без Mac, 10–15 минут, бесплатно)
1. Создай репозиторий на GitHub, залей туда папку `NovaTun/` целиком
   (включая `.github/workflows/ipa.yml`, `Scripts/build-ipa.sh`, `NovaTun.xcodeproj`).
2. Открой вкладку **Actions → Build IPA (Sideloadly) → Run workflow**.
   Воркфлоу на `macos-15` + Xcode 16:
   - клонирует Xray-core `v26.9.9`, собирает `XrayMobile.xcframework` через `gomobile bind`;
   - архивирует схему `NovaTun` без подписи (`CODE_SIGNING_ALLOWED=NO`);
   - пакует `NovaTun-sideloadly.ipa` и кладёт в Artifacts.
3. Скачай артефакт `NovaTun-sideloadly` → внутри `.ipa`.
4. Установи через **Sideloadly** (Windows/macOS): перетащи `.ipa`, введи Apple ID,
   дождись установки. Повторять раз в 7 дней (лимит бесплатного Apple ID).

## Путь Б — сборка на Mac (5 минут)
```bash
cd NovaTun
./Scripts/build-ipa.sh   # на выходе build/NovaTun-sideloadly.ipa
```
Дальше — тот же Sideloadly.

## Важно про bundle id и VPN-права
- В проекте Bundle ID: `com.example.NovaTun` + расширение `com.example.NovaTun.NovaTunPacketTunnel`.
  Перед установкой через Sideloadly поменяй на **свой уникальный** (например `com.tvoy-nik.novatun`),
  иначе Sideloadly может конфликтовать с чужими подписями. Места: 2 строчки
  `PRODUCT_BUNDLE_IDENTIFIER` в `NovaTun.xcodeproj/project.pbxproj`,
  `tunnelBundleID` в `NovaTun/Core/TunnelManager.swift`, App Group в
  `NovaTun/Resources/NovaTun.entitlements`.
- VPN-entitlement (`packet-tunnel-provider`) с бесплатным Apple ID работает —
  Sideloadly пропишет профиль, на iPhone подтвердишь VPN-конфигурацию.
- Deployment Target 17.0 — покрывает iPhone 11 / 12 / 13 Pro Max и iOS 27.

## Как пользоваться (когда установлено)
1. Открой NovaTun → «+» → вставь `vless://…` ссылку → Добавить.
   Или открой иконку обновления → вставь URL подписки → Обновить.
2. Выбери сервер в списке (пинг подскажет самый быстрый).
3. Жми большую кнопку питания → разреши VPN → статус «Подключено · Xray 26.9.9».

## Структура проекта
```
NovaTun/
  NovaTun/
    NovaTunApp.swift            точка входа
    XrayVersion.swift            версия ядра (26.9.9)
    Models/ServerProfile.swift   модель сервера
    Core/
      XrayConfigBuilder.swift    JSON-конфиг Xray 26.9.9 (reality/xhttp/vision)
      LinkParser.swift           vless/vmess/trojan/ss ссылки
      ProfileStore.swift         хранилище + подписки
      PingService.swift          проверка задержки
      TunnelManager.swift        вкл/выкл PacketTunnel
    UI/
      Theme.swift                тёмная тема, стеклянные карточки
      HomeView.swift             главный экран (кнопка питания)
      ServerListView.swift       список серверов + ping все
      AddServerView.swift        добавление + подписки + настройки
    Resources/
      NovaTun.entitlements       packet-tunnel + App Group
      Info-App.plist             метаданные приложения
  NovaTunPacketTunnel/
    PacketTunnelProvider.swift   TUN + запуск Xray-ядра
    Info-Tunnel.plist            NSExtension packet-tunnel
  Scripts/build-ipa.sh           сборка .ipa для Sideloadly (на Mac)
  .github/workflows/ipa.yml     облачная сборка .ipa (без Mac)
```

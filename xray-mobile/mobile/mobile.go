// Package mobile — gomobile-совместимая обёртка над Xray-core v26.9.9.
// Экспортируемые символы (StartXray/StartXrayFD/StopXray/Version) биндятся
// в XrayMobile.xcframework и вызываются из PacketTunnelProvider (Swift).
//
// Важно: main/distro/all НЕ импортирует proxy/tun, поэтому тун-инбаунд
// регистрируем явным импортом ниже — иначе protocol:"tun" не найдётся.
package mobile

import (
	"bytes"
	"os"
	"strconv"
	"sync"

	_ "golang.org/x/mobile/bind"

	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf/serial"
	_ "github.com/xtls/xray-core/main/distro/all"
	_ "github.com/xtls/xray-core/proxy/tun"
)

var (
	mu       sync.Mutex
	running  *core.Instance
)

// Version возвращает версию встроенного Xray-ядра.
func Version() string { return "26.9.9" }

// StartXray запускает ядро с JSON-конфигом. Возвращает "" при успехе или текст ошибки.
// Для iOS-туннеля используй StartXrayFD — он передаёт fd utun ядру.
func StartXray(jsonConfig string) string {
	mu.Lock()
	defer mu.Unlock()
	return startLocked(jsonConfig)
}

// StartXrayFD запускает ядро с TUN-инбаундом, привязанным к fd utun,
// полученному от NetworkExtension (см. Xray README, iOS-режим).
// fd < 0 — запуск без тун-устройства.
func StartXrayFD(jsonConfig string, fd int32) string {
	mu.Lock()
	defer mu.Unlock()
	if fd >= 0 {
		// Xray читает флаг через platform.NewEnvFlag("xray.tun.fd")
		// (плюс альтернативное имя XRAY_TUN_FD) в момент создания тун-инбаунда.
		v := strconv.Itoa(int(fd))
		os.Setenv("xray.tun.fd", v)
		os.Setenv("XRAY_TUN_FD", v)
	}
	return startLocked(jsonConfig)
}

// startLocked запускает ядро; mu должен быть взят вызывающим.
// Прежний инстанс останавливается, чтобы переподключение работало без ложной
// ошибки "already running".
func startLocked(jsonConfig string) string {
	if running != nil {
		running.Close()
		running = nil
	}
	cfg, err := serial.LoadJSONConfig(bytes.NewReader([]byte(jsonConfig)))
	if err != nil {
		return "config: " + err.Error()
	}
	inst, err := core.New(cfg)
	if err != nil {
		return "core: " + err.Error()
	}
	if err := inst.Start(); err != nil {
		return "start: " + err.Error()
	}
	running = inst
	return ""
}

// StopXray останавливает ядро. Возвращает "" при успехе или текст ошибки.
func StopXray() string {
	mu.Lock()
	defer mu.Unlock()
	if running == nil {
		return ""
	}
	err := running.Close()
	running = nil
	if err != nil {
		return "stop: " + err.Error()
	}
	return ""
}

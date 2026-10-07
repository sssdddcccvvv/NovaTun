// Package mobile — gomobile-совместимая обёртка над Xray-core v26.9.9.
// Экспортируемые символы (StartXray/StopXray/Version) биндятся в XrayMobile.xcframework.
package mobile

import (
	"bytes"

	_ "golang.org/x/mobile/bind"
	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf/serial"
	_ "github.com/xtls/xray-core/main/distro/all"
)

var runningInstance *core.Instance

// Version возвращает версию встроенного Xray-ядра.
func Version() string { return "26.9.9" }

// StartXray запускает ядро с JSON-конфигом. Возвращает "" при успехе или текст ошибки.
func StartXray(jsonConfig string) string {
	if runningInstance != nil {
		return "already running"
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
	runningInstance = inst
	return ""
}

// StopXray останавливает ядро.
func StopXray() string {
	if runningInstance == nil {
		return ""
	}
	if err := runningInstance.Close(); err != nil {
		runningInstance = nil
		return "stop: " + err.Error()
	}
	runningInstance = nil
	return ""
}

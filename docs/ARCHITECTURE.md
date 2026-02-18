# Архитектура NetWarden

## Слои

1. UI (SwiftUI/AppKit)
- `main.swift`: menu bar приложение, popover, dashboard окно.
- `PopoverView.swift`: быстрый статус.
- `DashboardView.swift`: полный контроль и логи.

2. Состояние приложения
- `AppModel.swift`:
  - управляет игровым режимом,
  - хранит правила,
  - агрегирует мониторинг/рекомендации,
  - отдает лог-превью и фильтрацию.

3. Системные сервисы
- `NetworkMonitorService.swift`: снимки сети через `nettop`.
- `ProcessControlService.swift`: watchdog-цикл и применение правил.
- `SystemThrottleManager.swift`: отключение/восстановление auto-update ключей через `defaults`.
- `Shell.swift`: выполнение команд shell.

4. Данные
- `RulesStore.swift`: JSON-хранилище правил.
- `ProcessCatalog.swift`: описания процессов + защищенный список.
- `Models.swift`: модели и enum'ы.

5. Логи
- `AppLogger.swift`: unified logging (файл + OSLog), уровни `DEBUG/INFO/WARN/ERROR`, ротация.

## Потоки

- Мониторинг сети: каждые 2с.
- Watchdog: каждые 1с.
- Обновление лог-превью в UI: каждые 2с.

## Ключевые инварианты

- Процессы Riot/League/Vanguard не должны попадать под destructive действия.
- При выключении игрового режима выполняется попытка восстановления user-level настроек обновлений.
- Любое изменение правил должно сохраняться на диск.

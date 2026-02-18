# NetWarden

NetWarden — menu bar приложение для macOS, которое помогает держать стабильный пинг в игре за счет контроля фоновых сетевых процессов.

## Основные возможности

- Иконка в строке меню (без иконки в Dock).
- Быстрый popover (ЛКМ) и полноразмерный Dashboard (ПКМ/кнопка).
- Мониторинг потребления сети по процессам в реальном времени (`nettop`).
- Игровой режим с постоянным watchdog-контролем:
  - `Пауза` (`SIGSTOP`) или `Завершить` (`SIGTERM`) для выбранных процессов;
  - если процесс перезапускается, watchdog снова применяет правило.
- Пользовательские правила (добавить/удалить/включить/выключить/сменить действие).
- Жесткая защита Riot/League/Vanguard процессов (`ЗАЩИЩЕНО`).
- Техническое логирование (файл + system log), ротация логов.
- Автозапуск при логине (LaunchAgent) и тихий старт в menu bar.

## Быстрый старт

```bash
cd /Users/antonesse/Developer/macOS/NetWarden
swift build -c release
```

Запуск из исходников:

```bash
swift run NetWarden
```

Установленный `.app`:

- `/Users/antonesse/Applications/NetWarden.app`
- Ярлык на рабочем столе: `/Users/antonesse/Desktop/NetWarden.app`

## Логи

- Основной файл: `~/Library/Logs/NetWarden/netwarden.log`
- Архивы ротации: `netwarden.log.1`, `netwarden.log.2`, `netwarden.log.3`
- LaunchAgent stdout/stderr:
  - `/tmp/netwarden.launchd.out.log`
  - `/tmp/netwarden.launchd.err.log`

Команды:

```bash
tail -f ~/Library/Logs/NetWarden/netwarden.log
```

```bash
log stream --predicate 'subsystem == "com.antonesse.netwarden"'
```

## Документация

- Архитектура: `docs/ARCHITECTURE.md`
- Эксплуатация и отладка: `docs/OPERATIONS.md`
- Безопасность и защищенные процессы: `docs/SAFETY.md`

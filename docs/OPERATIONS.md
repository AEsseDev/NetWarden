# Эксплуатация и отладка

## Полезные пути

- Исходники: `/Users/antonesse/Developer/macOS/NetWarden`
- Приложение: `/Users/antonesse/Applications/NetWarden.app`
- LaunchAgent: `/Users/antonesse/Library/LaunchAgents/com.antonesse.netwarden.plist`

## Пересборка и обновление `.app`

```bash
cd /Users/antonesse/Developer/macOS/NetWarden
swift build -c release
cp .build/release/NetWarden /Users/antonesse/Applications/NetWarden.app/Contents/MacOS/NetWarden
chmod +x /Users/antonesse/Applications/NetWarden.app/Contents/MacOS/NetWarden
```

## Рестарт приложения

```bash
pkill -x NetWarden || true
open -gj /Users/antonesse/Applications/NetWarden.app
```

## Управление автозапуском

Включить:

```bash
uid=$(id -u)
launchctl bootstrap gui/$uid /Users/antonesse/Library/LaunchAgents/com.antonesse.netwarden.plist
launchctl enable gui/$uid/com.antonesse.netwarden
launchctl kickstart -k gui/$uid/com.antonesse.netwarden
```

Выключить:

```bash
uid=$(id -u)
launchctl disable gui/$uid/com.antonesse.netwarden
launchctl bootout gui/$uid/com.antonesse.netwarden
```

## Диагностика

Проверить, запущено ли приложение:

```bash
pgrep -lf '/Users/antonesse/Applications/NetWarden.app/Contents/MacOS/NetWarden'
```

Проверить launchd-сервис:

```bash
uid=$(id -u)
launchctl print gui/$uid/com.antonesse.netwarden
```

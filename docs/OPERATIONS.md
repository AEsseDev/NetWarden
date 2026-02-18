# Эксплуатация и отладка

## Полезные пути

- Исходники: `/path/to/NetWarden`
- Приложение: `~/Applications/NetWarden.app`
- LaunchAgent: `~/Library/LaunchAgents/com.antonesse.netwarden.plist`

## Пересборка и обновление `.app`

```bash
cd /path/to/NetWarden
swift build -c release
cp .build/release/NetWarden ~/Applications/NetWarden.app/Contents/MacOS/NetWarden
chmod +x ~/Applications/NetWarden.app/Contents/MacOS/NetWarden
```

## Рестарт приложения

```bash
pkill -x NetWarden || true
open -gj ~/Applications/NetWarden.app
```

## Управление автозапуском

Включить:

```bash
uid=$(id -u)
launchctl bootstrap gui/$uid ~/Library/LaunchAgents/com.antonesse.netwarden.plist
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
pgrep -lf "$HOME/Applications/NetWarden.app/Contents/MacOS/NetWarden"
```

Проверить launchd-сервис:

```bash
uid=$(id -u)
launchctl print gui/$uid/com.antonesse.netwarden
```

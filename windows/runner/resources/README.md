# Вендоренные бинарники (Windows)

| Файл | Источник | Версия |
|---|---|---|
| sing-box.exe | github.com/SagerNet/sing-box, `sing-box-<ver>-windows-amd64.zip` | <ver> |
| sing-box-test.exe | копия sing-box.exe | тот же |
| xray.exe | github.com/XTLS/Xray-core, `Xray-windows-64.zip` | <ver> |
| wintun.dll | wintun.net, `bin/amd64/wintun.dll` | <ver> |

`sing-box-test.exe` обязан быть отдельным файлом, а не симлинком: правило
`find_process` в конфиге различает боевой и тестовый процесс только по имени
исполняемого файла, а симлинки на Windows требуют прав администратора.

Обновление: заменить файлы, поднять версии в таблице, пересобрать.

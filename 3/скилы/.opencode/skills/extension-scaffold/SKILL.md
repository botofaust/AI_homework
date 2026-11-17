---
name: extension-scaffold
description: Использовать, когда нужно создать каркас нового расширения 1С в src/cfe (новое расширение, пустое расширение, Configuration.xml, ConfigDumpInfo.xml, подсистема, префикс). Скилл создаёт XML-выгрузку расширения для конфигурации БиблиотекаСтандартныхПодсистемДемо и не меняет src/cf.
---

# Каркас расширения 1С

Создать пустое расширение в `src/cfe/<Имя>` с корректными метаданными формата XML `2.20`, чтобы дальше добавлять в него объекты. Источник истины — XML-выгрузка; эталоном после первой загрузки становится результат `dump-extension.ps1`.

## Когда использовать

- Нужно новое расширение с нуля: каталог `src/cfe/<Имя>`, `Configuration.xml`, язык, пустая подсистема.
- Нужен предсказуемый старт перед добавлением справочников, документов, регистров, обработок и форм.

Не использовать для добавления объектов в уже существующее расширение и для изменений основной конфигурации `src/cf`.

## Перед началом

1. Уточните у пользователя `<Имя>` расширения (оно же имя каталога) и `<Префикс>`.
   - Имя — допустимый идентификатор 1С без пробелов, например `УстановкаЦен`.
   - Префикс оканчивается на `_`, например `УстЦен_`; им будут именоваться собственные объекты расширения.
   - Если отдельного префикса нет, используйте `<Имя>_`.
   - Подсистема называется `<Префикс><Имя>`, например `УстЦен_УстановкаЦен`.
2. Проверьте, что каталога `src/cfe/<Имя>` ещё нет. Не перезаписывайте существующее расширение.
3. Прочитайте UUID языка основной конфигурации — он нужен для заимствования языка:

   ```powershell
   ([xml](Get-Content 'src/cf/Languages/Русский.xml' -Raw -Encoding UTF8)).MetaDataObject.Language.uuid
   ```

   Это значение идёт в `ExtendedConfigurationObject`. Не берите его из чужого расширения.
4. Не изменяйте `src/cf`. Не копируйте UUID из `src/cfe/УстановкаЦен` или `src/cfe/АдресноеХранение`.

## Файлы каркаса

| Файл | Шаблон | Назначение |
|---|---|---|
| `src/cfe/<Имя>/Configuration.xml` | `references/Configuration.template.xml` | Корень расширения, `AddOn`, префикс, режим совместимости |
| `src/cfe/<Имя>/ConfigDumpInfo.xml` | `references/ConfigDumpInfo.template.xml` | Служебные версии объектов для загрузки из файлов |
| `src/cfe/<Имя>/Languages/Русский.xml` | `references/Language.template.xml` | Заимствованный язык `Русский` |
| `src/cfe/<Имя>/Subsystems/<Префикс><Имя>.xml` | `references/Subsystem.template.xml` | Пустая подсистема расширения |

Плейсхолдеры: `{{NAME}}`, `{{SYNONYM}}`, `{{PREFIX}}`, `{{CONFIG_UUID}}`, `{{LANGUAGE_UUID}}`, `{{LANGUAGE_OBJECT_UUID}}`, `{{SUBSYSTEM_UUID}}`, `{{CONTAINED_OBJECT_ID_1}}`…`{{CONTAINED_OBJECT_ID_7}}`, `{{CONFIG_VERSION}}`, `{{LANGUAGE_VERSION}}`, `{{SUBSYSTEM_VERSION}}`.

## Создание файлов

Выполните из корня репозитория, подставив имя, префикс и синоним. Скрипт создаёт каталоги, генерирует свежие UUID и версии, читает UUID языка из основной конфигурации и разворачивает шаблоны без BOM.

```powershell
$name    = 'МоеРасширение'      # каталог src/cfe/<Имя>
$prefix  = 'МоеРасш_'           # префикс, оканчивается на _
$synonym = 'Мое расширение'     # синоним расширения и подсистемы

$root = Join-Path (Get-Location) "src/cfe/$name"
if (Test-Path -LiteralPath $root) { throw "Каталог уже существует: $root" }

$languageObjectUuid = ([xml](Get-Content 'src/cf/Languages/Русский.xml' -Raw -Encoding UTF8)).MetaDataObject.Language.uuid
$configUuid    = [guid]::NewGuid()
$languageUuid  = [guid]::NewGuid()
$subsystemUuid = [guid]::NewGuid()
$containedIds  = 1..7 | ForEach-Object { [guid]::NewGuid() }
$versions      = 1..3 | ForEach-Object { ([guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')).Substring(0, 40) }

$values = @{
    NAME                 = $name
    SYNONYM              = $synonym
    PREFIX               = $prefix
    CONFIG_UUID          = $configUuid
    LANGUAGE_UUID        = $languageUuid
    LANGUAGE_OBJECT_UUID = $languageObjectUuid
    SUBSYSTEM_UUID       = $subsystemUuid
    CONFIG_VERSION       = $versions[0]
    LANGUAGE_VERSION     = $versions[1]
    SUBSYSTEM_VERSION    = $versions[2]
}
for ($i = 1; $i -le 7; $i++) { $values["CONTAINED_OBJECT_ID_$i"] = $containedIds[$i - 1] }

$skillDir = '.opencode/skills/extension-scaffold'
function New-ScaffoldFile {
    param([string] $Template, [string] $Target)
    $text = Get-Content -LiteralPath (Join-Path $skillDir $Template) -Raw -Encoding UTF8
    foreach ($key in $values.Keys) { $text = $text.Replace("{{$key}}", [string]$values[$key]) }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
    [System.IO.File]::WriteAllText($Target, $text, (New-Object System.Text.UTF8Encoding($false)))
}

New-ScaffoldFile 'references/Configuration.template.xml'  "$root/Configuration.xml"
New-ScaffoldFile 'references/ConfigDumpInfo.template.xml' "$root/ConfigDumpInfo.xml"
New-ScaffoldFile 'references/Language.template.xml'       "$root/Languages/Русский.xml"
New-ScaffoldFile 'references/Subsystem.template.xml'      "$root/Subsystems/$prefix$name.xml"

Write-Host "Каркас создан: $root"
```

Если плейсхолдеры заменяются вручную, всё равно генерируйте UUID через `[guid]::NewGuid()`: конфигурация, язык, подсистема и семь `xr:ObjectId` должны быть разными.

## Самопроверка до запуска 1С

```powershell
Get-ChildItem "src/cfe/$name" -Recurse -File | ForEach-Object {
    [xml](Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) | Out-Null
}

(Select-String -Path "src/cfe/$name/Configuration.xml" -Pattern '<xr:ContainedObject>' -AllMatches).Matches.Count  # 7

$ours = Get-ChildItem "src/cfe/$name" -Recurse -Filter *.xml |
    Select-String -Pattern 'uuid="([0-9a-f-]{36})"|<xr:ObjectId>([0-9a-f-]{36})</xr:ObjectId>' -AllMatches |
    ForEach-Object { $_.Matches | ForEach-Object { if ($_.Groups[1].Value) { $_.Groups[1].Value } else { $_.Groups[2].Value } } } |
    Sort-Object -Unique
$theirs = Get-ChildItem 'src/cfe/УстановкаЦен' -Recurse -Filter *.xml |
    Select-String -Pattern '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' -AllMatches |
    ForEach-Object { $_.Matches.Value } | Sort-Object -Unique
Compare-Object $ours $theirs -IncludeEqual -ExcludeDifferent
```

Ожидается: XML разбирается, `ContainedObject` ровно 7, последняя команда ничего не выводит (пересечений с `УстановкаЦен` нет). Фиксированные `ClassId` и значение `ExtendedConfigurationObject` в это сравнение не входят намеренно.

## Загрузка и проверка

```powershell
./tools/load-extension.ps1 -ExtensionName <Имя> -Create
./tools/check-extension.ps1 -ExtensionName <Имя>
./tools/dump-extension.ps1 -ExtensionName <Имя>
./tools/check-config.ps1
```

- `-Create` нужен только при первом появлении расширения в `var/ib`. Команда загружает все расширения из родительского каталога `src/cfe`, поэтому сломанное соседнее расширение сорвёт и эту загрузку.
- `check-extension.ps1` проверяет синтаксис и применимость расширения.
- `dump-extension.ps1` нормализует XML; после него результат выгрузки — эталон, а не исходные шаблоны.
- `check-config.ps1` подтверждает, что основная конфигурация не сломана.
- Если ИБ занята открытым клиентом 1С, закройте сеансы и повторите.
- Если проверки запускать нельзя, явно сообщите, какие команды пропущены и почему.

## Что сообщить в конце

- Путь `src/cfe/<Имя>` и список созданных файлов.
- Имя расширения, префикс и имя подсистемы.
- Какие проверки выполнены, а какие пропущены.
- Что дальше: применить расширение к БД можно только после резервной копии и с разрешения пользователя:

  ```powershell
  ./tools/backup-infobase.ps1
  ./tools/update-extension-db.ps1 -ExtensionName <Имя>
  ```

- Собрать файл поставки: `./tools/pack-extension.ps1 -ExtensionName <Имя>`.

## Подводные камни

Обязательно прочитайте `references/pitfalls.md` перед созданием файлов: там перечислены ошибки с UUID, `ContainedObject`, `Adopted`, режимом совместимости, языком, `ChildObjects`, ключом `-Create` и кодировкой.

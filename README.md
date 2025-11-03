
# ProjectView

**ProjectView** erstellt Projekt-Snapshots für AI/LLM-Integration. Perfekt für C#-Entwickler, um Code-Projekte schnell mit ChatGPT, Claude oder Copilot zu teilen.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- 📁 Vollständige Verzeichnisstruktur
- 📄 Alle Dateiinhalte mit relativen Pfaden
- 🔍 Automatische Binärdatei-Erkennung
- ⚙️ Konfigurierbare Ausschlüsse (.git, node_modules, bin, obj)
- 📊 Visueller Fortschrittsbalken
- ✅ UTF-8 Encoding für AI-Kompatibilität
- 🛡️ Robustes Error Handling

## Installation

Execution Policy setzen
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Modul-Verzeichnis erstellen
$modulePath = "$HOME\Documents\WindowsPowerShell\Modules\ProjectView"
New-Item -ItemType Directory -Path $modulePath -Force

Modul herunterladen
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/ProjectView/main/ProjectView.psm1" -OutFile "$modulePath\ProjectView.psm1"

Zum Profil hinzufuegen
if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
Add-Content -Path $PROFILE -Value "`nImport-Module ProjectView"

Profil neu laden
. $PROFILE



## Verwendung

Einfach
cd C:\Projekte\MeinApp
projectview create

Mit Optionen
projectview create -OutputFileName "mein_projekt.txt" -MaxFileSize 2MB

Erweitert
projectview create -ExcludeDirs @('.git', 'temp') -ExcludeFiles @('.log', '.tmp')

Hilfe anzeigen
projectview help



## Parameter

| Parameter | Standard | Beschreibung |
|-----------|----------|--------------|
| `OutputFileName` | `project_snapshot.txt` | Name der Ausgabedatei |
| `ExcludeDirs` | `.git`, `.vs`, `node_modules`, `bin`, `obj` | Ausgeschlossene Verzeichnisse |
| `ExcludeFiles` | `*.exe`, `*.dll`, `*.jpg`, `*.png`, `*.pdf` | Ausgeschlossene Dateimuster |
| `MaxFileSize` | `1MB` | Maximale Dateigroesse |

## Ausgabeformat

================================================================================
PROJECT SNAPSHOT
Generated: 2025-11-03 08:54:00
Root Path: C:\Projekte\MeinApp
DIRECTORY STRUCTURE
+-- [DIR] src
| +-- [FILE] Program.cs
+-- [FILE] README.md

================================================================================
FILE CONTENTS
================================================================================
File: src/Program.cs
using System;
// Dateiinhalt...



## Use Cases

### Fuer C#-Entwickler
cd C:\Projects\MicrowaveController
projectview create -OutputFileName "microwave_for_ai.txt"



Ideal fuer:
- Code-Reviews mit AI
- Architektur-Diskussionen
- Debugging-Hilfe
- Dokumentations-Generierung
- Test-Erstellung

### Fuer andere Sprachen
Python
cd C:\Projects\my-python-app
projectview create

JavaScript/React
cd C:\Projects\my-react-app
projectview create -ExcludeDirs @('.git', 'node_modules')


## Troubleshooting

**"projectview: command not found"**
Import-Module ProjectView -Force
. $PROFILE


**"Execution Policy" Fehler**
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force


**Ausgabedatei zu gross**
projectview create -MaxFileSize 512KB -ExcludeFiles @('.exe', '.dll', '*.json')


## Tipps

### Fuer grosse Projekte
- Nutzen Sie spezifische Ausschluesse
- Reduzieren Sie das Dateigroessen-Limit
- Verarbeiten Sie Unterverzeichnisse separat

### AI Token-Limits
- **GPT-4 Turbo:** ~128K tokens (~400 Seiten)
- **Claude 3:** ~200K tokens (~500 Seiten)
- **GPT-3.5:** ~16K tokens (~40 Seiten)

## Version

**v1.0.0** (2025-11-02)
- Initial Release



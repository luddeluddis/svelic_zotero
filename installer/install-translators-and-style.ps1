#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$DataDirectory = (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Zotero'),
    [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
    [string]$Repository = 'luddeluddis/svelic_zotero',
    [string]$Ref = 'main',
    [ValidateSet('Ask', 'Yes', 'No')]
    [string]$DisableDefaultUpToDate = 'Ask'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-TranslatorMetadata([string]$Path) {
    $text = [IO.File]::ReadAllText($Path)
    $match = [regex]::Match($text, '(?s)^\s*(\{.*?\r?\n\})')
    if (-not $match.Success) { throw "Missing translator metadata: $Path" }
    $metadata = $match.Groups[1].Value | ConvertFrom-Json
    if (-not $metadata.translatorID -or -not $metadata.label) { throw "Invalid translator: $Path" }
    return $metadata
}

function Install-ZoteroFiles {
    # Never modify files while Zotero is using them.
    if (Get-Process -Name zotero -ErrorAction SilentlyContinue) {
        throw 'Close Zotero, then run this installer again.'
    }
    while (-not (Test-Path -LiteralPath (Join-Path $DataDirectory 'zotero.sqlite') -PathType Leaf)) {
        Write-Host "No Zotero library found at: $DataDirectory"
        $answer = Read-Host 'Enter the data directory shown in Zotero Settings > Advanced > Files and Folders (blank to cancel)'
        if ([string]::IsNullOrWhiteSpace($answer)) { throw 'Installation cancelled.' }
        $DataDirectory = $answer.Trim().Trim('"')
    }
    $DataDirectory = (Resolve-Path -LiteralPath $DataDirectory).Path
    Write-Host "Zotero data directory: $DataDirectory"

    if ($DisableDefaultUpToDate -eq 'Ask') {
        $answer = Read-Host 'Disable Zotero bundled UpToDate References translator? Your UpToDate_article.js stays enabled. [Y/n]'
        if ($answer.Trim() -match '^(?i:n|no)$') { $DisableDefaultUpToDate = 'No' }
        elseif ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -match '^(?i:y|yes)$') { $DisableDefaultUpToDate = 'Yes' }
        else { throw 'Unrecognised answer. Run again and enter Y or N.' }
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $headers = @{ 'User-Agent' = 'SVELIC-Zotero-Installer'; 'Accept' = 'application/vnd.github+json' }
    # Pin this run to one commit so the downloads cannot mix repository versions.
    $encodedRef = [Uri]::EscapeDataString($Ref)
    $commit = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/commits/$encodedRef" -Headers $headers -TimeoutSec 60
    if ($commit.sha -notmatch '^[0-9a-f]{40}$') { throw 'GitHub returned an invalid commit.' }
    $base = "https://raw.githubusercontent.com/$Repository/$($commit.sha)"
    $files = @(
        'translators/FASS.js',
        'translators/Janusmed.js',
        'translators/Lexicomp.js',
        'translators/MedicinesComplete.js',
        'translators/SVELIC.js',
        'translators/UpToDate_article.js',
        'styles/nlm-citation-sequence-unnumbered-bibliography.csl'
    )
    $stage = Join-Path ([IO.Path]::GetTempPath()) ('svelic-zotero-' + [guid]::NewGuid().ToString('N'))
    $backup = Join-Path $DataDirectory ('svelic-installer-backups/' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $stage | Out-Null
    try {
        # Download and validate everything before changing the installed files.
        foreach ($file in $files) {
            $download = Join-Path $stage $file
            New-Item -ItemType Directory -Path (Split-Path $download) -Force | Out-Null
            Invoke-WebRequest -UseBasicParsing -Uri "$base/$file" -OutFile $download -TimeoutSec 60 -Headers $headers
            if ($file.EndsWith('.js')) { $null = Get-TranslatorMetadata $download }
            else {
                $xml = New-Object System.Xml.XmlDocument
                $xml.XmlResolver = $null
                $xml.Load($download)
                if ($xml.DocumentElement.LocalName -ne 'style' -or $xml.DocumentElement.NamespaceURI -ne 'http://purl.org/net/xbiblio/csl') {
                    throw "Invalid CSL style: $file"
                }
            }
        }
        # Match the bundled translator by ID, not its name. Never disable the custom ID.
        $bundledID = '70dc2609-d6fd-415a-822c-a2c04293cb5a'
        $customID = '4af8c4da-cf3d-4ec2-989f-15d4d0723bf1'
        $custom = Get-TranslatorMetadata (Join-Path $stage 'translators/UpToDate_article.js')
        if ($custom.translatorID -ne $customID) { throw 'Unexpected ID for the custom UpToDate translator.' }
        $bundled = @()
        $translatorDirectory = Join-Path $DataDirectory 'translators'
        if ($DisableDefaultUpToDate -eq 'Yes' -and (Test-Path -LiteralPath $translatorDirectory)) {
            foreach ($candidate in Get-ChildItem -LiteralPath $translatorDirectory -Filter '*.js' -File) {
                try { $metadata = Get-TranslatorMetadata $candidate.FullName }
                catch { Write-Warning "Cannot inspect $($candidate.Name); not considered for disabling."; continue }
                if ($metadata.translatorID -eq $bundledID) { $bundled += $candidate.FullName }
            }
        }
        if (Get-Process -Name zotero -ErrorAction SilentlyContinue) { throw 'Zotero was opened during download. Close it and rerun.' }
        foreach ($file in $files) {
            $download = Join-Path $stage $file
            $destination = Join-Path $DataDirectory $file
            if ((Test-Path -LiteralPath $destination -PathType Leaf) -and
                (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash) {
                Write-Host "Unchanged: $file"
                continue
            }
            New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
            if (Test-Path -LiteralPath $destination) {
                $saved = Join-Path $backup $file
                New-Item -ItemType Directory -Path (Split-Path $saved) -Force | Out-Null
            }
            # Copy to the same directory before an atomic rename/replacement.
            $pending = "$destination.$([guid]::NewGuid().ToString('N')).tmp"
            try {
                Copy-Item -LiteralPath $download -Destination $pending
                if (Test-Path -LiteralPath $destination) { [IO.File]::Replace($pending, $destination, $saved) }
                else { [IO.File]::Move($pending, $destination) }
            }
            finally { if (Test-Path -LiteralPath $pending) { Remove-Item -LiteralPath $pending } }
            Write-Host "Installed: $file"
        }
        foreach ($path in $bundled) {
            $disabled = "$path.disabled"
            # Keep earlier backups when Zotero has restored its bundled translator.
            if (Test-Path -LiteralPath $disabled) { $disabled += '.' + [guid]::NewGuid().ToString('N') }
            Move-Item -LiteralPath $path -Destination $disabled
            Write-Host "Disabled bundled translator: $(Split-Path $path -Leaf) -> $(Split-Path $disabled -Leaf)"
        }
        if ($DisableDefaultUpToDate -eq 'Yes' -and $bundled.Count -eq 0) {
            Write-Host 'Bundled UpToDate References translator is absent or already disabled.'
        }
        if (Test-Path -LiteralPath $backup) { Write-Host "Previous files backed up to: $backup" }
        Write-Host "Finished. Source commit: $($commit.sha)"
        Write-Host 'Open Zotero, restart your browser, and reload the article page.'
        Write-Host 'Select NLM/Vancouver (unnumbered bibliography) in Zotero or the Word document preferences.'
    }
    finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force } }
}

# Dot-sourcing exposes the functions for isolated tests without running the installer.
if ($MyInvocation.InvocationName -ne '.') {
    try { Install-ZoteroFiles }
    catch { Write-Error $_; exit 1 }
}

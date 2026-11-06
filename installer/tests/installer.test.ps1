# Run with: pwsh -NoProfile -File installer/tests/installer.test.ps1
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../install-translators-and-style.ps1"
$sourceRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('svelic-test-' + [guid]::NewGuid().ToString('N'))
$DataDirectory = Join-Path $testRoot 'Library with spaces'
$script:running = $false
$script:failDownload = $false
$script:invalidStyle = $false
$script:answer = ''
function Get-Process { param($Name, $ErrorAction) if ($script:running) { return $true } }
$script:closeOnPrompt = $false
$script:promptCount = 0
function Read-Host {
    param($Prompt)
    $script:promptCount++
    if ($script:closeOnPrompt) { $script:running = $false }
    return $script:answer
}
function Invoke-RestMethod { param($Uri, $Headers, $TimeoutSec) return @{ sha = ('a' * 40) } }
function Invoke-WebRequest {
    param([switch]$UseBasicParsing, $Uri, $OutFile, $TimeoutSec, $Headers)
    if ($script:failDownload) { throw 'Simulated network failure' }
    $relative = ($Uri -split '/[a-f0-9]{40}/', 2)[1]
    Copy-Item -LiteralPath (Join-Path $sourceRoot $relative) -Destination $OutFile
    if ($script:invalidStyle -and $relative.EndsWith('.csl')) { [IO.File]::WriteAllText($OutFile, '<html>Not a CSL file</html>') }
}
function Assert($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Write-Bundled([string]$Name) {
    $path = Join-Path $DataDirectory "translators/$Name"
    # Bundled translators must be preserved regardless of filename.
    [IO.File]::WriteAllText($path, "{`n`"translatorID`":`"70dc2609-d6fd-415a-822c-a2c04293cb5a`",`n`"label`":`"UpToDate References`",`n`"priority`":100`n}")
    return $path
}
try {
    New-Item -ItemType Directory -Path (Join-Path $DataDirectory 'translators') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $DataDirectory 'zotero.sqlite') | Out-Null
    $bundled = Write-Bundled 'UpToDate References.js'
    Install-ZoteroFiles
    Assert (Test-Path -LiteralPath $bundled) 'Bundled translator was removed'
    Assert (-not (Test-Path -LiteralPath "$bundled.disabled")) 'Bundled translator was renamed'
    $custom = Join-Path $DataDirectory 'translators/UpToDate_article.js'
    Assert ((Get-TranslatorMetadata $custom).translatorID -eq '4af8c4da-cf3d-4ec2-989f-15d4d0723bf1') 'Custom translator missing or disabled'
    Assert ((Get-TranslatorMetadata $custom).priority -eq 50) 'Custom translator priority was not installed'
    Assert ((Get-TranslatorMetadata $custom).priority -lt (Get-TranslatorMetadata $bundled).priority) 'Custom translator does not take precedence'
    Assert ($script:promptCount -eq 0) 'Installer unexpectedly prompted to disable a translator'
    $style = Join-Path $DataDirectory 'styles/nlm-citation-sequence-unnumbered-bibliography.csl'
    Assert (Test-Path -LiteralPath $style) 'Style was not installed'
    $firstStyleTime = (Get-Item -LiteralPath $style).LastWriteTimeUtc
    $firstTime = (Get-Item -LiteralPath $custom).LastWriteTimeUtc
    Install-ZoteroFiles
    Assert ((Get-Item -LiteralPath $custom).LastWriteTimeUtc -eq $firstTime) 'Unchanged file was rewritten'
    Assert ((Get-Item -LiteralPath $style).LastWriteTimeUtc -eq $firstStyleTime) 'Unchanged style was rewritten'
    Assert (-not (Test-Path -LiteralPath (Join-Path $DataDirectory 'svelic-installer-backups'))) 'Unchanged files were backed up'

    # Modified files must be replaced and the previous contents backed up.
    [IO.File]::WriteAllText($custom, 'old custom translator')
    Install-ZoteroFiles
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $DataDirectory 'svelic-installer-backups') -Recurse -File)
    Assert ($backups.Count -eq 1) 'Expected one backup'
    Assert ([IO.File]::ReadAllText($backups[0].FullName) -eq 'old custom translator') 'Backup content changed'
    Assert ((Get-TranslatorMetadata $custom).label -eq 'UpToDate article') 'Custom update failed'

    $renamed = Write-Bundled 'Renamed bundled.js'
    $legacyDisabled = "$bundled.disabled"
    Copy-Item -LiteralPath $bundled -Destination $legacyDisabled
    $bundledBefore = (Get-FileHash -LiteralPath $bundled).Hash
    $renamedBefore = (Get-FileHash -LiteralPath $renamed).Hash
    $disabledBefore = (Get-FileHash -LiteralPath $legacyDisabled).Hash
    Install-ZoteroFiles
    Assert ((Get-FileHash -LiteralPath $bundled).Hash -eq $bundledBefore) 'Bundled translator was changed'
    Assert ((Get-FileHash -LiteralPath $renamed).Hash -eq $renamedBefore) 'Renamed bundled translator was changed'
    Assert ((Get-FileHash -LiteralPath $legacyDisabled).Hash -eq $disabledBefore) 'Previous disabled backup was changed'

    # A bad final download must prevent changes to every earlier file.
    [IO.File]::WriteAllText($style, 'old local style')
    $script:invalidStyle = $true
    $failed = $false
    try { Install-ZoteroFiles } catch { $failed = $true }
    Assert $failed 'Invalid CSL was accepted'
    Assert ([IO.File]::ReadAllText($style) -eq 'old local style') 'Validation failure changed installed style'
    $script:invalidStyle = $false
    Install-ZoteroFiles
    Assert ([IO.File]::ReadAllText($style) -ne 'old local style') 'Style was not updated'
    $savedStyles = @(Get-ChildItem -LiteralPath (Join-Path $DataDirectory 'svelic-installer-backups') -Filter '*.csl' -Recurse -File)
    Assert ($savedStyles.Count -eq 1) 'Previous style was not backed up'
    Assert ([IO.File]::ReadAllText($savedStyles[0].FullName) -eq 'old local style') 'Style backup content changed'
    $script:running = $true
    $script:answer = 'q'
    $before = (Get-FileHash -LiteralPath $custom).Hash
    Install-ZoteroFiles
    Assert ((Get-FileHash -LiteralPath $custom).Hash -eq $before) 'Cancellation changed installed files'
    Assert $script:running 'Installer closed Zotero itself'
    $script:answer = ''
    $script:closeOnPrompt = $true
    $promptsBefore = $script:promptCount
    Install-ZoteroFiles
    Assert ($script:promptCount -eq $promptsBefore + 1) 'Running Zotero did not prompt to retry'
    Assert (-not $script:running) 'Retry did not continue after Zotero closed'
    $script:closeOnPrompt = $false
    $script:failDownload = $true
    $before = (Get-FileHash -LiteralPath $custom).Hash
    $failed = $false
    try { Install-ZoteroFiles } catch { $failed = $true }
    Assert $failed 'Download failure was ignored'
    Assert ((Get-FileHash -LiteralPath $custom).Hash -eq $before) 'Failed download changed installed translator'
    Write-Host 'PASS: install, custom priority, bundled translators preserved, repeat runs, backups, running Zotero, download failure.'
}
finally { Remove-Item -LiteralPath $testRoot -Recurse -Force }

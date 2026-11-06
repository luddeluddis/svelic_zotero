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
function Read-Host { param($Prompt) return $script:answer }
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
    # A different filename tests ID-based identification, including the current bundled name.
    [IO.File]::WriteAllText($path, "{`n`"translatorID`":`"70dc2609-d6fd-415a-822c-a2c04293cb5a`",`n`"label`":`"UpToDate References`"`n}")
    return $path
}
try {
    New-Item -ItemType Directory -Path (Join-Path $DataDirectory 'translators') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $DataDirectory 'zotero.sqlite') | Out-Null
    $bundled = Write-Bundled 'UpToDate References.js'
    $DisableDefaultUpToDate = 'Ask'
    Install-ZoteroFiles
    Assert (Test-Path -LiteralPath "$bundled.disabled") 'Default Yes did not disable the bundled translator'
    Assert (-not (Test-Path -LiteralPath $bundled)) 'Bundled translator is still enabled'
    $custom = Join-Path $DataDirectory 'translators/UpToDate_article.js'
    Assert ((Get-TranslatorMetadata $custom).translatorID -eq '4af8c4da-cf3d-4ec2-989f-15d4d0723bf1') 'Custom translator missing or disabled'
    $style = Join-Path $DataDirectory 'styles/nlm-citation-sequence-unnumbered-bibliography.csl'
    Assert (Test-Path -LiteralPath $style) 'Style was not installed'
    $firstStyleTime = (Get-Item -LiteralPath $style).LastWriteTimeUtc
    $firstTime = (Get-Item -LiteralPath $custom).LastWriteTimeUtc
    $DisableDefaultUpToDate = 'Yes'
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

    $bundled = Write-Bundled 'Renamed bundled.js'
    $DisableDefaultUpToDate = 'Ask'
    $script:answer = 'n'
    Install-ZoteroFiles
    Assert (Test-Path -LiteralPath $bundled) 'No choice was ignored'
    $DisableDefaultUpToDate = 'Yes'
    Install-ZoteroFiles
    Assert (Test-Path -LiteralPath "$bundled.disabled") 'Renamed bundled translator was not disabled by ID'
    $null = Write-Bundled 'Renamed bundled.js'
    Install-ZoteroFiles
    Assert (@(Get-ChildItem -LiteralPath (Split-Path $bundled) -Filter 'Renamed bundled.js.disabled*').Count -eq 2) 'Earlier disabled copy was overwritten'
    Assert (Test-Path -LiteralPath $custom) 'Custom translator disabled during repeated runs'

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
    $failed = $false
    try { Install-ZoteroFiles } catch { $failed = $true }
    Assert $failed 'Running Zotero was not rejected'
    $script:running = $false
    $script:failDownload = $true
    $before = (Get-FileHash -LiteralPath $custom).Hash
    $failed = $false
    try { Install-ZoteroFiles } catch { $failed = $true }
    Assert $failed 'Download failure was ignored'
    Assert ((Get-FileHash -LiteralPath $custom).Hash -eq $before) 'Failed download changed installed translator'
    Write-Host 'PASS: install, default Yes, opt-out, ID matching, custom protection, repeat runs, backups, running Zotero, download failure.'
}
finally { Remove-Item -LiteralPath $testRoot -Recurse -Force }

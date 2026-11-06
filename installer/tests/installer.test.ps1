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
    # A normal installation must not open unrelated translator files.
    $fastDirectory = Join-Path $testRoot 'Many translators'
    New-Item -ItemType Directory -Path $fastDirectory | Out-Null
    for ($i = 0; $i -lt 300; $i++) {
        [IO.File]::WriteAllText((Join-Path $fastDirectory "Unrelated-$i.js"), 'Not metadata; must not be opened on the fast path')
    }
    $known = Join-Path $fastDirectory 'UpToDate References.js'
    [IO.File]::WriteAllText($known, "{`n`"translatorID`":`"70dc2609-d6fd-415a-822c-a2c04293cb5a`",`n`"label`":`"UpToDate References`"`n}`n" + ('x' * 1000000))
    # Even a misleading filename containing the custom translator must stay enabled.
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'translators/UpToDate_article.js') -Destination (Join-Path $fastDirectory 'UpToDate.js')
    $script:originalHeaderReader = ${function:Get-TranslatorHeader}
    $script:headersRead = New-Object 'Collections.Generic.List[string]'
    function Get-TranslatorHeader([string]$Path) {
        $script:headersRead.Add($Path)
        & $script:originalHeaderReader $Path
    }
    $found = @(Find-BundledUpToDate $fastDirectory)
    Assert ($found.Count -eq 1 -and $found[0] -eq $known) 'Known filename did not identify only the bundled ID'
    Assert ($script:headersRead.Count -eq 2) 'Fast path opened unrelated translators'
    $header = Get-TranslatorHeader $known
    Assert ($header.Length -lt 1000) 'Reader returned translator code instead of only metadata'

    # Fallback still finds a renamed bundled file and ignores IDs occurring in code.
    $fallbackDirectory = Join-Path $testRoot 'Renamed translator search'
    New-Item -ItemType Directory -Path $fallbackDirectory | Out-Null
    $renamed = Join-Path $fallbackDirectory 'Renamed.js'
    Copy-Item -LiteralPath $known -Destination $renamed
    $decoy = Join-Path $fallbackDirectory 'Decoy.js'
    [IO.File]::WriteAllText($decoy, "{`n`"translatorID`":`"different-id`",`n`"label`":`"Other translator`"`n}`n// 70dc2609-d6fd-415a-822c-a2c04293cb5a")
    $found = @(Find-BundledUpToDate $fallbackDirectory)
    Assert ($found.Count -eq 1 -and $found[0] -eq $renamed) 'Fallback matched translator code or missed renamed bundled translator'
    Write-Host 'PASS: install, default Yes, opt-out, ID matching, custom protection, repeat runs, backups, running Zotero, download failure, fast lookup and bounded metadata reads.'
}
finally { Remove-Item -LiteralPath $testRoot -Recurse -Force }

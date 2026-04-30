[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = Join-Path (Split-Path -Parent $scriptDir) "assets\data"

function Merge-WordList {
    param([string]$BaseFile, [string]$SupUrl, [int]$Target, [string]$OutFile)

    Write-Host "Reading base file: $BaseFile"
    $baseJson = Get-Content $BaseFile -Raw -Encoding UTF8
    $baseObj = $baseJson | ConvertFrom-Json
    $baseCards = $baseObj.cards
    $baseWords = @{}
    foreach ($c in $baseCards) { $baseWords[$c.front] = $true }
    Write-Host "  Base words: $($baseCards.Count)"

    $needed = $Target - $baseCards.Count
    if ($needed -le 0) {
        Write-Host "  Already at target, no merge needed."
        return
    }

    Write-Host "  Need $needed more words. Downloading supplement..."
    try {
        $resp = Invoke-WebRequest -Uri $SupUrl -UseBasicParsing -TimeoutSec 120
        $supWords = $resp.Content | ConvertFrom-Json
    } catch {
        Write-Host "  Download failed: $_" -ForegroundColor Red
        return
    }
    Write-Host "  Supplement source: $($supWords.Count) words"

    $newCards = New-Object System.Collections.ArrayList
    foreach ($c in $baseCards) { [void]$newCards.Add($c) }

    $added = 0
    foreach ($w in $supWords) {
        if ($added -ge $needed) { break }
        if (-not $w.word) { continue }
        if ($baseWords.ContainsKey($w.word)) { continue }
        $parts = New-Object System.Collections.ArrayList
        if ($w.translations) {
            foreach ($t in $w.translations) {
                $ty = $t.type; $tr = $t.translation
                if ($ty -and $tr) { [void]$parts.Add("$ty. $tr") }
                elseif ($tr) { [void]$parts.Add("$tr") }
            }
        }
        $back = $parts -join "; "
        if (-not $back) { continue }
        [void]$newCards.Add(@{ front = $w.word; back = $back })
        $baseWords[$w.word] = $true
        $added++
    }

    Write-Host "  Added $added new words. Total: $($newCards.Count)" -ForegroundColor Green

    $result = @{
        name = $baseObj.name
        description = $baseObj.description
        icon = $baseObj.icon
        color = $baseObj.color
        cards = $newCards.ToArray()
    }
    $json = $result | ConvertTo-Json -Depth 4
    $json = [System.Text.RegularExpressions.Regex]::Unescape($json)
    [System.IO.File]::WriteAllText($OutFile, $json, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "  Saved: $OutFile" -ForegroundColor Green
}

$cet6File = Join-Path $outputDir "cet6_words.json"
$kaoyanFile = Join-Path $outputDir "postgrad_words.json"

Merge-WordList -BaseFile $cet6File -SupUrl "https://raw.githubusercontent.com/KyleBing/english-vocabulary/master/json_original/json-simple/CET6_2.json" -Target 1500 -OutFile $cet6File

Merge-WordList -BaseFile $kaoyanFile -SupUrl "https://raw.githubusercontent.com/KyleBing/english-vocabulary/master/json_original/json-simple/KaoYan_2.json" -Target 1500 -OutFile $kaoyanFile

Write-Host "All done!" -ForegroundColor Yellow

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = Join-Path (Split-Path -Parent $scriptDir) "assets\data"
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

function Convert-WordList {
    param([string]$Url, [string]$OutputFile, [string]$Name, [string]$Desc, [string]$Icon, [string]$Color, [int]$Max = 1500)
    Write-Host "Downloading: $Url"
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 120
        $words = $resp.Content | ConvertFrom-Json
    } catch {
        Write-Host "Download failed: $_" -ForegroundColor Red
        return
    }
    Write-Host "  Source count: $($words.Count)"
    $cards = New-Object System.Collections.ArrayList
    foreach ($w in $words) {
        if ($cards.Count -ge $Max) { break }
        $word = $w.word
        if (-not $word) { continue }
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
        [void]$cards.Add(@{ front = $word; back = $back })
    }
    Write-Host "  Converted: $($cards.Count)" -ForegroundColor Green
    $result = @{ name = $Name; description = $Desc; icon = $Icon; color = $Color; cards = $cards.ToArray() }
    $json = $result | ConvertTo-Json -Depth 4
    $json = [System.Text.RegularExpressions.Regex]::Unescape($json)
    [System.IO.File]::WriteAllText($OutputFile, $json, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "  Saved: $OutputFile" -ForegroundColor Green
}

Convert-WordList -Url "https://raw.githubusercontent.com/KyleBing/english-vocabulary/master/json_original/json-simple/CET6_1.json" -OutputFile (Join-Path $outputDir "cet6_words.json") -Name "英语六级核心词汇" -Desc "CET-6 English Vocabulary" -Icon "language" -Color "#1565C0" -Max 1500

Convert-WordList -Url "https://raw.githubusercontent.com/KyleBing/english-vocabulary/master/json_original/json-simple/KaoYan_1.json" -OutputFile (Join-Path $outputDir "postgrad_words.json") -Name "考研英语核心词汇" -Desc "Postgrad English Vocabulary" -Icon "school" -Color "#C62828" -Max 1500

Write-Host "Done!" -ForegroundColor Yellow

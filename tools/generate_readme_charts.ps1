[CmdletBinding()]
param(
    [string]$OutputDirectory = "docs\assets"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

function Get-Utf8Text {
    param([string]$Base64)

    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64))
}

function New-BarChart {
    param(
        [string]$Path,
        [string]$Title,
        [string]$Subtitle,
        [object[]]$Rows,
        [double]$Maximum,
        [string]$Suffix
    )

    $width = 1180
    $height = 132 + ($Rows.Count * 72)
    $image = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($image)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::FromArgb(248, 250, 252))

    $titleFont = [System.Drawing.Font]::new("Arial", 22, [System.Drawing.FontStyle]::Bold)
    $subtitleFont = [System.Drawing.Font]::new("Arial", 11)
    $labelFont = [System.Drawing.Font]::new("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $valueFont = [System.Drawing.Font]::new("Arial", 11)
    $noteFont = [System.Drawing.Font]::new("Arial", 10)
    $darkBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 41, 59))
    $mutedBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(71, 85, 105))
    $trackBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(226, 232, 240))

    $graphics.DrawString($Title, $titleFont, $darkBrush, 32, 20)
    $graphics.DrawString($Subtitle, $subtitleFont, $mutedBrush, 34, 58)

    $barX = 330
    $barWidth = 690
    $y = 116
    foreach ($row in $Rows) {
        $graphics.DrawString($row.Label, $labelFont, $darkBrush, 34, $y + 7)
        $graphics.FillRectangle($trackBrush, $barX, $y, $barWidth, 36)
        $actualWidth = [math]::Round(($row.Value / $Maximum) * $barWidth)
        $barBrush = [System.Drawing.SolidBrush]::new($row.Color)
        $graphics.FillRectangle($barBrush, $barX, $y, $actualWidth, 36)
        $barBrush.Dispose()
        $graphics.DrawString(("{0}{1}" -f $row.Value, $Suffix), $valueFont, $darkBrush, $barX + $actualWidth + 12, $y + 8)
        if ($row.Note) {
            $graphics.DrawString($row.Note, $noteFont, $mutedBrush, $barX, $y + 40)
        }
        $y += 72
    }

    $image.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $trackBrush.Dispose()
    $mutedBrush.Dispose()
    $darkBrush.Dispose()
    $valueFont.Dispose()
    $noteFont.Dispose()
    $labelFont.Dispose()
    $subtitleFont.Dispose()
    $titleFont.Dispose()
    $graphics.Dispose()
    $image.Dispose()
}

$green = [System.Drawing.Color]::FromArgb(22, 163, 74)
$blue = [System.Drawing.Color]::FromArgb(37, 99, 235)
$amber = [System.Drawing.Color]::FromArgb(217, 119, 6)
$purple = [System.Drawing.Color]::FromArgb(124, 58, 237)
$teal = [System.Drawing.Color]::FromArgb(13, 148, 136)

New-BarChart `
    -Path (Join-Path $OutputDirectory "model-gpu-footprint.png") `
    -Title (Get-Utf8Text "0J7QsdGK0ZHQvCDQsiDQstC40LTQtdC+0L/QsNC80Y/RgtC4") `
    -Subtitle (Get-Utf8Text "0KLQvtC70YzQutC+INC00L7Qv9GD0YnQtdC90L3Ri9C1INC/0YDQvtGE0LjQu9C4OyDQstGB0LUg0L7RgdGC0LDRjtGC0YHRjyDQvdCwIDEwMCUgR1BV") `
    -Maximum 15 `
    -Suffix (Get-Utf8Text "INCT0JE=") `
    -Rows @(
        @{ Label = "Qwen 3 8B"; Value = 11; Color = $green; Note = "ctx 40k; $(Get-Utf8Text '0L7RgdC90L7QstC90L7QuQ==')" }
        @{ Label = "Ministral 3 8B"; Value = 11; Color = $purple; Note = "ctx 32k; $(Get-Utf8Text '0L/QvtCy0YLQvtGAINC/0YDQvtC50LTQtdC9')" }
        @{ Label = "Gemma 4 E4B"; Value = 13; Color = $amber; Note = "ctx 128k; $(Get-Utf8Text '0L7Qs9GA0LDQvdC40YfQtdC90L3Ri9C1INC30LDQtNCw0YfQuA==')" }
        @{ Label = "Granite 4.1 8B"; Value = 14; Color = $blue; Note = "ctx 32k; $(Get-Utf8Text '0L3QsNC00ZHQttC90YvQuSDQt9Cw0L/QsNGB0L3QvtC5')" }
        @{ Label = "GPT-OSS 20B"; Value = 14; Color = $teal; Note = "ctx 32k; $(Get-Utf8Text '0L/QvtC70L3Ri9C5INC/0YDQvtGF0L7QtA==')" }
    )

New-BarChart `
    -Path (Join-Path $OutputDirectory "model-first-attempt-score.png") `
    -Title (Get-Utf8Text "0J/RgNC+0LnQtNC10L3QvdGL0LUg0Y3RgtCw0L/RiyDRgSDQv9C10YDQstC+0Lkg0L/QvtC/0YvRgtC60Lg=") `
    -Subtitle (Get-Utf8Text "0KLQvtGH0L3Ri9C5INC+0YLQstC10YIsINC30LDQv9GD0YHQuiDQutC+0LzQsNC90LTRiyDQuCDRgNCw0LHQvtGC0LAg0YEg0YTQsNC50LvQsNC80Lg=") `
    -Maximum 3 `
    -Suffix " of 3" `
    -Rows @(
        @{ Label = "Qwen 3 8B"; Value = 3; Color = $green; Note = (Get-Utf8Text "0LTQvtC/0YPRidC10L0=") }
        @{ Label = "Granite 4.1 8B"; Value = 3; Color = $green; Note = (Get-Utf8Text "0LTQvtC/0YPRidC10L0=") }
        @{ Label = "GPT-OSS 20B"; Value = 3; Color = $green; Note = (Get-Utf8Text "0LTQvtC/0YPRidC10L0=") }
        @{ Label = "Ministral 3 8B"; Value = 2; Color = $amber; Note = (Get-Utf8Text "0YDQsNCx0L7RgtCwINGBINGE0LDQudC70LDQvNC4INC/0YDQvtC50LTQtdC90LAg0L/RgNC4INC/0L7QstGC0L7RgNC1") }
        @{ Label = "Gemma 4 E4B"; Value = 2; Color = $amber; Note = (Get-Utf8Text "0YPRgdGC0L7QudGH0LjQstC+0YHRgtGMINC00LvQuNC90L3QvtC5INGA0LDQsdC+0YLRiyDQvdC1INC/0L7QtNGC0LLQtdGA0LbQtNC10L3QsA==") }
    )

New-BarChart `
    -Path (Join-Path $OutputDirectory "model-successful-agent-time.png") `
    -Title (Get-Utf8Text "0JLRgNC10LzRjyDRg9GB0L/QtdGI0L3QvtC5INGA0LDQsdC+0YLRiyDRgSDRhNCw0LnQu9Cw0LzQuA==") `
    -Subtitle (Get-Utf8Text "0JzQtdC90YzRiNC1IC0g0LvRg9GH0YjQtTsg0L3QtdGD0LTQsNGH0L3Ri9C1INC/0L7Qv9GL0YLQutC4INC90LUg0YHRh9C40YLQsNC10Lwg0YDQtdC60L7RgNC00LDQvNC4") `
    -Maximum 310 `
    -Suffix " s" `
    -Rows @(
        @{ Label = "Qwen 3 8B"; Value = 148.6; Color = $green; Note = (Get-Utf8Text "0LTQvtC/0YPRidC10L0=") }
        @{ Label = "Granite 4.1 8B"; Value = 217.1; Color = $blue; Note = (Get-Utf8Text "0LTQvtC/0YPRidC10L0=") }
        @{ Label = "Ministral 3 8B"; Value = 219.5; Color = $purple; Note = (Get-Utf8Text "0YPRgdC/0LXRiNC90YvQuSDQv9C+0LLRgtC+0YA=") }
        @{ Label = "GPT-OSS 20B"; Value = 294.9; Color = $teal; Note = (Get-Utf8Text "0LTQvtC/0YPRidC10L0=") }
    )

New-BarChart `
    -Path (Join-Path $OutputDirectory "model-context-window.png") `
    -Title (Get-Utf8Text "0JLRi9Cx0YDQsNC90L3QvtC1INGA0LDQsdC+0YfQtdC1INC+0LrQvdC+") `
    -Subtitle (Get-Utf8Text "0J3QsNGB0YLRgNC+0LnQutCwINC00LvRjyDQutCw0LbQtNC+0Lkg0LzQvtC00LXQu9C4INGB0L7RhdGA0LDQvdGP0LXRgiDQv9GA0LDQstC40LvQviDQv9C+0LvQvdC+0LPQviDRgNCw0LfQvNC10YnQtdC90LjRjyDQsiBHUFU=") `
    -Maximum 131072 `
    -Suffix " $(Get-Utf8Text '0YLQvtC6Lg==')" `
    -Rows @(
        @{ Label = "Granite 4.1 8B"; Value = 32768; Color = $blue; Note = (Get-Utf8Text "0YHQu9C10LTRg9GO0YnQuNC5INGI0LDQsyDQstGL0LPRgNGD0LbQsNC10YIg0YfQsNGB0YLRjCDQsiBDUFU=") }
        @{ Label = "Ministral 3 8B"; Value = 32768; Color = $purple; Note = (Get-Utf8Text "0L7RgdGC0L7RgNC+0LbQvdCw0Y8g0L3QsNGB0YLRgNC+0LnQutCw") }
        @{ Label = "GPT-OSS 20B"; Value = 32768; Color = $teal; Note = (Get-Utf8Text "0L7RgdGC0L7RgNC+0LbQvdCw0Y8g0L3QsNGB0YLRgNC+0LnQutCw") }
        @{ Label = "Qwen 3 8B"; Value = 40960; Color = $green; Note = (Get-Utf8Text "0L/RgNC10LTQtdC7INC40YHRhdC+0LTQvdC+0Lkg0LzQvtC00LXQu9C4") }
        @{ Label = "Gemma 4 E4B"; Value = 131072; Color = $amber; Note = (Get-Utf8Text "0LvRg9GH0YjQtdC1INGA0LDQt9C80LXRidC10L3QuNC1OyDQvtCz0YDQsNC90LjRh9C10L3QvdGL0LUg0LfQsNC00LDRh9C4") }
    )

New-BarChart `
    -Path (Join-Path $OutputDirectory "model-coder-fixture-score.png") `
    -Title (Get-Utf8Text "0JfQsNC00LDRh9C4INGBINGC0LXRgdGC0LDQvNC4OiDQv9C10YDQstGL0Lkg0LrRgNGD0LM=") `
    -Subtitle (Get-Utf8Text "0JTQstC1INC90LXQsdC+0LvRjNGI0LjQtSDQt9Cw0LTQsNGH0Lg7INCy0YvRiNC1INC70YPRh9GI0LU=") `
    -Maximum 2 `
    -Suffix (Get-Utf8Text "INC40LcgMg==") `
    -Rows @(
        @{ Label = "GPT-OSS 20B"; Value = 2; Color = $teal; Note = (Get-Utf8Text "0LTQstC1INC30LDQtNCw0YfQuCDQv9GA0L7QudC00LXQvdGL") }
        @{ Label = "Ministral 3 8B"; Value = 2; Color = $purple; Note = (Get-Utf8Text "0LTQstC1INC30LDQtNCw0YfQuCDQv9GA0L7QudC00LXQvdGL") }
        @{ Label = "Gemma 4 E4B"; Value = 2; Color = $amber; Note = (Get-Utf8Text "0LTQstC1INC30LDQtNCw0YfQuCDQv9GA0L7QudC00LXQvdGLOyDQv9C+0LLRgtC+0YAgR2VtbWEg0L3QtdGB0YLQsNCx0LjQu9C10L0=") }
        @{ Label = "Granite 4.1 8B"; Value = 1; Color = $blue; Note = (Get-Utf8Text "0L3QtSDRg9GH0ZHQuyDRgdC+0YHQtdC00L3QuNC1INC00LjQsNC/0LDQt9C+0L3Riw==") }
        @{ Label = "Qwen 3 8B"; Value = 0; Color = $green; Note = (Get-Utf8Text "0L3QtSDQuNC30LzQtdC90LjQuyDRhNCw0LnQuw==") }
    )

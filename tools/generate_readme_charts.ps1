[CmdletBinding()]
param(
    [string]$OutputDirectory = "docs\assets"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

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
    $height = 120 + ($Rows.Count * 72)
    $image = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($image)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::FromArgb(248, 250, 252))

    $titleFont = [System.Drawing.Font]::new("Arial", 22, [System.Drawing.FontStyle]::Bold)
    $subtitleFont = [System.Drawing.Font]::new("Arial", 11)
    $labelFont = [System.Drawing.Font]::new("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $valueFont = [System.Drawing.Font]::new("Arial", 11)
    $darkBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 41, 59))
    $mutedBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(71, 85, 105))
    $trackBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(226, 232, 240))

    $graphics.DrawString($Title, $titleFont, $darkBrush, 32, 20)
    $graphics.DrawString($Subtitle, $subtitleFont, $mutedBrush, 34, 58)

    $barX = 315
    $barWidth = 760
    $y = 104
    foreach ($row in $Rows) {
        $graphics.DrawString($row.Label, $labelFont, $darkBrush, 34, $y + 7)
        $graphics.FillRectangle($trackBrush, $barX, $y, $barWidth, 36)
        $actualWidth = [math]::Round(($row.Value / $Maximum) * $barWidth)
        $barBrush = [System.Drawing.SolidBrush]::new($row.Color)
        $graphics.FillRectangle($barBrush, $barX, $y, $actualWidth, 36)
        $barBrush.Dispose()
        $graphics.DrawString(("{0}{1}" -f $row.Value, $Suffix), $valueFont, $darkBrush, $barX + $actualWidth + 12, $y + 8)
        $y += 72
    }

    $image.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $trackBrush.Dispose()
    $mutedBrush.Dispose()
    $darkBrush.Dispose()
    $valueFont.Dispose()
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
$red = [System.Drawing.Color]::FromArgb(220, 38, 38)

New-BarChart `
    -Path (Join-Path $OutputDirectory "model-gpu-footprint.png") `
    -Title "GPU / GB" `
    -Subtitle "" `
    -Maximum 15 `
    -Suffix " GB" `
    -Rows @(
        @{ Label = "Nemotron 3 Nano 4B"; Value = 5.7; Color = $green }
        @{ Label = "Qwen 3 8B"; Value = 11; Color = $blue }
        @{ Label = "Ministral 3 8B"; Value = 11; Color = $purple }
        @{ Label = "Gemma 4 E4B"; Value = 13; Color = $amber }
        @{ Label = "Granite 4.1 8B"; Value = 14; Color = $red }
    )

New-BarChart `
    -Path (Join-Path $OutputDirectory "model-first-attempt-score.png") `
    -Title "3 / 3" `
    -Subtitle "" `
    -Maximum 3 `
    -Suffix " of 3" `
    -Rows @(
        @{ Label = "Qwen 3 8B"; Value = 3; Color = $green }
        @{ Label = "Granite 4.1 8B"; Value = 3; Color = $green }
        @{ Label = "Ministral 3 8B"; Value = 2; Color = $amber }
        @{ Label = "Gemma 4 E4B"; Value = 2; Color = $amber }
        @{ Label = "Nemotron 3 Nano 4B"; Value = 0; Color = $red }
    )

New-BarChart `
    -Path (Join-Path $OutputDirectory "model-successful-agent-time.png") `
    -Title "Seconds" `
    -Subtitle "" `
    -Maximum 230 `
    -Suffix " s" `
    -Rows @(
        @{ Label = "Qwen 3 8B"; Value = 148.6; Color = $green }
        @{ Label = "Granite 4.1 8B"; Value = 217.1; Color = $blue }
        @{ Label = "Ministral 3 8B"; Value = 219.5; Color = $purple }
    )

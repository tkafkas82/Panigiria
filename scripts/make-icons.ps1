# Generates PWA icons for Panigiria: a white Cycladic chapel with a blue dome
# and cross, on a sea->sky gradient. No external dependencies (System.Drawing).
Add-Type -AssemblyName System.Drawing

$outDir = Join-Path $PSScriptRoot "..\icons"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

function Rect([double]$x, [double]$y, [double]$w, [double]$h) {
    New-Object System.Drawing.RectangleF([single]$x, [single]$y, [single]$w, [single]$h)
}

function New-Icon {
    param(
        [int]$Size,
        [string]$Path,
        [double]$Inset = 0.0,   # fraction of size kept empty around art (maskable safe zone)
        [bool]$RoundedBg = $true
    )

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([System.Drawing.Color]::Transparent)

    $sea = [System.Drawing.Color]::FromArgb(26, 74, 107)   # #1a4a6b
    $sky = [System.Drawing.Color]::FromArgb(45, 122, 184)  # #2d7ab8
    $white = [System.Drawing.Color]::FromArgb(253, 252, 249)
    $dome = [System.Drawing.Color]::FromArgb(45, 122, 184)
    $accent = [System.Drawing.Color]::FromArgb(192, 98, 42) # #c0622a

    # Background (full bleed) gradient
    $bgRect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($bgRect, $sea, $sky, 90.0)
    if ($RoundedBg) {
        $r = [int]($Size * 0.22)
        $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
        $gp.AddArc(0, 0, 2*$r, 2*$r, 180, 90)
        $gp.AddArc($Size-2*$r, 0, 2*$r, 2*$r, 270, 90)
        $gp.AddArc($Size-2*$r, $Size-2*$r, 2*$r, 2*$r, 0, 90)
        $gp.AddArc(0, $Size-2*$r, 2*$r, 2*$r, 90, 90)
        $gp.CloseFigure()
        $g.FillPath($brush, $gp)
    } else {
        $g.FillRectangle($brush, $bgRect)
    }

    # Art area (inside inset)
    $pad = [int]($Size * $Inset)
    $aw = $Size - 2*$pad
    $ax = $pad
    $ay = $pad

    # Chapel geometry, relative to art box
    $cw = $aw * 0.52           # chapel body width
    $ch = $aw * 0.34           # chapel body height
    $cx = $ax + ($aw - $cw)/2  # body left
    $cyBottom = $ay + $aw * 0.80
    $cyTop = $cyBottom - $ch

    $whiteBrush = New-Object System.Drawing.SolidBrush($white)
    $domeBrush  = New-Object System.Drawing.SolidBrush($dome)
    $accentBrush= New-Object System.Drawing.SolidBrush($accent)

    # Body
    $g.FillRectangle($whiteBrush, (Rect $cx $cyTop $cw $ch))

    # Door (accent)
    $doorW = $cw * 0.22
    $doorH = $ch * 0.5
    $doorX = $cx + ($cw - $doorW)/2
    $doorY = $cyBottom - $doorH
    $g.FillRectangle($accentBrush, (Rect $doorX $doorY $doorW $doorH))

    # Dome (blue) sitting on the body
    $domeD = $cw * 0.5
    $domeX = $cx + ($cw - $domeD)/2
    $domeY = $cyTop - $domeD*0.62
    $g.FillPie($domeBrush, [single]$domeX, [single]$domeY, [single]$domeD, [single]$domeD, 180, 180)
    # Dome drum (white) under dome
    $drumH = $aw*0.02
    $g.FillRectangle($whiteBrush, (Rect $domeX ($cyTop-$drumH) $domeD ($drumH+1)))

    # Cross on top of dome
    $crossCx = $cx + $cw/2
    $crossTop = $domeY - $aw*0.10
    $barW = [Math]::Max(2.0, $aw*0.018)
    $crossH = $aw*0.10
    $crossArm = $aw*0.05
    # vertical
    $g.FillRectangle($whiteBrush, (Rect ($crossCx-$barW/2) $crossTop $barW $crossH))
    # horizontal
    $g.FillRectangle($whiteBrush, (Rect ($crossCx-$crossArm/2) ($crossTop+$crossH*0.22) $crossArm $barW))

    # Save
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "wrote $Path"
}

New-Icon -Size 192 -Path (Join-Path $outDir "icon-192.png") -Inset 0.0 -RoundedBg $true
New-Icon -Size 512 -Path (Join-Path $outDir "icon-512.png") -Inset 0.0 -RoundedBg $true
New-Icon -Size 512 -Path (Join-Path $outDir "icon-maskable-512.png") -Inset 0.16 -RoundedBg $false
New-Icon -Size 180 -Path (Join-Path $outDir "apple-touch-icon.png") -Inset 0.06 -RoundedBg $false
New-Icon -Size 32  -Path (Join-Path $outDir "favicon-32.png") -Inset 0.0 -RoundedBg $true
Write-Host "done"

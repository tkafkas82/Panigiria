# Generates a 1200x630 Open Graph share image for Panigiria:
# Cycladic chapel on a sea->sky gradient with the site title. No external deps.
Add-Type -AssemblyName System.Drawing

$outDir = Join-Path $PSScriptRoot "..\icons"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$path = Join-Path $outDir "og-image.png"

$W = 1200; $H = 630
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

$sea   = [System.Drawing.Color]::FromArgb(26, 74, 107)
$sky   = [System.Drawing.Color]::FromArgb(63, 143, 207)
$white = [System.Drawing.Color]::FromArgb(253, 252, 249)
$dome  = [System.Drawing.Color]::FromArgb(45, 122, 184)
$accent= [System.Drawing.Color]::FromArgb(192, 98, 42)
$sand  = [System.Drawing.Color]::FromArgb(244, 238, 226)

# background gradient (sky top -> sea bottom)
$bgRect = New-Object System.Drawing.Rectangle(0, 0, $W, $H)
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($bgRect, $sky, $sea, 90.0)
$g.FillRectangle($brush, $bgRect)

$whiteBrush = New-Object System.Drawing.SolidBrush($white)
$domeBrush  = New-Object System.Drawing.SolidBrush($dome)
$accentBrush= New-Object System.Drawing.SolidBrush($accent)

# --- chapel on the right side ---
$baseX = 880.0; $baseY = 420.0
$cw = 220.0; $ch = 150.0
$cx = $baseX; $cyTop = $baseY - $ch
$g.FillRectangle($whiteBrush, (New-Object System.Drawing.RectangleF([single]$cx, [single]$cyTop, [single]$cw, [single]$ch)))
# dome
$domeD = 120.0
$domeX = $cx + ($cw - $domeD)/2
$domeY = $cyTop - $domeD*0.6
$g.FillPie($domeBrush, [single]$domeX, [single]$domeY, [single]$domeD, [single]$domeD, 180, 180)
$g.FillRectangle($whiteBrush, (New-Object System.Drawing.RectangleF([single]$domeX, [single]($cyTop-8), [single]$domeD, [single]10)))
# cross
$crossCx = $cx + $cw/2
$crossTop = $domeY - 70
$g.FillRectangle($whiteBrush, (New-Object System.Drawing.RectangleF([single]($crossCx-5), [single]$crossTop, [single]10, [single]60)))
$g.FillRectangle($whiteBrush, (New-Object System.Drawing.RectangleF([single]($crossCx-22), [single]($crossTop+16), [single]44, [single]10)))
# door
$g.FillRectangle($accentBrush, (New-Object System.Drawing.RectangleF([single]($cx+$cw/2-26), [single]($baseY-80), [single]52, [single]80)))

# --- title text on the left ---
$titleFont = New-Object System.Drawing.Font("Georgia", 76, [System.Drawing.FontStyle]::Bold)
$subFont   = New-Object System.Drawing.Font("Segoe UI", 30, [System.Drawing.FontStyle]::Regular)
$eyebrowFont = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)

$g.DrawString("ΣΕΡΙΦΟΣ - ΚΥΚΛΑΔΕΣ", $eyebrowFont, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 220, 235))), 80, 150)
$g.DrawString("Πανηγύρια", $titleFont, $whiteBrush, 72, 200)
$g.DrawString("2026", $titleFont, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(142, 200, 240))), 78, 300)
$g.DrawString("Πρόγραμμα, ημερομηνίες & γλέντια", $subFont, (New-Object System.Drawing.SolidBrush($sand)), 80, 420)

$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "wrote $path"

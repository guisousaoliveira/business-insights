Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$purple = [System.Drawing.Color]::FromArgb(255, 189, 109, 242)
$accent = [System.Drawing.Color]::FromArgb(255, 189, 78, 191)
$white = [System.Drawing.Color]::White

function New-RoundedPath([float]$size, [float]$radius) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = $radius * 2
    $path.AddArc(0, 0, $diameter, $diameter, 180, 90)
    $path.AddArc($size - $diameter, 0, $diameter, $diameter, 270, 90)
    $path.AddArc($size - $diameter, $size - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc(0, $size - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-GlowIcon([string]$path, [int]$size, [bool]$fullBleed = $false) {
    $directory = Split-Path -Parent $path
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }

    $bitmap = [System.Drawing.Bitmap]::new($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $bounds = [System.Drawing.RectangleF]::new(0, 0, $size, $size)
    $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        $bounds,
        $purple,
        $accent,
        45
    )
    $rounded = $null
    if ($fullBleed) {
        $graphics.FillRectangle($gradient, $bounds)
    } else {
        $rounded = New-RoundedPath $size ($size * 0.24)
        $graphics.FillPath($gradient, $rounded)
    }

    $center = $size * 0.5
    $outer = $size * 0.29
    $inner = $size * 0.075
    $sparkle = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $points = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($center, $center - $outer),
        [System.Drawing.PointF]::new($center + $inner, $center - $inner),
        [System.Drawing.PointF]::new($center + $outer, $center),
        [System.Drawing.PointF]::new($center + $inner, $center + $inner),
        [System.Drawing.PointF]::new($center, $center + $outer),
        [System.Drawing.PointF]::new($center - $inner, $center + $inner),
        [System.Drawing.PointF]::new($center - $outer, $center),
        [System.Drawing.PointF]::new($center - $inner, $center - $inner)
    )
    $sparkle.AddPolygon($points)
    $whiteBrush = [System.Drawing.SolidBrush]::new($white)
    $graphics.FillPath($whiteBrush, $sparkle)
    $graphics.FillEllipse(
        $whiteBrush,
        $size * 0.73,
        $size * 0.18,
        $size * 0.09,
        $size * 0.09
    )

    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $whiteBrush.Dispose()
    $sparkle.Dispose()
    if ($null -ne $rounded) { $rounded.Dispose() }
    $gradient.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

$android = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}
foreach ($entry in $android.GetEnumerator()) {
    New-GlowIcon (
        Join-Path $repoRoot "frontend/salao_app/android/app/src/main/res/$($entry.Key)/ic_launcher.png"
    ) $entry.Value
}

$iosRoot = Join-Path $repoRoot 'frontend/salao_app/ios/Runner/Assets.xcassets/AppIcon.appiconset'
$ios = @{
    'Icon-App-20x20@1x.png' = 20; 'Icon-App-20x20@2x.png' = 40; 'Icon-App-20x20@3x.png' = 60
    'Icon-App-29x29@1x.png' = 29; 'Icon-App-29x29@2x.png' = 58; 'Icon-App-29x29@3x.png' = 87
    'Icon-App-40x40@1x.png' = 40; 'Icon-App-40x40@2x.png' = 80; 'Icon-App-40x40@3x.png' = 120
    'Icon-App-60x60@2x.png' = 120; 'Icon-App-60x60@3x.png' = 180
    'Icon-App-76x76@1x.png' = 76; 'Icon-App-76x76@2x.png' = 152
    'Icon-App-83.5x83.5@2x.png' = 167; 'Icon-App-1024x1024@1x.png' = 1024
}
foreach ($entry in $ios.GetEnumerator()) {
    New-GlowIcon (Join-Path $iosRoot $entry.Key) $entry.Value $true
}

New-GlowIcon (Join-Path $repoRoot 'frontend/salao_web/public/favicon-32.png') 32
New-GlowIcon (Join-Path $repoRoot 'frontend/salao_web/public/apple-touch-icon.png') 180 $true
New-GlowIcon (Join-Path $repoRoot 'frontend/salao_web/public/glowapp-icon.png') 512

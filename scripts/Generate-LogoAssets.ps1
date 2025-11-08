# PowerShell script to generate optimized logo assets for Flutter
# Uses .NET System.Drawing for image processing

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

# Paths
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LogoDir = Join-Path $ProjectRoot "assets\images\logo"
$OutputDir = Join-Path $LogoDir "generated"

# Source images  
$PlaystoreImg = Join-Path $LogoDir "appicons\playstore.png"
$LogoNotextImg = Join-Path $LogoDir "imagesets\ios\seferet-logo-notext-colored@3x.png"

# Colors
$BgColorLight = [System.Drawing.Color]::White
$BgColorDark = [System.Drawing.Color]::FromArgb(26, 26, 26)

Write-Host "SeferEt Logo Asset Generator" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
Write-Host "Output directory: $OutputDir" -ForegroundColor Green

function Crop-DecorativeBars {
    param([System.Drawing.Bitmap]$image)
    
    # Remove decorative bars more aggressively
    # Bars take up roughly 18-20% each at top and bottom
    $cropTop = [int]($image.Height * 0.20)
    $cropBottom = [int]($image.Height * 0.20)
    $cropHeight = $image.Height - $cropTop - $cropBottom
    
    # Also trim some horizontal padding
    $cropLeft = [int]($image.Width * 0.05)
    $cropRight = [int]($image.Width * 0.05)
    $cropWidth = $image.Width - $cropLeft - $cropRight
    
    $rect = New-Object System.Drawing.Rectangle($cropLeft, $cropTop, $cropWidth, $cropHeight)
    $cropped = $image.Clone($rect, $image.PixelFormat)
    
    return $cropped
}

function Create-IconWithPadding {
    param(
        [System.Drawing.Bitmap]$sourceImg,
        [int]$size,
        [int]$paddingPercent = 15,
        [System.Drawing.Color]$bgColor = $BgColorLight
    )
    
    # Create canvas
    $canvas = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear($bgColor)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    
    # Crop decorative bars
    $logo = Crop-DecorativeBars $sourceImg
    
    # Calculate padding
    $padding = [int]($size * $paddingPercent / 100)
    $logoArea = $size - (2 * $padding)
    
    # Calculate scaled size maintaining aspect ratio
    $scale = [Math]::Min($logoArea / $logo.Width, $logoArea / $logo.Height)
    $newWidth = [int]($logo.Width * $scale)
    $newHeight = [int]($logo.Height * $scale)
    
    # Calculate position to center
    $x = [int](($size - $newWidth) / 2)
    $y = [int](($size - $newHeight) / 2)
    
    # Draw logo
    $destRect = New-Object System.Drawing.Rectangle($x, $y, $newWidth, $newHeight)
    $graphics.DrawImage($logo, $destRect)
    
    $graphics.Dispose()
    $logo.Dispose()
    
    return $canvas
}

function Create-SplashWithPadding {
    param(
        [System.Drawing.Bitmap]$sourceImg,
        [int]$width,
        [int]$height,
        [int]$scalePercent = 35,
        [System.Drawing.Color]$bgColor = $BgColorLight
    )
    
    # Create canvas
    $canvas = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear($bgColor)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    
    # Use full logo with decorative bars for splash
    $targetHeight = [int]($height * $scalePercent / 100)
    $aspectRatio = $sourceImg.Width / $sourceImg.Height
    $targetWidth = [int]($targetHeight * $aspectRatio)
    
    # Center position
    $x = [int](($width - $targetWidth) / 2)
    $y = [int](($height - $targetHeight) / 2)
    
    $destRect = New-Object System.Drawing.Rectangle($x, $y, $targetWidth, $targetHeight)
    $graphics.DrawImage($sourceImg, $destRect)
    
    $graphics.Dispose()
    
    return $canvas
}

function Create-AdaptiveIconForeground {
    param(
        [System.Drawing.Bitmap]$sourceImg,
        [int]$size = 1024
    )
    
    # Create transparent canvas
    $canvas = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    
    # Crop decorative bars
    $logo = Crop-DecorativeBars $sourceImg
    
    # Scale to 60% for safe area
    $logoSize = [int]($size * 0.60)
    $scale = [Math]::Min($logoSize / $logo.Width, $logoSize / $logo.Height)
    $newWidth = [int]($logo.Width * $scale)
    $newHeight = [int]($logo.Height * $scale)
    
    # Center
    $x = [int](($size - $newWidth) / 2)
    $y = [int](($size - $newHeight) / 2)
    
    $destRect = New-Object System.Drawing.Rectangle($x, $y, $newWidth, $newHeight)
    $graphics.DrawImage($logo, $destRect)
    
    $graphics.Dispose()
    $logo.Dispose()
    
    return $canvas
}

# Load source images
Write-Host "`nLoading source images..." -ForegroundColor Yellow
$source = [System.Drawing.Bitmap]::FromFile($PlaystoreImg)
$sourceNotext = [System.Drawing.Bitmap]::FromFile($LogoNotextImg)

# Generate app icons
Write-Host "`nGenerating app icons..." -ForegroundColor Yellow

$icon1024 = Create-IconWithPadding -sourceImg $sourceNotext -size 1024 -paddingPercent 20 -bgColor $BgColorLight
$outputPath = Join-Path $OutputDir "app_icon_1024.png"
$icon1024.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$icon1024.Dispose()
Write-Host "  iOS app icon (1024x1024): $outputPath" -ForegroundColor Green

$icon512 = Create-IconWithPadding -sourceImg $sourceNotext -size 512 -paddingPercent 15 -bgColor $BgColorLight
$outputPath = Join-Path $OutputDir "app_icon_512.png"
$icon512.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$icon512.Dispose()
Write-Host "  Android standard icon (512x512): $outputPath" -ForegroundColor Green

# Generate adaptive icon
Write-Host "`nGenerating Android adaptive icon..." -ForegroundColor Yellow

$adaptiveFg = Create-AdaptiveIconForeground -sourceImg $sourceNotext -size 1024
$outputPath = Join-Path $OutputDir "adaptive_icon_foreground.png"
$adaptiveFg.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$adaptiveFg.Dispose()
Write-Host "  Adaptive foreground: $outputPath" -ForegroundColor Green

$adaptiveBg = New-Object System.Drawing.Bitmap(1024, 1024)
$graphics = [System.Drawing.Graphics]::FromImage($adaptiveBg)
$graphics.Clear($BgColorLight)
$graphics.Dispose()
$outputPath = Join-Path $OutputDir "adaptive_icon_background.png"
$adaptiveBg.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$adaptiveBg.Dispose()
Write-Host "  Adaptive background: $outputPath" -ForegroundColor Green

# Generate splash screens
Write-Host "`nGenerating splash screens..." -ForegroundColor Yellow

$splashLight = Create-SplashWithPadding -sourceImg $source -width 1242 -height 2688 -scalePercent 30 -bgColor $BgColorLight
$outputPath = Join-Path $OutputDir "splash_light.png"
$splashLight.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$splashLight.Dispose()
Write-Host "  Splash (light): $outputPath" -ForegroundColor Green

$splashDark = Create-SplashWithPadding -sourceImg $source -width 1242 -height 2688 -scalePercent 30 -bgColor $BgColorDark
$outputPath = Join-Path $OutputDir "splash_dark.png"
$splashDark.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$splashDark.Dispose()
Write-Host "  Splash (dark): $outputPath" -ForegroundColor Green

$android12 = Create-SplashWithPadding -sourceImg $source -width 288 -height 288 -scalePercent 65 -bgColor ([System.Drawing.Color]::Transparent)
$outputPath = Join-Path $OutputDir "splash_android12.png"
$android12.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$android12.Dispose()
Write-Host "  Splash (Android 12): $outputPath" -ForegroundColor Green

# Cleanup
$source.Dispose()
$sourceNotext.Dispose()

Write-Host "`n$("=" * 50)" -ForegroundColor Cyan
Write-Host "All assets generated successfully!" -ForegroundColor Green
Write-Host "`nOutput location: $OutputDir" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Update pubspec.yaml to use new generated images"
Write-Host "  2. Run: dart run flutter_launcher_icons"
Write-Host "  3. Run: dart run flutter_native_splash:create"

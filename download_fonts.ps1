# Create assets/fonts directory
New-Item -ItemType Directory -Force -Path "assets/fonts"

# Download Poppins font files from Google Fonts
$fonts = @(
    "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Regular.ttf",
    "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Medium.ttf",
    "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-SemiBold.ttf",
    "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf"
)

foreach ($font in $fonts) {
    $filename = Split-Path $font -Leaf
    $outputPath = "assets/fonts/$filename"
    Write-Host "Downloading $filename..."
    Invoke-WebRequest -Uri $font -OutFile $outputPath
    Write-Host "Downloaded $filename to $outputPath"
}

Write-Host "All font files downloaded successfully!"
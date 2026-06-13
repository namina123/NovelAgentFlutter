param(
  [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-GeneratedDartFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FileName
  )

  return $FileName -match '\.(g|freezed|mocks|gr)\.dart$' -or
    $FileName -eq 'generated_plugin_registrant.dart'
}

function Get-EffectiveLineStats {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath
  )

  $rawLines = @(Get-Content -LiteralPath $FilePath)
  $totalLines = $rawLines.Count
  $nonEmptyLines = 0
  $effectiveLines = 0
  $inBlockComment = $false

  foreach ($rawLine in $rawLines) {
    if ($rawLine.Trim().Length -gt 0) {
      $nonEmptyLines += 1
    }

    $line = $rawLine
    $builder = New-Object System.Text.StringBuilder
    $cursor = 0

    while ($cursor -lt $line.Length) {
      if ($inBlockComment) {
        $blockEnd = $line.IndexOf('*/', $cursor)
        if ($blockEnd -lt 0) {
          $cursor = $line.Length
          break
        }
        $inBlockComment = $false
        $cursor = $blockEnd + 2
        continue
      }

      $lineComment = $line.IndexOf('//', $cursor)
      $blockStart = $line.IndexOf('/*', $cursor)

      if ($lineComment -ge 0 -and ($blockStart -lt 0 -or $lineComment -lt $blockStart)) {
        [void]$builder.Append($line.Substring($cursor, $lineComment - $cursor))
        $cursor = $line.Length
        break
      }

      if ($blockStart -ge 0) {
        [void]$builder.Append($line.Substring($cursor, $blockStart - $cursor))
        $cursor = $blockStart + 2
        $inBlockComment = $true
        continue
      }

      [void]$builder.Append($line.Substring($cursor))
      $cursor = $line.Length
      break
    }

    if ($builder.ToString().Trim().Length -gt 0) {
      $effectiveLines += 1
    }
  }

  return [PSCustomObject]@{
    total_lines = $totalLines
    non_empty_lines = $nonEmptyLines
    effective_lines = $effectiveLines
  }
}

function Get-RelativePathCompat {
  param(
    [Parameter(Mandatory = $true)]
    [string]$BasePath,
    [Parameter(Mandatory = $true)]
    [string]$TargetPath
  )

  $baseFullPath = [System.IO.Path]::GetFullPath($BasePath)
  if (-not $baseFullPath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $baseFullPath += [System.IO.Path]::DirectorySeparatorChar
  }
  $targetFullPath = [System.IO.Path]::GetFullPath($TargetPath)
  $baseUri = New-Object System.Uri($baseFullPath)
  $targetUri = New-Object System.Uri($targetFullPath)
  $relativeUri = $baseUri.MakeRelativeUri($targetUri)
  return [System.Uri]::UnescapeDataString(
    $relativeUri.ToString().Replace('/', [System.IO.Path]::DirectorySeparatorChar)
  )
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoots = @(
  Join-Path $repoRoot 'apps'
  Join-Path $repoRoot 'packages'
)

$candidateDirs = @()
foreach ($root in $sourceRoots) {
  if (-not (Test-Path -LiteralPath $root)) {
    continue
  }

  $libDirs = Get-ChildItem -LiteralPath $root -Directory |
    ForEach-Object { Join-Path $_.FullName 'lib' } |
    Where-Object { Test-Path -LiteralPath $_ }
  $candidateDirs += $libDirs
}

$files = foreach ($dir in $candidateDirs) {
  Get-ChildItem -LiteralPath $dir -Recurse -File -Filter *.dart |
    Where-Object { -not (Test-GeneratedDartFile $_.Name) }
}

$results = foreach ($file in $files) {
  $stats = Get-EffectiveLineStats -FilePath $file.FullName
  [PSCustomObject]@{
    relative_path = Get-RelativePathCompat -BasePath $repoRoot -TargetPath $file.FullName
    total_lines = $stats.total_lines
    non_empty_lines = $stats.non_empty_lines
    effective_lines = $stats.effective_lines
  }
}

$grouped = $results |
  Group-Object {
    $relative = $_.relative_path.Replace('\', '/')
    if ($relative.StartsWith('apps/')) {
      return ($relative -split '/')[1]
    }
    if ($relative.StartsWith('packages/')) {
      return ($relative -split '/')[1]
    }
    return 'other'
  } |
  Sort-Object Name

$summary = [PSCustomObject]@{
  generated_at = (Get-Date).ToString('s')
  roots = @(
    'apps/*/lib'
    'packages/*/lib'
  )
  exclude = @(
    'tests'
    'tool scripts'
    'generated *.g.dart'
    'generated *.freezed.dart'
    'generated *.mocks.dart'
    'generated *.gr.dart'
    'generated_plugin_registrant.dart'
  )
  file_count = @($results).Count
  total_lines = ($results | Measure-Object -Property total_lines -Sum).Sum
  non_empty_lines = ($results | Measure-Object -Property non_empty_lines -Sum).Sum
  effective_lines = ($results | Measure-Object -Property effective_lines -Sum).Sum
  breakdown = @(
    $grouped | ForEach-Object {
      [PSCustomObject]@{
        scope = $_.Name
        file_count = $_.Count
        total_lines = ($_.Group | Measure-Object -Property total_lines -Sum).Sum
        non_empty_lines = ($_.Group | Measure-Object -Property non_empty_lines -Sum).Sum
        effective_lines = ($_.Group | Measure-Object -Property effective_lines -Sum).Sum
      }
    }
  )
}

if ($Json) {
  $summary | ConvertTo-Json -Depth 6
  exit 0
}

Write-Host 'Effective Source Line Count'
Write-Host "Repo: $repoRoot"
Write-Host 'Included roots: apps/*/lib, packages/*/lib'
Write-Host 'Excluded: tests, tool scripts, common generated Dart files'
Write-Host ''
Write-Host ("Files:           {0}" -f $summary.file_count)
Write-Host ("Total lines:     {0}" -f $summary.total_lines)
Write-Host ("Non-empty lines: {0}" -f $summary.non_empty_lines)
Write-Host ("Effective lines: {0}" -f $summary.effective_lines)
Write-Host ''
Write-Host 'Breakdown:'

foreach ($item in $summary.breakdown) {
  Write-Host (
    "  - {0}: files={1}, total={2}, non-empty={3}, effective={4}" -f
    $item.scope,
    $item.file_count,
    $item.total_lines,
    $item.non_empty_lines,
    $item.effective_lines
  )
}

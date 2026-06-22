param(
	[string[]]$Roots = @("main.tscn", "src")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Get-Location).Path
$banned = @(
	"res://.godot/imported",
	"res://assets/MATCH3美术资产"
)
$failures = New-Object System.Collections.Generic.List[string]

function Resolve-ResPath {
	param([string]$Path)
	if (-not $Path.StartsWith("res://")) {
		return $null
	}
	$relative = $Path.Substring("res://".Length).Replace("/", [IO.Path]::DirectorySeparatorChar)
	return Join-Path $repo $relative
}

function Get-TscnFiles {
	param([string[]]$ScanRoots)
	$files = New-Object System.Collections.Generic.List[string]
	foreach ($rootPath in $ScanRoots) {
		if (Test-Path -LiteralPath $rootPath -PathType Leaf) {
			if ($rootPath.EndsWith(".tscn")) {
				$files.Add((Resolve-Path -LiteralPath $rootPath).Path)
			}
			continue
		}
		if (Test-Path -LiteralPath $rootPath -PathType Container) {
			Get-ChildItem -LiteralPath $rootPath -Recurse -Filter "*.tscn" | ForEach-Object {
				$files.Add($_.FullName)
			}
		}
	}
	return $files
}

$sceneFiles = @(Get-TscnFiles -ScanRoots $Roots)
foreach ($scene in $sceneFiles) {
	$lineNumber = 0
	foreach ($line in Get-Content -LiteralPath $scene -Encoding UTF8) {
		$lineNumber += 1
		foreach ($match in [regex]::Matches($line, 'path="(res://[^"]+)"')) {
			$resPath = $match.Groups[1].Value
			foreach ($bannedPrefix in $banned) {
				if ($resPath.StartsWith($bannedPrefix)) {
					$failures.Add("${scene}:${lineNumber}: banned resource path $resPath")
				}
			}
			$fsPath = Resolve-ResPath -Path $resPath
			if ($fsPath -and -not (Test-Path -LiteralPath $fsPath)) {
				$failures.Add("${scene}:${lineNumber}: missing resource $resPath")
			}
		}
	}
}

if ($failures.Count -gt 0) {
	foreach ($failure in $failures) {
		Write-Error "[SceneResources] $failure"
	}
	exit 1
}

Write-Host "[SceneResources] OK - scanned $($sceneFiles.Count) TSCN files"
exit 0

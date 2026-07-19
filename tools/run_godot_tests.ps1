param(
	[string]$GodotBin = $env:GODOT_BIN,
	[string[]]$Tests = @(),
	[string]$TestPattern = "*_test.gd",
	[int]$TimeoutSec = 60,
	[string]$SaveRoot = "tmp/test-saves",
	[string]$LogRoot = "tmp/test-logs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-GodotBin {
	param([string]$Candidate)
	if ($Candidate -and (Test-Path -LiteralPath $Candidate)) {
		return (Resolve-Path -LiteralPath $Candidate).Path
	}

	$cmd = Get-Command godot -ErrorAction SilentlyContinue
	if ($cmd -and $cmd.Source) {
		return $cmd.Source
	}

	$proc = Get-CimInstance Win32_Process |
		Where-Object { ($_.Name -like "*godot*" -or $_.ExecutablePath -like "*Godot*") -and $_.ExecutablePath } |
		Select-Object -First 1
	if ($proc -and $proc.ExecutablePath -and (Test-Path -LiteralPath $proc.ExecutablePath)) {
		return $proc.ExecutablePath
	}

	throw "Godot executable not found. Pass -GodotBin or set GODOT_BIN."
}

function Get-TestScripts {
	param([string[]]$Requested, [string]$Pattern)
	if ($Requested.Count -gt 0) {
		return $Requested | ForEach-Object {
			if ($_ -like "res://*") { $_.Substring("res://tests/".Length) } else { Split-Path $_ -Leaf }
		}
	}
	return Get-ChildItem -Path "tests" -Filter $Pattern |
		Where-Object { $_.Name -notin @("capture_runtime_scene.gd", "capture_album_scene.gd", "visual_scene_runner.gd") } |
		Sort-Object Name |
		ForEach-Object { $_.Name }
}

function Stop-ProcessTree {
	param([int]$ProcessId)
	$children = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
		Where-Object { $_.ParentProcessId -eq $ProcessId } |
		Select-Object -ExpandProperty ProcessId)
	foreach ($childId in $children) {
		Stop-ProcessTree -ProcessId $childId
	}
	$target = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
	if ($target -ne $null) {
		Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
	}
}

function Invoke-GodotTest {
	param(
		[string]$Godot,
		[string]$TestName,
		[string]$SaveDir,
		[string]$OutputDir,
		[int]$Timeout
	)

	$safeName = [IO.Path]::GetFileNameWithoutExtension($TestName) -replace "[^A-Za-z0-9_.-]", "_"
	$stdoutPath = Join-Path $OutputDir "$safeName.out.log"
	$stderrPath = Join-Path $OutputDir "$safeName.err.log"
	$savePath = (Join-Path $SaveDir "$safeName.cfg").Replace("\", "/")

	# Start-Process works on Windows PowerShell 5.1, where ProcessStartInfo.ArgumentList
	# does not exist and direct redirected ProcessStartInfo launches can hang Godot.
	$oldSavePath = $env:MATCH3_SAVE_PATH
	$oldSeed = $env:MATCH3_TEST_SEED
	$oldLocale = $env:MATCH3_TEST_LOCALE
	$env:MATCH3_SAVE_PATH = $savePath
	$env:MATCH3_TEST_SEED = "20260622"
	$env:MATCH3_TEST_LOCALE = "zh_CN"
	$proc = $null
	try {
		$proc = Start-Process -FilePath $Godot `
			-ArgumentList @("--headless", "--fixed-fps", "60", "--path", ".", "--script", "res://tests/$TestName") `
			-WorkingDirectory (Get-Location).Path `
			-RedirectStandardOutput $stdoutPath `
			-RedirectStandardError $stderrPath `
			-PassThru `
			-WindowStyle Hidden
	} finally {
		$env:MATCH3_SAVE_PATH = $oldSavePath
		$env:MATCH3_TEST_SEED = $oldSeed
		$env:MATCH3_TEST_LOCALE = $oldLocale
	}
	$completed = $proc.WaitForExit($Timeout * 1000)
	if (-not $completed) {
		Stop-ProcessTree -ProcessId $proc.Id
		Start-Sleep -Milliseconds 200
		try {
			"TIMEOUT after ${Timeout}s" | Add-Content -LiteralPath $stderrPath -Encoding UTF8
		} catch {
			# A child process can briefly retain the redirected stream after termination.
		}
		return @{ Name = $TestName; Ok = $false; Reason = "timeout"; ExitCode = $null }
	}
	$proc.Refresh()
	$stdout = Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue
	$stderr = Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue
	$combined = "$stdout`n$stderr"
	# Some legacy SceneTree tests quit during renderer teardown. Treat those
	# known engine-exit diagnostics as warnings; script errors and all other
	# engine errors still fail the test below.
	$testOutput = (($combined -split "`r?`n") | Where-Object {
		$_ -notmatch "ObjectDB instances leaked at exit" -and
		$_ -notmatch "resources still in use at exit" -and
		$_ -notmatch "RID allocations.*leaked at exit" -and
		$_ -notmatch "^\s+at: (cleanup|clear)"
	}) -join "`n"
	# On Windows PowerShell 5.1, Start-Process with redirected console output can
	# return a completed Process whose ExitCode is null. The test scripts report
	# failures through Godot errors, which are checked below.
	[int]$exitCode = if ($null -eq $proc.ExitCode) { 0 } else { [int]$proc.ExitCode }

	$badPatterns = @(
		"SCRIPT ERROR",
		"ERROR:",
		"Parse Error",
		"Resource file not found",
		"Failed loading resource",
		"Leaked instance"
	)
	$engineError = $false
	foreach ($pattern in $badPatterns) {
		if ($testOutput -match [regex]::Escape($pattern)) {
			$engineError = $true
			break
		}
	}

	$ok = $exitCode -eq 0 -and -not $engineError
	$reason = if ($ok) { "ok" } elseif ($exitCode -ne 0) { "exit:$exitCode" } else { "engine-error" }
	return @{ Name = $TestName; Ok = $ok; Reason = $reason; ExitCode = $exitCode }
}

$godot = Resolve-GodotBin -Candidate $GodotBin
$saveDir = Join-Path (Get-Location) $SaveRoot
$logDir = Join-Path (Get-Location) $LogRoot
New-Item -ItemType Directory -Force -Path $saveDir, $logDir | Out-Null

$testNames = @(Get-TestScripts -Requested $Tests -Pattern $TestPattern)
if ($testNames.Count -eq 0) {
	throw "No tests matched $TestPattern"
}

Write-Host "[GodotTests] Godot: $godot"
Write-Host "[GodotTests] Running $($testNames.Count) tests with ${TimeoutSec}s timeout"

$results = @()
foreach ($testName in $testNames) {
	Write-Host "[GodotTests] $testName"
	$results += Invoke-GodotTest -Godot $godot -TestName $testName -SaveDir $saveDir -OutputDir $logDir -Timeout $TimeoutSec
}

$failed = @($results | Where-Object { -not $_.Ok })
Write-Host "[GodotTests] Passed: $($results.Count - $failed.Count) / $($results.Count)"
if ($failed.Count -gt 0) {
	foreach ($item in $failed) {
		Write-Error "[GodotTests] FAILED $($item.Name): $($item.Reason)"
	}
	exit 1
}

exit 0

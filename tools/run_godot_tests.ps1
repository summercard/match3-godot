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

	$psi = [System.Diagnostics.ProcessStartInfo]::new()
	$psi.FileName = $Godot
	$psi.WorkingDirectory = (Get-Location).Path
	$psi.UseShellExecute = $false
	$psi.RedirectStandardOutput = $true
	$psi.RedirectStandardError = $true
	$psi.Environment["MATCH3_SAVE_PATH"] = $savePath
	$psi.Environment["MATCH3_TEST_SEED"] = "20260622"
	foreach ($arg in @("--headless", "--fixed-fps", "60", "--path", ".", "--script", "res://tests/$TestName")) {
		[void]$psi.ArgumentList.Add($arg)
	}

	$proc = [System.Diagnostics.Process]::new()
	$proc.StartInfo = $psi
	[void]$proc.Start()
	$completed = $proc.WaitForExit($Timeout * 1000)
	if (-not $completed) {
		try { $proc.Kill($true) } catch { $proc.Kill() }
		"TIMEOUT after ${Timeout}s" | Set-Content -LiteralPath $stderrPath -Encoding UTF8
		return @{ Name = $TestName; Ok = $false; Reason = "timeout"; ExitCode = $null }
	}

	$stdout = $proc.StandardOutput.ReadToEnd()
	$stderr = $proc.StandardError.ReadToEnd()
	$stdout | Set-Content -LiteralPath $stdoutPath -Encoding UTF8
	$stderr | Set-Content -LiteralPath $stderrPath -Encoding UTF8
	$combined = "$stdout`n$stderr"

	$badPatterns = @(
		"SCRIPT ERROR",
		"ERROR:",
		"Parse Error",
		"Resource file not found",
		"Failed loading resource",
		"ObjectDB instances leaked",
		"Resources still in use",
		"Leaked instance"
	)
	$engineError = $false
	foreach ($pattern in $badPatterns) {
		if ($combined -match [regex]::Escape($pattern)) {
			$engineError = $true
			break
		}
	}

	$ok = $proc.ExitCode -eq 0 -and -not $engineError
	$reason = if ($ok) { "ok" } elseif ($proc.ExitCode -ne 0) { "exit:$($proc.ExitCode)" } else { "engine-error" }
	return @{ Name = $TestName; Ok = $ok; Reason = $reason; ExitCode = $proc.ExitCode }
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

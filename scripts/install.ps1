$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & aftman install
    if ($LASTEXITCODE -ne 0) { throw 'Aftman install failed' }
    if ($IsMacOS) {
        # Aftman rewrites its tool launchers in place, and macOS then kills them on
        # launch (exit 137). Replacing each with a fresh copy gives it a new file.
        Get-ChildItem (Join-Path $HOME '.aftman/bin') -File | ForEach-Object {
            $fresh = "$($_.FullName).fresh"
            Copy-Item -LiteralPath $_.FullName -Destination $fresh
            Move-Item -LiteralPath $fresh -Destination $_.FullName -Force
            # Keep it writable, or the next Aftman install can't replace it.
            & chmod u+w $_.FullName
        }
    }
    if (-not (Test-Path -LiteralPath globalTypes.d.luau)) {
        Invoke-WebRequest 'https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau' -OutFile globalTypes.d.luau
    }
    & wally install
    if ($LASTEXITCODE -ne 0) { throw 'Wally install failed' }
    & rojo sourcemap default.project.json --output sourcemap.json
    if ($LASTEXITCODE -ne 0) { throw 'Rojo sourcemap failed' }
    & wally-package-types --sourcemap sourcemap.json Packages/
    if ($LASTEXITCODE -ne 0) { throw 'Package type export failed' }
    & wally-package-types --sourcemap sourcemap.json ServerPackages/
    if ($LASTEXITCODE -ne 0) { throw 'Server package type export failed' }
} finally {
    Pop-Location
}

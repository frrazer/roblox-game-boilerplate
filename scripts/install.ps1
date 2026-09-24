$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & aftman install
    if ($LASTEXITCODE -ne 0) { throw 'Aftman install failed' }
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

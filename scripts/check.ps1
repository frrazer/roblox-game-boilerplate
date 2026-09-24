$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    if (-not (Test-Path -LiteralPath globalTypes.d.luau) -or -not (Test-Path -LiteralPath Packages)) {
        throw 'Project is not installed. Run ./scripts/install.ps1 first.'
    }
    & stylua src
    if ($LASTEXITCODE -ne 0) { throw 'StyLua formatting failed' }
    & rojo sourcemap default.project.json --output sourcemap.json
    if ($LASTEXITCODE -ne 0) { throw 'Rojo sourcemap failed' }
    & luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sourcemap.json ./src
    if ($LASTEXITCODE -ne 0) { throw 'Luau analysis failed' }
    New-Item -ItemType Directory -Force build | Out-Null
    & rojo build default.project.json --output build/code.rbxlx
    if ($LASTEXITCODE -ne 0) { throw 'Rojo build failed' }
} finally {
    Pop-Location
}

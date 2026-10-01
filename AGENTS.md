# Game Boilerplate — agent instructions

## Code style

- Do not add comments to code. Luau directives such as `--!strict` are allowed.
- Keep `--!strict` at the top of every Luau file. Run `./scripts/check.ps1` before handing off code changes.
- Format with StyLua (tabs, 110 columns, double quotes). Never edit generated `Packages/`, `ServerPackages/`, `build/` or `sourcemap.json`, or vendored code in `vendor/`.

### Naming

| Thing | Convention | Example |
| --- | --- | --- |
| Files, modules, folders | PascalCase, matching the returned table | `PurchaseService.luau`, `RateLimit.luau` |
| Services and controllers | PascalCase ending in `Service` or `Controller`; `Name` matches the file | `DataService`, `UIController` |
| Types | PascalCase; export shared ones with `export type` | `PlayerData.Data`, `Types.Screen` |
| Public functions, methods, fields and signals | PascalCase | `DataService:GetData`, `DataService.PlayerLoaded` |
| Private fields | `_camelCase` | `self._trove` |
| Local variables and local functions | camelCase | `local activeSessions`, `local function refresh()` |
| Constants | camelCase locals, or PascalCase keys in a frozen `Config` table | `local maxReceipts = 100`, `GameConfig.Name` |
| Unused parameters | `_` prefix | `_self`, `_player` |
| Packets | PascalCase verb or event name | `Buy`, `RoundStarted` |
| Tags and attributes | PascalCase | `Spinner`, `SpinSpeed`, `Ready` |
| Services and packages | Local named after the service or package | `local Players = game:GetService("Players")`, `local Trove = require(...Trove)` |

- Name things for what they are, not how they are used: `Catalog`, not `ShopHelper`.
- Avoid abbreviations except universally understood ones (`id`, `ui`, `dt`).
- Booleans read as questions: `isOpen`, `hasLoaded`, `StartsOpen`.

## Scope

- This is a generic game boilerplate. Keep it game-agnostic: no genre-specific systems, assets or design decisions unless the user asks. Ask before making material design decisions.
- Explicit user instructions take precedence.

## Setup and checks

Tools are pinned in `aftman.toml`: Rojo, Wally, StyLua, wally-package-types and luau-lsp. The only prerequisite is [Aftman](https://github.com/LPGhatguy/aftman).

```powershell
./scripts/install.ps1
rojo serve default.project.json --address 127.0.0.1
```

- `scripts/install.ps1` installs the tools, downloads the Roblox type definitions (`globalTypes.d.luau`, Git-ignored) if missing, runs `wally install`, then `wally-package-types` so package types (such as `Signal.Signal<T...>`) are visible to strict code. Run it on a fresh clone and after changing `wally.toml`; never run bare `wally install`. On first run Aftman may ask the user to trust each tool.
- Connect the Rojo plugin in Studio to `localhost:34873`. Once the game has a place, add `"servePlaceIds": [<placeId>]` to `default.project.json`.
- In Studio, enable **Game Settings > Security > Enable Studio Access to API Services** (the place must be published). Without it (or in an unpublished place), ProfileStore falls back to in-memory mock data: everything works, but data resets when Play stops, and `DataService` warns once. Live servers always have DataStore access.
- In Play, output shows `[Game Boilerplate] Server services ready`, `Client controllers ready` and a Packet round trip. Both Bootstraps set a `Ready` attribute.
- `./scripts/check.ps1` is the one command to run after every change. It formats `src` with StyLua, regenerates the sourcemap, runs luau-lsp type and lint analysis, and does a Rojo build. Fix every error it reports and rerun it until it passes.
- `rojo build` output is code-only, not a replacement for the authored place.

## Layout

| Files | Studio destination | Contents |
| --- | --- | --- |
| `src/server` | `ServerScriptService` | `Bootstrap.server.luau`, `Registry.luau`, `Services/`, `Data/`, `Components/` (create when needed) |
| `src/client` | `StarterPlayer.StarterPlayerScripts` | `Bootstrap.client.luau`, `Registry.luau`, `Controllers/`, `Components/` |
| `src/shared` | `ReplicatedStorage` | `Lifecycle`, `Packet/`, `Packets`, `Config/`, `Utils/` |
| `Packages` | `ReplicatedStorage.Packages` | Generated Wally dependencies |
| `ServerPackages` | `ServerScriptService.ServerPackages` | Generated server-only Wally dependencies |
| `vendor/Replica` | `ReplicatedStorage.ReplicaClient`, `ReplicatedStorage.ReplicaShared`, `ServerScriptService.ReplicaServer` | Vendored Replica (see Packages) |

- Edit code on disk; Rojo syncs it. Code lives directly in the service roots, with no Client/Server/Shared wrapper folders.
- Rojo owns mapped folders. Unknown children at service roots are preserved. Workspace, lighting, GUI and other art are edited and saved in Studio, not on disk.
- Tag authoring-only content in Workspace (prefab libraries, reference models, anything the game reads from a copy elsewhere) `EditorOnly`. `Bootstrap.server.luau` moves tagged instances into `ServerStorage.EditorOnly` before any system starts, so they stay editable in Studio but are never replicated to players. Never tag something code reads from Workspace.
- Server-only code (secrets, rules, data) belongs in `src/server`. Everything in `src/shared` is visible to clients.
- Put tunable constants in `src/shared/Config` as frozen tables, or in server modules if clients must not see them.
- Put pure logic in plain modules (such as `src/server/Data`) with no service dependencies.
- Keep `src/shared` tidy: its root holds only the framework (`Lifecycle`, `Packet`, `Packets`) and folders. Reusable, game-agnostic helpers used by more than one system go in `src/shared/Utils` (such as `Utils/RateLimit`), one module per helper. Server-only helpers go in `src/server/Utils`. Helpers used by a single system stay inside that system's folder.

## Systems

A system is a service (server) or controller (client): a ModuleScript table run by `src/shared/Lifecycle.luau`.

- **Services** own state, validation and game rules. Never trust the client: validate every request on the server.
- **Controllers** own input, camera, UI and presentation. They request changes from services; they never decide outcomes.

### When to make a new system

Make a new service when a feature has all of:

- its own state that other code should change only through its methods (a shop's stock, a round's timer, a player's inventory),
- its own lifetime: connections, per-player setup and cleanup, or timers,
- its own requests from clients.

On the client, all UI belongs to one `UIController`, with one child module per screen (see UI below). Make a separate controller only for non-UI client behaviour with its own state and per-frame work: `CameraController`, `VehicleController`, `PlacementController`. Screens reach those controllers through the registry.

Do not make a system for:

- part of an existing feature: add a child module to that system instead (see below),
- behaviour attached to tagged instances: use a component,
- constants: use `src/shared/Config`,
- stateless helpers: use a plain module next to the code that uses it, or in `src/shared/Utils` if several systems need it.

If a system's methods start being about two unrelated things, or other systems keep reaching into its data, split it into two systems.

### Structuring a system across files

Keep each system's concerns in separate files. Once a system has more than one concern (or its file passes about 300 lines), turn it into a folder. Rojo maps a folder containing `init.luau` to a single ModuleScript with the other files as its children, so the registry `require` does not change.

```text
src/server/Services/ShopService/
	init.luau
	Catalog.luau
	Purchasing.luau
	Types.luau
src/client/Controllers/CameraController/
	init.luau
	Modes.luau
	Smoothing.luau
```

| File | Role |
| --- | --- |
| `init.luau` | The only file with `Name`, `Init`, `Start` and `Destroy`, and the only one in `Registry.luau`. Owns the system's state, connections and packet handlers, and routes each request to a child module. |
| Child modules (`Catalog`, `Purchasing`, `Modes`, ...) | One concern each. Plain modules: no lifecycle, no connections or state at module level, never registered. They receive what they need (the registry, the player, state) as arguments. |
| `Types.luau` | Types shared between the system's files. |

- Only `init.luau` wires children together. Children may require `Types` and pure siblings such as `Catalog`, but never `init.luau` and never in a cycle.
- Split by responsibility, not by line count: data lookup, validation and mutation, networking, and presentation belong in different files.
- Non-UI controllers follow the same pattern, for example `CameraController/init.luau` with `Modes.luau` and `Smoothing.luau`.

```lua
--!strict

local Catalog = require(script.Parent.Catalog)
local Types = require(script.Parent.Types)

local Purchasing = {}

function Purchasing.Buy(context: Types.Context, player: Player, itemId: string): boolean
	local item = Catalog.Get(itemId)
	if not item then
		return false
	end
	return context.Services.DataService:AdjustCash(player, -item.Price)
end

return Purchasing
```

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local Purchasing = require(script.Purchasing)
local Types = require(script.Types)

local ShopService = { Name = "ShopService" }
local context: Types.Context = { Services = {} }

function ShopService.Init(_self: any, registry: { [string]: any })
	context.Services = registry
end

function ShopService.Start(_self: any)
	Packets.Buy.OnServerInvoke = function(player: Player, itemId: string)
		return Purchasing.Buy(context, player, itemId)
	end
end

function ShopService.Destroy(_self: any)
	Packets.Buy.OnServerInvoke = nil
end

return ShopService
```

### UI

`UIController` (`src/client/Controllers/UIController`) owns every screen. It ships with no screens; its `modules` table is empty.

**Build UI in Studio, not in code.** Prefer ScreenGuis authored in StarterGui, with code finding and driving them. Only create UI in code (`Instance.new`, React or similar) if the user says they prefer that.

- Use the Roblox Studio MCP tools to create and edit UI in StarterGui: inspect the existing tree, add ScreenGuis and elements, and take screenshots to check the result.
- If no Roblox Studio MCP is connected, do not fall back to building UI in code. Tell the user to set it up using https://create.roblox.com/docs/studio/mcp, and continue with the code side (the screen module) meanwhile.
- UI in StarterGui is saved in the place file, not on disk; Rojo does not sync it. Remind the user to save the place after UI changes.

```text
src/client/Controllers/UIController/
	init.luau
	Types.luau
	Screens/
		<Name>.luau
```

- **Adding a screen:**
  1. Create a ScreenGui in StarterGui named after the screen.
  2. Add `Screens/<Name>.luau` using the template below.
  3. Add `<Name> = require(script.Screens.<Name>)` to the `modules` table in `init.luau`.
- **What `init.luau` does:**
  - Waits up to 15 seconds for each ScreenGui with `WaitFor`. If one is missing, it warns with the expected path and disables only that screen.
  - Sets `ResetOnSpawn = false` so screens survive respawns.
  - Creates each screen, tracks which are open, closes other modals when a modal opens, and destroys everything in `Destroy`.
- **API for other systems:** `UIController:Open(name)`, `UIController:Close(name)` and `UIController:IsOpen(name)`.
- **Screen contract** (`Types.luau`):
  - A screen module returns `{ new = function(context, gui): Screen }`.
  - The screen object has `Modal`, `StartsOpen`, `Open`, `Close` and `Destroy`.
  - Non-modal screens (HUD, notifications) can be open together. Opening a modal screen (shop, settings) closes other modals.
  - Screens may hold state because they are created objects. They own their connections through a Trove and clean them up in `Destroy`.
- **What screens receive:** `context.Controllers` (the controller registry), `context.Open` and `context.Close`. Screens never require each other; open another screen through `context.Open`.
- **What screens may do:** send requests through `Packets` and display player data through `context.Controllers.DataController` (see Player data). They never decide outcomes.
- **Finding elements:** look up authored elements by name inside `gui` and check their class (`IsA`) before use, so a renamed element fails visibly rather than erroring.
- **Complex client logic** such as a placement preview goes in its own controller, which the screen calls through `context.Controllers`.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local Hud = {}

function Hud.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()

	trove:Add(context.Controllers.DataController:Observe({ "Cash" }, function(cash: any)
		local label = gui:FindFirstChild("Cash", true)
		if label and label:IsA("TextLabel") then
			label.Text = if type(cash) == "number" then string.format("%d", cash) else "..."
		end
	end))

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Hud
```

### Adding a system

1. Create `src/server/Services/NameService.luau` or `src/client/Controllers/NameController.luau`.
2. Return a table with a unique `Name` matching the file name, and optional `Init`, `Start` and `Destroy`.
3. Add a `require` to that side's `Registry.luau`, after every system it depends on.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Packets = require(ReplicatedStorage.Packets)

local ExampleService: Lifecycle.System = { Name = "ExampleService" }
local services: { [string]: any } = {}

function ExampleService.Init(_self: Lifecycle.System, registry: { [string]: any })
	services = registry
end

function ExampleService.Start(_self: Lifecycle.System)
	Packets.GetCash.OnServerInvoke = function(player: Player)
		local data = services.DataService:GetData(player)
		return if data then data.Cash else 0
	end
end

function ExampleService.Destroy(_self: Lifecycle.System)
	Packets.GetCash.OnServerInvoke = nil
end

return ExampleService
```

The matching packet in `Packets.luau` would be `GetCash = Packet("GetCash"):Response(Packet.NumberF64):RateLimit(5, 1)`, and a controller calls it with `local cash = Packets.GetCash:Fire()`.

### Lifecycle rules

- Order: every system's `Init` runs in registry order, then every `Start` in registry order. Startup happens once per session; there is no hot reload.
- `Init(self, registry)` receives the complete name-to-system table. Store it and set up local state only. Do not call other systems here: they may not be initialised yet.
- `Start(self)` connects events, binds packets and begins work. Other systems are safe to call from here on.
- Hooks must return promptly. Never yield or run permanent loops inside them; use `task.spawn` or connections instead.
- `Destroy(self)` disconnects connections, destroys instances and cancels owned threads. It must tolerate a partially completed `Init` and being called when `Start` never ran.
- Module loading must have no side effects: no connections, instances or yields at require time.
- Errors in `Init`/`Start` are reported as `[System.Phase]`; the lifecycle then destroys initialised systems in reverse order and stops startup. Duplicate names and repeated starts are rejected.
- The server calls `Destroy` through `BindToClose`; the client bootstrap does so when destroyed. Both bootstraps set a `Ready` attribute once startup succeeds.

### Using other systems

- Access other systems through the registry captured in `Init` (`services.DataService:GetData(player)`), not by requiring their modules directly. Direct requires break when the registry order changes and hide dependencies.
- Dependencies must point one way. If two systems need each other, give one a `Signal` (`ReplicatedStorage.Packages.Signal`) that the other connects to in `Start`, as `DataService.PlayerLoaded` does.
- Clean up with Trove (`ReplicatedStorage.Packages.Trove`), as `AppController` does, or with plain connection lists.

### Components

Use a component for behaviour attached to many tagged instances (doors, pickups, hazards, spinners). Use a system for game-wide state. Components use the Component package and CollectionService tags.

- Put client components in `src/client/Components` and server components in `src/server/Components`. Add the module's `require` to the `factories` list in `ComponentController` or `ComponentService`.
- A component module returns a factory `function(registry)` that creates and returns the class. The loader calls it in `Start`, so requiring the module has no side effects, and the component can reach systems through the registry.
- Cast the class to `any` and type `self` explicitly, because the package's inferred types do not work in strict mode. `src/client/Components/Spinner.luau` is the example: tag a part `Spinner` and optionally set a `SpinSpeed` attribute (degrees per second).
- Use `Construct` for setup, `Start` for connections, `Stop` for cleanup, and `HeartbeatUpdate`/`RenderSteppedUpdate` for per-frame work. Components start only under `workspace` and `Players` unless `Ancestors` is given.
- Server components own authoritative behaviour; client components are presentation only. Destroying the class stops tag tracking but does not stop already running instances, so it is suitable only at shutdown.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)

type Door = { Instance: Instance }

return function(services: { [string]: any })
	local Door = Component.new({ Tag = "Door" }) :: any

	function Door.Start(self: Door) end

	function Door.Stop(self: Door) end

	return Door
end
```

### Packages

Shared packages are in `ReplicatedStorage.Packages`; server-only ones in `ServerScriptService.ServerPackages`. Add new ones to `wally.toml` and run `scripts/install.ps1`. Commit `wally.toml` and `wally.lock`.

| Package | Use it for |
| --- | --- |
| `Trove` | Cleaning up connections, instances and threads owned by a system or component. |
| `Signal` | Custom events between systems. Also used by Packet for `OnServerEvent`/`OnClientEvent`. Prefer `Fire`; Packet uses `FireDeferred`. |
| `Component` | Tag-driven behaviour; see Components. |
| `Input` | Client input: `Input.Keyboard.new()`, `Input.Mouse.new()`, `Input.Gamepad.new()`, `Input.Touch.new()`, and `Input.PreferredInput.observe(callback)` to adapt UI to the current device. Create them in a controller's `Start` and `Destroy` them in `Destroy`. |
| `WaitFor` | Waiting for authored instances with a timeout, such as `WaitFor.Child(parent, "Name", 15)`. It returns a Promise: use `:andThen`/`:catch`, and on failure `warn` with the full path and leave that feature disabled rather than hanging. |
| `TableUtil` | Table helpers (`Copy`, `Sync`, `Reconcile`, `Map`, `Filter`, `Keys`, `Values`, ...). Use it instead of rewriting common helpers. |
| `ProfileStore` | Server only, used by `DataService` alone. |
| `Replica` | Replicating player data to clients, used by `DataService` and `DataController`; see Player data. |

Promise, Symbol and Signal also arrive as dependencies of Component and WaitFor. Do not add packages that duplicate these, Packet or Replica (no Comm, Net, TypedRemote, ReplicaService, Janitor or Knit) without the user's agreement.

Replica ([MadStudioRoblox/Replica](https://github.com/MadStudioRoblox/Replica)) is not on Wally, so it is vendored unmodified in `vendor/Replica` at commit `9cae236`, with its Apache-2.0 `LICENSE`. It requires itself from fixed paths, so `default.project.json` maps it to `ReplicatedStorage.ReplicaClient`, `ReplicatedStorage.ReplicaShared` and `ServerScriptService.ReplicaServer`; do not move it. `vendor/.luaurc` turns off type checking for it. To update, replace `src/`, `LICENSE` and `README.md` with a newer upstream commit, update the commit above, and run `./scripts/check.ps1` and a Play test. Do not use Wally forks of Replica without checking them.

### Networking

- Define every Packet channel in `src/shared/Packets.luau`. The server errors if a packet is defined after the first frame.
- `Packet(name, ...types)` declares an event; `:Response(...types)` makes it a request with a 10-second default timeout. Raise `ResponseTimeout` for anything that waits on a save.
- Services bind `OnServerEvent`/`OnServerInvoke` in `Start` and clear them in `Destroy`. Validate the sender, every argument and range on the server.
- Rate limit every packet the client can send by chaining `:RateLimit(count, window)`, allowing `count` calls per `window` seconds per player: `Buy = Packet("Buy", Packet.String):Response(Packet.Boolean8):RateLimit(5, 1)`. The server drops excess calls before they reach handlers (warning in Studio). A dropped request gets no reply, so the client's `Fire` returns `ResponseTimeoutValue` after `ResponseTimeout`; debounce buttons on the client so normal use never hits the limit.
- For limits that are not per packet (per action, per target, shared across packets), use `Utils/RateLimit` directly: `local limiter = RateLimit.new(3, 10)`, then `limiter:Allow(player)`. Call `limiter:Remove(player)` when the player leaves.
- Packet is for actions and Replica is for state. Clients send requests and receive events through Packet; the server's player data reaches clients through Replica (see Player data). Do not add packets that mirror data a replica already holds.
- Prefer Packet over RemoteEvents and RemoteFunctions. Use attributes only for simple values that belong to an instance, such as a plot's owner or the Bootstraps' `Ready`.

### Player data

- Only `DataService` touches ProfileStore. Other services call `GetData`, `Set`, `AdjustCash`, `GetReplica`, `RequestSave` and `WaitForSave`.
- Each loaded player's profile data is wrapped in a `PlayerData` replica that replicates to that player only. The replica's `Data` is the profile's data table, so a change made through the replica is saved as well as replicated.
- Change data that clients show only through the replica: `DataService:Set(player, { "Cash" }, 10)`, `DataService:AdjustCash(player, 10)`, or `DataService:GetReplica(player)` for `SetValues`, `TableInsert` and `TableRemove`. Assigning to the data table directly saves but never reaches the client. Only server bookkeeping (`SchemaVersion`, `LastSeenAt`, `Receipts`) and final writes in `PlayerReleasing` are written directly; clients must not read those fields.
- Replicated data cannot contain arrays with gaps or keys that are not strings or numbers.
- The whole data table is sent once when the player loads; after that each change sends only its path and value to the owner. `DataService:Set` skips unchanged non-table values. Keep traffic small: change the deepest path that changed rather than setting a whole table, group related changes with `SetValues`, and never change player data every frame (per-frame values belong in Packet events or client-side state).
- On the client, read data through `DataController`: `Get(path?)` returns the current value (nil until loaded), `Observe(path, callback)` calls `callback(value)` once the data loads and after every change at, above or below `path`, and returns a connection to add to a Trove. `Loaded` fires once with the data table and `IsLoaded()` checks it. Treat values from `Get` as read-only.
- Data that other players should see (leaderboards, public stats) needs its own replica with `:Replicate()`, or an attribute; never replicate another player's `PlayerData`.
- For per-player setup, connect to `DataService.PlayerLoaded(player, data)` in `Start`, not `Players.PlayerAdded` (which fires before data exists). Loading always yields, so every service that connects in `Start` sees every player, including those already in the server.
- For per-player cleanup, connect to `DataService.PlayerReleasing(player, data)`. It fires just before the session is saved and released, on leave and on shutdown. Write final state into `data` there, without yielding. `DataService` is registered first, so it is destroyed last; do not disconnect `PlayerLoaded`/`PlayerReleasing` connections in your own `Destroy`, or the shutdown release will miss you.
- Check `GetData` for nil in every handler, and never keep the data table across a yield. On the client, show data through `DataController:Observe` so nothing is shown before it loads.
- When adding a field, update `Data`, `Template` and `Validate` in `src/server/Data/PlayerData.luau` together. Add an explicit migration before changing `SchemaVersion`. Never reset progress for invalid data.

### Purchases

`PurchaseService` owns `MarketplaceService.ProcessReceipt`. Nothing else may set it; Roblox allows only one handler.

- **Adding a developer product:** add `[productId] = function(player, services): boolean` to `src/server/Services/PurchaseService/Products.luau`. Return `true` once the reward is granted, `false` to have Roblox retry later.
- **Grants change only the player's profile data** (through `services.DataService`), such as `services.DataService:AdjustCash(player, 500)`. The receipt ID is recorded in the same profile (`Receipts`), and the purchase is confirmed only after one save contains both, so a crash cannot grant twice or lose a paid reward. Rewards outside the profile (server-wide effects) are not protected this way; ask the user before adding them.
- Grants must not yield, prompt or wait on the player: the receipt is recorded right after the grant returns, and a yield would let a save capture the reward without it. If the player has left or their data is not loaded, the purchase stays pending and Roblox retries it when they next join.
- Prompt purchases from the client with `MarketplaceService:PromptProductPurchase(player, productId)`; never grant from a client request.
- Game passes are not receipts: check ownership with `MarketplaceService:UserOwnsGamePassAsync` on the server (and on `PromptGamePassPurchaseFinished`), not in `Products`.
- The last 100 receipt IDs are kept per player.

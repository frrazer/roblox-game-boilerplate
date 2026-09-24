--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Products = require(script.Products)

local PurchaseService = { Name = "PurchaseService" }
local registry: { [string]: any } = {}
local maxReceipts = 100

local function prune(receipts: { [string]: number })
	local ids = {}
	for purchaseId in receipts do
		table.insert(ids, purchaseId)
	end
	if #ids <= maxReceipts then
		return
	end
	table.sort(ids, function(a, b)
		return receipts[a] < receipts[b]
	end)
	for index = 1, #ids - maxReceipts do
		receipts[ids[index]] = nil
	end
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local purchaseId = tostring(receipt.PurchaseId)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local dataService = registry.DataService
	local data = player and dataService:GetData(player)
	if not player or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if data.Receipts[purchaseId] == nil then
		local grant = Products[receipt.ProductId]
		if not grant then
			warn(`[PurchaseService] No grant for product {receipt.ProductId}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, granted = pcall(grant, player, registry)
		if not ok then
			warn(`[PurchaseService] Grant for product {receipt.ProductId} failed: {granted}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if granted ~= true or dataService:GetData(player) ~= data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		data.Receipts[purchaseId] = os.time()
		prune(data.Receipts)
	end
	local saved = dataService:WaitForSave(player, function(snapshot: any)
		return type(snapshot.Receipts) == "table" and snapshot.Receipts[purchaseId] ~= nil
	end)
	return if saved
		then Enum.ProductPurchaseDecision.PurchaseGranted
		else Enum.ProductPurchaseDecision.NotProcessedYet
end

function PurchaseService.Init(_self: any, services: { [string]: any })
	registry = services
end

function PurchaseService.Start(_self: any)
	MarketplaceService.ProcessReceipt = processReceipt
end

function PurchaseService.Destroy(_self: any)
	MarketplaceService.ProcessReceipt = nil :: any
end

return PurchaseService

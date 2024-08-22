
--> Services

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

--> Includes

local ServerPackages = ServerScriptService.ServerPackages

local DataKeep = require(ServerPackages.datakeep)
local DataTemplate = require(script.DataTemplate)

export type playerObject = {
    Player: Player,
    Keep: {any},

    getData: (playerObject, key: string) -> (any),
    setData: (playerObject, key: string) -> (any),
    destroy: (playerObject) -> (),
    getCurrentSlot: (playerObject) -> (number),
    getSlotData: (playerObject, key: string) -> (any)
}

--> Module Definition
local Player = {}
Player.__index = Player

--> Variables
local keepStore = DataKeep.GetStore("PlayerData", DataTemplate):expect()
local objectStorage = {}

--> Private Functions
local function loadKeep(playerClass)
    local player = playerClass.Player

    local keep = keepStore:LoadKeep("Player_" .. player.UserId)

    keep:andThen(function(dataKeep)
        if dataKeep == nil then
            player:Kick("Data locked")
        end

        dataKeep:Reconcile()
        dataKeep:AddUserId(player.UserId)

        dataKeep.Releasing:Connect(function(releaseState) -- no clean needed-- datakeep releases internals
            releaseState
                :andThen(function()
                    player:Kick("Session released")
                end)
                :catch(function(err)
                    warn(err)
                end)
        end)

        if not player:IsDescendantOf(Players) then
            playerClass:destroy()
            return
        end
    end)

    return keep -- so they can attach to the promise
end

--> Constructor
function Player.new(player): playerObject
    if objectStorage[player] then return objectStorage[player] end

    local self = setmetatable({
        Player = player,
        Keep = {},
    }, Player)

    self.Keep = loadKeep(self)

    objectStorage[player] = self

    return self
end

--> Public Methods
function Player:getData(key: string?)
    local keep = self.Keep:expect()

    return key and keep.Data[key] or keep.Data
end

function Player:getCurrentSlot()
    local keep = self.Keep:expect()

    return keep.Data.SlotData.SelectedSlot
end

function Player:getSlotData(key: string?)
    local keep = self.Keep:expect()

    local slotData = keep.Data.SlotData['Slot'.. tostring(self:getCurrentSlot())]

    return key and slotData[key] or slotData
end

function Player:setData(key: string?, value: any)
    local keep = self.Keep:expect()

    if key then
        keep.Data[key] = value
    else
        keep.Data = value
    end

    return keep.Data[key]
end


function Player:destroy()
    local keep = self.Keep:expect()
    if not keep then return end

    keep:Release()
end

--> Connections
Players.PlayerAdded:Connect(function(player: Player)
    Player.new(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    local playerObject = Player.new(player)
    if not playerObject then return end
    playerObject:destroy()
end)

return Player
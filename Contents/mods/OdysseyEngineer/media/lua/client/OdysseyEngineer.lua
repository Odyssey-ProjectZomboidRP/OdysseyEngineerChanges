-- Functions

---@return boolean 
---@param player IsoPlayer The player
---@param weapon HandWeapon The weapon used
--- We check that the current weapon is a gun, and that the ammoType is correct
function CheckGunType(player, weapon)
    --- We get the ammoType
    local ammo = weapon:getAmmoType()
    local isAmmoValid = CorrectAmmoType(weapon)

    if weapon:isRanged() and isAmmoValid then
        return true
    end
    return false
end

---@param weapon HandWeapon The weapon we use
---@return boolean 
---return true if the ammoType is correct using `SandboxVars.TOC_Engineer.ListAmmos`
function CorrectAmmoType(weapon)
    local ammo = weapon:getAmmoType()
    local listOfAmmos = SandboxVars.TOC_Engineer.ListAmmos

    -- "OdysseyExploShells",
    -- "OdysseyExplo44",

    for i = 1, #listOfAmmos do
        if ammo == listOfAmmos[i] then
            return true
        end
    end
    return false
end

---@param weapon HandWeapon The weapon used
--- Make the gun jam, reduce condition by `SandboxVars.TOC_Engineer.ConditionReduction` amount
function SetGunStuff(weapon, bonusOfReduction)
    --- Set the gun to be jammed
    weapon:setJammed(true)
    local condition = weapon:getCondition()
    --- If the condition is less than the reduction, we set the condition to 0 to avoid fuckery
    if (condition < SandboxVars.TOC_Engineer.ConditionReduction + bonusOfReduction) then
        weapon:setCondition(0)
    else
        weapon:setCondition(condition - SandboxVars.TOC_Engineer.ConditionReduction + bonusOfReduction)
    end
end

---@return Caliber int The caliber (type) of the weapon
---@param player IsoPlayer The player
--[[ We get the `Caliber` used by `StartFire(posX, posY, posZ, radius)`. It can either be
`SandboxVars.TOC_Engineer.ShotgunFireRadius` or `SandboxVars.TOC_Engineer.PistolFireRadius` depending on the
caliber. The list of default ammos is `SandboxVars.TOC_Engineer.ListAmmos`
]]
function GetCaliber(player)
    local listOfAmmos = SandboxVars.TOC_Engineer.ListAmmos
    local weapon = player:getGunType()
    local Caliber = 0

    for i = 1, #listOfAmmos do
        if listOfAmmos[i] == "TOCShotgunShellsFire" then
            Caliber = SandboxVars.TOC_Engineer.ShotgunFireRadiusSandboxVars.TOC_Engineer.ChanceToJam

        elseif listOfAmmos[i] == "TOCBullets45Fire" then
            Caliber = SandboxVars.TOC_Engineer.PistolFireRadius
        end
    end
    return Caliber
end

---@param player IsoPlayer The player
---@param zombie IsoZombie The zombie we hit
---@return void
--[[ We get the `AimLevel` and `ReloadLevel` of the player, the pos of said player, and the pos of the zed we hit.
We then use `SandboxVars.TOC_Engineer.ReloadLevel` to check if the player is high enough to only have `SandboxVars.TOC_Engineer.ChanceToJam` to jam

Else, garanteed chance of jam & reduced condition as set by the function `SetGunStuff(weapon)`.
The condition is reduced by `SandboxVars.TOC_Engineer.ConditionReduction` and further reduced by either `SandboxVars.TOC_Engineer.BonusConditionReductionLowLevel` or ` SandboxVars.TOC_Engineer.BonusConditionReductionHighLevel`
This also use `SandboxVars.TOC_Engineer.AimingLevel` to check wether the fire start at `PlayerPos` or `ZombiePos`.

It then use `StartFire(PosX, PosY, PosZ, Caliber)` to start a fire at the positions. `Caliber` is
the radius of the fire which is gotten using `GetCaliber(player)`.
It is either `SandboxVars.TOC_Engineer.PistolFireRadius` or `SandboxVars.TOC_Engineer.ShotgunFireRadius`
]]--
function MainFunc(player, zombie)
    --- We check the aiming level, used for the pos of the fire and the condition reduction
    local AimLevel = player:getPerkLevel(Perks.Aiming)
    local ReloadLevel = player:getPerkLevel(Perks.Reloading)

    --- Get pos of player
    local PlayerPosX = player:getLlx()
    local PlayerPosY = player:getLly()
    local PlayerPosZ = player:getLlz()

    --- We get the Caliber
    local Caliber = GetCaliber(player)

    --- Get pos of zombie we hit
    local ZombiePosX = zombie:getLlX()
    local ZombiePosY = zombie:getLlY()
    local ZombiePosZ = zombie:getLlZ()
    if CheckGunType(player, weapon) then
        if (reloadLevel < SandboxVars.TOC_Engineer.ReloadLevel) then
            --- We set the gun to be jammed and the condition is reduced by a bonus 2
            SetGunStuff(player:getPrimaryHandItem(), SandboxVars.TOC_Engineer.BonusConditionReductionLowLevel)
        --- Else, only a certain chance to jamm
        else
            local HundredChance = ZombRand(100)
            if (HundredChance <= SandboxVars.TOC_Engineer.ChanceToJam) then
                SetGunStuff(player:getPrimaryHandItem(), SandboxVars.TOC_Engineer.BonusConditionReductionHighLevel)
            end
        end

        --- We check if the aiming level is high enough, else toasty bunkies
        if (aimLevel <= SandboxVars.TOC_Engineer.AimingLevel) then
            StartFire(PlayerPosX, PlayerPosY, PlayerPosZ, Caliber);
        else
            StartFire(ZombiePosX, ZombiePosY, ZombiePosZ, Caliber);
        end
    end
end

---@param posX int The position in the X axis
---@param posY int The position in the Y axis
---@param posZ int The position in the Z axis
---@return void
--[[
    This function start a fire  in a radius `(posX-radius*2)` and `(posY-radius*2)`
]]
function StartFire(posX, posY, posZ, radius)
    local square = cell:getGridSquare(ZombRand(posX-radius*2, posX+radius*2), ZombRand(posY-radius*2, posY+radius*2), posZ);
    local randomduration = {150,200,250,300}
    if square ~= nil and not square:haveFire() then
        IsoFireManager.StartFire(square:getCell(), square, true, 100, randomduration[ZombRand(4)+1]);
    end
end


---@param player IsoPlayer The player who joined the game
--[[
This function adds `SandboxVars.TOC_Engineer.EngineerRecipes` recipes to the player if they have the `engineer` profession when they join the game
It can also be added to `SandboxVars.TOC_Engineer.EngineerProfession` or the list `SandboxVars.TOC_Engineer.EngineersProfList`
]]
---@return void
function AddEngineerRecipes(player)
    EngineerRecipes = SandboxVars.TOC_Engineer.EngineerRecipes;
    EngineerProf = SandboxVars.TOC_Engineer.EngineerProfession;
    EngineerProfList = SandboxVars.TOC_Engineer.EngineersProfList;


    if (player:getProfession() == "engineer" or (EngineerProf ~= nil and player:getProfession() == EngineerProf)) then
        player:setFreeRecipes(EngineerRecipes)
    else if (SandboxVars.TOC_Engineer.EngineersProfList ~= nil) then
            for i = 1, #EngineerProfList do
                if (player:getProfession() == EngineerProfList[i]) then
                    player:setFreeRecipes(EngineerRecipes)
                end
            end
    end
end
end

Events.OnGameBoot(AddEngineerRecipes(player));
Events.OnHitZombie.Add(StartFunc(player, zombie));

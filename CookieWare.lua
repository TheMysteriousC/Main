repeat task.wait(0.5) until game:IsLoaded() and workspace:FindFirstChild("Mobs") or workspace:FindFirstChild("YourPlayer")
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/quadshoota/RBLX/refs/heads/main/InsaneEagle27.lua"))()


local Data =
{
    Name = "ZeHub",
    Version = "Developer",
}

local Globals =
{
    RoleChecker = function(self)
        if (not LRM_UserNote) then
            return "Developer"
        end

        if (string.find(LRM_UserNote, "Tester")) then
            return "Tester"
        elseif (string.find(LRM_UserNote, "Premium")) then
            return "Premium"
        elseif (string.find(LRM_UserNote, "Developer")) then
            return "Developer"
        else
            return "Freemium"
        end
    end,

    formatVersion = function(self, version)
        local formattedVersion = "v" .. version:sub(2):gsub(".", "%0.")
        return formattedVersion:sub(1, #formattedVersion - 1)
    end,

    safe_require = function(path)
        local success, result = pcall(function()
            local current = game

            for component in string.gmatch(path, "[^%.]+") do
                current = current:FindFirstChild(component)
                if (not current) then
                    error("Path traversal failed")
                end
            end

            return require(current)
        end)

        if (success) then
            return result
        else
            return {}
        end
    end,

    StripNonNumeric = function(self, str)
        if (not str) then
            return ""
        end
        return str:gsub("%D", "")
    end,
}

local Filesystem =
{
    Settings =
    {
        Name = "CookieWare",
        Game = "CookieWare",
        Storage = {},
    },

    GetRoot = function(self)
        return self.Settings.Name
    end,

    GetGame = function(self)
        return self.Settings.Name .. "/" .. self.Settings.Game
    end,

    GetIcons = function(self)
        return self.Settings.Name .. "/" .. self.Settings.Game .. "/icons"
    end,

    EnsureFolders = function(self)
        if (not isfolder(self:GetRoot())) then
            makefolder(self:GetRoot())
        end
        if (not isfolder(self:GetGame())) then
            makefolder(self:GetGame())
        end
        if (not isfolder(self:GetIcons())) then
            makefolder(self:GetIcons())
        end
    end,

    DoEnvironment = function(self)
        if (not (isfolder and makefolder and isfile and writefile and getcustomasset)) then
            warn("ZeHub: Missing filesystem functions")
            return false
        end

        local ok, err = pcall(function()
            self:EnsureFolders()
        end)

        if (not ok) then
            warn("ZeHub: Failed to create folders - " .. tostring(err))
            return false
        end

        local available
        local fetchOk, fetchResult = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/quadshoota/RBLX/refs/heads/main/Available.lua"))()
        end)

        if (not fetchOk or not fetchResult) then
            warn("ZeHub: Failed to fetch icon list - " .. tostring(fetchResult))
            return false
        end

        available = fetchResult

        for _, iconName in pairs(available) do
            local iconPath = self:GetIcons() .. "/" .. iconName .. ".png"

            if (not isfile(iconPath)) then
                pcall(function()
                    local content = game:HttpGet("https://raw.githubusercontent.com/quadshoota/RBLX/main/Icons/" .. iconName .. ".png")
                    if (content and content ~= "") then
                        writefile(iconPath, content)
                    end
                end)
            end

            if (isfile(iconPath)) then
                local assetOk, asset = pcall(getcustomasset, iconPath)
                if (assetOk and asset) then
                    self.Settings.Storage[iconName] = asset
                end
            end
        end

        return true
    end,
}

local initsys = Filesystem:DoEnvironment()
repeat task.wait() until initsys == true

local isInMenu = workspace:FindFirstChild("YourPlayer") ~= nil
if (isInMenu) then
    task.wait(2)
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PrivateServerSea"):InvokeServer()
    end)
    return
end

Library:Window{
    Name = "CookieWare",
    Key = "syscureistheboss1337",
    Logo = false,
}

local VirtualUser = game:GetService("VirtualUser")
local plr = game.Players.LocalPlayer
plr.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

Library:MobileButton(Filesystem.Settings.Storage["LunacyPNG"])
Library:Notification("Loaded anti-afk", 5, "info")

local hrp = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
local localplayer = game.Players.LocalPlayer
local ModuleCache = {}
local LoadedModules = {}
local ModuleManager =
{
    LoadModule = function(self, Base, Path)
        local CacheKey = tostring(Base) .. Path
        if (ModuleCache[CacheKey]) then
            return ModuleCache[CacheKey]
        end

        local Components = Path:split(".")
        for _, Component in Components do
            Base = Base:FindFirstChild(Component)
            if (not Base) then
                return {}
            end
        end

        local success, result = pcall(require, Base)
        if (success) then
            ModuleCache[CacheKey] = result
            return result
        else
            ModuleCache[CacheKey] = {}
            return {}
        end
    end,

    GetModule = function(self, moduleName)
        if (LoadedModules[moduleName]) then
            return LoadedModules[moduleName]
        end

        local moduleConfigs = {

        }

        local config = moduleConfigs[moduleName]
        if (not config) then
            warn("Unknown module:", moduleName)
            LoadedModules[moduleName] = {}
            return {}
        end

        local module = self:LoadModule(config.base, config.path)
        LoadedModules[moduleName] = module
        task.wait(0.01)

        return module
    end,
}

local Config =
{
    PrivacyOptions =
    {
        UsernameOptions = {"Display", "Disabled"},
        SelectedUsernameOption = "Display",
        UsernamePreferences = {"Displayname", "Username", "Custom"},
        SelectedUsernamePreference = "Displayname",
        CustomUsername = "Cookieware",
    },

    Connections = {},
    Cooldowns =
    {
        CollectDropsEvery = 0.4,
        LastCollectedDrops = 0,
    },

    Storage =
    {
        Quests = {},
        QuestMobs = {},
    },

    Farm =
    {
        AutoFarm = false,
        Enemies = {},
        SelectedEnemies = {},
        TweenSpeed = 150,
        PlatformStand = true,
        SelectedTool = "",
    },

    Combat =
    {
        HelmetSpam = false,
        SelectedHelmet = "TanzakniteHelmet",
        HelmetOptions = {"TanzakniteHelmet", "DemonHorns"},
        M2Attack = false,
        M2Interval = 5,
    },

    Player =
    {

    },
}

local Utils =
{
    Contains = function(self, tbl, val)
        for i = 1, #tbl do
            if tbl[i] == val then
                return true
            end
        end
        return false
    end,

    GetRole = function(self)
        if (not LRM_UserNote) then
            return "Developer"
        end

        if (string.find(LRM_UserNote, "Ad Reward")) then
            return "Freemium"
        elseif (string.find(LRM_UserNote, "Premium")) then
            return "Premium"
        elseif (string.find(LRM_UserNote, "Developer")) then
            return "Developer"
        elseif (string.find(LRM_UserNote, "Tester")) then
            return "Tester"
        else
            return "Freemium"
        end
    end,

    ModifyTbl = function(self, tbl, name, value)
        for i,v in pairs(tbl) do
            if (i == name) then
                tbl[i] = value
            elseif (type(v) == "table") then
                self:ModifyTbl(v, name, value)
                Helpers:Log("MODIFY TABLE", "Modified table: " .. tostring(i) .. " to value: " .. tostring(value))
            end
        end
    end,

    TweenTo = function(self, target)
        local TweenService = game:GetService("TweenService")
        local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if (not hrp or not humanoid) then return end

        local targetCFrame
        if (typeof(target) == "Instance") then
            targetCFrame = target.CFrame
        elseif (typeof(target) == "CFrame") then
            targetCFrame = target
        elseif (typeof(target) == "Vector3") then
            targetCFrame = CFrame.new(target)
        else
            return
        end

        local stepSize = 50
        local startPos = hrp.CFrame
        local distance = (startPos.Position - targetCFrame.Position).Magnitude
        local steps = math.max(1, math.ceil(distance / stepSize))

        for i = 1, steps do
            if (not Config.Farm.AutoFarm) then break end

            local alpha = i / steps
            local stepCFrame = startPos:Lerp(targetCFrame, alpha)
            local stepDist = (hrp.Position - stepCFrame.Position).Magnitude
            local time = stepDist / Config.Farm.TweenSpeed

            local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = stepCFrame})
            tween:Play()

            local elapsed = 0
            local maxWait = time + 1
            while (tween.PlaybackState == Enum.PlaybackState.Playing and elapsed < maxWait) do
                task.wait(0.1)
                elapsed = elapsed + 0.1
            end

            tween:Cancel()

            local driftDist = (hrp.Position - stepCFrame.Position).Magnitude
            if (driftDist > 20) then
                humanoid.PlatformStand = false
                local character = game.Players.LocalPlayer.Character
                if (character) then
                    for _,v in pairs(character:GetDescendants()) do
                        if (v:IsA("Part") or v:IsA("MeshPart")) then
                            v.CanCollide = true
                        end
                    end
                end
                break
            end
        end

        humanoid.PlatformStand = false
        local character = game.Players.LocalPlayer.Character
        if (character) then
            for _,v in pairs(character:GetDescendants()) do
                if (v:IsA("Part") or v:IsA("MeshPart")) then
                    v.CanCollide = true
                end
            end
        end
    end,

    SetCollision = function(self, value)
        local character = game.Players.LocalPlayer.Character
        if (not character) then return end
        for i,v in pairs(character:GetDescendants()) do
            if (v:IsA("Part") or v:IsA("MeshPart")) then
                if (v.CanCollide == value) then continue end
                v.CanCollide = value
            end
        end
    end,
}

for i,v in pairs(workspace.Mobs:GetChildren()) do
    local cleanName = v.Name:match("^[^%d]+")
    if (#Config.Farm.Enemies == 0 or not Utils:Contains(Config.Farm.Enemies, cleanName)) then
        table.insert(Config.Farm.Enemies, cleanName)
    end
end

local Features =
{
    Farm =
    {
        AutoFarm = function(self)
            local closestDist = math.huge
            local closestModel = nil
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")

            for i,v in pairs(workspace.Mobs:GetChildren()) do
                local cleanName = v.Name:match("^[^%d]+")
                if (#Config.Farm.SelectedEnemies > 0 and not Utils:Contains(Config.Farm.SelectedEnemies, cleanName)) then
                    continue
                end

                local hum = v:FindFirstChildOfClass("Humanoid")
                if (not hum or hum.Health <= 0) then continue end

                local pivot = v:GetPivot()
                local dist = hrp and (hrp.Position - pivot.Position).Magnitude or math.huge
                if (dist < closestDist) then
                    closestDist = dist
                    closestModel = v
                end
            end

            if (not hrp or not humanoid) then return end

            if (not closestModel) then
                humanoid.PlatformStand = false
                return
            end

            for i,v in pairs(game.Players.LocalPlayer.Character.HumanoidRootPart:GetChildren()) do
                if (v:IsA("Motor6D")) then
                    v.Enabled = false
                end
            end

            local ActiveRemote = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if (not ActiveRemote) then
                local toolinbackpack = Config.Farm.SelectedTool ~= "" and game.Players.LocalPlayer.Backpack:FindFirstChild(Config.Farm.SelectedTool) or game.Players.LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                humanoid:EquipTool(toolinbackpack)
                return
            end

            if (Config.Farm.SelectedTool ~= "" and ActiveRemote.Name ~= Config.Farm.SelectedTool) then
                local toolinbackpack = game.Players.LocalPlayer.Backpack:FindFirstChild(Config.Farm.SelectedTool)
                if (toolinbackpack) then
                    humanoid:EquipTool(toolinbackpack)
                    return
                end
            end

            ActiveRemote = ActiveRemote.SwordScript.Activate
            if (not ActiveRemote) then return end

            local EnemyPivot = closestModel:GetPivot()
            local BehindAbove = EnemyPivot * CFrame.new(0, 6, 7)
            local TranslatedCFrame = CFrame.lookAt(BehindAbove.Position, EnemyPivot.Position)

            local character = game.Players.LocalPlayer.Character
            if (character) then
                for _,v in pairs(character:GetDescendants()) do
                    if (v:IsA("Part") or v:IsA("MeshPart")) then
                        v.CanCollide = false
                    end
                end
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            if (closestDist > 10) then
                humanoid.PlatformStand = Config.Farm.PlatformStand
                Utils:TweenTo(TranslatedCFrame)
                return
            else
                humanoid.PlatformStand = Config.Farm.PlatformStand
                hrp.CFrame = TranslatedCFrame
                ActiveRemote:FireServer()
                return
            end
        end,

        CollectDrops = function(self)
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if (not hrp) then return end

            local drops = {}
            for i,v in pairs(workspace.Drops:GetChildren()) do
                if (not v:IsA("Model")) then continue end

                local ok, pivot = pcall(function() return v:GetPivot() end)
                if (not ok) then continue end

                local dist = (hrp.Position - pivot.Position).Magnitude
                table.insert(drops, {model = v, dist = dist})
            end

            table.sort(drops, function(a, b) return a.dist < b.dist end)

            for _,drop in pairs(drops) do
                for _,part in pairs(drop.model:GetDescendants()) do
                    if (part:IsA("TouchTransmitter")) then
                        firetouchinterest(hrp, part.Parent, 0)
                        firetouchinterest(hrp, part.Parent, 1)
                    end
                end
            end
        end,
    },

    Combat =
    {
        HelmetSpam = function(self)
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local addHelmet = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AddHelmet")
            local removeHelmet = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RemoveHelmet")
            while (Config.Combat.HelmetSpam) do
                addHelmet:FireServer(Config.Combat.SelectedHelmet, false)
                removeHelmet:FireServer("Helmet")
                task.wait()
            end
        end,

        M2Attack = function(self)
            while (Config.Combat.M2Attack) do
                local char = game.Players.LocalPlayer.Character
                if (char) then
                    local ActiveTool = char:FindFirstChildOfClass("Tool")
                    if (ActiveTool) then
                        local swordScript = ActiveTool:FindFirstChild("SwordScript")
                        if (swordScript) then
                            local stopEvent = swordScript:FindFirstChild("M2")
                            local startEvent = swordScript:FindFirstChild("M2Charge")
                            if (not char:FindFirstChild(ActiveTool.Name .. "M2")) then
                                if (stopEvent) then stopEvent:FireServer() end
                                task.wait(0.05)
                                if (startEvent) then startEvent:FireServer() end
                            end
                        end
                    end
                end
                task.wait(Config.Combat.M2Interval)
            end
        end,
    },
}


local Tabs =
{
    Main = Library:Tab{
        Title = "Main",
        Icon = Filesystem.Settings.Storage["user"],
        Vertical = false,
    },

    Farm = Library:Tab{
        Title = "Farm",
        Icon = Filesystem.Settings.Storage["browser"],
        Vertical = false,
    },

    Combat = Library:Tab{
        Title = "Combat",
        Icon = Filesystem.Settings.Storage["browser"],
        Vertical = false,
    },

    Configs = Library:Tab{
        Title = "Configs",
        Icon = Filesystem.Settings.Storage["cloudfile"],
        Vertical = false,
    },
}

local Sections =
{
    Profile = Tabs.Main:Section{
        Name = "Profile",
        Side = "Left",
        ShowTitle = false,
    },

    Changelog = Tabs.Main:Section{
        Name = "Changelogs",
        Side = "Right",
        ShowTitle = false,
    },

    Automation = Tabs.Farm:Section{
        Name = "Automation",
        Side = "Left",
        ShowTitle = false,
    },

    ExtraAutomation = Tabs.Farm:Section{
        Name = "Extra Automation",
        Side = "Right",
        ShowTitle = false,
    },

    Advertise = Tabs.Farm:Section{
        Name = "Advertise",
        Side = "Right",
        ShowTitle = false,
    },

    CombatLeft = Tabs.Combat:Section{
        Name = "Combat",
        Side = "Left",
        ShowTitle = false,
    },

    CombatRight = Tabs.Combat:Section{
        Name = "Armour",
        Side = "Right",
        ShowTitle = false,
    },

    Configs = Tabs.Configs:Section{
        Name = "Configs",
        Side = "Left",
        ShowTitle = false,
    },
}

local Subsections =
{
    Automation = Sections.Automation:Subsection{
        Name = "Farming",
        Side = "Left",
        HasSubsection = true,
    },

    Quests = Sections.ExtraAutomation:Subsection{
        Name = "Quests",
        Side = "Left",
        HasSubsection = true,
    },

    Combat = Sections.CombatLeft:Subsection{
        Name = "Attack",
        Side = "Left",
        HasSubsection = true,
    },

    Armour = Sections.CombatRight:Subsection{
        Name = "Helmet",
        Side = "Left",
        HasSubsection = true,
    },
}


Subsections.Automation:Toggle{
    Name = "Auto Farm",
    State = Config.Farm.AutoFarm,
    Flag = "AutoFarm",
    Callback = function(value)
        Config.Farm.AutoFarm = value
        if (value) then
            if (not Config.Connections.AutoFarm) then
                Config.Connections.AutoFarm = game:GetService("RunService").Heartbeat:Connect(function()
                    Features.Farm:AutoFarm()
                end)
            end
        else
            if (Config.Connections.AutoFarm) then
                Config.Connections.AutoFarm:Disconnect()
                Config.Connections.AutoFarm = nil
                local character = game.Players.LocalPlayer.Character
                if (character) then
                    for _,v in pairs(character:GetDescendants()) do
                        if (v:IsA("Part") or v:IsA("MeshPart")) then
                            v.CanCollide = true
                        end
                    end
                end
                local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                if (humanoid) then humanoid.PlatformStand = false end
            end
        end
    end
}

Subsections.Automation:Toggle{
    Name = "Collect Drops",
    State = false,
    Flag = "AutoCollectDrops",
    Callback = function(value)
        if (value) then
            if (not Config.Connections.AutoCollectDrops) then
                Config.Connections.AutoCollectDrops = game:GetService("RunService").Heartbeat:Connect(function()
                    local currentTime = os.time()
                    if (currentTime - Config.Cooldowns.LastCollectedDrops >= Config.Cooldowns.CollectDropsEvery) then
                        Features.Farm:CollectDrops()
                        Config.Cooldowns.LastCollectedDrops = currentTime
                    end
                end)
            end
        else
            if (Config.Connections.AutoCollectDrops) then
                Config.Connections.AutoCollectDrops:Disconnect()
                Config.Connections.AutoCollectDrops = nil
            end
        end
    end
}

Subsections.Automation:Separator{}

Subsections.Automation:Slider{
    Name = "Tween Speed",
    Min = 50,
    Max = 10000,
    Default = Config.Farm.TweenSpeed,
    Flag = "TweenSpeed",
    Callback = function(value)
        Config.Farm.TweenSpeed = value
    end
}

Subsections.Automation:Separator{}

Subsections.Automation:Dropdown{
    Name = "Select Enemies",
    Options = Config.Farm.Enemies,
    Default = Config.Farm.SelectedEnemies,
    Max = 99,
    Flag = "SelectedEnemies",
    Callback = function(value)
        Config.Farm.SelectedEnemies = value
    end
}

Subsections.Automation:Button{
    Name = "Refresh Enemies",
    Flag = "RefreshEnemies",
    Callback = function()
        Config.Farm.Enemies = {}
if (workspace:FindFirstChild("Mobs")) then
    for i,v in pairs(workspace.Mobs:GetChildren()) do
        local cleanName = v.Name:match("^[^%d]+")
        if (#Config.Farm.Enemies == 0 or not Utils:Contains(Config.Farm.Enemies, cleanName)) then
            table.insert(Config.Farm.Enemies, cleanName)
        end
    end
end
}

Subsections.Automation:Toggle{
    Name = "Platform Stand",
    State = Config.Farm.PlatformStand,
    Flag = "PlatformStand",
    Callback = function(value)
        Config.Farm.PlatformStand = value
    end
}

Subsections.Automation:Dropdown{
    Name = "Select Tool",
    Options = (function()
        local tools = {""}
        for _,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
            if (v:IsA("Tool")) then
                table.insert(tools, v.Name)
            end
        end
        local equipped = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if (equipped and not Utils:Contains(tools, equipped.Name)) then
            table.insert(tools, equipped.Name)
        end
        return tools
    end)(),
    Default = {Config.Farm.SelectedTool},
    Max = 1,
    Flag = "SelectedTool",
    Callback = function(value)
        if (type(value) == "table") then
            value = value[1]
        end
        Config.Farm.SelectedTool = value or ""
    end
}

Subsections.Combat:Toggle{
    Name = "M2 Attack",
    State = Config.Combat.M2Attack,
    Flag = "M2Attack",
    Callback = function(value)
        Config.Combat.M2Attack = value
        if (value) then
            task.spawn(function()
                Features.Combat:M2Attack()
            end)
        end
    end
}

Subsections.Combat:Slider{
    Name = "M2 Interval (seconds)",
    Min = 1,
    Max = 30,
    Default = Config.Combat.M2Interval,
    Flag = "M2Interval",
    Callback = function(value)
        Config.Combat.M2Interval = value
    end
}

Subsections.Armour:Dropdown{
    Name = "Helmet",
    Options = Config.Combat.HelmetOptions,
    Default = {Config.Combat.SelectedHelmet},
    Max = 1,
    Flag = "SelectedHelmet",
    Callback = function(value)
        if (type(value) == "table") then
            value = value[1]
        end
        Config.Combat.SelectedHelmet = value
    end
}

Subsections.Armour:Toggle{
    Name = "Helmet Spam",
    State = Config.Combat.HelmetSpam,
    Flag = "HelmetSpam",
    Callback = function(value)
        Config.Combat.HelmetSpam = value
        if (value) then
            task.spawn(function()
                Features.Combat:HelmetSpam()
            end)
        end
    end
}


local WelcomeMessage = Sections.Profile:Paragraph{
    Title = "Greetings!",
    Description = {
        {Text = "Welcome » " .. tostring(game.Players.LocalPlayer.DisplayName), Icon = Filesystem.Settings.Storage["user"]},
        {Text = "Version » " .. tostring(Utils:GetRole()), Icon = Filesystem.Settings.Storage["role"]},
        {Text = "Last Update » 20/03/2026", Icon = Filesystem.Settings.Storage["calender"]},
    },
    Position = "Center",
}

Sections.Profile:Separator{}

Sections.Profile:Dropdown{
    Name = "Username Options",
    Flag = "UsernameOptions",
    Options = Config.PrivacyOptions.UsernameOptions,
    Default = Config.PrivacyOptions.SelectedUsernameOption,
    Max = 1,
    AutoSize = true,
    Callback = function(Value)
        if (type(Value) == "table") then
            Value = Value[1]
        end
        Config.PrivacyOptions.SelectedUsernameOption = Value

        local setname
        if (Config.PrivacyOptions.SelectedUsernameOption == "Disabled") then
            setname = "eh, ghost?"
        else
            if (Config.PrivacyOptions.SelectedUsernamePreference == "Custom") then
                if (Config.PrivacyOptions.CustomUsername and Config.PrivacyOptions.CustomUsername ~= "") then
                    setname = Config.PrivacyOptions.CustomUsername
                else
                    setname = game.Players.LocalPlayer.DisplayName
                end
            elseif (Config.PrivacyOptions.SelectedUsernamePreference == "Username") then
                setname = game.Players.LocalPlayer.Name
            elseif (Config.PrivacyOptions.SelectedUsernamePreference == "Displayname") then
                setname = game.Players.LocalPlayer.DisplayName
            end
        end

        setname = tostring(setname)
        WelcomeMessage:SetDescription{
            {Text = "Welcome » " .. setname, Icon = Filesystem.Settings.Storage["user"]},
            {Text = "Version » " .. tostring(Utils:GetRole()), Icon = Filesystem.Settings.Storage["role"]},
            {Text = "Last Update » 17/03/2026", Icon = Filesystem.Settings.Storage["calender"]},
        }
    end,
}

Sections.Profile:Dropdown{
    Name = "Display Preferences",
    Flag = "UsernamePreferences",
    Options = Config.PrivacyOptions.UsernamePreferences,
    Default = Config.PrivacyOptions.SelectedUsernamePreference,
    Max = 1,
    AutoSize = true,
    Depends = {
        ["UsernameOptions"] = {contains = {"Display"}}
    },
    Callback = function(Value)
        if (type(Value) == "table") then
            Value = Value[1]
        end
        Config.PrivacyOptions.SelectedUsernamePreference = Value

        local setname
        if (Config.PrivacyOptions.SelectedUsernamePreference == "Custom") then
            if (Config.PrivacyOptions.CustomUsername and Config.PrivacyOptions.CustomUsername ~= "") then
                setname = Config.PrivacyOptions.CustomUsername
            else
                setname = game.Players.LocalPlayer.DisplayName
            end
        elseif (Config.PrivacyOptions.SelectedUsernamePreference == "Username") then
            setname = game.Players.LocalPlayer.Name
        elseif (Config.PrivacyOptions.SelectedUsernamePreference == "Displayname") then
            setname = game.Players.LocalPlayer.DisplayName
        end

        setname = tostring(setname)
        WelcomeMessage:SetDescription{
            {Text = "Welcome » " .. setname, Icon = Filesystem.Settings.Storage["user"]},
            {Text = "Version » " .. tostring(Utils:GetRole()), Icon = Filesystem.Settings.Storage["role"]},
            {Text = "Last Update » 17/03/2026", Icon = Filesystem.Settings.Storage["calender"]},
        }
    end,
}

Sections.Profile:Textbox{
    Name = "Displayname",
    Flag = "CustomUsername",
    PlaceholderText = "lunacy.rocks",
    Default = Config.PrivacyOptions.CustomUsername or "",
    Depends = {
        ["UsernamePreferences"] = {contains = {"Custom"}},
        ["UsernameOptions"] = {contains = {"Display"}}
    },
    Callback = function(Value)
        Config.PrivacyOptions.CustomUsername = Value

        if (Value == "" or Value == nil) then
            Value = tostring(game.Players.LocalPlayer.DisplayName)
        end

        WelcomeMessage:SetDescription{
            {Text = "Welcome » " .. tostring(Value), Icon = Filesystem.Settings.Storage["user"]},
            {Text = "Version » " .. tostring(Utils:GetRole()), Icon = Filesystem.Settings.Storage["role"]},
            {Text = "Last Update » 17/03/2026", Icon = Filesystem.Settings.Storage["calender"]},
        }
    end,
}

local advertisemsg = Sections.Advertise:Paragraph{
    Title = "Further questions?",
    Description = {
        {Text = "  » " .. ".GG/74rBQJ4FyQ", Icon = Filesystem.Settings.Storage["discord"]},
        {Text = "  » " .. "syscure.vip <3", Icon = Filesystem.Settings.Storage["user"]},
    },
    Position = "Center",
}

Sections.Changelog:Separator{
    Name = "Latest Changes",
    Margin = 1,
}

local execname, execversion = identifyexecutor()
local ChangelogMessage = Sections.Changelog:Paragraph{
    Title = false,
    Description = {
        {Text = "Released » " .. "CookieWare"},
        {Text = "Status » " .. "Operational"},
        {Text = "Platform » " .. tostring(execname)},
    },
    Position = "Center",
}

local ConfigUtils = {
    AUTOLOAD_FILE = "autoload.txt",
    AUTOLOAD_INDICATOR = " [autoload]",

    GetConfigsPath = function(self)
        return Filesystem:GetGame() .. "/configs"
    end,

    GetAutoloadPath = function(self)
        return self:GetConfigsPath() .. "/" .. self.AUTOLOAD_FILE
    end,

    EnsureFolder = function(self)
        if (isfolder and makefolder and not isfolder(self:GetConfigsPath())) then
            makefolder(self:GetConfigsPath())
        end
    end,

    GetConfigList = function(self)
        local configs = {}
        if (not (isfolder and listfiles)) then return configs end

        self:EnsureFolder()

        local success, files = pcall(function()
            return listfiles(self:GetConfigsPath())
        end)

        if (success and files) then
            for _, filePath in pairs(files) do
                local fileName = filePath:match("([^/\\]+)$")
                if (fileName and fileName:lower():sub(-4) == ".txt" and fileName ~= self.AUTOLOAD_FILE) then
                    local configName = fileName:sub(1, -5)
                    table.insert(configs, configName)
                end
            end
        end

        table.sort(configs)
        return configs
    end,

    GetDisplayList = function(self)
        local configs = self:GetConfigList()
        local autoload = self:GetAutoloadConfig()
        local display = {}

        for _, name in ipairs(configs) do
            if (name == autoload) then
                table.insert(display, name .. self.AUTOLOAD_INDICATOR)
            else
                table.insert(display, name)
            end
        end

        return display
    end,

    StripIndicator = function(self, name)
        if (not name) then return name end
        local indicator = self.AUTOLOAD_INDICATOR
        if (name:sub(-#indicator) == indicator) then
            return name:sub(1, -#indicator - 1)
        end
        return name
    end,

    ConfigExists = function(self, configName)
        if (not configName or configName == "" or not isfile) then return false end
        return isfile(self:GetConfigsPath() .. "/" .. configName .. ".txt")
    end,

    SaveConfig = function(self, configName)
        if (not configName or configName == "" or not writefile or not Library) then
            return false, "Invalid config name or missing dependencies"
        end

        local success, result = pcall(function()
            self:EnsureFolder()
            local config = Library:GetConfig()
            if (not config) then
                return false, "Failed to get library config"
            end
            writefile(self:GetConfigsPath() .. "/" .. configName .. ".txt", config)
            return true, "Config saved successfully"
        end)

        return success, success and result or ("Failed to save config: " .. tostring(result))
    end,

    LoadConfig = function(self, configName)
        if (not configName or configName == "" or not (readfile and isfile)) then
            return false, "Invalid config name or missing dependencies"
        end

        local path = self:GetConfigsPath() .. "/" .. configName .. ".txt"
        if (not isfile(path)) then
            return false, "Config file not found"
        end

        local success, configData = pcall(readfile, path)
        if (not success) then
            return false, "Failed to read config file: " .. tostring(configData)
        end

        if (not configData or configData == "") then
            return false, "Config file is empty"
        end

        if (not Library or not Library.LoadConfig) then
            return false, "Library.LoadConfig not available"
        end

        setthreadidentity(8)
        game:GetService("RunService").Heartbeat:Wait()
        Library:LoadConfig(configData)

        return true, "Config loaded successfully"
    end,

    DeleteConfig = function(self, configName)
        if (not configName or configName == "" or not (delfile and isfile)) then
            return false, "Invalid config name or missing dependencies"
        end

        local path = self:GetConfigsPath() .. "/" .. configName .. ".txt"
        if (not isfile(path)) then
            return false, "Config file not found"
        end

        local success, result = pcall(function()
            delfile(path)
            return true, "Config deleted successfully"
        end)

        return success, success and result or ("Failed to delete config: " .. tostring(result))
    end,

    SaveAutoloadConfig = function(self, configName)
        if (not writefile) then return false, "File system not available" end

        local success, result = pcall(function()
            self:EnsureFolder()
            writefile(self:GetAutoloadPath(), configName or "")
            return true, "Autoload config updated"
        end)

        return success, success and result or ("Failed to save autoload config: " .. tostring(result))
    end,

    GetAutoloadConfig = function(self)
        if (not (readfile and isfile)) then return "" end

        local path = self:GetAutoloadPath()
        if (isfile(path)) then
            local success, content = pcall(readfile, path)
            return success and content or ""
        end
        return ""
    end,

    IsAutoload = function(self, configName)
        local current = self:GetAutoloadConfig()
        return current ~= "" and current == configName
    end,

    AutoloadConfig = function(self)
        local autoloadConfig = self:GetAutoloadConfig()
        if (autoloadConfig and autoloadConfig ~= "" and autoloadConfig ~= "None") then
            self:LoadConfig(autoloadConfig)
        end
        return false
    end,
}

local UIHelpers = {
    ShowMessage = function(self, message, isSuccess)
        local icon = isSuccess and "[+]" or "[-]"
        print(icon .. " " .. tostring(message))
    end,

    ValidateConfigName = function(self, name)
        if (not name or name == "") then
            return false, "Config name cannot be empty"
        end

        if (name:match("[<>:\"/\\|?*]")) then
            return false, "Config name contains invalid characters"
        end

        if (#name > 50) then
            return false, "Config name too long (max 50 characters)"
        end

        return true, ""
    end,

    RefreshList = function(self, configListWidget, configUtils)
        if (configListWidget) then
            configListWidget:Refresh(configUtils:GetDisplayList())
        end
    end,

    ClearConfigInput = function(self, configNameTextbox)
        if (configNameTextbox) then
            configNameTextbox:Set("")
        end
    end,

    StartAutoRefresh = function(self, configUtils, configListWidget, interval)
        interval = interval or 5

        spawn(function()
            while true do
                wait(interval)
                self:RefreshList(configListWidget, configUtils)
            end
        end)
    end,
}

local configListWidget, configNameTextbox
local configName = ""

local ConfigActions = {
    SaveConfig = function(self, configName, configUtils, uiHelpers, configListWidget)
        local isValid, errorMsg = uiHelpers:ValidateConfigName(configName)
        if (not isValid) then
            uiHelpers:ShowMessage(errorMsg, false)
            return false
        end

        if (configUtils:ConfigExists(configName)) then
            uiHelpers:ShowMessage("Config already exists. Overwriting...", true)
        end

        local success, message = configUtils:SaveConfig(configName)
        uiHelpers:ShowMessage(message, success)

        if (success) then
            uiHelpers:RefreshList(configListWidget, configUtils)
        end

        return success
    end,

    LoadConfig = function(self, configName, configUtils, uiHelpers)
        local isValid, errorMsg = uiHelpers:ValidateConfigName(configName)
        if (not isValid) then
            uiHelpers:ShowMessage(errorMsg, false)
            return false
        end

        local success, message = configUtils:LoadConfig(configName)
        uiHelpers:ShowMessage(message, success)
        return success
    end,

    DeleteConfig = function(self, configName, configUtils, uiHelpers, configListWidget, configNameTextbox)
        local isValid, errorMsg = uiHelpers:ValidateConfigName(configName)
        if (not isValid) then
            uiHelpers:ShowMessage(errorMsg, false)
            return false
        end

        local success, message = configUtils:DeleteConfig(configName)
        uiHelpers:ShowMessage(message, success)

        if (success) then
            uiHelpers:ClearConfigInput(configNameTextbox)
            uiHelpers:RefreshList(configListWidget, configUtils)
        end

        return success
    end,

    ToggleAutoload = function(self, configName, configUtils, uiHelpers, configListWidget)
        local isValid, errorMsg = uiHelpers:ValidateConfigName(configName)
        if (not isValid) then
            uiHelpers:ShowMessage(errorMsg, false)
            return false
        end

        if (not configUtils:ConfigExists(configName)) then
            uiHelpers:ShowMessage("Config does not exist: " .. configName, false)
            return false
        end

        if (configUtils:IsAutoload(configName)) then
            local success, message = configUtils:SaveAutoloadConfig("")
            if (success) then
                uiHelpers:ShowMessage("Autoload removed for: " .. configName, true)
            else
                uiHelpers:ShowMessage(message, false)
            end
            uiHelpers:RefreshList(configListWidget, configUtils)
            return success
        else
            local success, message = configUtils:SaveAutoloadConfig(configName)
            if (success) then
                uiHelpers:ShowMessage("Autoload set to: " .. configName, true)
            else
                uiHelpers:ShowMessage(message, false)
            end
            uiHelpers:RefreshList(configListWidget, configUtils)
            return success
        end
    end,
}


configNameTextbox = Sections.Configs:Textbox{
    Name = "Config Name",
    PlaceholderText = "Enter config name...",
    Default = "",
    Flag = "ConfigName",
    Callback = function(value)
        configName = value:gsub("^%s*(.-)%s*$", "%1")
    end,
}

configListWidget = Sections.Configs:List{
    Name = "Config List",
    Options = ConfigUtils:GetDisplayList(),
    Flag = "ConfigList",
    MaxHeight = 120,
    Callback = function(selected)
        if (selected and selected ~= "") then
            local real = ConfigUtils:StripIndicator(selected)
            configNameTextbox:Set(real)
            configName = real
        end
    end,
}

local SaveConfigButton = Sections.Configs:Button{
    Name = "Save Config",
    Flag = "SaveConfigButton",
    Callback = function()
        if (configName == "" or not configName) then
            UIHelpers:ShowMessage("Please enter a config name", false)
            return
        end
        ConfigActions:SaveConfig(configName, ConfigUtils, UIHelpers, configListWidget)
    end,
}

local LoadConfigButton = Sections.Configs:Button{
    Name = "Load Config",
    Flag = "LoadConfigButton",
    Callback = function()
        if (configName == "" or not configName) then
            UIHelpers:ShowMessage("Please enter a config name", false)
            return
        end
        ConfigActions:LoadConfig(configName, ConfigUtils, UIHelpers)
    end,
}

local DeleteConfigButton = Sections.Configs:Button{
    Name = "Delete Config",
    Flag = "DeleteConfigButton",
    Callback = function()
        if (configName == "" or not configName) then
            UIHelpers:ShowMessage("Please enter a config name", false)
            return
        end
        ConfigActions:DeleteConfig(configName, ConfigUtils, UIHelpers, configListWidget, configNameTextbox)
        configName = ""
    end,
}

local ToggleAutoloadButton = Sections.Configs:Button{
    Name = "Toggle Autoload",
    Flag = "ToggleAutoloadButton",
    Callback = function()
        if (configName == "" or not configName) then
            UIHelpers:ShowMessage("Please enter a config name", false)
            return
        end
        ConfigActions:ToggleAutoload(configName, ConfigUtils, UIHelpers, configListWidget)
    end,
}

Sections.Configs:Button{
    Name = "Rejoin Game",
    Callback = function()
        local ts = game:GetService("TeleportService")
        local p = game:GetService("Players").LocalPlayer
        ts:Teleport(game.PlaceId, p)
    end,
}

UIHelpers:StartAutoRefresh(ConfigUtils, configListWidget, 5)
ConfigUtils:AutoloadConfig()

    repeat task.wait() until game:IsLoaded()

    local function getEarlyExecutorName()
        local names = {}
        local function addName(value)
            if type(value) == "string" and value ~= "" then
                names[#names + 1] = value
            end
        end

        pcall(function()
            if type(identifyexecutor) == "function" then
                local first, second = identifyexecutor()
                addName(first)
                addName(second)
            end
        end)
        pcall(function()
            if type(getexecutorname) == "function" then
                addName(getexecutorname())
            end
        end)
        pcall(function()
            if type(getgenv) == "function" then
                local env = getgenv()
                for _, key in ipairs({"executor", "Executor", "executor_name", "ExecutorName", "EXECUTOR_NAME", "exploit", "Exploit"}) do
                    addName(env[key])
                end
            end
        end)

        return table.concat(names, " "):lower()
    end

    local EarlyUnsupportedName = nil
    do
        local executorName = getEarlyExecutorName()
        EarlyUnsupportedName = executorName:find("xeno", 1, true) and "Xeno"
            or executorName:find("solara", 1, true) and "Solara"
    end

    local ICEHUB_LOGO_URL = ""
    local ICEHUB_LOGO_PATH = "IceHubX/icehub-logo-runtime.png"

    local function getIceHubGlobal(name)
        local value
        pcall(function()
            local env = getgenv and getgenv()
            value = env and env[name]
        end)
        if value ~= nil then return value end
        pcall(function()
            local env = getfenv and getfenv(0)
            value = env and env[name]
        end)
        return value
    end

    local function ensureIceHubLogoDownloaded()
        -- ICEHUB safety: no external downloads or executor file writes for branding.
        return nil
    end

    local function resolveIceHubLogoAsset()
        local cached = getIceHubGlobal("IceHubLogoAsset")
        if type(cached) == "string" and cached ~= "" then
            return cached
        end

        local assetResolver = getcustomasset or getsynasset
            or getIceHubGlobal("getcustomasset")
            or getIceHubGlobal("getsynasset")
        if type(assetResolver) ~= "function" then
            return ""
        end

        local fileExists = isfile or getIceHubGlobal("isfile")
        local downloadedPath = ensureIceHubLogoDownloaded()
        for _, path in ipairs({
            downloadedPath,
            ICEHUB_LOGO_PATH,
            "IceHubX/icehub-logo-v2.png",
            "assets/icehub-logo.png",
            "IceHubX/icehub-logo.png",
            "C:\\Users\\Ice\\Desktop\\icehubxscripts\\assets\\icehub-logo.png",
        }) do
            if path then
                local canUse = true
                if type(fileExists) == "function" then
                    local checked, exists = pcall(fileExists, path)
                    canUse = checked and exists == true
                end
                if canUse then
                    local ok, asset = pcall(assetResolver, path)
                    if ok and type(asset) == "string" and asset ~= "" then
                        pcall(function()
                            if getgenv then getgenv().IceHubLogoAsset = asset end
                        end)
                        return asset
                    end
                end
            end
        end

        return ""
    end

    -- ═══ CLEANUP ══════════════════════════════════════════════════════
    -- Modern startup loading screen. The main script waits here until it finishes.
    do
        local LoadingTweenService = game:GetService("TweenService")
        local LoadingCoreGui = game:GetService("CoreGui")
        local LoadingAccent = Color3.fromRGB(126, 34, 206)
        local LoadingAccentLight = Color3.fromRGB(192, 132, 252)
        local oldLoading = LoadingCoreGui:FindFirstChild("IceHubLoading")
        if oldLoading then oldLoading:Destroy() end

        local loadingLogoAsset = resolveIceHubLogoAsset()

        local function create(className, properties, parent)
            local object = Instance.new(className)
            for property, value in pairs(properties or {}) do
                object[property] = value
            end
            object.Parent = parent
            return object
        end

        local loadingGui = create("ScreenGui", {
            Name = "IceHubLoading",
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            DisplayOrder = 2000,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
        }, LoadingCoreGui)

        local overlay = create("Frame", {
            Name = "Overlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, loadingGui)

        local card = create("Frame", {
            Name = "Card",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.52),
            Size = UDim2.fromOffset(430, 244),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, overlay)
        local cardGradient = create("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, LoadingAccent),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
            },
            Rotation = 45,
        }, card)
        create("UICorner", {CornerRadius = UDim.new(0, 12)}, card)
        local cardStroke = create("UIStroke", {
            Color = LoadingAccent,
            Thickness = 1,
            Transparency = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, card)

        local loadingCamera = workspace.CurrentCamera
        local loadingViewport = loadingCamera and loadingCamera.ViewportSize or Vector2.new(800, 600)
        local targetCardScale = math.clamp(
            math.min((loadingViewport.X - 24) / 430, (loadingViewport.Y - 24) / 244),
            0.72,
            1
        )
        local cardScale = create("UIScale", {Scale = targetCardScale * 0.92}, card)

        local badge = create("TextLabel", {
            Position = UDim2.fromOffset(24, 20),
            Size = UDim2.fromOffset(112, 24),
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = "SECURE STARTUP",
            TextColor3 = LoadingAccentLight,
            TextSize = 10,
            TextScaled = true,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, card)
        create("UICorner", {CornerRadius = UDim.new(0, 12)}, badge)
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }, badge)
        create("UITextSizeConstraint", {
            MinTextSize = 8,
            MaxTextSize = 10,
        }, badge)

        local logo = create("Frame", {
            Position = UDim2.fromOffset(24, 61),
            Size = UDim2.fromOffset(58, 58),
            BackgroundColor3 = Color3.fromRGB(10, 10, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, card)
        create("UICorner", {CornerRadius = UDim.new(0, 15)}, logo)
        local logoStroke = create("UIStroke", {
            Color = LoadingAccent,
            Thickness = 1.2,
            Transparency = 1,
        }, logo)

        local logoImage = create("ImageLabel", {
            Position = UDim2.fromOffset(7, 7),
            Size = UDim2.new(1, -14, 1, -14),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = loadingLogoAsset,
            ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
        }, logo)

        local logoFallback = create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "IH",
            TextColor3 = LoadingAccentLight,
            TextSize = 18,
            TextTransparency = 1,
            Visible = loadingLogoAsset == "",
        }, logo)

        local title = create("TextLabel", {
            Position = UDim2.fromOffset(100, 63),
            Size = UDim2.new(1, -124, 0, 31),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "ICEHUB",
            TextColor3 = Color3.fromRGB(239, 240, 247),
            TextSize = 25,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local subtitle = create("TextLabel", {
            Position = UDim2.fromOffset(101, 94),
            Size = UDim2.new(1, -125, 0, 21),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = "Blade Ball  |  v1.1.9",
            TextColor3 = Color3.fromRGB(117, 120, 137),
            TextSize = 11,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local divider = create("Frame", {
            Position = UDim2.fromOffset(24, 139),
            Size = UDim2.new(1, -48, 0, 1),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, card)

        local status = create("TextLabel", {
            Position = UDim2.fromOffset(24, 155),
            Size = UDim2.new(1, -90, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = "Initializing core...",
            TextColor3 = Color3.fromRGB(174, 177, 191),
            TextSize = 11,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local percent = create("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -24, 0, 155),
            Size = UDim2.fromOffset(55, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "0%",
            TextColor3 = LoadingAccentLight,
            TextSize = 11,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, card)

        local progressTrack = create("Frame", {
            Position = UDim2.fromOffset(24, 187),
            Size = UDim2.new(1, -48, 0, 7),
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, card)
        create("UICorner", {CornerRadius = UDim.new(1, 0)}, progressTrack)

        local progressFill = create("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = LoadingAccentLight,
            BorderSizePixel = 0,
        }, progressTrack)
        create("UICorner", {CornerRadius = UDim.new(1, 0)}, progressFill)

        local footer = create("TextLabel", {
            Position = UDim2.fromOffset(24, 207),
            Size = UDim2.new(1, -48, 0, 18),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = "Preparing a smooth and secure experience",
            TextColor3 = Color3.fromRGB(74, 77, 91),
            TextSize = 9,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local warningPanel = create("Frame", {
            Position = UDim2.fromOffset(24, 151),
            Size = UDim2.new(1, -48, 0, 39),
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, card)
        create("UICorner", {CornerRadius = UDim.new(0, 8)}, warningPanel)
        local warningStroke = create("UIStroke", {
            Color = LoadingAccent,
            Thickness = 1,
            Transparency = 1,
        }, warningPanel)

        local warningText = create("TextLabel", {
            Position = UDim2.fromOffset(11, 0),
            Size = UDim2.new(1, -22, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = EarlyUnsupportedName
                and (EarlyUnsupportedName .. " is not supported. The main script will not be loaded.")
                or "",
            TextColor3 = Color3.fromRGB(174, 177, 191),
            TextSize = 10,
            TextTransparency = 1,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, warningPanel)

        local closeUnsupportedButton = create("TextButton", {
            Position = UDim2.fromOffset(24, 199),
            Size = UDim2.new(1, -48, 0, 30),
            BackgroundColor3 = LoadingAccent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold,
            Text = "Close",
            TextColor3 = Color3.fromRGB(239, 240, 247),
            TextSize = 11,
            TextTransparency = 1,
            Visible = false,
        }, card)
        create("UICorner", {CornerRadius = UDim.new(0, 8)}, closeUnsupportedButton)

        local function tween(object, duration, properties, style, direction)
            local animation = LoadingTweenService:Create(
                object,
                TweenInfo.new(
                    duration,
                    style or Enum.EasingStyle.Quint,
                    direction or Enum.EasingDirection.Out
                ),
                properties
            )
            animation:Play()
            return animation
        end

        local function closeLoading()
            if not loadingGui.Parent then return end
            tween(cardScale, 0.35, {Scale = targetCardScale * 0.96})
            tween(card, 0.35, {
                Position = UDim2.fromScale(0.5, 0.48),
                BackgroundTransparency = 1,
            })
            tween(overlay, 0.4, {BackgroundTransparency = 1})
            for _, object in ipairs(card:GetDescendants()) do
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                    tween(object, 0.25, {TextTransparency = 1, BackgroundTransparency = 1})
                elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
                    tween(object, 0.25, {ImageTransparency = 1, BackgroundTransparency = 1})
                elseif object:IsA("Frame") then
                    tween(object, 0.25, {BackgroundTransparency = 1})
                elseif object:IsA("UIStroke") then
                    tween(object, 0.25, {Transparency = 1})
                end
            end
            task.wait(0.4)
            if loadingGui.Parent then loadingGui:Destroy() end
        end

        tween(overlay, 0.3, {BackgroundTransparency = 0.12})
        tween(card, 0.45, {
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 0.05,
        })
        tween(cardScale, 0.45, {Scale = targetCardScale})
        tween(cardStroke, 0.4, {Transparency = 0.5})
        tween(badge, 0.35, {BackgroundTransparency = 0.05, TextTransparency = 0})
        tween(logo, 0.4, {BackgroundTransparency = 0.02})
        tween(logoStroke, 0.4, {Transparency = 0.15})
        tween(logoImage, 0.4, {ImageTransparency = loadingLogoAsset ~= "" and 0 or 1})
        tween(logoFallback, 0.4, {TextTransparency = 0})
        tween(title, 0.4, {TextTransparency = 0})
        tween(subtitle, 0.4, {TextTransparency = 0})
        tween(divider, 0.4, {BackgroundTransparency = 0.35})

        tween(status, 0.4, {TextTransparency = 0})
        tween(percent, 0.4, {TextTransparency = 0})
        tween(progressTrack, 0.4, {BackgroundTransparency = 0})
        tween(footer, 0.4, {TextTransparency = 0})
        tween(progressFill, 4.65, {Size = UDim2.fromScale(1, 1)}, Enum.EasingStyle.Quart)

        local startedAt = os.clock()
        local stages = {
            {time = 0, text = "Initializing core..."},
            {time = 1.15, text = "Loading interface assets..."},
            {time = 2.35, text = "Connecting game systems..."},
            {time = 3.55, text = "Applying security checks..."},
            {time = 4.55, text = "Ready to launch."},
        }
        local stageIndex = 1

        while os.clock() - startedAt < 5 do
            local elapsed = os.clock() - startedAt
            local progress = math.clamp(elapsed / 5, 0, 1)
            percent.Text = tostring(math.floor(progress * 100 + 0.5)) .. "%"

            if stageIndex < #stages and elapsed >= stages[stageIndex + 1].time then
                stageIndex += 1
                status.TextTransparency = 1
                status.Text = stages[stageIndex].text
                tween(status, 0.2, {TextTransparency = 0})
            end
            task.wait(0.08)
        end

        percent.Text = "100%"
        status.Text = "Ready to launch."
        progressFill.Size = UDim2.fromScale(1, 1)
        task.wait(0.18)

        if EarlyUnsupportedName then
            local dismissed = false
            closeUnsupportedButton.MouseEnter:Connect(function()
                tween(closeUnsupportedButton, 0.15, {BackgroundColor3 = LoadingAccentLight})
            end)
            closeUnsupportedButton.MouseLeave:Connect(function()
                tween(closeUnsupportedButton, 0.15, {BackgroundColor3 = LoadingAccent})
            end)
            closeUnsupportedButton.Activated:Connect(function()
                dismissed = true
            end)

            tween(cardScale, 0.22, {Scale = targetCardScale * 0.965}, Enum.EasingStyle.Quart)
            tween(badge, 0.18, {TextTransparency = 1, BackgroundTransparency = 1})
            tween(title, 0.18, {TextTransparency = 1})
            tween(subtitle, 0.18, {TextTransparency = 1})
            tween(status, 0.18, {TextTransparency = 1})
            tween(percent, 0.18, {TextTransparency = 1})
            tween(progressTrack, 0.18, {BackgroundTransparency = 1})
            tween(progressFill, 0.18, {BackgroundTransparency = 1})
            tween(footer, 0.18, {TextTransparency = 1})
            task.wait(0.22)

            badge.Text = "UNSUPPORTED EXECUTOR"
            badge.Size = UDim2.fromOffset(164, 24)
            title.Text = EarlyUnsupportedName .. " Not Supported"
            subtitle.Text = "ICEHUB cannot start on this executor."
            warningPanel.Visible = true
            closeUnsupportedButton.Visible = true
            status.Visible = false
            percent.Visible = false
            progressTrack.Visible = false
            footer.Visible = false

            tween(cardScale, 0.38, {Scale = targetCardScale})
            tween(badge, 0.3, {BackgroundTransparency = 0.05, TextTransparency = 0})
            tween(title, 0.32, {TextTransparency = 0})
            tween(subtitle, 0.36, {TextTransparency = 0})
            tween(warningPanel, 0.38, {BackgroundTransparency = 0.05})
            tween(warningStroke, 0.38, {Transparency = 0.2})
            tween(warningText, 0.4, {TextTransparency = 0})
            tween(closeUnsupportedButton, 0.42, {
                BackgroundTransparency = 0,
                TextTransparency = 0,
            })

            repeat task.wait() until dismissed or not loadingGui.Parent
            closeLoading()
        else
            closeLoading()
        end
    end

    if EarlyUnsupportedName then return end

    local function cleanup()
        for _,name in pairs({"IceHubMain","IceHubGui","SpamCenter","IceHubPlayerViewer","IceDarkUI","IceDarkMobileLauncher","IceDarkNotifications","IceHubLoading","IceHubCustomRadialWheel","IceHubEmoteMobileButton"}) do
            local old=game.CoreGui:FindFirstChild(name); if old then old:Destroy() end
        end
    end
    cleanup()

    -- ═══ SERVICES ════════════════════════════════════════════════════
    local RunService        = game:GetService("RunService")
    local Players           = game:GetService("Players")
    local LocalPlayer       = Players.LocalPlayer
    local UserInputService  = game:GetService("UserInputService")
    local TweenService      = game:GetService("TweenService")
    local StatsService      = game:GetService("Stats")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService       = game:GetService("HttpService")
    local TextService       = game:GetService("TextService")
    local ContentProvider   = game:GetService("ContentProvider")
    local Lighting          = game:GetService("Lighting")
    local CoreGui           = game:GetService("CoreGui")

    local mouse     = LocalPlayer:GetMouse()
    local cloneref  = cloneref or function(s) return s end

    -- ═══ STATE ════════════════════════════════════════════════════════
    local spamRemote,spamRaw=nil,nil
    local spamRevertedRemotes={}
    local revertedRemotes={}
    local AnimFix=false; local ShowPeak=false
    local ManualSpamEnabled=false
    local CooldownProtect=false; local Headless=false; local LowRender=false
    local spamActive=false; local peakVel=0
    local fireParry
    local spamRemoteHooked=false
    local Selected_Parry_Type=nil
    local autoSpamParryEnabled=false
    local autoSpamParryConn=nil
    getgenv().lobbyAutoParry = getgenv().lobbyAutoParry or false
    getgenv().lobbyParryAccuracy = getgenv().lobbyParryAccuracy or 100
    getgenv().lobbyRandomAccuracy = getgenv().lobbyRandomAccuracy or false
    getgenv().lobbyParryKeypress = getgenv().lobbyParryKeypress or false
    getgenv().SelectedParryMode = getgenv().SelectedParryMode or "Remote"
    getgenv().semiImmortalBeta = getgenv().semiImmortalBeta or false
    getgenv().AbilityESP=false
    local lastSpamTime=0
    local billboardLabels={}
    local spamInterval=0.05
    local detections={infinity=false,deathslash=false,timehole=false,slashesoffury=false,phantom=false,pull=false}
    local infinity_active=false; local deathslash_active=false
    local timehole_active=false; local slashesoffury_active=false; local pull_active=false
    local slashesoffury_count=0; local maxParryCount=36; local parryDelay=0.05
    local DISCORD_LINK="https://discord.gg/hMHCnUJNMG"
    local lobbyAutoParryConnection = nil
    local lobbyTrainingParried = false
    local lobbyLastParryTime = 0
    local lobbyLastBallTarget = nil
    local LobbyAP_Speed_Divisor_Multiplier = 1.1
    local function isInGame() return workspace:FindFirstChild("Alive")~=nil end
    local function isInLobby() return workspace:FindFirstChild("TrainingBalls")~=nil end

    -- Capture the native remote methods before the Auto Parry metatable hook is installed.
    local function getEarlySpamGlobal(name)
        local value
        pcall(function()
            local env=getgenv and getgenv()
            value=env and env[name]
        end)
        if value~=nil then return value end
        pcall(function()
            local env=getfenv and getfenv(0)
            value=env and env[name]
        end)
        if value~=nil then return value end
        pcall(function()
            local env=getrenv and getrenv()
            value=env and env[name]
        end)
        if value~=nil then return value end
        if _G and _G[name]~=nil then return _G[name] end
        if shared and shared[name]~=nil then return shared[name] end
        return nil
    end

    local spamHookFunction=hookfunction or getEarlySpamGlobal("hookfunction") or getEarlySpamGlobal("hookfunc")
    local spamNewCClosure=newcclosure or getEarlySpamGlobal("newcclosure") or function(f) return f end

    local function isValidSpamRemoteArgs(args)
        return #args==7
            and type(args[2])=="string"
            and type(args[3])=="number"
            and typeof(args[4])=="CFrame"
            and type(args[5])=="table"
            and type(args[6])=="table"
            and type(args[7])=="boolean"
    end

    getgenv()._hookUsedStr="None"

    if spamHookFunction and spamNewCClosure then
        local ok,err=pcall(function()
            local dummyEvent=Instance.new("RemoteEvent")
            local dummyFunc=Instance.new("RemoteFunction")

            local origFS
            origFS=spamHookFunction(dummyEvent.FireServer,spamNewCClosure(function(self,...)
                local args={...}
                if isValidSpamRemoteArgs(args) then
                    if not spamRevertedRemotes[self] then
                        spamRevertedRemotes[self]={args=args,raw=origFS}
                    end
                    if not revertedRemotes[self] then
                        revertedRemotes[self]=args
                    end
                    if not spamRemoteHooked then
                        spamRemoteHooked=true
                        spamRemote=self
                        spamRaw=origFS
                    end
                    return origFS(self,unpack(args))
                end
                return origFS(self,...)
            end))

            local origIS
            origIS=spamHookFunction(dummyFunc.InvokeServer,spamNewCClosure(function(self,...)
                local args={...}
                if isValidSpamRemoteArgs(args) then
                    if not spamRevertedRemotes[self] then
                        spamRevertedRemotes[self]={args=args,raw=origIS}
                    end
                    if not revertedRemotes[self] then
                        revertedRemotes[self]=args
                    end
                    if not spamRemoteHooked then
                        spamRemoteHooked=true
                        spamRemote=self
                        spamRaw=origIS
                    end
                    return origIS(self,unpack(args))
                end
                return origIS(self,...)
            end))

            getgenv()._hookUsedStr="HookFunction (Deep Bypass)"
        end)
        if not ok then warn("Hook failed: ",err) end
    end

    -- ═══ LOBBY AUTO PARRY ════════════════════════════════════════════

    -- AUTO PARRY SYSTEM (literal ap.txt core; startup controlled by UI)
    repeat task.wait() until game:IsLoaded()

    local Players = cloneref(game:GetService('Players'))
    local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
    local UserInputService = cloneref(game:GetService('UserInputService'))
    local RunService = cloneref(game:GetService('RunService'))
    local Stats = cloneref(game:GetService('Stats'))

    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end

    local Alive = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive", 3)
    local Runtime = workspace:FindFirstChild("Runtime")

    -- ═══ ALION-STYLE ACCURACY VARS ═══════════════════════════════════════
    local AccuracyMin      = 100   -- slider value (1-100)
    local AccuracyMax      = 100   -- used when humanizer is on
    local HumanizerEnabled = false -- random accuracy per-ball toggle

    -- Per-ball parry state (replaces single __parried flag)
    local GlobalParryLocks = {}

    local System = {
        __properties = {
            __autoparry_enabled = false,
            __play_animation = false,
            __curve_mode = 1,
            __accuracy = 1,
            __divisor_multiplier = 1.1,
            __parried = false,
            __parries = 0,
            __grab_animation = nil,
            __tornado_time = tick(),
            __connections = {},
            __reverted_remotes = {},
            __infinity_active = false,
            __deathslash_active = false,
            __timehole_active = false,
            __pull_active = false,
            __slashesoffury_active = false,
            __slashesoffury_count = 0,
            __randomized_accuracy_enabled = false,
            __is_mobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
        },

        __config = {
            __curve_names = {'Camera', 'Random', 'Accelerated', 'Backwards', 'Slow', 'High'},
            __detections = {
                __infinity = false,
                __deathslash = false,
                __timehole = false,
                __pull = false,
                __slashesoffury = false,
                __phantom = false
            }
        }
    }

    local Parry_Key = nil
    local PF = nil

    local function update_divisor()
        -- Safer multiplier: max ~1.0 instead of >3.5
        System.__properties.__divisor_multiplier = 0.59 + (System.__properties.__accuracy - 1) * (0.41 / 99)
    end

    local function update_randomized_accuracy()
        -- legacy compat: kept for UI sliders that still reference __randomized_accuracy_enabled
        if not System.__properties.__randomized_accuracy_enabled then return end
        local ping_str = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        local ping = tonumber(ping_str:match("%d+")) or 0
        local new_accuracy
        if ping >= 90 then
            new_accuracy = 4
        elseif ping <= 50 then
            new_accuracy = math.random(70, 100)
        else
            new_accuracy = System.__properties.__accuracy
        end
        if new_accuracy then
            System.__properties.__accuracy = new_accuracy
            update_divisor()
        end
    end

    -- ═══ ALION CURVE DETECTOR ════════════════════════════════════════════
    -- Tek tablo: 14 local → 1 local (Lua 200-local limitini aşmamak için)
    local _BD = {
        MIN_SPEED      = 1,
        MIN_DIST       = 0.001,
        LERP_FACTOR    = 0.55,
        LERP_THRESHOLD = 0.022,
        TI_WINDOW_DIV  = 1.15,
        CURVE_ANGLE    = 0.08,
        BACK_RANGE     = 200,
        FRAME_TIME     = 1/60,
        -- cached ping (0.1s'de güncellenir)
        pingSec       = 0,
        pingThreshold = 0.45,
        -- warp/lerp state
        props = {
            lerp_radians = 0,
            last_warping = tick(),
            curving      = tick(),
        },
    }

    task.spawn(function()
        local pingItem = Stats.Network.ServerStatsItem["Data Ping"]
        while true do
            local ms = pingItem:GetValue()
            _BD.pingSec       = ms / 1000
            _BD.pingThreshold = math.clamp(0.40 + _BD.pingSec * 0.3, 0.40, 0.60)
            task.wait(0.1)
        end
    end)

    -- BallHelper.ball_curved (ported from alion, uses _BD table)
    local function ballCurved()
        local ball = System.ball.get()
        if not ball then return false end
        local zoomies = ball:FindFirstChild("zoomies")
        if not zoomies then return false end
        local char = LocalPlayer.Character
        if not char then return false end
        local hrp = char.PrimaryPart
        if not hrp then return false end

        local velocity = zoomies.VectorVelocity
        local speed    = velocity.Magnitude
        if speed < _BD.MIN_SPEED then return false end

        local delta    = hrp.Position - ball.Position
        local distance = delta.Magnitude
        if distance < _BD.MIN_DIST then return false end

        local toMe    = delta * (1 / distance)
        local velUnit = velocity * (1 / speed)
        local pingSec = _BD.pingSec

        local timeToImpact = math.max(distance / speed - pingSec, _BD.FRAME_TIME)
        local targeted     = ball:GetAttribute("target") == LocalPlayer.Name

        -- Signal 1: current alignment dot
        local dot = toMe:Dot(velUnit)

        -- Signal 2: predictive dot (lookahead scales with distance)
        local lookahead   = math.clamp(pingSec * 2 + (distance / speed) * 0.1, pingSec * 2, 0.5)
        local futurePos   = ball.Position + velocity * lookahead
        local futureDelta = hrp.Position - futurePos
        local futureDist  = futureDelta.Magnitude
        local futureDot   = futureDist > _BD.MIN_DIST
            and (futureDelta * (1 / futureDist)):Dot(velUnit)
            or dot

        -- Signal 3: lateral cross magnitude
        local cross = toMe:Cross(velUnit).Magnitude

        -- Signal 4: predictive miss
        local predictedPos = ball.Position + velocity * timeToImpact
        local missAmount   = (hrp.Position - predictedPos).Magnitude
        local hitbox       = math.clamp(4 + pingSec * speed * 0.08 + distance * 0.04, 4, 22)
        local willMiss     = missAmount > hitbox

        -- Backwards curve
        if targeted and distance < _BD.BACK_RANGE then
            if dot < 0.05 and futureDot < 0.15 then
                return true
            end
            local bcDotThreshold = math.clamp(0.55 - (distance / _BD.BACK_RANGE) * 0.25, 0.30, 0.55)
            if willMiss and dot < bcDotThreshold and speed > 15 then
                return true
            end
        end

        -- Warp guard
        local p = _BD.props
        local angleRad = math.acos(math.clamp(dot, -1, 1))
        p.lerp_radians = p.lerp_radians + _BD.LERP_FACTOR * (angleRad - p.lerp_radians)

        if p.lerp_radians < _BD.LERP_THRESHOLD then
            p.last_warping = tick()
        end

        local now      = tick()
        local tiWindow = math.min(timeToImpact / _BD.TI_WINDOW_DIV, 0.6)

        if (now - p.last_warping) < tiWindow
        and (now - p.curving)     < tiWindow then
            return true
        end

        -- Final gate: cross + dot, distance-aware
        local crossNeeded = _BD.CURVE_ANGLE + (distance / 500) * 0.05
        if cross > crossNeeded and dot < _BD.pingThreshold then
            return true
        end
        if targeted and cross > crossNeeded * 2 then
            return true
        end

        return false
    end

    local function computeLobbySpeedDivisorMultiplierFromPercent(value)
        value = math.clamp(value or 100, 1, 100)
        return 0.7 + (value - 1) * (0.35 / 99)
    end

    local function computeLobbyParryAccuracy(speed, ping, multiplier)
        local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
        local speed_divisor_base = 2.4 + capped_speed_diff * 0.002
        local speed_divisor = speed_divisor_base * (multiplier or 1)
        if speed_divisor <= 0 then
            return ping
        end
        return ping + math.max(speed / speed_divisor, 9.5)
    end

    local function getLobbyBall()
        local training_balls = workspace:FindFirstChild("TrainingBalls")
        if not training_balls then
            return nil
        end

        for _, instance in pairs(training_balls:GetChildren()) do
            if instance:GetAttribute("realBall") then
                return instance
            end
        end

        return nil
    end

    task.spawn(function()
        while task.wait(1) do
            if System.__properties.__randomized_accuracy_enabled then
                update_randomized_accuracy()
            end
        end
    end)

    local DualBypassSystem = {
        __properties = {
            __captured_data = nil,
            __test_bypass_enabled = true,
            __original_metatables = {},
        }
    }

    function DualBypassSystem.isValidRemoteArgs(args)
        return #args == 7 and
            type(args[2]) == "string" and
            type(args[3]) == "number" and
            typeof(args[4]) == "CFrame" and
            type(args[5]) == "table" and
            type(args[6]) == "table" and
            type(args[7]) == "boolean"
    end

    function DualBypassSystem.hookRemote(remote)
        if not DualBypassSystem.__properties.__original_metatables[getrawmetatable(remote)] then
            DualBypassSystem.__properties.__original_metatables[getrawmetatable(remote)] = true
            local meta = getrawmetatable(remote)
            setreadonly(meta, false)

            local oldIndex = meta.__index
            meta.__index = function(self, key)
                if (key == "FireServer" and self:IsA("RemoteEvent")) or
                (key == "InvokeServer" and self:IsA("RemoteFunction")) then
                    return function(obj, ...)
                        local args = {...}
                        if DualBypassSystem.isValidRemoteArgs(args) and not DualBypassSystem.__properties.__captured_data then
                            DualBypassSystem.__properties.__captured_data = {
                                remote = obj,
                                args = args
                            }
                        end

                        if DualBypassSystem.isValidRemoteArgs(args) and not revertedRemotes[obj] then
                            revertedRemotes[obj] = args
                            Parry_Key = args[2]
                        end

                        return oldIndex(self, key)(obj, unpack(args))
                    end
                end
                return oldIndex(self, key)
            end
            setreadonly(meta, true)
        end
    end

    for _, remote in pairs(ReplicatedStorage:GetChildren()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            DualBypassSystem.hookRemote(remote)
        end
    end

    ReplicatedStorage.ChildAdded:Connect(function(child)
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            DualBypassSystem.hookRemote(child)
        end
    end)

    System.animation = {}

    function System.animation.play_grab_parry()
        if not System.__properties.__play_animation then
            return
        end

        local character = LocalPlayer.Character
        if not character then return end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        local animator = humanoid and humanoid:FindFirstChildOfClass('Animator')
        if humanoid and not animator then
            animator = Instance.new('Animator')
            animator.Parent = humanoid
        end
        if not humanoid or not animator then return end

        local sword_name = character:GetAttribute('CurrentlyEquippedSword')
        if not sword_name then return end

        local sword_api = ReplicatedStorage.Shared.SwordAPI.Collection
        local parry_animation = sword_api.Default:FindFirstChild('GrabParry')
        if not parry_animation then return end

        local sword_data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(sword_name)
        if not sword_data or not sword_data['AnimationType'] then return end

        for _, object in pairs(sword_api:GetChildren()) do
            if object.Name == sword_data['AnimationType'] then
                if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                    local animation_type = object:FindFirstChild('GrabParry') and 'GrabParry' or 'Grab'
                    parry_animation = object[animation_type]
                end
            end
        end

        if System.__properties.__grab_animation and System.__properties.__grab_animation.IsPlaying then
            System.__properties.__grab_animation:Stop()
        end

        System.__properties.__grab_animation = animator:LoadAnimation(parry_animation)
        System.__properties.__grab_animation.Priority = Enum.AnimationPriority.Action4
        System.__properties.__grab_animation:Play()
    end

    System.ball = {}

    function System.ball.get()
        local balls = workspace:FindFirstChild('Balls')
        if not balls then return nil end

        for _, ball in pairs(balls:GetChildren()) do
            if ball:GetAttribute('realBall') then
                ball.CanCollide = false
                return ball
            end
        end
        return nil
    end

    function System.ball.get_all()
        local balls_table = {}
        local balls = workspace:FindFirstChild('Balls')
        if not balls then return balls_table end

        for _, ball in pairs(balls:GetChildren()) do
            if ball:GetAttribute('realBall') then
                ball.CanCollide = false
                table.insert(balls_table, ball)
            end
        end
        return balls_table
    end

    System.player = {}

    function System.player.set_spinbot(enabled, speed)
        System.__properties.spinbot_enabled = enabled
        System.__properties.spinbot_speed = speed or 1
        
        if enabled then
            if not System.__properties.spinbot_thread then
                System.__properties.spinbot_thread = coroutine.create(function()
                    local RunService = game:GetService("RunService")
                    while System.__properties.spinbot_enabled do
                        RunService.Heartbeat:Wait()
                        local character = LocalPlayer.Character
                        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                        if character and rootPart then
                            rootPart.CFrame *= CFrame.Angles(0, math.rad(System.__properties.spinbot_speed), 0)
                        end
                    end
                end)
                coroutine.resume(System.__properties.spinbot_thread)
            end
        else
            if System.__properties.spinbot_thread then
                System.__properties.spinbot_thread = nil
            end
        end
    end

    function System.player.set_fly(enabled, speed)
        System.__properties.fly_enabled = enabled
        System.__properties.fly_speed = speed or 50
        
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")
        
        if enabled then
            if not System.__properties.fly_ragdoll_handler then
                System.__properties.fly_ragdoll_handler = humanoid.StateChanged:Connect(function(oldState, newState)
                    if System.__properties.fly_enabled then
                        if newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll then
                            task.defer(function()
                                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                            end)
                        end
                    end
                end)
            end
            
            local gyro = rootPart:FindFirstChild("FlyBodyGyro") or Instance.new("BodyGyro")
            gyro.Name = "FlyBodyGyro"
            gyro.P = 90000
            gyro.MaxTorque = Vector3.new(9000000000.0, 9000000000.0, 9000000000.0)
            gyro.Parent = rootPart
            
            local velocity = rootPart:FindFirstChild("FlyBodyVelocity") or Instance.new("BodyVelocity")
            velocity.Name = "FlyBodyVelocity"
            velocity.Velocity = Vector3.new(0, 0, 0)
            velocity.MaxForce = Vector3.new(9000000000.0, 9000000000.0, 9000000000.0)
            velocity.Parent = rootPart
            
            humanoid.PlatformStand = true
            
            local RunService = game:GetService("RunService")
            local UserInputService = game:GetService("UserInputService")
            
            if not System.__properties.fly_resetter then
                System.__properties.fly_resetter = RunService.Heartbeat:Connect(function()
                    if not System.__properties.fly_enabled then return end
                    if gyro and gyro.Parent then
                        gyro.P = 90000
                        gyro.MaxTorque = Vector3.new(9000000000.0, 9000000000.0, 9000000000.0)
                    end
                    if velocity and velocity.Parent then
                        velocity.MaxForce = Vector3.new(9000000000.0, 9000000000.0, 9000000000.0)
                    end
                    humanoid.PlatformStand = true
                    if not gyro.Parent or not velocity.Parent then
                        if gyro then gyro:Destroy() end
                        if velocity then velocity:Destroy() end
                        gyro = Instance.new("BodyGyro")
                        gyro.Name = "FlyBodyGyro"
                        gyro.P = 90000
                        gyro.MaxTorque = Vector3.new(9000000000.0, 9000000000.0, 9000000000.0)
                        gyro.Parent = rootPart
                        velocity = Instance.new("BodyVelocity")
                        velocity.Name = "FlyBodyVelocity"
                        velocity.Velocity = Vector3.new(0, 0, 0)
                        velocity.MaxForce = Vector3.new(9000000000.0, 9000000000.0, 9000000000.0)
                        velocity.Parent = rootPart
                    end
                end)
            end
            
            if not System.__properties.fly_stepped then
                System.__properties.fly_stepped = RunService.RenderStepped:Connect(function()
                    if not System.__properties.fly_enabled then return end
                    local camCFrame = workspace.CurrentCamera.CFrame
                    local moveDir = Vector3.new(0, 0, 0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                    
                    velocity.Velocity = moveDir * System.__properties.fly_speed
                    gyro.CFrame = camCFrame
                end)
            end
            
        else
            if System.__properties.fly_stepped then
                System.__properties.fly_stepped:Disconnect()
                System.__properties.fly_stepped = nil
            end
            if System.__properties.fly_ragdoll_handler then
                System.__properties.fly_ragdoll_handler:Disconnect()
                System.__properties.fly_ragdoll_handler = nil
            end
            if System.__properties.fly_resetter then
                System.__properties.fly_resetter:Disconnect()
                System.__properties.fly_resetter = nil
            end
            local char = LocalPlayer.Character
            if char then
                local rPart = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if rPart then
                    local g = rPart:FindFirstChild("FlyBodyGyro")
                    if g then g:Destroy() end
                    local v = rPart:FindFirstChild("FlyBodyVelocity")
                    if v then v:Destroy() end
                end
                if hum then
                    hum.PlatformStand = false
                end
            end
        end
    end

    local Closest_Entity = nil

    function System.player.get_closest()
        local max_distance = math.huge
        local closest_entity = nil

        if not Alive then return nil end

        for _, entity in pairs(Alive:GetChildren()) do
            if entity ~= LocalPlayer.Character then
                if entity.PrimaryPart then
                    local distance = LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
                    if distance < max_distance then
                        max_distance = distance
                        closest_entity = entity
                    end
                end
            end
        end

        Closest_Entity = closest_entity
        return closest_entity
    end

    function System.player.get_closest_to_cursor()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
            return nil
        end

        local closest_player = nil
        local minimal_dot = -math.huge
        local camera = workspace.CurrentCamera

        if not Alive then return nil end

        local success, mouse_location = pcall(function()
            return UserInputService:GetMouseLocation()
        end)

        if not success then return nil end

        local ray = camera:ScreenPointToRay(mouse_location.X, mouse_location.Y)
        local pointer = CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction)

        for _, player in pairs(Alive:GetChildren()) do
            if player == LocalPlayer.Character then continue end
            if not player:FindFirstChild('HumanoidRootPart') then continue end

            local direction = (player.HumanoidRootPart.Position - camera.CFrame.Position).Unit
            local dot = pointer.LookVector:Dot(direction)

            if dot > minimal_dot then
                minimal_dot = dot
                closest_player = player
            end
        end

        return closest_player
    end

    System.curve = {}

    function System.curve.get_cframe()
        local camera = workspace.CurrentCamera
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        if not root then return camera.CFrame end

        local targetPart
        local closest = System.player.get_closest_to_cursor()
        if closest and closest:FindFirstChild('HumanoidRootPart') then
            targetPart = closest.HumanoidRootPart
        end

        local target_pos = targetPart and targetPart.Position or (root.Position + camera.CFrame.LookVector * 100)

        local curve_functions = {
            function() return camera.CFrame end,

            function()
                local direction = (target_pos - root.Position).Unit
                local random_offset
                local attempts = 0
                repeat
                    random_offset = Vector3.new(
                        math.random(-4000, 4000),
                        math.random(-4000, 4000),
                        math.random(-4000, 4000)
                    )
                    local curve_direction = (target_pos + random_offset - root.Position).Unit
                    local dot = direction:Dot(curve_direction)
                    attempts = attempts + 1
                until dot < 0.95 or attempts > 10
                return CFrame.new(root.Position, target_pos + random_offset)
            end,

            function()
                return CFrame.new(root.Position, target_pos + Vector3.new(0, 5, 0))
            end,

            function()
                local direction = (root.Position - target_pos).Unit
                local backwards_pos = root.Position + direction * 10000 + Vector3.new(0, 1000, 0)
                return CFrame.new(camera.CFrame.Position, backwards_pos)
            end,

            function()
                return CFrame.new(root.Position, target_pos + Vector3.new(0, -9e18, 0))
            end,

            function()
                return CFrame.new(root.Position, target_pos + Vector3.new(0, 9e18, 0))
            end
        }

        return curve_functions[System.__properties.__curve_mode]()
    end

    System.parry = {}

    function System.parry.execute()
        if System.__properties.__parries > 10000 or not LocalPlayer.Character then
            return false
        end

        local camera = workspace.CurrentCamera
        local success, mouse = pcall(function()
            return UserInputService:GetMouseLocation()
        end)

        if not success then return false end

        local vec2_mouse = {mouse.X, mouse.Y}
        local is_mobile = System.__properties.__is_mobile

        local event_data = {}
        if Alive then
            for _, entity in pairs(Alive:GetChildren()) do
                if entity.PrimaryPart then
                    local success2, screen_point = pcall(function()
                        return camera:WorldToScreenPoint(entity.PrimaryPart.Position)
                    end)
                    if success2 then
                        event_data[entity.Name] = screen_point
                    end
                end
            end
        end

        local curve_cframe = System.curve.get_cframe()

        local final_aim_target
        if is_mobile then
            local viewport = camera.ViewportSize
            final_aim_target = {viewport.X / 2, viewport.Y / 2}
        else
            final_aim_target = vec2_mouse
        end

        local fired = false
        for remote, original_args in pairs(revertedRemotes) do
            local modified_args = {
                original_args[1],
                original_args[2],
                original_args[3],
                curve_cframe,
                event_data,
                final_aim_target,
                original_args[7]
            }

            local ok = pcall(function()
                local hookData = spamRevertedRemotes[remote]
                if hookData and hookData.raw then
                    hookData.raw(remote, unpack(modified_args))
                    task.spawn(function()
                        hookData.raw(remote, unpack(modified_args))
                    end)
                else
                    if remote:IsA('RemoteEvent') then
                        remote:FireServer(unpack(modified_args))
                        task.spawn(function()
                            remote:FireServer(unpack(modified_args))
                        end)
                    elseif remote:IsA('RemoteFunction') then
                        remote:InvokeServer(unpack(modified_args))
                    end
                end
            end)
            fired = ok or fired
        end

        if not fired then return false end

        if System.__properties.__parries > 10000 then return false end

        System.__properties.__parries = System.__properties.__parries + 1
        task.delay(0.5, function()
            if System.__properties.__parries > 0 then
                System.__properties.__parries = System.__properties.__parries - 1
            end
        end)
        return true
    end

    function System.parry.execute_action()
        System.animation.play_grab_parry()

        if System.__properties.__parries > 10000 or not LocalPlayer.Character then
            return false
        end

        local mode = getgenv().SelectedParryMode or "Remote"
        
        -- Eğer Remote seçiliyse ama henüz remote hooklanmadıysa, yakalamak için Hardware click'e düş
        if mode == "Remote" and next(revertedRemotes) == nil then
            mode = "Hardware click"
        end

        if mode == "Keypress" then
            if keypress and keyrelease then
                pcall(keypress, 0x46)
                task.spawn(function()
                    task.wait(0.05)
                    pcall(keyrelease, 0x46)
                end)
            else
                local vim = game:GetService("VirtualInputManager")
                pcall(function()
                    vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                end)
                task.spawn(function()
                    task.wait(0.05)
                    pcall(function()
                        vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    end)
                end)
            end
            
            -- Hookfunction bypassed remote çağrısını tetikle (Curve bu çağrının içinde çalışır)
            System.parry.execute()
            
            return true
        elseif mode == "Hardware click" then
            if mouse1click then
                pcall(mouse1click)
            else
                local vim = game:GetService("VirtualInputManager")
                local cam = workspace.CurrentCamera
                local viewport = cam and cam.ViewportSize or Vector2.new(800, 600)
                local x, y = viewport.X / 2, viewport.Y / 2
                pcall(function()
                    vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
                end)
                task.spawn(function()
                    task.wait(0.05)
                    pcall(function()
                        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
                    end)
                end)
            end
            
            -- Hookfunction bypassed remote çağrısını tetikle (Curve bu çağrının içinde çalışır)
            System.parry.execute()
            
            return true
        else
            -- Wait for a real manual parry to provide the hooked remote arguments.
            if next(revertedRemotes) == nil then
                return false
            end

            return System.parry.execute()
        end
    end

    local function linear_predict(a, b, time_volume)
        return a + (b - a) * time_volume
    end

    System.detection = {
        __ball_properties = {
            __aerodynamic_time = tick(),
            __last_warping = tick(),
            __lerp_radians = 0,
            __curving = tick()
        }
    }

    -- ═══ is_curved: alion'un BallHelper.ball_curved sistemini kullanır ═══
    function System.detection.is_curved()
        return ballCurved()
    end

    ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c, d)
        System.__properties.__deathslash_active = d or false
    end)

    ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
        System.__properties.__infinity_active = b or false
    end)

    if ReplicatedStorage.Remotes:FindFirstChild("PlrPulled") then
        ReplicatedStorage.Remotes.PlrPulled.OnClientEvent:Connect(function(a, b)
            if type(a) == "boolean" then
                System.__properties.__pull_active = a
            elseif type(b) == "boolean" then
                System.__properties.__pull_active = b
            else
                System.__properties.__pull_active = true
                task.delay(1.5, function() System.__properties.__pull_active = false end)
            end
        end)
    end

    if ReplicatedStorage.Remotes:FindFirstChild("PlrPulsed") then
        ReplicatedStorage.Remotes.PlrPulsed.OnClientEvent:Connect(function(a, b)
            if type(a) == "boolean" then
                System.__properties.__pull_active = a
            elseif type(b) == "boolean" then
                System.__properties.__pull_active = b
            else
                System.__properties.__pull_active = true
                task.delay(1.5, function() System.__properties.__pull_active = false end)
            end
        end)
    end

    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(...)
        local args = {...}
        local player = args[1]

        if player == LocalPlayer or player == LocalPlayer.Name or (player and player.Name == LocalPlayer.Name) then
            System.__properties.__timehole_active = true
        end
    end)

    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function()
        System.__properties.__timehole_active = false
    end)

    System.autoparry = {}

    function System.autoparry.start()
        if System.__properties.__connections.__autoparry then
            System.__properties.__connections.__autoparry:Disconnect()
        end

        -- ── processParry: alion mimarisi (per-ball GlobalParryLocks) ──────────
        local function processParry(ball, is_training)
            if not ball then return end

            local zoomies = ball:FindFirstChild('zoomies')
            if not zoomies then return end

            -- Per-ball state (alion'dan: GlobalParryLocks)
            if not GlobalParryLocks[ball] then
                GlobalParryLocks[ball] = {
                    ParriedLastBall    = false,
                    lastTarget         = nil,
                    lastFireTick       = 0,
                    CurrentRandomAcc   = AccuracyMin,
                }
            end
            local lockData      = GlobalParryLocks[ball]
            local currentTarget = ball:GetAttribute('target')

            -- Re-roll accuracy her yeni hedef değişiminde
            if currentTarget ~= lockData.lastTarget then
                lockData.ParriedLastBall  = false
                lockData.lastTarget       = currentTarget
                if HumanizerEnabled then
                    local mn = math.min(AccuracyMin, AccuracyMax)
                    local mx = math.max(AccuracyMin, AccuracyMax)
                    lockData.CurrentRandomAcc = math.random(mn, mx)
                else
                    lockData.CurrentRandomAcc = AccuracyMin
                end
            end

            -- 1 saniyelik parry lock
            if lockData.ParriedLastBall then
                if (tick() - lockData.lastFireTick) > 1 then
                    lockData.ParriedLastBall = false
                else
                    return
                end
            end

            local velocity  = zoomies.VectorVelocity
            local distance  = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude

            -- Alion ping threshold (daha hassas)
            local pingValue      = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
            if type(pingValue) == "string" then pingValue = tonumber(pingValue:match("%d+%.?%d*")) or 50 end
            local ping           = pingValue
            local ping_threshold = math.clamp(ping / 10, 5, 17)
            local speed          = velocity.Magnitude

            -- Per-ball accuracy hesaplama (alion'dan)
            local capped_speed_diff  = math.max(speed - 9.5, 0)
            local currentAcc         = lockData.CurrentRandomAcc or AccuracyMin
            local mappedAcc          = 1 + (currentAcc - 1) * (79 / 99)
            -- Use a safer multiplier range (0.75 to ~1.15) instead of going up to >3
            local perBallDivisorMult = 0.75 + (mappedAcc - 1) * (0.4 / 79)
            local speed_divisor      = (2.4 + capped_speed_diff * 0.002) * perBallDivisorMult
            local parry_accuracy     = ping_threshold + math.max(speed / speed_divisor, 9.5)

            -- Parry modu latency compensation
            local mode = getgenv().SelectedParryMode or "Remote"
            if mode ~= "Remote" then
                parry_accuracy = parry_accuracy + speed * (mode == "Keypress" and 0.095 or 0.055)
            end

            if not is_training then
                -- Alion'dan: ballCurved() (predictive curve detection)
                local curved = ballCurved()

                if ball:FindFirstChild('AeroDynamicSlashVFX') then
                    ball.AeroDynamicSlashVFX:Destroy()
                    System.__properties.__tornado_time = tick()
                end

                if Runtime:FindFirstChild('Tornado') then
                    if (tick() - System.__properties.__tornado_time) <
                       (Runtime.Tornado:GetAttribute('TornadoTime') or 1) + 0.314159 then
                        return
                    end
                end

                -- Curved = bait, tamamen atla
                if currentTarget == LocalPlayer.Name and curved then return end

                if ball:FindFirstChild('ComboCounter') then return end
                if LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then return end
                if System.__config.__detections.__infinity   and System.__properties.__infinity_active   then return end
                if System.__config.__detections.__deathslash and System.__properties.__deathslash_active then return end
                if System.__config.__detections.__timehole   and System.__properties.__timehole_active   then return end
                if System.__config.__detections.__pull       and System.__properties.__pull_active       then return end
            end

            -- 0.15 s fire-rate guard (alion'dan)
            if currentTarget == LocalPlayer.Name and distance <= parry_accuracy then
                if (tick() - lockData.lastFireTick) >= 0.15 then
                    lockData.ParriedLastBall = true
                    lockData.lastFireTick    = tick()
                    System.parry.execute_action()
                end
            end
        end
        -- ─────────────────────────────────────────────────────────────────────

        System.__properties.__connections.__autoparry = RunService.PreSimulation:Connect(function()
            if not System.__properties.__autoparry_enabled or not LocalPlayer.Character or
               not LocalPlayer.Character.PrimaryPart then
                return
            end

            local balls = System.ball.get_all()

            -- Oyun içi toplar
            for _, ball in pairs(balls) do
                processParry(ball, false)
            end

            -- Lobby training topu
            local trainingBalls = workspace:FindFirstChild("TrainingBalls")
            if trainingBalls then
                for _, inst in pairs(trainingBalls:GetChildren()) do
                    if inst:GetAttribute("realBall") then
                        processParry(inst, true)
                        break
                    end
                end
            end
        end)
    end

    function System.autoparry.stop()
        if System.__properties.__connections.__autoparry then
            System.__properties.__connections.__autoparry:Disconnect()
            System.__properties.__connections.__autoparry = nil
        end
    end

    getgenv().updateLobbyAutoParry = function()
        if lobbyAutoParryConnection then
            lobbyAutoParryConnection:Disconnect()
            lobbyAutoParryConnection = nil
        end

        if not getgenv().lobbyAutoParry then
            lobbyTrainingParried = false
            lobbyLastBallTarget = nil
            return
        end

        LobbyAP_Speed_Divisor_Multiplier = computeLobbySpeedDivisorMultiplierFromPercent(getgenv().lobbyParryAccuracy or 100)

        local lobbyParryUpdateCounter = 0
        lobbyAutoParryConnection = RunService.Heartbeat:Connect(function()
            lobbyParryUpdateCounter += 1
            if lobbyParryUpdateCounter % 2 ~= 0 then
                return
            end

            if not getgenv().lobbyAutoParry then
                return
            end

            if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
                return
            end

            if not isInLobby() then
                lobbyTrainingParried = false
                lobbyLastBallTarget = nil
                return
            end

            local ball = getLobbyBall()
            if not ball then
                lobbyTrainingParried = false
                lobbyLastBallTarget = nil
                return
            end

            local zoomies = ball:FindFirstChild("zoomies")
            if not zoomies then
                return
            end

            local ballTarget = ball:GetAttribute("target")
            if ballTarget ~= lobbyLastBallTarget then
                lobbyTrainingParried = false
                lobbyLastBallTarget = ballTarget
            end

            if lobbyTrainingParried then
                if tick() - (lobbyLastParryTime or 0) >= 1 then
                    lobbyTrainingParried = false
                else
                    return
                end
            end

            local velocity = zoomies.VectorVelocity
            local distance = LocalPlayer:DistanceFromCharacter(ball.Position)
            local speed = velocity.Magnitude
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 10

            local effectiveMultiplier = LobbyAP_Speed_Divisor_Multiplier
            if getgenv().lobbyRandomAccuracy then
                effectiveMultiplier = computeLobbySpeedDivisorMultiplierFromPercent(math.random(1, 100))
            end

            local parryAccuracy = computeLobbyParryAccuracy(speed, ping, effectiveMultiplier)
            
            local mode = getgenv().SelectedParryMode or "Remote"
            if mode ~= "Remote" then
                parryAccuracy = parryAccuracy + (speed * (mode == "Keypress" and 0.095 or 0.055))
            end

            if ballTarget == LocalPlayer.Name and distance <= parryAccuracy then
                if System.parry.execute_action() then
                    lobbyTrainingParried = true
                    lobbyLastParryTime = tick()
                end
            end
        end)
    end

    local function startLobbyAutoParry()
        getgenv().lobbyAutoParry = true
        getgenv().updateLobbyAutoParry()
    end

    local function stopLobbyAutoParry()
        getgenv().lobbyAutoParry = false
        getgenv().updateLobbyAutoParry()
    end

    local function startAutoParry()
        System.__properties.__autoparry_enabled = true
        System.autoparry.start()
    end

    local function stopAutoParry()
        System.__properties.__autoparry_enabled = false
        System.autoparry.stop()
    end

    -- MANUEL SPAM GUI
    getgenv().autoSpamKey = getgenv().autoSpamKey or Enum.KeyCode.E
    getgenv().autoSpamNotify = getgenv().autoSpamNotify or false
    getgenv().ManualSpamEnabled = getgenv().ManualSpamEnabled or false
    local spamActive = false

    local SpamGui=Instance.new("ScreenGui",game.CoreGui)
    SpamGui.Name="SpamCenter"
    SpamGui.Enabled=false
    SpamGui.DisplayOrder=998
    SpamGui.ResetOnSpawn=false
    SpamGui.IgnoreGuiInset=true
    getgenv().SpamGui = SpamGui

    local SpamOuter=Instance.new("Frame",SpamGui)
    SpamOuter.Size=UDim2.new(0,188,0,64)
    SpamOuter.Position=UDim2.new(1,-208,0.5,0)
    SpamOuter.BackgroundTransparency=1
    SpamOuter.BorderSizePixel=0

    local SpamBody=Instance.new("Frame",SpamOuter)
    SpamBody.Size=UDim2.new(1,0,1,0)
    SpamBody.BackgroundColor3=Color3.fromRGB(16,10,25)
    SpamBody.BackgroundTransparency=0.02
    SpamBody.BorderSizePixel=0
    Instance.new("UICorner",SpamBody).CornerRadius=UDim.new(0,22)

    local SpamBorder=Instance.new("UIStroke",SpamBody)
    SpamBorder.Color=Color3.fromRGB(168,85,247)
    SpamBorder.Thickness=1
    SpamBorder.Transparency=0.12

    local UIGradient = Instance.new("UIGradient", SpamBody)
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32,20,46)),
        ColorSequenceKeypoint.new(0.52, Color3.fromRGB(16,10,25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25,15,38))
    }
    UIGradient.Rotation = 18

    local SpamAccentBar=Instance.new("Frame",SpamBody)
    SpamAccentBar.Size=UDim2.new(0,5,1,-18)
    SpamAccentBar.Position=UDim2.new(0,10,0,9)
    SpamAccentBar.BackgroundColor3=Color3.fromRGB(168,85,247)
    SpamAccentBar.BorderSizePixel=0
    Instance.new("UICorner",SpamAccentBar).CornerRadius=UDim.new(1,0)
    SpamAccentBar.ZIndex=2

    local SpamDot=Instance.new("Frame",SpamBody)
    SpamDot.Size=UDim2.new(0,32,0,32)
    SpamDot.Position=UDim2.new(0,24,0.5,-16)
    SpamDot.BackgroundColor3=Color3.fromRGB(42,30,56)
    SpamDot.BorderSizePixel=0
    Instance.new("UICorner",SpamDot).CornerRadius=UDim.new(1,0)
    SpamDot.ZIndex=2
    local SpamDotInner=Instance.new("Frame",SpamDot)
    SpamDotInner.AnchorPoint=Vector2.new(0.5,0.5)
    SpamDotInner.Position=UDim2.fromScale(0.5,0.5)
    SpamDotInner.Size=UDim2.fromOffset(12,12)
    SpamDotInner.BackgroundColor3=Color3.fromRGB(178,160,194)
    SpamDotInner.BorderSizePixel=0
    Instance.new("UICorner",SpamDotInner).CornerRadius=UDim.new(1,0)
    SpamDotInner.ZIndex=3

    local SpamLabel=Instance.new("TextLabel",SpamBody)
    SpamLabel.Size=UDim2.new(1,-108,0,22)
    SpamLabel.Position=UDim2.new(0,66,0,13)
    SpamLabel.BackgroundTransparency=1
    SpamLabel.Text="Manual Spam"
    SpamLabel.Font=Enum.Font.GothamBold
    SpamLabel.TextSize=14
    SpamLabel.TextColor3=Color3.fromRGB(248,242,255)
    SpamLabel.TextXAlignment=Enum.TextXAlignment.Left
    SpamLabel.ZIndex=2

    local SpamSubLabel=Instance.new("TextLabel",SpamBody)
    SpamSubLabel.Size=UDim2.new(1,-108,0,16)
    SpamSubLabel.Position=UDim2.new(0,66,0,35)
    SpamSubLabel.BackgroundTransparency=1
    SpamSubLabel.Text="tap to toggle"
    SpamSubLabel.Font=Enum.Font.GothamMedium
    SpamSubLabel.TextSize=10
    SpamSubLabel.TextColor3=Color3.fromRGB(174,156,190)
    SpamSubLabel.TextXAlignment=Enum.TextXAlignment.Left
    SpamSubLabel.ZIndex=2

    local SpamStatusChip=Instance.new("Frame",SpamBody)
    SpamStatusChip.AnchorPoint=Vector2.new(1,0.5)
    SpamStatusChip.Position=UDim2.new(1,-14,0.5,0)
    SpamStatusChip.Size=UDim2.fromOffset(54,26)
    SpamStatusChip.BackgroundColor3=Color3.fromRGB(38,26,51)
    SpamStatusChip.BorderSizePixel=0
    Instance.new("UICorner",SpamStatusChip).CornerRadius=UDim.new(1,0)
    SpamStatusChip.ZIndex=2

    local SpamStatusText=Instance.new("TextLabel",SpamStatusChip)
    SpamStatusText.Size=UDim2.fromScale(1,1)
    SpamStatusText.BackgroundTransparency=1
    SpamStatusText.Text="OFF"
    SpamStatusText.Font=Enum.Font.GothamBlack
    SpamStatusText.TextSize=10
    SpamStatusText.TextColor3=Color3.fromRGB(205,190,220)
    SpamStatusText.ZIndex=3

    local SpamPulse=Instance.new("Frame",SpamBody)
    SpamPulse.Size=UDim2.new(0,32,0,32)
    SpamPulse.Position=UDim2.new(0,24,0.5,-16)
    SpamPulse.BackgroundTransparency=1
    SpamPulse.BorderSizePixel=0
    Instance.new("UICorner",SpamPulse).CornerRadius=UDim.new(1,0)
    SpamPulse.ZIndex=1

    local SpamPulseStroke=Instance.new("UIStroke",SpamPulse)
    SpamPulseStroke.Color=Color3.fromRGB(192,132,252)
    SpamPulseStroke.Thickness=2
    SpamPulseStroke.Transparency=1

    local pulseRunning=false
    local function startPulse()
        if pulseRunning then return end
        pulseRunning=true
        task.spawn(function()
            while spamActive do
                SpamPulse.Size=UDim2.new(0,32,0,32)
                SpamPulse.Position=UDim2.new(0,24,0.5,-16)
                SpamPulseStroke.Transparency=0.1
                TweenService:Create(SpamPulse,TweenInfo.new(0.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,56,0,56),Position=UDim2.new(0,12,0.5,-28)}):Play()
                TweenService:Create(SpamPulseStroke,TweenInfo.new(0.6),{Transparency=1}):Play()
                task.wait(0.8)
            end
            pulseRunning=false
        end)
    end

    getgenv().setSpam = function(val)
        spamActive=val
        if val then
            SpamDot.BackgroundColor3=Color3.fromRGB(45,27,66)
            SpamDotInner.BackgroundColor3=Color3.fromRGB(192,132,252)
            SpamAccentBar.BackgroundColor3=Color3.fromRGB(192,132,252)
            SpamSubLabel.Text="running"
            SpamSubLabel.TextColor3=Color3.fromRGB(216,180,254)
            SpamStatusChip.BackgroundColor3=Color3.fromRGB(126,34,206)
            SpamStatusText.Text="ON"
            SpamStatusText.TextColor3=Color3.fromRGB(255,250,255)
            SpamLabel.TextColor3=Color3.fromRGB(255,250,255)
            SpamBorder.Color=Color3.fromRGB(192,132,252)
            SpamBorder.Transparency=0.02
            TweenService:Create(SpamBody,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(13,16,31)}):Play()
            startPulse()
            if getgenv().autoSpamNotify then
                pcall(function()
                    WindUI:Notify({ Title = "Manuel Spam", Content = "Enabled", Duration = 2 })
                end)
            end
        else
            SpamDot.BackgroundColor3=Color3.fromRGB(42,30,56)
            SpamDotInner.BackgroundColor3=Color3.fromRGB(178,160,194)
            SpamAccentBar.BackgroundColor3=Color3.fromRGB(168,85,247)
            SpamSubLabel.Text="tap to toggle"
            SpamSubLabel.TextColor3=Color3.fromRGB(174,156,190)
            SpamStatusChip.BackgroundColor3=Color3.fromRGB(38,26,51)
            SpamStatusText.Text="OFF"
            SpamStatusText.TextColor3=Color3.fromRGB(205,190,220)
            SpamLabel.TextColor3=Color3.fromRGB(248,242,255)
            SpamBorder.Color=Color3.fromRGB(168,85,247)
            SpamBorder.Transparency=0.12
            SpamPulseStroke.Transparency=1
            SpamPulse.Size=UDim2.new(0,32,0,32)
            SpamPulse.Position=UDim2.new(0,24,0.5,-16)
            TweenService:Create(SpamBody,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(16,10,25)}):Play()
            if getgenv().autoSpamNotify then
                pcall(function()
                    WindUI:Notify({ Title = "Manuel Spam", Content = "Disabled", Duration = 2 })
                end)
            end
        end
    end

    local DRAG_THRESHOLD=10
    local TAP_MAX_TIME=0.3
    local _drag=false
    local _dragStart=nil
    local _posStart=nil
    local _touchTime=0
    local _moved=false
    local _canDrag=false
    local _dragToken=0
    local _lastDragPosition=nil

    local function isOnSpam(pos)
        if not SpamGui.Enabled then return false end
        local abs=SpamOuter.AbsolutePosition
        local siz=SpamOuter.AbsoluteSize
        return pos.X>=abs.X and pos.X<=abs.X+siz.X and pos.Y>=abs.Y and pos.Y<=abs.Y+siz.Y
    end

    UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
        if not isOnSpam(inp.Position) or not isInGame() then return end
        _drag=true
        _moved=false
        _canDrag=inp.UserInputType~=Enum.UserInputType.Touch
        _dragStart=inp.Position
        _lastDragPosition=inp.Position
        _posStart=SpamOuter.Position
        _touchTime=tick()
        _dragToken+=1
        local token=_dragToken
        if inp.UserInputType==Enum.UserInputType.Touch then
            task.delay(0.28,function()
                if _drag and token==_dragToken and not _moved then
                    _canDrag=true
                    _dragStart=_lastDragPosition or _dragStart
                    _posStart=SpamOuter.Position
                end
            end)
        end
        TweenService:Create(SpamBody,TweenInfo.new(0.1),{BackgroundTransparency=0}):Play()
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not _drag then return end
        if inp.UserInputType~=Enum.UserInputType.MouseMovement and inp.UserInputType~=Enum.UserInputType.Touch then return end
        _lastDragPosition=inp.Position
        if not _canDrag then return end
        local d=inp.Position-_dragStart
        if d.Magnitude>DRAG_THRESHOLD then
            _moved=true
            SpamOuter.Position=UDim2.new(_posStart.X.Scale,_posStart.X.Offset+d.X,_posStart.Y.Scale,_posStart.Y.Offset+d.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if not _drag then return end
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
        TweenService:Create(SpamBody,TweenInfo.new(0.1),{BackgroundTransparency=0.1}):Play()
        if not _moved and tick()-_touchTime<TAP_MAX_TIME then
            getgenv().setSpam(not spamActive)
        end
        _drag=false
        _canDrag=false
        _moved=false
        _dragStart=nil
        _lastDragPosition=nil
        _dragToken+=1
    end)

    UserInputService.InputBegan:Connect(function(inp,gp)
        if gp then return end
        if inp.KeyCode==(getgenv().autoSpamKey or Enum.KeyCode.E) and getgenv().ManualSpamEnabled then
            if not isInGame() then return end
            getgenv().setSpam(not spamActive)
        end
    end)

    -- ═══ END AUTO PARRY & AUTO SPAM SYSTEMS ════════════════════════════════════

    -- ═══ GAME SYSTEMS ════════════════════════════════════════════════
    -- Curve used by the existing manual/auto spam systems.
    getgenv().CurrentCurveMethod = getgenv().CurrentCurveMethod or "Camera"
    local function getCurveCFrame()
        local camera = workspace.CurrentCamera
        if not camera then return CFrame.new() end
        local method = getgenv().CurrentCurveMethod or "Camera"
        if method == "Backwards" then
            return CFrame.new(camera.CFrame.Position, camera.CFrame.Position - (camera.CFrame.LookVector * 1000))
        elseif method == "Random" then
            return CFrame.new(camera.CFrame.Position, Vector3.new(math.random(-3000,3000), math.random(-3000,3000), math.random(-3000,3000)))
        else
            return camera.CFrame
        end
    end

    -- Low Render
    local originalQuality=nil
    local function setLowRender(enabled)
        if enabled then
            pcall(function() originalQuality=settings().Rendering.QualityLevel; settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
            pcall(function() game:GetService("Lighting").GlobalShadows=false; game:GetService("Lighting").FogEnd=9e9 end)
        else
            pcall(function() if originalQuality then settings().Rendering.QualityLevel=originalQuality end end)
            pcall(function() game:GetService("Lighting").GlobalShadows=true end)
        end
    end

    local function setNoRender(enabled)
        pcall(function()
            local playerScripts=LocalPlayer:FindFirstChild("PlayerScripts")
            local effectScripts=playerScripts and playerScripts:FindFirstChild("EffectScripts")
            local clientFX=effectScripts and effectScripts:FindFirstChild("ClientFX")
            if clientFX then clientFX.Disabled=enabled end
        end)
    end

    -- Animation used by the existing spam systems.
    local _Shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
    local SwordAPI = _Shared and (_Shared:FindFirstChild("SwordAPI") or _Shared:WaitForChild("SwordAPI", 3))
    local lastplayedd=0; local bypasscd=false; local AnimationDelay=1; local AnimationCache={}; local Grab_Parry=nil
    local function GetCharacter() return LocalPlayer.Character end
    local function GetHumanoid() local char=GetCharacter(); return char and char:FindFirstChildOfClass("Humanoid") end
    local function StopAnimation(track) track:Stop(track:GetAttribute("StopFadeTime") or 0.1) end
    local function PlayGrabAnimation(track) track:Play(track:GetAttribute("PlayFadeTime") or 0,track:GetAttribute("PlayWeight") or 1,track:GetAttribute("PlaySpeed") or 1) end
    local function GetAnimator(hum)
        if not hum then return nil end
        local animator=hum:FindFirstChildOfClass("Animator")
        if not animator then
            animator=Instance.new("Animator")
            animator.Parent=hum
        end
        return animator
    end
    local function GetParryAnimation()
        local char=GetCharacter(); if not char then return nil end
        local cs=char:GetAttribute("CurrentlyEquippedSword"); if not cs then return SwordAPI.Collection.Default:FindFirstChild("GrabParry") end
        if AnimationCache[cs] then return AnimationCache[cs] end
        local ok,sd=pcall(function() return ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(cs) end)
        if not ok or type(sd)~="table" then AnimationCache[cs]=SwordAPI.Collection.Default:FindFirstChild("GrabParry"); return AnimationCache[cs] end
        for _,obj in pairs(SwordAPI.Collection:GetChildren()) do if obj.Name==sd.AnimationType then local a=obj:FindFirstChild("GrabParry") or obj:FindFirstChild("Grab"); if a then AnimationCache[cs]=a; return a end end end
        AnimationCache[cs]=SwordAPI.Collection.Default:FindFirstChild("GrabParry"); return AnimationCache[cs]
    end
    local function PlayParry_Animation()
        local hum=GetHumanoid(); if not hum then return end; local anim=GetParryAnimation(); if not anim then return end
        local animator=GetAnimator(hum); if not animator then return end
        for _,track in pairs(animator:GetPlayingAnimationTracks()) do
            if track.Name=="GrabParry" or track.Name=="Grab" then track.TimePosition=0; StopAnimation(track)
            elseif track.Name=="SuccessParry" or track.Name=="Success" then StopAnimation(track) end
        end
        Grab_Parry=animator:LoadAnimation(anim); PlayGrabAnimation(Grab_Parry)
    end
    local function SpamParry_Animation()
        if (os.clock()-lastplayedd)>=(AnimationDelay-0.8) or bypasscd then lastplayedd=os.clock(); bypasscd=false; PlayParry_Animation() end
    end
    pcall(function()
        ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
            bypasscd=true; local hum=GetHumanoid()
            local animator=GetAnimator(hum)
            if animator then for _,t in pairs(animator:GetPlayingAnimationTracks()) do if t.Name=="GrabParry" or t.Name=="Grab" then StopAnimation(t) end end end
        end)
    end)

    -- Byte_Library
    local Byte_Library={}
    local function connectCharEvents(char)
        local hum=char:WaitForChild("Humanoid",10); if not hum then return end
        hum.Died:Connect(function()
            spamActive=false
            lobbyTrainingParried=false
            lobbyLastBallTarget=nil
        end)
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        lobbyTrainingParried=false
        lobbyLastBallTarget=nil
        if LowRender then setLowRender(true) end
        task.spawn(function() connectCharEvents(char) end)
    end)
    if LocalPlayer.Character then
        lobbyTrainingParried=false
        lobbyLastBallTarget=nil
        task.spawn(function() connectCharEvents(LocalPlayer.Character) end)
    end

    -- ═══ EXECUTOR HELPERS ════════════════════════════════════════════
    local function getExecutorGlobal(name)
        if getgenv and getgenv()[name] ~= nil then return getgenv()[name] end
        if _G and _G[name] ~= nil then return _G[name] end
        if shared and shared[name] ~= nil then return shared[name] end
        if getrenv and getrenv()[name] ~= nil then return getrenv()[name] end

        local val = nil
        pcall(function()
            if gethui then
                local hui = gethui()
                if hui and hui[name] ~= nil then val = hui[name] end
            end
        end)
        if val ~= nil then return val end

        pcall(function()
            if getfenv then
                local env = getfenv(0)
                if env and env[name] ~= nil then val = env[name] end
            end
        end)
        if val ~= nil then return val end

        return nil
    end

    -- Ball Finder
    local function findBall()
        local bc=workspace:FindFirstChild("Balls")
        if bc then for _,b in pairs(bc:GetChildren()) do if b:IsA("BasePart") and b:GetAttribute("realBall") then return b end end
            local b=bc:GetChildren()[1]; if b and b:IsA("BasePart") then return b end end
        for _,v in ipairs(workspace:GetChildren()) do if v:IsA("BasePart") and v.Name:lower():find("ball") then return v end end
        for _,fn in ipairs({"TrainingBalls","Lobby","Training","Practice","Map","Game"}) do
            local f=workspace:FindFirstChild(fn)
            if f then 
                local bFolder = f:FindFirstChild("Balls") or f
                for _,v in ipairs(bFolder:GetChildren()) do 
                    if v:IsA("BasePart") and (v:GetAttribute("realBall") or v.Name:lower():find("ball")) then return v end 
                end 
            end 
        end
        return nil
    end
    local function getBallVelocity(ball)
        local zoomies=ball and ball:FindFirstChild("zoomies")
        return zoomies and zoomies.VectorVelocity or (ball and ball.AssemblyLinearVelocity) or Vector3.zero
    end

    fireParry = function()
        if not spamRemoteHooked then return end
        local curveCF=getCurveCFrame()
        local method=getgenv().CurrentCurveMethod or "Camera"

        if method=="Camera" then
            local data=spamRevertedRemotes[spamRemote]
            if not data then return end

            local cam=workspace.CurrentCamera
            local char=LocalPlayer.Character
            if not cam or not char then return end

            local events={}
            for _,entity in ipairs(Alive:GetChildren()) do
                if entity~=char and entity.PrimaryPart then
                    local screenPosition,visible=cam:WorldToScreenPoint(entity.PrimaryPart.Position)
                    if visible then
                        events[tostring(entity)]=screenPosition
                    end
                end
            end

            local viewport=cam.ViewportSize
            local originalArgs=data.args
            local modifiedArgs={
                originalArgs[1],
                originalArgs[2],
                curveCF.LookVector,
                curveCF,
                events,
                {viewport.X/2,viewport.Y/2},
                originalArgs[7],
            }
            data.raw(spamRemote,unpack(modifiedArgs))
        else
            for capturedRemote,data in pairs(spamRevertedRemotes) do
                local originalArgs=data.args
                local modifiedArgs={
                    originalArgs[1],
                    originalArgs[2],
                    originalArgs[3],
                    curveCF,
                    originalArgs[5],
                    originalArgs[6],
                    originalArgs[7],
                }
                data.raw(capturedRemote,unpack(modifiedArgs))
            end
        end

        if AnimFix then task.spawn(SpamParry_Animation) end
    end

    -- Existing Auto Spam Parry logic, kept separate from the transplanted Auto Parry.
    local Auto_Spam = {}
    local SpamClosestEntity=nil
    local SpamParries=0
    local SpamConnections={}

    function Auto_Spam.Get_Ball()
        local balls=workspace:FindFirstChild("Balls")
        if not balls then return nil end
        for _,instance in pairs(balls:GetChildren()) do
            if instance:GetAttribute("realBall") then
                instance.CanCollide=false
                return instance
            end
        end
    end

    function Auto_Spam.Closest_Player()
        local maxDistance=math.huge
        SpamClosestEntity=nil
        for _,entity in pairs(Alive:GetChildren()) do
            if tostring(entity)~=tostring(LocalPlayer) and entity.PrimaryPart then
                local distance=LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
                if distance<maxDistance then
                    maxDistance=distance
                    SpamClosestEntity=entity
                end
            end
        end
        return SpamClosestEntity
    end

    function Auto_Spam:Get_Entity_Properties()
        Auto_Spam.Closest_Player()
        if not SpamClosestEntity or not SpamClosestEntity.PrimaryPart then return false end
        local entityVelocity=SpamClosestEntity.PrimaryPart.Velocity
        local entityDirection=(LocalPlayer.Character.PrimaryPart.Position-SpamClosestEntity.PrimaryPart.Position).Unit
        local entityDistance=(LocalPlayer.Character.PrimaryPart.Position-SpamClosestEntity.PrimaryPart.Position).Magnitude
        return {Velocity=entityVelocity,Direction=entityDirection,Distance=entityDistance}
    end

    function Auto_Spam:Get_Ball_Properties()
        local ball=Auto_Spam.Get_Ball()
        if not ball then return false end
        local ballVelocity=Vector3.zero
        local ballDirection=(LocalPlayer.Character.PrimaryPart.Position-ball.Position).Unit
        local ballDistance=(LocalPlayer.Character.PrimaryPart.Position-ball.Position).Magnitude
        local ballDot=ballDirection:Dot(ballVelocity.Unit)
        return {Velocity=ballVelocity,Direction=ballDirection,Distance=ballDistance,Dot=ballDot}
    end

    function Auto_Spam:Spam_Service()
        local ball=Auto_Spam.Get_Ball()
        if not ball then return false end
        Auto_Spam.Closest_Player()
        if not SpamClosestEntity or not SpamClosestEntity.PrimaryPart then return 0 end

        local spamAccuracy=0
        local velocity=ball.AssemblyLinearVelocity
        local speed=velocity.Magnitude
        local direction=(LocalPlayer.Character.PrimaryPart.Position-ball.Position).Unit
        local dot=direction:Dot(velocity.Unit)
        local targetPosition=SpamClosestEntity.PrimaryPart.Position
        local targetDistance=LocalPlayer:DistanceFromCharacter(targetPosition)
        local maximumSpamDistance=self.Ping+math.min(speed/6.5,95)

        if self.Entity_Properties.Distance>maximumSpamDistance then return spamAccuracy end
        if self.Ball_Properties.Distance>maximumSpamDistance then return spamAccuracy end
        if targetDistance>maximumSpamDistance then return spamAccuracy end

        local maximumSpeed=5-math.min(speed/5,5)
        local maximumDot=math.clamp(dot,-1,0)*maximumSpeed
        return maximumSpamDistance-maximumDot
    end

    function Auto_Spam.Parry(useCurveTargetLock)
        fireParry(useCurveTargetLock)
        if SpamParries>7 then return false end
        SpamParries+=1
        task.delay(0.5,function()
            if SpamParries>0 then SpamParries-=1 end
        end)
    end

    local function startAutoSpamParry()
        if SpamConnections["Auto Spam"] then SpamConnections["Auto Spam"]:Disconnect() end
        SpamConnections["Auto Spam"]=RunService.PreSimulation:Connect(function()
            local ball=Auto_Spam.Get_Ball()
            if not ball or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end

            local zoomies=ball:FindFirstChild("zoomies")
            if not zoomies then return end

            Auto_Spam.Closest_Player()
            if not SpamClosestEntity or not SpamClosestEntity.PrimaryPart then return end

            local ping=Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            local pingThreshold=math.clamp(ping/10,10,16)
            local ballProperties=Auto_Spam:Get_Ball_Properties()
            local entityProperties=Auto_Spam:Get_Entity_Properties()
            if not ballProperties or not entityProperties then return end

            local spamAccuracy=Auto_Spam.Spam_Service({
                Ball_Properties=ballProperties,
                Entity_Properties=entityProperties,
                Ping=pingThreshold,
            })
            local distance=LocalPlayer:DistanceFromCharacter(ball.Position)

            local targetAttr=ball:GetAttribute("target")
            local ballTarget=targetAttr and Alive:FindFirstChild(targetAttr)
            if not ballTarget or not ballTarget.PrimaryPart then return end

            local targetDistance=LocalPlayer:DistanceFromCharacter(SpamClosestEntity.PrimaryPart.Position)
            if targetDistance>spamAccuracy or distance>spamAccuracy then return end

            if distance<=spamAccuracy and (SpamParries>0 or System.__properties.__parries>0) then
                Auto_Spam.Parry(Selected_Parry_Type)
            end
        end)
        autoSpamParryConn=SpamConnections["Auto Spam"]
    end

    local function stopAutoSpamParry()
        if SpamConnections["Auto Spam"] then
            SpamConnections["Auto Spam"]:Disconnect()
            SpamConnections["Auto Spam"]=nil
        end
        autoSpamParryConn=nil
    end

    -- Semi Immortal Beta (ported from alion Walkable Semi-Immortal)
    local IceHubCFrameHook = getgenv()._lhxCFrameHook or {
        Installed = false,
        OriginalIndex = nil,
        Handlers = {},
        Order = {},
    }
    getgenv()._lhxCFrameHook = IceHubCFrameHook

    local function dispatchIceHubCFrameHook(self, key)
        if key ~= "CFrame" or (checkcaller and checkcaller()) then
            return IceHubCFrameHook.OriginalIndex(self, key)
        end

        for _, name in ipairs(IceHubCFrameHook.Order) do
            local handler = IceHubCFrameHook.Handlers[name]
            if handler then
                local result = handler(self)
                if result ~= nil then
                    return result
                end
            end
        end

        return IceHubCFrameHook.OriginalIndex(self, key)
    end

    local function ensureIceHubCFrameHook()
        if IceHubCFrameHook.Installed then return true end

        local hookFunction = getExecutorGlobal("hookfunction") or getExecutorGlobal("hookfunc")
        local hookMetaMethod = getExecutorGlobal("hookmetamethod")
        local makeClosure = getExecutorGlobal("newcclosure") or function(callback) return callback end
        local getRawMetatable = getExecutorGlobal("getrawmetatable") or getrawmetatable

        if type(hookFunction) == "function" and type(getRawMetatable) == "function" then
            local ok = pcall(function()
                local mt = getRawMetatable(game)
                local originalIndex = mt and mt.__index
                if type(originalIndex) ~= "function" then
                    error("__index is not hookable")
                end

                IceHubCFrameHook.OriginalIndex = hookFunction(originalIndex, makeClosure(function(self, key)
                    return dispatchIceHubCFrameHook(self, key)
                end))
                IceHubCFrameHook.Installed = true
                IceHubCFrameHook.Method = "hookfunction"
            end)
            if ok and IceHubCFrameHook.Installed then return true end
        end

        if type(hookMetaMethod) == "function" then
            local ok = pcall(function()
                IceHubCFrameHook.OriginalIndex = hookMetaMethod(game, "__index", makeClosure(function(self, key)
                    return dispatchIceHubCFrameHook(self, key)
                end))
                IceHubCFrameHook.Installed = true
                IceHubCFrameHook.Method = "hookmetamethod"
            end)
            if ok and IceHubCFrameHook.Installed then return true end
        end

        return false
    end

    local function registerIceHubCFrameHandler(name, handler)
        if not IceHubCFrameHook.Handlers[name] then
            table.insert(IceHubCFrameHook.Order, name)
        end
        IceHubCFrameHook.Handlers[name] = handler
        return ensureIceHubCFrameHook()
    end

    local SemiImmortalBeta = {
        Enabled = false,
        Connection = nil,
        OriginalCFrame = nil,
        OriginalVelocity = nil,
        Character = nil,
        Root = nil,
        Head = nil,
        AliveFolder = nil,
        HeadOffset = Vector3.new(0, 0, 0),
        Radius = 25,
        BaseHeight = 5,
        RiseHeight = 30,
        CycleSpeed = 11.9,
        Velocity = Vector3.new(1, 1, 1),
    }

    local function updateSemiImmortalCache()
        local character = LocalPlayer.Character
        if character == SemiImmortalBeta.Character then
            if character then
                if not SemiImmortalBeta.Root or not SemiImmortalBeta.Root.Parent then
                    SemiImmortalBeta.Root = character:FindFirstChild("HumanoidRootPart")
                end
                if not SemiImmortalBeta.Head or not SemiImmortalBeta.Head.Parent then
                    SemiImmortalBeta.Head = character:FindFirstChild("Head")
                end
            end
            SemiImmortalBeta.AliveFolder = workspace:FindFirstChild("Alive")
            if SemiImmortalBeta.Root then
                SemiImmortalBeta.HeadOffset = Vector3.new(0, SemiImmortalBeta.Root.Size.Y * 0.5 + 0.5, 0)
            end
            return
        end

        SemiImmortalBeta.Character = character
        SemiImmortalBeta.Root = character and character:FindFirstChild("HumanoidRootPart") or nil
        SemiImmortalBeta.Head = character and character:FindFirstChild("Head") or nil
        SemiImmortalBeta.AliveFolder = workspace:FindFirstChild("Alive")

        if SemiImmortalBeta.Root then
            SemiImmortalBeta.HeadOffset = Vector3.new(0, SemiImmortalBeta.Root.Size.Y * 0.5 + 0.5, 0)
        else
            SemiImmortalBeta.HeadOffset = Vector3.new(0, 0, 0)
        end
    end

    local function isSemiImmortalCharacterAlive()
        return SemiImmortalBeta.AliveFolder
            and SemiImmortalBeta.Character
            and SemiImmortalBeta.Character.Parent == SemiImmortalBeta.AliveFolder
    end

    local function getSemiImmortalOrbitCFrame(root)
        local angle = math.random(-2147483647, 2147483647) * 1000
        local cycle = math.floor(tick() * SemiImmortalBeta.CycleSpeed) % 2
        local yOffset = cycle == 0 and 0 or SemiImmortalBeta.RiseHeight
        local position = root.Position

        return CFrame.new(
            position.X + math.cos(angle) * SemiImmortalBeta.Radius,
            position.Y - root.Size.Y * 0.5 + SemiImmortalBeta.BaseHeight + yOffset,
            position.Z + math.sin(angle) * SemiImmortalBeta.Radius
        )
    end

    local function runSemiImmortalDesync()
        updateSemiImmortalCache()

        local root = SemiImmortalBeta.Root
        if not SemiImmortalBeta.Enabled or not root or not isSemiImmortalCharacterAlive() then
            return
        end

        SemiImmortalBeta.OriginalCFrame = root.CFrame
        SemiImmortalBeta.OriginalVelocity = root.AssemblyLinearVelocity
        root.CFrame = getSemiImmortalOrbitCFrame(root)
        root.AssemblyLinearVelocity = SemiImmortalBeta.Velocity

        RunService.RenderStepped:Wait()

        if root and root.Parent then
            root.CFrame = SemiImmortalBeta.OriginalCFrame
            root.AssemblyLinearVelocity = SemiImmortalBeta.OriginalVelocity
        end
    end

    registerIceHubCFrameHandler("SemiImmortalBeta", function(self)
        if not SemiImmortalBeta.Enabled then return nil end
        updateSemiImmortalCache()

        if self == SemiImmortalBeta.Root then
            return SemiImmortalBeta.OriginalCFrame or CFrame.new()
        elseif self == SemiImmortalBeta.Head and SemiImmortalBeta.OriginalCFrame then
            return SemiImmortalBeta.OriginalCFrame + SemiImmortalBeta.HeadOffset
        end

        return nil
    end)

    local function setSemiImmortalBeta(enabled)
        SemiImmortalBeta.Enabled = enabled
        getgenv().semiImmortalBeta = enabled
        getgenv().Walkablesemiimortal = enabled

        if enabled then
            ensureIceHubCFrameHook()
            if not SemiImmortalBeta.Connection then
                SemiImmortalBeta.Connection = RunService.Heartbeat:Connect(runSemiImmortalDesync)
            end
        else
            if SemiImmortalBeta.Connection then
                SemiImmortalBeta.Connection:Disconnect()
                SemiImmortalBeta.Connection = nil
            end
            SemiImmortalBeta.OriginalCFrame = nil
            SemiImmortalBeta.OriginalVelocity = nil
        end
    end

    LocalPlayer.CharacterRemoving:Connect(function()
        SemiImmortalBeta.Character = nil
        SemiImmortalBeta.Root = nil
        SemiImmortalBeta.Head = nil
        SemiImmortalBeta.AliveFolder = nil
        SemiImmortalBeta.OriginalCFrame = nil
        SemiImmortalBeta.OriginalVelocity = nil
    end)

    local spamBalls=workspace:FindFirstChild("Balls")
    if spamBalls then
        spamBalls.ChildRemoved:Connect(function()
            SpamParries=0
        end)
    end

    -- Detection Listeners
    pcall(function() ReplicatedStorage.Remotes.SecondaryEndCD.OnClientEvent:Connect(function() end) end)
    pcall(function() ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(_,d) deathslash_active=d or false end) end)
    pcall(function() ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(_,b) infinity_active=b or false end) end)
    pcall(function() ReplicatedStorage.Remotes.PlrPulled.OnClientEvent:Connect(function(a,b) 
        if type(a)=="boolean" then pull_active=a elseif type(b)=="boolean" then pull_active=b else pull_active=true; task.delay(1.5, function() pull_active=false end) end 
    end) end)
    pcall(function() ReplicatedStorage.Remotes.PlrPulsed.OnClientEvent:Connect(function(a,b) 
        if type(a)=="boolean" then pull_active=a elseif type(b)=="boolean" then pull_active=b else pull_active=true; task.delay(1.5, function() pull_active=false end) end 
    end) end)
    pcall(function()
        local net=ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
        net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(...) local p=(...); if p==LocalPlayer or(p and p.Name==LocalPlayer.Name) then timehole_active=true end end)
        net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function() timehole_active=false end)
        net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(...) local p=(...); if p==LocalPlayer or(p and p.Name==LocalPlayer.Name) then slashesoffury_active=true; slashesoffury_count=0 end end)
        net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function() slashesoffury_active=false; slashesoffury_count=0 end)
        net["RE/SlashesOfFuryParry"].OnClientEvent:Connect(function() slashesoffury_count+=1 end)
        net["RE/SlashesOfFuryCatch"].OnClientEvent:Connect(function()
            task.spawn(function() while slashesoffury_active and slashesoffury_count<maxParryCount do if detections.slashesoffury then fireParry(); task.wait(parryDelay) else break end end end)
        end)
    end)
    pcall(function()
        Runtime.ChildAdded:Connect(function(obj)
            if not detections.phantom then return end
            if obj.Name~="maxTransmission" and obj.Name~="transmissionpart" then return end
            local weld=obj:FindFirstChildWhichIsA("WeldConstraint"); if not weld then return end
            local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            if char and weld.Part1==char.HumanoidRootPart then
                local ball=findBall(); weld:Destroy()
                if ball then
                    local conn; conn=RunService.RenderStepped:Connect(function()
                        local h=ball:GetAttribute("highlighted")
                        if h==true then ReplicatedStorage.Remotes.AbilityButtonPress:Fire() elseif h==false then conn:Disconnect() end
                    end); task.delay(3,function() if conn and conn.Connected then conn:Disconnect() end end)
                end
            end
        end)
    end)

    -- Ball Trail
    local PlasmaTrails={Active=false,Enabled=false,Attachments={},NumTrails=8,Color=Color3.fromRGB(0,255,255)}
    local function plasmaCreate(ball)
        if PlasmaTrails.Active then return end; PlasmaTrails.Active=true; PlasmaTrails.Attachments={}
        for i=1,PlasmaTrails.NumTrails do
            local angle=(i/PlasmaTrails.NumTrails)*math.pi*2; local radius=math.random(150,250)/100; local height=math.random(-150,150)/100
            local a0=Instance.new("Attachment"); a0.Name="PA0_"..i; a0.Position=Vector3.new(math.cos(angle)*radius,height+math.sin(angle*3)*0.8,math.sin(angle)*radius); a0.Parent=ball
            local a1=Instance.new("Attachment"); a1.Name="PA1_"..i; a1.Position=Vector3.new(math.cos(angle+math.pi*0.7)*radius*1.3,-height+math.cos(angle*2.5)*0.8,math.sin(angle+math.pi*0.7)*radius*1.3); a1.Parent=ball
            local trail=Instance.new("Trail"); trail.Name="PT_"..i; trail.Attachment0=a0; trail.Attachment1=a1; trail.Lifetime=0.6; trail.MinLength=0; trail.FaceCamera=true; trail.LightEmission=1; trail.LightInfluence=0; trail.Texture="rbxassetid://5029929719"; trail.TextureMode=Enum.TextureMode.Stretch
            local base=PlasmaTrails.Color; trail.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,base),ColorSequenceKeypoint.new(0.5,Color3.new(math.min(base.R*1.3,1),math.min(base.G*1.3,1),math.min(base.B*1.3,1))),ColorSequenceKeypoint.new(1,base)})
            trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(0.3,0),NumberSequenceKeypoint.new(0.7,0.3),NumberSequenceKeypoint.new(1,1)}); trail.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(0.3,0.25),NumberSequenceKeypoint.new(0.7,0.15),NumberSequenceKeypoint.new(1,0.02)}); trail.Parent=ball
            table.insert(PlasmaTrails.Attachments,{a0=a0,a1=a1,trail=trail,baseAngle=angle,angle=0,speed=math.random(15,30)/10,spiralSpeed=math.random(25,45)/10,rmul=math.random(80,130)/100,pulse=math.random()*math.pi*2,baseR=radius,baseH=height,chaos=math.random(10,20)/10})
        end
    end
    local function plasmaAnimate(dt)
        if not PlasmaTrails.Active then return end; local t=tick()
        for _,td in ipairs(PlasmaTrails.Attachments) do
            td.angle+=td.speed*dt; local sa=td.angle*td.spiralSpeed; local pulse=math.sin(t*4+td.pulse)*0.4+1; local twist=math.sin(td.angle*3)*0.7; local chaos=math.sin(t*td.chaos+td.pulse)*0.5
            local r1=td.baseR*td.rmul*pulse; local r2=td.baseR*1.3*td.rmul*pulse
            td.a0.Position=Vector3.new(math.cos(td.baseAngle+td.angle)*r1,td.baseH+math.sin((td.baseAngle+td.angle)*3)*0.8+twist+chaos,math.sin(td.baseAngle+td.angle)*r1)+Vector3.new(math.cos(sa)*0.6,math.sin(sa*2)*0.6,math.sin(sa)*0.6)
            td.a1.Position=Vector3.new(math.cos(td.baseAngle+td.angle+math.pi*0.7)*r2,-td.baseH+math.cos((td.baseAngle+td.angle)*2.5)*0.8-twist-chaos,math.sin(td.baseAngle+td.angle+math.pi*0.7)*r2)+Vector3.new(math.sin(sa*1.3)*0.5,math.cos(sa*1.7)*0.5,math.cos(sa*1.1)*0.5)
            td.trail.LightEmission=math.sin(t*5+td.pulse)*0.4+0.6
        end
    end
    local function plasmaClean(ball)
        if ball then for _,obj in pairs(ball:GetChildren()) do if obj.Name:sub(1,2)=="PA" or obj.Name:sub(1,2)=="PT" then obj:Destroy() end end end
        PlasmaTrails.Active=false; PlasmaTrails.Attachments={}
    end
    local lastTrailBall=nil
    local lastTrailBallCheck=0
    local cachedTrailBall=nil
    RunService.Heartbeat:Connect(function(dt)
        if PlasmaTrails.Enabled then
            local now=os.clock()
            if now-lastTrailBallCheck>0.08 then
                local hbState=getgenv()._lhxMainHeartbeat
                cachedTrailBall=hbState and hbState.cachedBall or findBall()
                lastTrailBallCheck=now
            end
            local ball=cachedTrailBall
            if ball and ball~=lastTrailBall then if lastTrailBall then plasmaClean(lastTrailBall) end; plasmaCreate(ball); lastTrailBall=ball
            elseif not ball and lastTrailBall then plasmaClean(lastTrailBall); lastTrailBall=nil end
            if ball and PlasmaTrails.Active then plasmaAnimate(dt) end
        else if lastTrailBall then plasmaClean(lastTrailBall); lastTrailBall=nil end end
    end)

    -- Falling Particles
    getgenv().fallingParticlesEnabled = getgenv().fallingParticlesEnabled or false
    getgenv().fallingParticlesAmount = getgenv().fallingParticlesAmount or 5
    getgenv().fallingParticlesSpeed = getgenv().fallingParticlesSpeed or 90
    getgenv().fallingParticlesHue = getgenv().fallingParticlesHue or 180
    do
        local state = getgenv()._lhxFallingParticles or { generation = 0 }
        getgenv()._lhxFallingParticles = state

        local function getParticleColors()
            local hue = math.clamp(tonumber(getgenv().fallingParticlesHue) or 180, 0, 360) / 360
            return {
                bright = Color3.fromHSV(hue, 0.18, 1),
                core = Color3.fromHSV(hue, 0.62, 1),
                mid = Color3.fromHSV(hue, 0.82, 1),
                deep = Color3.fromHSV(hue, 1, 0.92),
            }
        end

        local function clearParticles()
            local oldFolder = state.folder or workspace:FindFirstChild("IceHubFallingParticles")
            if oldFolder then oldFolder:Destroy() end
            state.folder = nil
        end

        local function spawnFallingParticle(generation)
            if generation ~= state.generation or not state.folder then return end
            local colors = getParticleColors()

            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local angle = math.random() * math.pi * 2
            local radius = math.sqrt(math.random()) * 125
            local horizontalOffset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            local rayOrigin = root.Position + horizontalOffset + Vector3.new(0, 125, 0)
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = { character, state.folder }
            rayParams.IgnoreWater = true

            local result = workspace:Raycast(rayOrigin, Vector3.new(0, -300, 0), rayParams)
            if not result then return end

            local targetPosition = result.Position + result.Normal * 0.35
            local startPosition = targetPosition + Vector3.new(
                math.random(-700, 700) / 100,
                math.random(7000, 11000) / 100,
                math.random(-700, 700) / 100
            )

            local star = Instance.new("Part")
            star.Name = "FallingStar"
            star.Shape = Enum.PartType.Ball
            star.Size = Vector3.new(0.7, 0.7, 0.7)
            star.Position = startPosition
            star.Anchored = true
            star.CanCollide = false
            star.CanTouch = false
            star.CanQuery = false
            star.CastShadow = false
            star.Material = Enum.Material.Neon
            star.Color = colors.core
            star.Parent = state.folder

            local front = Instance.new("Attachment")
            front.Position = Vector3.new(0, 0.22, 0)
            front.Parent = star

            local back = Instance.new("Attachment")
            back.Position = Vector3.new(0, -0.22, 0)
            back.Parent = star

            local trail = Instance.new("Trail")
            trail.Attachment0 = front
            trail.Attachment1 = back
            trail.FaceCamera = true
            trail.LightEmission = 1
            trail.LightInfluence = 0
            trail.Lifetime = 0.75
            trail.MinLength = 0.05
            trail.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, colors.bright),
                ColorSequenceKeypoint.new(0.35, colors.core),
                ColorSequenceKeypoint.new(1, colors.deep),
            })
            trail.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.7, 0.15),
                NumberSequenceKeypoint.new(1, 1),
            })
            trail.WidthScale = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.65),
                NumberSequenceKeypoint.new(0.35, 0.35),
                NumberSequenceKeypoint.new(1, 0),
            })
            trail.Parent = star

            local glow = Instance.new("ParticleEmitter")
            glow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            glow.Color = ColorSequence.new(colors.core, colors.deep)
            glow.LightEmission = 1
            glow.Lifetime = NumberRange.new(0.2, 0.45)
            glow.Speed = NumberRange.new(0.2, 1.5)
            glow.SpreadAngle = Vector2.new(180, 180)
            glow.Drag = 3
            glow.Rate = 18
            glow.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.22),
                NumberSequenceKeypoint.new(1, 0),
            })
            glow.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(1, 1),
            })
            glow.Parent = front

            local light = Instance.new("PointLight")
            light.Color = colors.mid
            light.Brightness = 2.2
            light.Range = 11
            light.Parent = star

            local distance = (startPosition - targetPosition).Magnitude
            local selectedSpeed = math.clamp(tonumber(getgenv().fallingParticlesSpeed) or 90, 20, 250)
            local variedSpeed = selectedSpeed * (math.random(85, 115) / 100)
            local duration = math.clamp(distance / variedSpeed, 0.25, 5)
            local tween = TweenService:Create(star, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Position = targetPosition,
            })
            tween.Completed:Once(function()
                star:Destroy()
            end)
            tween:Play()
        end

        getgenv().setFallingParticles = function(enabled)
            state.generation = (state.generation or 0) + 1
            state.enabled = enabled
            getgenv().fallingParticlesEnabled = enabled
            clearParticles()

            if not enabled then return end

            local folder = Instance.new("Folder")
            folder.Name = "IceHubFallingParticles"
            folder.Parent = workspace
            state.folder = folder

            local generation = state.generation
            task.spawn(function()
                while state.enabled and generation == state.generation do
                    local amount = math.clamp(math.floor(tonumber(getgenv().fallingParticlesAmount) or 5), 1, 10)
                    if state.folder and #state.folder:GetChildren() < amount * 5 then
                        spawnFallingParticle(generation)
                    end
                    task.wait((0.65 / amount) * (math.random(80, 120) / 100))
                end
            end)
        end

        state.generation = (state.generation or 0) + 1
        state.enabled = false
        clearParticles()
        getgenv().fallingParticlesEnabled = false
    end

    -- Skin Changer (yedek.txt backend)
    local SKIN_LAST_EQUIPPED_CONFIG_KEY = "Skin.LastEquippedSword"
    local EXPLOSION_LAST_EQUIPPED_CONFIG_KEY = "Skin.LastEquippedExplosion"
    local FINISHER_LAST_EQUIPPED_CONFIG_KEY = "Skin.LastEquippedFinisher"
    local AUTO_CONFIG_FILE = "IceHubX/auto_config.json"

    local function readIceHubAutoConfig()
        local data = {}
        pcall(function()
            if isfile and isfile(AUTO_CONFIG_FILE) then
                local decoded = HttpService:JSONDecode(readfile(AUTO_CONFIG_FILE))
                if type(decoded) == "table" then
                    data = decoded
                end
            end
        end)
        return data
    end

    local function writeIceHubAutoConfig(data)
        pcall(function()
            if isfolder and makefolder and not isfolder("IceHubX") then
                makefolder("IceHubX")
            end
            if writefile then
                writefile(AUTO_CONFIG_FILE, HttpService:JSONEncode(data or {}))
            end
        end)
    end

    local function loadLastEquippedSword()
        local data = readIceHubAutoConfig()
        local saved = data[SKIN_LAST_EQUIPPED_CONFIG_KEY]
        return type(saved) == "string" and saved or ""
    end

    local function loadLastEquippedExplosion()
        local data = readIceHubAutoConfig()
        local saved = data[EXPLOSION_LAST_EQUIPPED_CONFIG_KEY]
        return type(saved) == "string" and saved or ""
    end

    local function loadLastEquippedFinisher()
        local data = readIceHubAutoConfig()
        local saved = data[FINISHER_LAST_EQUIPPED_CONFIG_KEY]
        return type(saved) == "string" and saved or ""
    end

    getgenv().saveLastEquippedSword = function(swordName)
        if type(swordName) ~= "string" or swordName == "" then return end

        local autoConfig = getgenv()._lhxAutoConfig
        local data = autoConfig and autoConfig.Data
        if type(data) ~= "table" then
            data = readIceHubAutoConfig()
        end

        data[SKIN_LAST_EQUIPPED_CONFIG_KEY] = swordName
        if autoConfig and type(autoConfig.Data) == "table" then
            autoConfig.Data[SKIN_LAST_EQUIPPED_CONFIG_KEY] = swordName
        end
        writeIceHubAutoConfig(data)
    end

    getgenv().saveLastEquippedExplosion = function(explosionName)
        if type(explosionName) ~= "string" or explosionName == "" then return end

        local autoConfig = getgenv()._lhxAutoConfig
        local data = autoConfig and autoConfig.Data
        if type(data) ~= "table" then
            data = readIceHubAutoConfig()
        end

        data[EXPLOSION_LAST_EQUIPPED_CONFIG_KEY] = explosionName
        if autoConfig and type(autoConfig.Data) == "table" then
            autoConfig.Data[EXPLOSION_LAST_EQUIPPED_CONFIG_KEY] = explosionName
        end
        writeIceHubAutoConfig(data)
    end

    getgenv().saveLastEquippedFinisher = function(finisherName)
        if type(finisherName) ~= "string" or finisherName == "" then return end

        local autoConfig = getgenv()._lhxAutoConfig
        local data = autoConfig and autoConfig.Data
        if type(data) ~= "table" then
            data = readIceHubAutoConfig()
        end

        data[FINISHER_LAST_EQUIPPED_CONFIG_KEY] = finisherName
        if autoConfig and type(autoConfig.Data) == "table" then
            autoConfig.Data[FINISHER_LAST_EQUIPPED_CONFIG_KEY] = finisherName
        end
        writeIceHubAutoConfig(data)
    end

    local savedLastSword = loadLastEquippedSword()
    local savedLastExplosion = loadLastEquippedExplosion()
    local savedLastFinisher = loadLastEquippedFinisher()
    getgenv().skinChanger = getgenv().skinChanger or savedLastSword ~= ""
    getgenv().swordModel = type(getgenv().swordModel) == "string" and getgenv().swordModel ~= "" and getgenv().swordModel or savedLastSword
    getgenv().swordAnimations = type(getgenv().swordAnimations) == "string" and getgenv().swordAnimations ~= "" and getgenv().swordAnimations or savedLastSword
    getgenv().swordFX = type(getgenv().swordFX) == "string" and getgenv().swordFX ~= "" and getgenv().swordFX or savedLastSword
    getgenv().explosionChanger = getgenv().explosionChanger or savedLastExplosion ~= ""
    getgenv().explosionFX = type(getgenv().explosionFX) == "string" and getgenv().explosionFX ~= "" and getgenv().explosionFX or savedLastExplosion
    getgenv().finisherChanger = getgenv().finisherChanger or savedLastFinisher ~= ""
    getgenv().finisherModel = type(getgenv().finisherModel) == "string" and getgenv().finisherModel ~= "" and getgenv().finisherModel or savedLastFinisher

    task.spawn(function()
        local rs = game:GetService("ReplicatedStorage")
        local swordInstancesInstance = rs:WaitForChild("Shared", 9e9):WaitForChild("ReplicatedInstances", 9e9):WaitForChild("Swords", 9e9)
        local swordInstances = require(swordInstancesInstance)

        local swordsController
        task.spawn(function()
            while task.wait(0.25) and not swordsController do
                local ok, conns = pcall(getconnections, rs.Remotes.FireSwordInfo.OnClientEvent)
                if ok and conns then
                    for _, v in ipairs(conns) do
                        if v.Function and islclosure and islclosure(v.Function) then
                            local ok2, up = pcall(getupvalues, v.Function)
                            if ok2 and #up == 1 and type(up[1]) == "table" then
                                swordsController = up[1]
                                break
                            end
                        end
                    end
                end
            end
        end)

        local function getSlashName(swordName)
            local ok, sln = pcall(function() return swordInstances:GetSword(swordName) end)
            return (ok and sln and sln.SlashName) or "SlashEffect"
        end

        local function refreshSlashName()
            local fxName = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
            if fxName ~= "" then
                getgenv().slashName = getSlashName(fxName)
            else
                getgenv().slashName = "SlashEffect"
            end
        end
        refreshSlashName()

        local function setSword()
            if not getgenv().skinChanger then return end
            if not LocalPlayer.Character then return end
            pcall(function()
                local f = rawget(swordInstances, "EquipSwordTo")
                if type(f) == "function" then
                    local ups = getupvalues(f)
                    for i = 1, #ups do
                        if type(ups[i]) == "boolean" then
                            setupvalue(f, i, false)
                            break
                        end
                    end
                end
            end)
            pcall(function()
                swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel)
            end)
            task.spawn(function()
                local attempts = 0
                while not swordsController and attempts < 20 do
                    task.wait(0.5); attempts += 1
                end
                if not swordsController then return end
                pcall(function()
                    if swordsController.SetSword then
                        swordsController:SetSword(getgenv().swordAnimations ~= "" and getgenv().swordAnimations or getgenv().swordModel)
                    end
                end)
                pcall(function()
                    local targetSword = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
                    if rs.Remotes:FindFirstChild("FireSwordInfo") then
                        rs.Remotes.FireSwordInfo:FireServer(targetSword)
                    end
                    if swordsController.currentSword ~= nil then
                        pcall(function() swordsController.currentSword = targetSword end)
                    end
                    if swordsController.SwordFX ~= nil then
                        pcall(function() swordsController.SwordFX = targetSword end)
                    end
                end)
            end)
        end

        -- Hook Parry Remotes for FX
        local hookedFuncs = {}
        task.spawn(function()
            local remotesToHook = {"ParrySuccessAll", "ParryAttempt", "ParrySuccess", "PlaySound", "PlayVisuals"}
            while task.wait(1) do
                for _, remoteName in ipairs(remotesToHook) do
                    local remote = rs.Remotes:FindFirstChild(remoteName)
                    if remote and remote:IsA("RemoteEvent") then
                        local ok, conns = pcall(getconnections, remote.OnClientEvent)
                        if ok and type(conns) == "table" then
                            for _, v in ipairs(conns) do
                                local func = v.Function
                                if func and not hookedFuncs[func] then
                                    
                                    hookedFuncs[func] = true
                                    v:Disable()
                                    local targetFunc = func
                                    local ourFunc
                                    ourFunc = function(...)
                                        local args = { ... }

                                        local isLocal = false
                                        for _, arg in ipairs(args) do
                                            if tostring(arg) == LocalPlayer.Name or (typeof(arg) == "Instance" and (arg == LocalPlayer.Character or arg == LocalPlayer)) then
                                                isLocal = true
                                                break
                                            end
                                        end

                                        if isLocal and getgenv().skinChanger then
                                            local fxSword = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
                                            refreshSlashName()

                                            local swordFound = false
                                            local slashFound = false

                                            for i, arg in ipairs(args) do
                                                if type(arg) == "string" then
                                                    if fxSword ~= "" and not slashFound and (arg:match("Slash") or arg == "Default" or arg:match("Effect")) then
                                                        args[i] = getgenv().slashName
                                                        slashFound = true
                                                    elseif fxSword ~= "" and not swordFound then
                                                        local isSword = false
                                                        pcall(function()
                                                            if rs.Shared.ReplicatedInstances.Swords:FindFirstChild(arg) then
                                                                isSword = true
                                                            end
                                                        end)
                                                        if isSword or arg == LocalPlayer:GetAttribute("CurrentlyEquippedSword") then
                                                            args[i] = fxSword
                                                            swordFound = true
                                                        end
                                                    end
                                                end
                                            end

                                            -- Fallback to default indexes if not found dynamically
                                            if fxSword ~= "" and not slashFound and type(args[1]) == "string" then
                                                args[1] = getgenv().slashName
                                            end
                                            if fxSword ~= "" and not swordFound and type(args[3]) == "string" then
                                                args[3] = fxSword
                                            end
                                        end
                                        if setthreadidentity then pcall(setthreadidentity, 2) end
                                        pcall(targetFunc, unpack(args))
                                    end
                                    hookedFuncs[ourFunc] = true
                                    remote.OnClientEvent:Connect(ourFunc)
                                end
                            end
                        end
                    end
                end
            end
        end)

        getgenv().updateSword = function()
            refreshSlashName()
            if getgenv().skinChanger and getgenv().swordModel ~= "" and getgenv().saveLastEquippedSword then
                getgenv().saveLastEquippedSword(getgenv().swordModel)
            end
            setSword()
        end

        -- Persistent equip loop
        task.spawn(function()
            while task.wait(1) do
                if getgenv().skinChanger and getgenv().swordModel ~= "" then
                    local char = LocalPlayer.Character
                    if char then
                        if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then
                            setSword()
                        end
                        if not char:FindFirstChild(getgenv().swordModel) then
                            setSword()
                        end
                        for _, v in char:GetChildren() do
                            if v:IsA("Model") and v.Name ~= getgenv().swordModel then
                                v:Destroy()
                            end
                            task.wait()
                        end
                    end
                end
            end
        end)

        LocalPlayer.CharacterAdded:Connect(function()
            if getgenv().skinChanger then
                getgenv().skinChanger = false
                if getgenv().setSkinChangerToggleUI then getgenv().setSkinChangerToggleUI(false) end
                task.wait(2)
                getgenv().skinChanger = true
                if getgenv().setSkinChangerToggleUI then getgenv().setSkinChangerToggleUI(true) end
                task.wait(0.5)
                pcall(function() getgenv().updateSword() end)
            end
        end)
    end)


    -- Explosion Changer
    task.spawn(function()
        local rs = game:GetService("ReplicatedStorage")
        
        -- Native Finisher Suppressor Hook
        task.spawn(function()
            local hookFunction = getExecutorGlobal("hookfunction") or getExecutorGlobal("hookfunc")
            if type(hookFunction) ~= "function" then return end
            local controllers = rs:WaitForChild("Controllers", 10)
            if not controllers then return end
            local fcModule = controllers:WaitForChild("FinishersController", 10)
            if not fcModule then return end
            local ok, module = pcall(require, fcModule)
            if ok and type(module) == "table" then
                getgenv()._lhxFCModule = module
                for k, v in pairs(module) do
                    if type(v) == "function" then
                        local orig
                        orig = hookFunction(v, function(self, ...)
                            if getgenv().finisherModel and getgenv().finisherModel ~= "" then
                                local newArgs = { ... }
                                if type(newArgs[1]) == "string" then
                                    newArgs[1] = getgenv().finisherModel
                                elseif type(newArgs[2]) == "string" then
                                    newArgs[2] = getgenv().finisherModel
                                end
                                return orig(self, unpack(newArgs))
                            end
                            return orig(self, ...)
                        end)
                    end
                end
            end
        end)

        local explosionHookedFuncs = {}
        local explosionDirectHooked = {}
        local deadFolderHooked = false
        local explosionModule = nil
        local bindableInvokeHooked = false
        local nativeExplosionSuppressorHooked = {}
        local pendingKillExplosionPosition = nil
        local pendingKillExplosionAt = 0
        local lastLocalKillAt = 0
        local lastLocalKillStatTotal = nil
        local killStatWatcherStarted = false
        local lastLocalExplosionPlayedAt = 0
        local lastLocalExplosionPlayedPosition = nil

        local function normalizeExplosionName(value)
            return tostring(value or ""):lower():gsub("[^%w]", "")
        end

        local function getNetFolder()
            local packages = rs:FindFirstChild("Packages")
            local index = packages and packages:FindFirstChild("_Index")
            local sleitnick = index and index:FindFirstChild("sleitnick_net@0.1.0")
            return sleitnick and sleitnick:FindFirstChild("net")
        end

        local function getExplosionInstances()
            local shared = rs:FindFirstChild("Shared")
            local replicatedInstances = shared and shared:FindFirstChild("ReplicatedInstances")
            return replicatedInstances and replicatedInstances:FindFirstChild("Explosions")
        end

        local function getExplosionDataFolder()
            local misc = rs:FindFirstChild("Misc")
            return misc and misc:FindFirstChild("DataExplosions")
        end

        local function getExplosionEffectsFolder()
            return rs:FindFirstChild("ExplosionEffects")
        end

        local function getExplosionModule()
            if explosionModule ~= nil then return explosionModule end
            local instance = getExplosionInstances()
            if instance and instance:IsA("ModuleScript") then
                local ok, result = pcall(function()
                    return require(instance)
                end)
                explosionModule = ok and result or false
            end
            return explosionModule
        end

        local function findExplosionInstanceByName(value)
            if type(value) ~= "string" or value == "" then return nil end
            local wanted = normalizeExplosionName(value)
            for _, root in ipairs({getExplosionDataFolder(), getExplosionEffectsFolder(), getExplosionInstances()}) do
                if root then
                    local exact = root:FindFirstChild(value, true)
                    if exact then return exact end
                    for _, child in ipairs(root:GetDescendants()) do
                        if normalizeExplosionName(child.Name) == wanted then
                            return child
                        end
                    end
                end
            end
            return nil
        end

        local function findExplosionDataConfig(value)
            if type(value) ~= "string" or value == "" then return nil end
            local dataFolder = getExplosionDataFolder()
            if not dataFolder then return nil end

            local wanted = normalizeExplosionName(value)
            local exact = dataFolder:FindFirstChild(value, true)
            if exact then return exact end

            for _, child in ipairs(dataFolder:GetDescendants()) do
                if normalizeExplosionName(child.Name) == wanted then
                    return child
                end
                for _, attributeValue in pairs(child:GetAttributes()) do
                    if type(attributeValue) == "string"
                        and normalizeExplosionName(attributeValue) == wanted then
                        return child
                    end
                end
            end
            return nil
        end

        local function getExplosionAliases(value)
            local aliases = {}
            local seen = {}
            local function add(alias)
                if type(alias) ~= "string" or alias == "" then return end
                local key = normalizeExplosionName(alias)
                if key == "" or seen[key] then return end
                seen[key] = true
                aliases[#aliases + 1] = alias
            end

            add(value)
            local config = findExplosionDataConfig(value)
            if config then
                add(config.Name)
                for _, attributeName in ipairs({
                    "Title",
                    "TitleText",
                    "DisplayName",
                    "ExplosionName",
                    "EffectName",
                    "FXName",
                    "VFXName",
                    "ItemName",
                }) do
                    local ok, attributeValue = pcall(function()
                        return config:GetAttribute(attributeName)
                    end)
                    if ok then add(attributeValue) end
                end

                local scanned = 0
                for _, object in ipairs(config:GetDescendants()) do
                    if object:IsA("StringValue") then
                        add(object.Value)
                        scanned += 1
                        if scanned >= 20 then break end
                    end
                end
            end
            return aliases
        end

        local function isPlayableExplosionTemplate(instance)
            if typeof(instance) ~= "Instance" then return false end
            if instance:IsA("Configuration")
                or instance:IsA("ModuleScript")
                or instance:IsA("Script")
                or instance:IsA("LocalScript")
                or instance:IsA("BindableFunction")
                or instance:IsA("BindableEvent")
                or instance:IsA("ObjectValue") then
                return false
            end
            return instance:IsA("Folder")
                or instance:IsA("Model")
                or instance:IsA("BasePart")
                or instance:IsA("Attachment")
                or instance:IsA("Accessory")
                or instance:IsA("Tool")
                or instance:FindFirstChildWhichIsA("BasePart", true) ~= nil
                or instance:FindFirstChildWhichIsA("ParticleEmitter", true) ~= nil
                or instance:FindFirstChildWhichIsA("Beam", true) ~= nil
                or instance:FindFirstChildWhichIsA("Trail", true) ~= nil
        end

        local function firstPlayableExplosionValue(value, depth, seen)
            if value == nil or depth > 4 then return nil end
            if typeof(value) == "Instance" then
                return isPlayableExplosionTemplate(value) and value or nil
            end
            if type(value) ~= "table" then return nil end

            seen = seen or {}
            if seen[value] then return nil end
            seen[value] = true

            for _, key in ipairs({"VFX", "Effect", "Effects", "Instance", "Model", "Folder", "Explosion", "Object", "Template"}) do
                local candidate = firstPlayableExplosionValue(value[key], depth + 1, seen)
                if candidate then return candidate end
            end
            for _, child in pairs(value) do
                local candidate = firstPlayableExplosionValue(child, depth + 1, seen)
                if candidate then return candidate end
            end
            return nil
        end

        local function getReplicatedExplosionTemplate(value)
            local instances = getExplosionInstances()
            if not instances then return nil end

            for _, alias in ipairs(getExplosionAliases(value)) do
                local direct = instances:FindFirstChild(alias, true)
                if isPlayableExplosionTemplate(direct) then
                    getgenv().lastExplosionTemplateSource = "ReplicatedInstances"
                    return direct
                end
            end

            local bindable = instances:FindFirstChild("GetInstance")
            if bindable and bindable:IsA("BindableFunction") then
                for _, alias in ipairs(getExplosionAliases(value)) do
                    local ok, result = pcall(function()
                        return bindable:Invoke(alias)
                    end)
                    local template = ok and firstPlayableExplosionValue(result, 0, {}) or nil
                    if template then
                        getgenv().lastExplosionTemplateSource = "ReplicatedInstances.GetInstance"
                        return template
                    end
                end
            end

            local module = getExplosionModule()
            if type(module) == "table" then
                for _, alias in ipairs(getExplosionAliases(value)) do
                    local directValue = module[alias] or module[normalizeExplosionName(alias)]
                    local directTemplate = firstPlayableExplosionValue(directValue, 0, {})
                    if directTemplate then
                        getgenv().lastExplosionTemplateSource = "ReplicatedInstances.Module"
                        return directTemplate
                    end

                    for _, methodName in ipairs({"GetInstance", "GetExplosion", "GetExplosionVFX", "GetEffect", "Get"}) do
                        local method = module[methodName]
                        if type(method) == "function" then
                            for _, callWithSelf in ipairs({true, false}) do
                                local ok, result = pcall(function()
                                    if callWithSelf then
                                        return method(module, alias)
                                    end
                                    return method(alias)
                                end)
                                local template = ok and firstPlayableExplosionValue(result, 0, {}) or nil
                                if template then
                                    getgenv().lastExplosionTemplateSource = "ReplicatedInstances." .. methodName
                                    return template
                                end
                            end
                        end
                    end
                end
            end

            return nil
        end

        local function findExplosionEffectTemplate(value)
            if type(value) ~= "string" or value == "" then return nil end
            local replicatedTemplate = getReplicatedExplosionTemplate(value)
            if replicatedTemplate then return replicatedTemplate end

            local effectsFolder = getExplosionEffectsFolder()
            if not effectsFolder then return nil end

            for _, alias in ipairs(getExplosionAliases(value)) do
                local exact = effectsFolder:FindFirstChild(alias, true)
                if exact and isPlayableExplosionTemplate(exact) then
                    getgenv().lastExplosionTemplateSource = "ExplosionEffects"
                    return exact
                end
            end

            for _, alias in ipairs(getExplosionAliases(value)) do
                local wanted = normalizeExplosionName(alias)
                for _, child in ipairs(effectsFolder:GetDescendants()) do
                    if isPlayableExplosionTemplate(child) and normalizeExplosionName(child.Name) == wanted then
                        getgenv().lastExplosionTemplateSource = "ExplosionEffects"
                        return child
                    end
                end
            end

            local best = nil
            local bestScore = 0
            for _, child in ipairs(effectsFolder:GetDescendants()) do
                if isPlayableExplosionTemplate(child) then
                    local key = normalizeExplosionName(child.Name)
                    local score = 0
                    for _, alias in ipairs(getExplosionAliases(value)) do
                        local wanted = normalizeExplosionName(alias)
                        if wanted:find(key, 1, true) or key:find(wanted, 1, true) then
                            score = math.max(score, math.min(#key, #wanted))
                        else
                            for word in tostring(alias):gmatch("[%w]+") do
                                local wordKey = normalizeExplosionName(word)
                                if #wordKey >= 4 and key:find(wordKey, 1, true) then
                                    score += #wordKey
                                end
                            end
                        end
                    end
                    if score > bestScore then
                        best = child
                        bestScore = score
                    end
                end
            end

            if best then
                getgenv().lastExplosionTemplateSource = "ExplosionEffects.Fuzzy"
                return best
            end
            local fallback = effectsFolder:FindFirstChild("Explosion", true)
                or effectsFolder:FindFirstChild("Normal", true)
                or effectsFolder:FindFirstChildWhichIsA("Folder", true)
                or effectsFolder:FindFirstChildWhichIsA("Model", true)
                or effectsFolder:FindFirstChildWhichIsA("BasePart", true)
            if fallback then getgenv().lastExplosionTemplateSource = "ExplosionEffects.Fallback" end
            return fallback
        end

        local function getSelectedExplosionName()
            local selected = getgenv().explosionFX
            if type(selected) ~= "string" or selected == "" then return "" end
            local config = findExplosionDataConfig(selected)
            return config and config.Name or selected
        end

        local function isPlayerString(value)
            if type(value) ~= "string" then return false end
            for _, player in ipairs(Players:GetPlayers()) do
                if value == player.Name or value == player.DisplayName then
                    return true
                end
            end
            return false
        end

        local function isKnownExplosionName(value)
            if type(value) ~= "string" or value == "" then return false end
            if findExplosionInstanceByName(value) then return true end
            local instances = getExplosionInstances()
            if instances then
                local bindable = instances:FindFirstChild("GetInstance")
                if bindable and bindable:IsA("BindableFunction") then
                    local ok, result = pcall(function()
                        return bindable:Invoke(value)
                    end)
                    if ok and result then return true end
                end
                if instances:FindFirstChild(value, true) then return true end
            end

            local module = getExplosionModule()
            if type(module) == "table" then
                if module[value] ~= nil then return true end
                for _, methodName in ipairs({"GetExplosion", "GetInstance", "Get"}) do
                    if type(module[methodName]) == "function" then
                        local ok, result = pcall(function()
                            return module[methodName](module, value)
                        end)
                        if ok and result then return true end
                    end
                end
            end
            return false
        end

        local function argsMentionLocal(args)
            for _, arg in ipairs(args) do
                if arg == LocalPlayer or arg == LocalPlayer.Character or arg == LocalPlayer.Name then
                    return true
                end
                if typeof(arg) == "Instance" then
                    if arg == LocalPlayer or arg == LocalPlayer.Character then return true end
                    if LocalPlayer.Character and arg:IsDescendantOf(LocalPlayer.Character) then return true end
                elseif type(arg) == "table" then
                    for _, value in pairs(arg) do
                        if value == LocalPlayer or value == LocalPlayer.Character or value == LocalPlayer.Name then
                            return true
                        end
                    end
                end
            end
            return false
        end

        local function valueMentionsLocal(value, depth)
            if depth > 4 or value == nil then return false end
            if value == LocalPlayer or value == LocalPlayer.Character or value == LocalPlayer.Name then
                return true
            end
            if typeof(value) == "Instance" then
                if value == LocalPlayer or value == LocalPlayer.Character then return true end
                if value:IsA("Player") then
                    return value == LocalPlayer
                        or value.Name == LocalPlayer.Name
                        or value.DisplayName == LocalPlayer.DisplayName
                end
                return LocalPlayer.Character and value:IsDescendantOf(LocalPlayer.Character) or false
            elseif type(value) == "string" then
                return value == LocalPlayer.Name or value == LocalPlayer.DisplayName
            elseif type(value) == "table" then
                for _, child in pairs(value) do
                    if valueMentionsLocal(child, depth + 1) then return true end
                end
            end
            return false
        end

        local function tableIndicatesLocalKill(tbl, depth)
            if type(tbl) ~= "table" or depth > 4 then return false end
            for key, value in pairs(tbl) do
                local keyText = tostring(key):lower()
                local killerKey = keyText:find("killer", 1, true)
                    or keyText:find("attacker", 1, true)
                    or keyText:find("creator", 1, true)
                    or keyText:find("source", 1, true)
                    or keyText:find("from", 1, true)
                    or keyText:find("dealer", 1, true)
                    or keyText:find("owner", 1, true)
                local victimKey = keyText:find("victim", 1, true)
                    or keyText:find("dead", 1, true)
                    or keyText:find("killed", 1, true)
                    or keyText:find("target", 1, true)
                if killerKey and valueMentionsLocal(value, 0) then return true end
                if victimKey and valueMentionsLocal(value, 0) then return false end
            end
            for _, value in pairs(tbl) do
                if tableIndicatesLocalKill(value, depth + 1) then return true end
            end
            return false
        end

        local function tableIndicatesLocalDeath(tbl, depth)
            if type(tbl) ~= "table" or depth > 4 then return false end
            for key, value in pairs(tbl) do
                local keyText = tostring(key):lower()
                local victimKey = keyText:find("victim", 1, true)
                    or keyText:find("dead", 1, true)
                    or keyText:find("killed", 1, true)
                    or keyText:find("target", 1, true)
                if victimKey and valueMentionsLocal(value, 0) then return true end
            end
            for _, value in pairs(tbl) do
                if tableIndicatesLocalDeath(value, depth + 1) then return true end
            end
            return false
        end

        local function argsIndicateLocalDeath(args)
            for _, arg in ipairs(args) do
                if tableIndicatesLocalDeath(arg, 0) then return true end
            end
            return false
        end

        local function argsIndicateLocalKill(args, remoteName)
            for _, arg in ipairs(args) do
                if tableIndicatesLocalKill(arg, 0) then return true end
            end
            local first = args[1]
            local second = args[2]
            local third = args[3]
            if valueMentionsLocal(second, 0) and not valueMentionsLocal(first, 0) then return true end
            if valueMentionsLocal(third, 0) and not valueMentionsLocal(first, 0) then return true end
            if valueMentionsLocal(first, 0) and not valueMentionsLocal(second, 0) then return true end

            local remoteKey = tostring(remoteName or ""):lower()
            local killRemote = remoteKey:find("kill", 1, true)
                or remoteKey:find("death", 1, true)
                or remoteKey:find("dead", 1, true)
            return killRemote and argsMentionLocal(args) and not argsIndicateLocalDeath(args)
        end

        local function getPositionFromExplosionValue(value, depth)
            if depth > 3 or value == nil then return nil end
            if typeof(value) == "Vector3" then return value end
            if typeof(value) == "CFrame" then return value.Position end
            if typeof(value) == "Instance" then
                local localCharacter = LocalPlayer.Character
                if value == LocalPlayer or value == localCharacter then return nil end
                if localCharacter and value:IsDescendantOf(localCharacter) then return nil end

                if value:IsA("BasePart") then return value.Position end
                if value:IsA("Player") then
                    local character = value.Character
                    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
                    return root and root.Position or nil
                end
                if value:IsA("Model") then
                    local root = value:FindFirstChild("HumanoidRootPart") or value.PrimaryPart
                    if root then return root.Position end
                    local ok, pivot = pcall(function() return value:GetPivot() end)
                    if ok and pivot then return pivot.Position end
                end
            elseif type(value) == "table" then
                for _, child in pairs(value) do
                    local position = getPositionFromExplosionValue(child, depth + 1)
                    if position then return position end
                end
            end
            return nil
        end

        local function isLocalExplosionPosition(position)
            if typeof(position) ~= "Vector3" then return false end
            local character = LocalPlayer.Character
            local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
            return root and (position - root.Position).Magnitude <= 4 or false
        end

        local function getExplosionPositionFromArgs(args)
            for _, arg in ipairs(args) do
                local position = getPositionFromExplosionValue(arg, 0)
                if position and not isLocalExplosionPosition(position) then return position end
            end
            return nil
        end

        local function parseVector3Attribute(value)
            if typeof(value) == "Vector3" then return value end
            if type(value) ~= "string" then return nil end
            local numbers = {}
            for numberText in value:gmatch("[-+]?%d+%.?%d*") do
                numbers[#numbers + 1] = tonumber(numberText)
                if #numbers >= 3 then break end
            end
            if #numbers >= 3 then
                return Vector3.new(numbers[1], numbers[2], numbers[3])
            end
            return nil
        end

        local function getNumberAttribute(object, names)
            for _, name in ipairs(names) do
                local value = tonumber(object:GetAttribute(name))
                if value then return value end
            end
            return nil
        end

        local function delayedTween(object, delayTime, duration, properties)
            if not next(properties) then return end
            task.delay(delayTime or 0, function()
                if object and object.Parent then
                    pcall(function()
                        TweenService:Create(
                            object,
                            TweenInfo.new(math.max(duration or 0.05, 0.05), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            properties
                        ):Play()
                    end)
                end
            end)
        end

        local function activateLocalExplosionObject(root)
            local objects = {root}
            for _, object in ipairs(root:GetDescendants()) do
                objects[#objects + 1] = object
            end

            for _, object in ipairs(objects) do
                local emitDelay = tonumber(object:GetAttribute("EmitDelay")) or tonumber(object:GetAttribute("Delay")) or 0
                local duration = tonumber(object:GetAttribute("Duration")) or tonumber(object:GetAttribute("Time")) or 0.35
                if object:IsA("BasePart") then
                    object.Anchored = true
                    object.CanCollide = false
                    object.CanTouch = false
                    object.CanQuery = false

                    local properties = {}
                    local sizeTarget = parseVector3Attribute(object:GetAttribute("Size_Target"))
                        or parseVector3Attribute(object:GetAttribute("Size"))
                    local transparencyTarget = tonumber(object:GetAttribute("Transparency_Target"))
                        or tonumber(object:GetAttribute("Transparency"))
                    if sizeTarget then properties.Size = sizeTarget end
                    if transparencyTarget then properties.Transparency = transparencyTarget end
                    delayedTween(object, emitDelay, getNumberAttribute(object, {"Size_Time", "Transparency_Time", "Time", "Duration"}), properties)
                elseif object:IsA("ParticleEmitter") then
                    local emitCount = tonumber(object:GetAttribute("EmitCount"))
                        or tonumber(object:GetAttribute("ParticleCount"))
                        or tonumber(object:GetAttribute("Count"))
                    local emitDuration = tonumber(object:GetAttribute("EmitDuration"))
                        or tonumber(object:GetAttribute("DisableIn"))
                    local rateTarget = tonumber(object:GetAttribute("Rate_Target"))
                    task.delay(emitDelay, function()
                        if object and object.Parent then
                            if emitCount and emitCount > 0 then
                                pcall(function() object:Emit(emitCount) end)
                            else
                                pcall(function() object.Enabled = true end)
                                if emitDuration and emitDuration > 0 then
                                    task.delay(emitDuration, function()
                                        if object and object.Parent then object.Enabled = false end
                                    end)
                                end
                            end
                            if rateTarget then
                                delayedTween(object, 0, duration, {Rate = rateTarget})
                            end
                        end
                    end)
                elseif object:IsA("Beam") then
                    task.delay(emitDelay, function()
                        if object and object.Parent then object.Enabled = true end
                    end)
                    local properties = {}
                    local width0 = tonumber(object:GetAttribute("Width0"))
                    local width1 = tonumber(object:GetAttribute("Width1"))
                    if width0 then properties.Width0 = width0 end
                    if width1 then properties.Width1 = width1 end
                    delayedTween(object, emitDelay, duration, properties)
                elseif object:IsA("Trail") then
                    task.delay(emitDelay, function()
                        if object and object.Parent then object.Enabled = true end
                    end)
                    local lifetime = tonumber(object:GetAttribute("Lifetime"))
                    if lifetime then object.Lifetime = lifetime end
                elseif object:IsA("Light") then
                    task.delay(emitDelay, function()
                        if object and object.Parent then object.Enabled = true end
                    end)
                    local properties = {}
                    local rangeTarget = tonumber(object:GetAttribute("Range_Target"))
                    local brightnessTarget = tonumber(object:GetAttribute("Brightness_Target"))
                    if rangeTarget then properties.Range = rangeTarget end
                    if brightnessTarget then properties.Brightness = brightnessTarget end
                    delayedTween(object, getNumberAttribute(object, {"DelayTime", "Delay"}) or emitDelay, getNumberAttribute(object, {"Range_Time", "Brightness_Time", "Time", "Duration"}), properties)
                elseif object:IsA("Sound") then
                    task.delay(tonumber(object:GetAttribute("Delay")) or emitDelay, function()
                        if object and object.Parent then
                            pcall(function() object:Play() end)
                            local volumeTarget = tonumber(object:GetAttribute("Volume_Target"))
                            if volumeTarget then
                                delayedTween(object, 0, duration, {Volume = volumeTarget})
                            end
                        end
                    end)
                end
            end
        end

        local function playSyntheticExplosion(position)
            getgenv().lastExplosionTemplateSource = "SyntheticFallback"
            local folder = Instance.new("Folder")
            folder.Name = "IceHubExplosion_LocalFallback"
            folder.Parent = workspace:FindFirstChild("Runtime") or workspace

            local part = Instance.new("Part")
            part.Name = "Burst"
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Material = Enum.Material.Neon
            part.Shape = Enum.PartType.Ball
            part.Size = Vector3.new(1, 1, 1)
            part.Color = Color3.fromRGB(120, 180, 255)
            part.Transparency = 1
            pcall(function() part.LocalTransparencyModifier = 1 end)
            part.CFrame = CFrame.new(position or Vector3.zero)
            part.Parent = folder

            local attachment = Instance.new("Attachment")
            attachment.Parent = part

            local emitter = Instance.new("ParticleEmitter")
            emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(90, 130, 255))
            emitter.LightEmission = 1
            emitter.Lifetime = NumberRange.new(0.35, 0.9)
            emitter.Speed = NumberRange.new(28, 58)
            emitter.SpreadAngle = Vector2.new(180, 180)
            emitter.Drag = 4
            emitter.Rate = 0
            emitter.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.8),
                NumberSequenceKeypoint.new(1, 0),
            })
            emitter.Parent = attachment
            emitter:Emit(90)

            local light = Instance.new("PointLight")
            light.Color = part.Color
            light.Brightness = 5
            light.Range = 18
            light.Parent = part

            TweenService:Create(part, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = Vector3.new(9, 9, 9),
                Transparency = 1,
            }):Play()
            TweenService:Create(light, TweenInfo.new(0.45), {Brightness = 0, Range = 0}):Play()

            task.delay(2, function()
                if folder and folder.Parent then folder:Destroy() end
            end)
            return true
        end



        local function playLocalExplosion(position)
            if not getgenv().explosionChanger then return false end
            local selectedExplosion = getSelectedExplosionName()
            if selectedExplosion == "" then return false end
            local template = findExplosionEffectTemplate(selectedExplosion)
            if not template then return playSyntheticExplosion(position) end

            local clone = template:Clone()
            clone.Name = "IceHubExplosion_" .. selectedExplosion

            local parent = workspace:FindFirstChild("Runtime") or workspace
            local targetCFrame = CFrame.new(position or Vector3.zero)

            if clone:IsA("Attachment") then
                local folder = Instance.new("Folder")
                folder.Name = "IceHubExplosion_" .. selectedExplosion
                folder.Parent = parent

                local anchor = Instance.new("Part")
                anchor.Name = "IceHubExplosionAnchor"
                anchor.Anchored = true
                anchor.CanCollide = false
                anchor.CanTouch = false
                anchor.CanQuery = false
                anchor.Transparency = 1
                anchor.Size = Vector3.new(1, 1, 1)
                anchor.CFrame = targetCFrame
                anchor.Parent = folder

                clone.Parent = anchor
                clone = folder
            else
                clone.Parent = parent
            end

            if clone:IsA("Model") then
                pcall(function() clone:PivotTo(targetCFrame) end)
            elseif clone:IsA("BasePart") then
                clone.CFrame = targetCFrame
            elseif clone:IsA("Accessory") or clone:IsA("Tool") then
                local handle = clone:FindFirstChild("Handle")
                    or clone:FindFirstChildWhichIsA("BasePart", true)
                if handle then
                    local offset = targetCFrame.Position - handle.Position
                    for _, part in ipairs(clone:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CFrame = part.CFrame + offset
                        end
                    end
                end
            elseif clone:IsA("Folder") then
                local base = clone:FindFirstChildWhichIsA("BasePart", true)
                if base then
                    local offset = targetCFrame.Position - base.Position
                    for _, part in ipairs(clone:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CFrame = part.CFrame + offset
                        end
                    end
                else
                    local anchor = Instance.new("Part")
                    anchor.Name = "IceHubExplosionAnchor"
                    anchor.Anchored = true
                    anchor.CanCollide = false
                    anchor.CanTouch = false
                    anchor.CanQuery = false
                    anchor.Transparency = 1
                    anchor.Size = Vector3.new(1, 1, 1)
                    anchor.CFrame = targetCFrame
                    anchor.Parent = clone
                    for _, child in ipairs(clone:GetDescendants()) do
                        if child:IsA("Attachment") and not child.Parent:IsA("BasePart") then
                            child.Parent = anchor
                        end
                    end
                end
            end

            activateLocalExplosionObject(clone)
            task.delay(8, function()
                if clone and clone.Parent then clone:Destroy() end
            end)
            return true
        end

        local function isIceHubExplosionObject(object)
            local current = object
            while current and current ~= workspace do
                if type(current.Name) == "string"
                    and current.Name:find("IceHubExplosion", 1, true) then
                    return true
                end
                current = current.Parent
            end
            return false
        end

        local function hideNativeExplosionVisual(object)
            if not object or isIceHubExplosionObject(object) then return end
            local objects = { object }
            for _, descendant in ipairs(object:GetDescendants()) do
                objects[#objects + 1] = descendant
            end

            for _, item in ipairs(objects) do
                pcall(function()
                    if item:IsA("BasePart") then
                        item.Transparency = 1
                        item.LocalTransparencyModifier = 1
                        item.CanCollide = false
                        item.CanTouch = false
                        item.CanQuery = false
                    elseif item:IsA("ParticleEmitter") then
                        item.Enabled = false
                        item.Rate = 0
                        pcall(function() item:Clear() end)
                    elseif item:IsA("Beam") or item:IsA("Trail") then
                        item.Enabled = false
                    elseif item:IsA("Light") then
                        item.Enabled = false
                        item.Brightness = 0
                        item.Range = 0
                    elseif item:IsA("Sound") then
                        item.Volume = 0
                        pcall(function() item:Stop() end)
                    end
                end)
            end
        end

        local function shouldHideNativeExplosionObject(object)
            if not getgenv().explosionChanger then return false end
            if (getgenv()._lhxExplosionLocalKillUntil or 0) <= os.clock() then return false end
            if isIceHubExplosionObject(object) then return false end

            local key = normalizeExplosionName(object and object.Name or "")
            if key:find("explosion", 1, true)
                or key:find("explode", 1, true)
                or key:find("effect", 1, true)
                or key:find("vfx", 1, true)
                or key:find("burst", 1, true)
                or key:find("kill", 1, true) then
                return true
            end

            local parent = object and object.Parent
            local parentKey = normalizeExplosionName(parent and parent.Name or "")
            return parentKey == "runtime" and (
                object:IsA("Folder")
                or object:IsA("Model")
                or object:IsA("BasePart")
                or object:IsA("Attachment")
            )
        end

        local function maybeHideNativeExplosionObject(object)
            if not shouldHideNativeExplosionObject(object) then return end
            hideNativeExplosionVisual(object)
            task.delay(0.03, function() hideNativeExplosionVisual(object) end)
            task.delay(0.12, function() hideNativeExplosionVisual(object) end)
            task.delay(0.3, function() hideNativeExplosionVisual(object) end)
        end

        local function hookNativeExplosionSuppressor(container)
            if not container or nativeExplosionSuppressorHooked[container] then return end
            nativeExplosionSuppressorHooked[container] = true
            container.ChildAdded:Connect(maybeHideNativeExplosionObject)
        end

        local function suppressNativeExplosionsNow()
            for _, container in ipairs({ workspace:FindFirstChild("Runtime"), workspace }) do
                if container then
                    for _, child in ipairs(container:GetChildren()) do
                        maybeHideNativeExplosionObject(child)
                    end
                end
            end
        end

        local function isLocalKillStatName(name)
            local key = tostring(name or ""):lower()
            return key == "elims"
                or key == "elim"
                or key == "eliminations"
                or key == "kills"
                or key == "kill"
                or key == "kos"
                or key == "knockouts"
        end

        local function numericStatValue(value)
            if type(value) == "number" then return value end
            if type(value) == "string" then return tonumber(value) end
            if typeof(value) == "Instance" then
                if value:IsA("IntValue")
                    or value:IsA("NumberValue")
                    or value:IsA("StringValue") then
                    return tonumber(value.Value)
                end
            end
            return nil
        end

        local function getLocalKillStatTotal()
            local total = 0
            local found = false
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                for _, stat in ipairs(leaderstats:GetChildren()) do
                    if isLocalKillStatName(stat.Name) then
                        local value = numericStatValue(stat)
                        if value then
                            total += value
                            found = true
                        end
                    end
                end
            end
            for _, attributeName in ipairs({"PlayerElims", "Elims", "Eliminations", "Kills", "KillCount", "Knockouts"}) do
                local attributeValue = LocalPlayer:GetAttribute(attributeName)
                local value = numericStatValue(attributeValue)
                if value then
                    total += value
                    found = true
                end
            end
            return found and total or nil
        end

        local function playPendingKillExplosion()
            if not getgenv().explosionChanger and (not getgenv().finisherModel or getgenv().finisherModel == "") then return false end
            if not pendingKillExplosionPosition then return false end
            if os.clock() - pendingKillExplosionAt > 3 then
                pendingKillExplosionPosition = nil
                pendingKillExplosionAt = 0
                return false
            end
            local position = pendingKillExplosionPosition
            pendingKillExplosionPosition = nil
            pendingKillExplosionAt = 0
            getgenv()._lhxExplosionLocalKillUntil = os.clock() + 1.25
            if lastLocalExplosionPlayedPosition
                and os.clock() - lastLocalExplosionPlayedAt < 0.25
                and (lastLocalExplosionPlayedPosition - position).Magnitude < 8 then
                return false
            end
            lastLocalExplosionPlayedAt = os.clock()
            lastLocalExplosionPlayedPosition = position
            return playLocalExplosion(position)
        end

        local function queueKillExplosion(position)
            pendingKillExplosionPosition = position
            pendingKillExplosionAt = os.clock()
            if os.clock() - lastLocalKillAt <= 2.5 then
                playPendingKillExplosion()
            end
        end

        local function markLocalKill(position)
            lastLocalKillAt = os.clock()
            getgenv()._lhxExplosionLocalKillUntil = os.clock() + 1.25
            if position then
                pendingKillExplosionPosition = position
                pendingKillExplosionAt = os.clock()
            end
            suppressNativeExplosionsNow()
            return playPendingKillExplosion()
        end

        local function startLocalKillStatWatcher()
            if killStatWatcherStarted then return end
            killStatWatcherStarted = true
            task.spawn(function()
                while task.wait(0.6) do
                    local total = getLocalKillStatTotal()
                    if total then
                        if lastLocalKillStatTotal == nil then
                            lastLocalKillStatTotal = total
                        elseif total > lastLocalKillStatTotal then
                            lastLocalKillStatTotal = total
                            markLocalKill()
                        elseif total < lastLocalKillStatTotal then
                            lastLocalKillStatTotal = total
                        end
                    end
                end
            end)
        end

        local function patchExplosionTable(tbl, remoteKey, selectedExplosion, depth)
            if type(tbl) ~= "table" or depth > 2 then return false end
            local changed = false
            for key, value in pairs(tbl) do
                local keyText = tostring(key):lower()
                if type(value) == "string" then
                    local keyLooksRight = keyText:find("explosion", 1, true)
                        or keyText:find("effect", 1, true)
                        or keyText:find("fx", 1, true)
                    if keyLooksRight or isKnownExplosionName(value) then
                        tbl[key] = selectedExplosion
                        changed = true
                    end
                elseif type(value) == "table" then
                    changed = patchExplosionTable(value, remoteKey, selectedExplosion, depth + 1) or changed
                end
            end
            return changed
        end

        local function patchExplosionArgs(remoteName, args, isOurKill)
            if not getgenv().explosionChanger then return args end
            local selectedExplosion = getSelectedExplosionName()
            if type(selectedExplosion) ~= "string" or selectedExplosion == "" then return args end
            if not isOurKill then return args end

            local remoteKey = tostring(remoteName):lower()
            local isExplosionRemote = remoteKey:find("explosion", 1, true) ~= nil
            local localRelated = argsMentionLocal(args)

            local changed = false

            for index, arg in ipairs(args) do
                if type(arg) == "string" and not isPlayerString(arg) then
                    local valueKey = arg:lower()
                    local shouldPatch = isKnownExplosionName(arg)
                        or isExplosionRemote
                        or (localRelated and (
                            valueKey:find("explosion", 1, true)
                            or valueKey:find("effect", 1, true)
                            or valueKey:find("fx", 1, true)
                        ))
                    if shouldPatch then
                        args[index] = selectedExplosion
                        changed = true
                    end
                elseif type(arg) == "table" then
                    changed = patchExplosionTable(arg, remoteKey, selectedExplosion, 0) or changed
                end
            end

            if isExplosionRemote and not changed then
                for index, arg in ipairs(args) do
                    if type(arg) == "string" and not isPlayerString(arg) then
                        args[index] = selectedExplosion
                        break
                    end
                end
            end

            return args
        end

        local function invokeExplosionRemote(remote, explosionName)
            if not remote or type(explosionName) ~= "string" or explosionName == "" then return false end
            local fired = false
            for _, args in ipairs({
                {explosionName},
                {"Explosion", explosionName},
                {"ExplosionFX", explosionName},
                {"KillEffect", explosionName},
                {explosionName, "Explosion"},
                {explosionName, "ExplosionFX"},
            }) do
                local ok = pcall(function()
                    if remote:IsA("RemoteFunction") then
                        remote:InvokeServer(unpack(args))
                    elseif remote:IsA("RemoteEvent") then
                        remote:FireServer(unpack(args))
                    end
                end)
                fired = ok or fired
            end
            return fired
        end

        local function isExplosionBindable(instance)
            if typeof(instance) ~= "Instance" or not instance:IsA("BindableFunction") then return false end
            local nameKey = normalizeExplosionName(instance.Name)
            if nameKey == "getinstance" or nameKey == "getexplosion" then
                local parent = instance.Parent
                while parent and parent ~= rs do
                    if normalizeExplosionName(parent.Name):find("explosion", 1, true) then
                        return true
                    end
                    parent = parent.Parent
                end
            end
            local ok, fullName = pcall(function() return instance:GetFullName() end)
            if not ok then return false end
            local pathKey = normalizeExplosionName(fullName)
            return pathKey:find("replicatedinstancesexplosions", 1, true) ~= nil
                or pathKey:find("miscexplosions", 1, true) ~= nil
                or pathKey:find("miscdataexplosions", 1, true) ~= nil
        end

        local function installExplosionBindableHook()
            if bindableInvokeHooked then return end
            local hookFunction = getExecutorGlobal("hookfunction") or getExecutorGlobal("hookfunc")
            local makeClosure = getExecutorGlobal("newcclosure") or function(callback) return callback end
            if type(hookFunction) ~= "function" then return end

            local dummyBindable = Instance.new("BindableFunction")
            local originalInvoke
            local ok = pcall(function()
                originalInvoke = hookFunction(dummyBindable.Invoke, makeClosure(function(self, ...)
                    local args = { ... }
                    local localKillWindow = (getgenv()._lhxExplosionLocalKillUntil or 0) > os.clock()
                    if getgenv().explosionChanger and localKillWindow and isExplosionBindable(self) then
                        local selectedExplosion = getSelectedExplosionName()
                        if selectedExplosion ~= "" then
                            for index, value in ipairs(args) do
                                if type(value) == "string" and not isPlayerString(value) then
                                    args[index] = selectedExplosion
                                    break
                                end
                            end
                            if #args == 0 then
                                args[1] = selectedExplosion
                            end
                        end
                    end
                    return originalInvoke(self, unpack(args))
                end))
            end)
            dummyBindable:Destroy()
            bindableInvokeHooked = ok == true
        end

        local function findExplosionEquipRemotes()
            local remotes = {}
            local store = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("Store")
            local net = getNetFolder()
            local function addRemote(remote)
                if not remote then return end
                for _, existing in ipairs(remotes) do
                    if existing == remote then return end
                end
                table.insert(remotes, remote)
            end

            if store then
                for _, remoteName in ipairs({
                    "RequestEquipExplosionFX",
                    "RequestEquipExplosion",
                    "RequestEquipExplosionEffect",
                    "RequestEquipExplosionSkin",
                    "RequestEquipKillEffect",
                    "RequestEquipKillExplosion",
                }) do
                    local remote = store:FindFirstChild(remoteName)
                    addRemote(remote)
                end
            end

            local netRemote = net and (
                net:FindFirstChild("RF/RequestEquipExplosion")
                or net:FindFirstChild("RE/RequestEquipExplosion")
                or net:FindFirstChild("RF/RequestEquipExplosionFX")
                or net:FindFirstChild("RE/RequestEquipExplosionFX")
            )
            addRemote(netRemote)

            if #remotes == 0 then
                for _, obj in ipairs(rs:GetDescendants()) do
                    if obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent") then
                        local key = obj.Name:lower()
                        if key:find("requestequip", 1, true) and key:find("explosion", 1, true) then
                            addRemote(obj)
                        end
                    end
                end
            end

            return remotes
        end

        getgenv().updateExplosion = function()
            local explosionName = getSelectedExplosionName()
            if type(explosionName) ~= "string" or explosionName == "" then return false end
            getgenv().explosionFX = explosionName

            pcall(function() LocalPlayer:SetAttribute("CurrentlyEquippedExplosion", explosionName) end)
            pcall(function() LocalPlayer:SetAttribute("CurrentlyEquippedExplosionFX", explosionName) end)
            pcall(function() LocalPlayer:SetAttribute("EquippedExplosion", explosionName) end)
            pcall(function() LocalPlayer:SetAttribute("EquippedExplosionFX", explosionName) end)
            pcall(function() LocalPlayer:SetAttribute("SelectedExplosion", explosionName) end)
            pcall(function() LocalPlayer:SetAttribute("SelectedExplosionFX", explosionName) end)
            pcall(function() LocalPlayer:SetAttribute("CurrentExplosion", explosionName) end)
            pcall(function() LocalPlayer:SetAttribute("CurrentExplosionFX", explosionName) end)
            pcall(function() LocalPlayer:SetAttribute("KillEffect", explosionName) end)
            pcall(function() LocalPlayer:SetAttribute("EquippedKillEffect", explosionName) end)
            if LocalPlayer.Character then
                pcall(function() LocalPlayer.Character:SetAttribute("CurrentlyEquippedExplosion", explosionName) end)
                pcall(function() LocalPlayer.Character:SetAttribute("CurrentlyEquippedExplosionFX", explosionName) end)
                pcall(function() LocalPlayer.Character:SetAttribute("EquippedExplosion", explosionName) end)
                pcall(function() LocalPlayer.Character:SetAttribute("EquippedExplosionFX", explosionName) end)
                pcall(function() LocalPlayer.Character:SetAttribute("SelectedExplosion", explosionName) end)
                pcall(function() LocalPlayer.Character:SetAttribute("SelectedExplosionFX", explosionName) end)
                pcall(function() LocalPlayer.Character:SetAttribute("CurrentExplosion", explosionName) end)
                pcall(function() LocalPlayer.Character:SetAttribute("CurrentExplosionFX", explosionName) end)
                pcall(function() LocalPlayer.Character:SetAttribute("KillEffect", explosionName) end)
                pcall(function() LocalPlayer.Character:SetAttribute("EquippedKillEffect", explosionName) end)
            end

            if getgenv().saveLastEquippedExplosion then
                getgenv().saveLastEquippedExplosion(explosionName)
            end

            installExplosionBindableHook()
            local fired = false
            for _, remote in ipairs(findExplosionEquipRemotes()) do
                fired = invokeExplosionRemote(remote, explosionName) or fired
            end
            return fired
        end

        getgenv().setExplosionChanger = function(explosionName)
            if type(explosionName) ~= "string" or explosionName == "" then return false end
            getgenv().explosionFX = explosionName
            getgenv().explosionChanger = true
            if getgenv().setExplosionChangerToggleUI then getgenv().setExplosionChangerToggleUI(true) end
            if getgenv().setExplosionInputUI then getgenv().setExplosionInputUI(explosionName) end
            return getgenv().updateExplosion()
        end

        getgenv().testExplosion = function()
            local character = LocalPlayer.Character
            local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
            local camera = workspace.CurrentCamera
            local position = root and (root.Position + root.CFrame.LookVector * 7)
                or camera and (camera.CFrame.Position + camera.CFrame.LookVector * 12)
                or Vector3.zero
            return playLocalExplosion(position)
        end

        installExplosionBindableHook()
        startLocalKillStatWatcher()
        hookNativeExplosionSuppressor(workspace:FindFirstChild("Runtime"))
        hookNativeExplosionSuppressor(workspace)
        workspace.ChildAdded:Connect(function(child)
            if child.Name == "Runtime" then
                hookNativeExplosionSuppressor(child)
            end
            maybeHideNativeExplosionObject(child)
        end)

        local function hookDeadFolder()
            if deadFolderHooked then return end
            local deadFolder = workspace:FindFirstChild("Dead")
            if not deadFolder then return end
            deadFolderHooked = true
            deadFolder.ChildAdded:Connect(function(character)
                if not getgenv().explosionChanger and (not getgenv().finisherModel or getgenv().finisherModel == "") then return end
                task.wait(0.05)
                if character == LocalPlayer.Character then return end

                local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
                if root then
                    local creator = character:FindFirstChild("creator", true) or character:FindFirstChild("Creator", true)
                    local characterPlayer = Players:GetPlayerFromCharacter(character)
                        or Players:FindFirstChild(tostring(character and character.Name or ""))
                    
                    local isLocalKill = false
                    if creator and (creator.Value == LocalPlayer or creator.Value == LocalPlayer.Name) then
                        isLocalKill = true
                        markLocalKill(root.Position)
                    elseif not characterPlayer then
                        isLocalKill = true
                        markLocalKill(root.Position)
                    else
                        queueKillExplosion(root.Position)
                    end
                    
                    if isLocalKill and getgenv().finisherModel and getgenv().finisherModel ~= "" and getgenv()._lhxFCModule then
                        if not characterPlayer then
                            task.spawn(function()
                                local s = pcall(function()
                                    getgenv()._lhxFCModule:Play(getgenv().finisherModel, character)
                                end)
                                if not s then
                                    pcall(function()
                                        getgenv()._lhxFCModule:Play(character, getgenv().finisherModel)
                                    end)
                                end
                            end)
                        end
                    end
                end
            end)
        end

        hookDeadFolder()
        workspace.ChildAdded:Connect(function(child)
            if child.Name == "Dead" then
                deadFolderHooked = false
                task.defer(hookDeadFolder)
            end
        end)

        LocalPlayer.CharacterAdded:Connect(function(character)
            task.wait(0.75)
            if getgenv().explosionChanger and getgenv().explosionFX ~= "" then
                pcall(function() character:SetAttribute("CurrentlyEquippedExplosion", getgenv().explosionFX) end)
                pcall(getgenv().updateExplosion)
            end
        end)

        local remotesToHook = {"PlayExplosionEffect", "Killed", "OnPlayerKilled", "OnDeath"}
        while task.wait(1) do
            local remotesFolder = rs:FindFirstChild("Remotes")
            if remotesFolder then
                for _, remoteName in ipairs(remotesToHook) do
                    local remote = remotesFolder:FindFirstChild(remoteName)
                    if remote and remote:IsA("RemoteEvent") then
                        if not explosionDirectHooked[remote] then
                            explosionDirectHooked[remote] = true
                            remote.OnClientEvent:Connect(function(...)
                                if not getgenv().explosionChanger then return end
                                local rawArgs = { ... }
                                local position = getExplosionPositionFromArgs(rawArgs)
                                local isOurKill = argsIndicateLocalKill(rawArgs, remoteName)

                                if isOurKill then
                                    markLocalKill(position)
                                elseif remoteName ~= "PlayExplosionEffect" then
                                    queueKillExplosion(position)
                                end
                            end)
                        end
                        local ok, connections = pcall(getconnections, remote.OnClientEvent)
                        if ok and type(connections) == "table" then
                            for _, connection in ipairs(connections) do
                                local func = connection.Function
                                if func and not explosionHookedFuncs[func] then
                                    if isourclosure and isourclosure(func) then
                                        explosionHookedFuncs[func] = true
                                        continue
                                    end
                                    explosionHookedFuncs[func] = true
                                    connection:Disable()
                                    local targetFunc = func
                                    local ourFunc
                                    ourFunc = function(...)
                                        local rawArgs = { ... }
                                        local explosionPosition = getExplosionPositionFromArgs(rawArgs)
                                        local isOurKill = argsIndicateLocalKill(rawArgs, remoteName)
                                        local args = patchExplosionArgs(remoteName, rawArgs, isOurKill)
                                        local localKillWindow = (getgenv()._lhxExplosionLocalKillUntil or 0) > os.clock()

                                        if getgenv().explosionChanger then
                                            if isOurKill then
                                                markLocalKill(explosionPosition)
                                            elseif remoteName ~= "PlayExplosionEffect" then
                                                queueKillExplosion(explosionPosition)
                                            end
                                            if remoteName == "PlayExplosionEffect" and (isOurKill or localKillWindow) then
                                                return
                                            end
                                        end
                                        if setthreadidentity then pcall(setthreadidentity, 2) end
                                        pcall(targetFunc, unpack(args))
                                    end
                                    explosionHookedFuncs[ourFunc] = true
                                    remote.OnClientEvent:Connect(ourFunc)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)



    -- Avatar Changer
    local __av_flags={}; local __av_persistent={}
    local function __av_match(a,b)
        if not a or not b then return false end
        for _,k in ipairs({"Shirt","Pants","ShirtGraphic","Head","Face","BodyTypeScale","HeightScale","WidthScale"}) do local av,bv=a[k],b[k]; if av~=nil and bv~=nil and tostring(av)~=tostring(bv) then return false end end; return true
    end
    local function __av_force_apply(hum,desc)
        if not hum or not desc then return false end
        for _=1,20 do pcall(function() hum:ApplyDescriptionClientServer(desc) end); task.wait(0.05); local ok,ap=pcall(function() return hum:GetAppliedDescription() end); if ok and ap and __av_match(ap,desc) then return true end end
        pcall(function() hum.Description=Instance.new("HumanoidDescription") end); task.wait(0.1)
        for _=1,40 do pcall(function() hum:ApplyDescriptionClientServer(desc) end); task.wait(0.05); local ok,ap=pcall(function() return hum:GetAppliedDescription() end); if ok and ap and __av_match(ap,desc) then return true end end
        return false
    end
    local function __av_start_persistent(char,desc)
        if not char or not desc then return end; local key=char; if __av_persistent[key] then return end
        local stop=false; __av_persistent[key]={stop=function() stop=true end}
        spawn(function()
            local hum=char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid",5); if not hum then __av_persistent[key]=nil; return end
            while not stop and char.Parent do
                pcall(function() __av_force_apply(hum,desc) end)
                local ok,ap=pcall(function() return hum:GetAppliedDescription() end)
                if ok and ap and __av_match(ap,desc) then for _=1,40 do if stop or not char.Parent then break end; task.wait(0.25) end
                else for _=1,20 do if stop or not char.Parent then break end; pcall(function() hum:ApplyDescriptionClientServer(desc) end); task.wait(0.1) end end
                if not hum.Parent then hum=char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid",5) end
            end; __av_persistent[key]=nil
        end)
    end
    local function __av_stop_all() for k,v in pairs(__av_persistent) do if v and type(v.stop)=="function" then pcall(v.stop) end; __av_persistent[k]=nil end end
    local function __av_set(name,char)
        if not name or name=="" then return end; local hum=char and char:WaitForChild("Humanoid",5); if not hum then return end
        local ok,desc=pcall(function() local id=Players:GetUserIdFromNameAsync(name); return Players:GetHumanoidDescriptionFromUserId(id) end)
        if not ok or not desc then return end
        pcall(function() LocalPlayer:ClearCharacterAppearance(); hum.Description=Instance.new("HumanoidDescription") end)
        task.wait(0.05); pcall(function() __av_force_apply(hum,desc) end); __av_start_persistent(char,desc)
    end

    -- Ability ESP
    local function createBillboardGui(p)
        task.spawn(function()
            local character=p.Character; while not character or not character.Parent do task.wait(0.25); character=p.Character end
            local head=character:WaitForChild("Head",10); if not head then return end
            local bg=Instance.new("BillboardGui"); bg.Name="AbilityESP_Gui"; bg.Adornee=head; bg.Size=UDim2.new(0,220,0,60); bg.StudsOffset=Vector3.new(0,3.5,0); bg.AlwaysOnTop=true; bg.Parent=head
            local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,0,1,0); tl.TextColor3=Color3.fromRGB(220,50,50); tl.TextSize=16; tl.TextStrokeTransparency=0; tl.TextStrokeColor3=Color3.fromRGB(0,0,0); tl.Font=Enum.Font.GothamBold; tl.BackgroundTransparency=1; tl.Parent=bg; tl.Visible=getgenv().AbilityESP == true; billboardLabels[p]=tl
            local hum=character:FindFirstChild("Humanoid"); if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
            
            local charRemovingConn
            charRemovingConn = p.CharacterRemoving:Connect(function()
                charRemovingConn:Disconnect()
                pcall(function() bg:Destroy() end)
                billboardLabels[p] = nil
            end)
        end)
    end
    for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then p.CharacterAdded:Connect(function() createBillboardGui(p) end); if p.Character then createBillboardGui(p) end end end
    Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() createBillboardGui(p) end) end)

    -- Single background thread updating ESP text/visibility throttled to 3 times a second (0.33s)
    task.spawn(function()
        while task.wait(0.33) do
            for p, tl in pairs(billboardLabels) do
                if tl and tl.Parent then
                    local show = getgenv().AbilityESP == true
                    if tl.Visible ~= show then
                        tl.Visible = show
                    end
                    if show then
                        local ab = p:GetAttribute("EquippedAbility")
                        local text = ab and (p.DisplayName .. " [" .. ab .. "]") or p.DisplayName
                        if tl.Text ~= text then
                            tl.Text = text
                        end
                    end
                end
            end
        end
    end)

    -- ═══ BACKEND: PLAYER SPEED ══════════════════════════════════════
    getgenv().playerSpeedEnabled = false
    getgenv().playerSpeed = 36
    do
        local speedChangedConn = nil
        local function enforceSpeed(hum)
            if speedChangedConn then speedChangedConn:Disconnect(); speedChangedConn = nil end
            if not hum then return end
            local currentTarget = getgenv().playerSpeedEnabled and getgenv().playerSpeed or 36
            hum.WalkSpeed = currentTarget
            speedChangedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                local target = getgenv().playerSpeedEnabled and getgenv().playerSpeed or 36
                if hum.WalkSpeed ~= target then
                    hum.WalkSpeed = target
                end
            end)
        end

        getgenv().updatePlayerSpeed = function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then enforceSpeed(hum) end
        end

        getgenv().playerJumpEnabled = getgenv().playerJumpEnabled or false
        getgenv().playerJump = getgenv().playerJump or 50
        local jumpChangedConn = nil
        local function enforceJump(hum)
            if jumpChangedConn then jumpChangedConn:Disconnect(); jumpChangedConn = nil end
            if not hum then return end
            pcall(function() hum.UseJumpPower = true end)
            local currentTarget = getgenv().playerJumpEnabled and getgenv().playerJump or 50
            hum.JumpPower = currentTarget
            jumpChangedConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
                local target = getgenv().playerJumpEnabled and getgenv().playerJump or 50
                if hum.JumpPower ~= target then
                    hum.JumpPower = target
                end
            end)
        end

        getgenv().updatePlayerJump = function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then enforceJump(hum) end
        end

        LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                enforceSpeed(hum)
                enforceJump(hum)
            end
        end)
    end

    -- ═══ BACKEND: FOV ══════════════════════════════════════════════════
    getgenv().fovEnabled = false
    getgenv().fov = 70
    do
        local fovConn = nil
        local function enforceFov()
            if fovConn then fovConn:Disconnect(); fovConn = nil end
            local cam = workspace.CurrentCamera
            if not cam then return end
            if not getgenv().fovEnabled then
                cam.FieldOfView = 70
                return
            end
            cam.FieldOfView = getgenv().fov
            fovConn = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                if getgenv().fovEnabled and cam.FieldOfView ~= getgenv().fov then
                    cam.FieldOfView = getgenv().fov
                end
            end)
        end

        getgenv().updateFOV = enforceFov
        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(enforceFov)
    end

    -- BACKEND: BLADE BALL EMOTES
    getgenv().selectedEmote = getgenv().selectedEmote or ""
    getgenv().emoteVFXEnabled = false
    getgenv().emoteLooped = getgenv().emoteLooped or false
    ;(function()
        local EMOTE_FAVORITES_FILE = "IceHubX/emote_favorites.json"
        local function loadEmoteFavorites()
            local favorites = {}
            pcall(function()
                if isfile and isfile(EMOTE_FAVORITES_FILE) then
                    local decoded = HttpService:JSONDecode(readfile(EMOTE_FAVORITES_FILE))
                    if type(decoded) == "table" then
                        for _, name in ipairs(decoded) do
                            if type(name) == "string" and name ~= "" then
                                favorites[name] = true
                            end
                        end
                    end
                end
            end)
            return favorites
        end

        local function saveEmoteFavorites(favorites)
            pcall(function()
                if isfolder and makefolder and not isfolder("IceHubX") then
                    makefolder("IceHubX")
                end
                if not writefile then return end

                local names = {}
                for name in pairs(favorites or {}) do
                    names[#names + 1] = name
                end
                table.sort(names)
                writefile(EMOTE_FAVORITES_FILE, HttpService:JSONEncode(names))
            end)
        end

        local previousState = getgenv()._lhxBladeBallEmotes
        local previousEmoteWheelTemplate = previousState and previousState.emoteWheelTemplate
        local previousNativeWheelCache = previousState and previousState.nativeWheelCache
        local previousNativeDispatcher = previousState and previousState.nativeDispatcher
        if previousState and type(previousState.Destroy) == "function" then
            pcall(previousState.Destroy)
        end

        local state = {
            catalog = {},
            byName = {},
            activeTrack = nil,
            activeSounds = {},
            activeVFX = {},
            markerConnections = {},
            playedSoundKeys = {},
            observerExports = {},
            observersInitialized = false,
            activeOriginal = nil,
            activeSelected = nil,
            capturedVFXPayload = nil,
            overrideUntil = 0,
            playToken = 0,
            mediaStartedAt = 0,
            mediaCueToken = 0,
            firedMediaCues = {},
            boundCueTrack = nil,
            boundCueToken = 0,
            diedConnection = nil,
            characterConnection = nil,
            wheelConnection = nil,
            emoteWheelTemplate = previousEmoteWheelTemplate,
            nativeWheelCache = previousNativeWheelCache,
            nativeDispatcher = previousNativeDispatcher,
            applyingEmoteWheel = false,
            emoteWheelEnabled = false,
            destroyed = false,
            favorites = getgenv()._lhxBladeBallEmoteFavorites or loadEmoteFavorites(),
            customWheelGui = nil,
            customWheelConn = nil,
            customWheelButtonGui = nil,
            catalogSignature = "",
            wheelInitialized = false,
            lastWheelApply = 0,
            wheelScrollControls = {},
            wheelScrollConnections = {},
            wheelSearchConnections = {},
            vfxRootCache = nil,
            vfxRootCacheAt = 0,
            vfxPayloadCache = {},
            namedVFXCache = {},
            emoteAccessoryCache = {},
            entrySoundCache = {},
            debugEmotes = getgenv().IceHubEmoteDebug == true,
        }
        getgenv()._lhxBladeBallEmotes = state
        getgenv()._lhxBladeBallEmoteFavorites = state.favorites

        local function emoteDebugWarn(...)
            if state.debugEmotes then warn(...) end
        end

        local hooks = getgenv()._lhxBladeBallEmoteHooks or {}
        if hooks.version ~= 2 then
            hooks.version = 2
            hooks.bindableFunction = false
            hooks.bindableEvent = false
            hooks.remoteEvent = false
            hooks.remoteFunction = false
            hooks.animator = false
            hooks.humanoid = false
        end
        if hooks.clone == nil then hooks.clone = false end
        hooks.activeState = state
        getgenv()._lhxBladeBallEmoteHooks = hooks

        local function normalize(value)
            return tostring(value or ""):lower():gsub("[^%w]", "")
        end

        local function assetId(value)
            return tostring(value or ""):match("%d+")
        end

        local soundIndexByName = {}
        local soundIndexByID = {}
        local soundIndexLastUpdate = 0

        local function rebuildSoundIndex()
            table.clear(soundIndexByName)
            table.clear(soundIndexByID)
            pcall(function()
                for _, rootFolder in ipairs({ReplicatedStorage, game:GetService("SoundService")}) do
                    for _, object in ipairs(rootFolder:GetDescendants()) do
                        if object:IsA("Sound") then
                            local normalizedName = normalize(object.Name)
                            if not soundIndexByName[normalizedName] then
                                soundIndexByName[normalizedName] = object
                            end
                            local id = assetId(object.SoundId)
                            if id and not soundIndexByID[id] then
                                soundIndexByID[id] = object
                            end
                        end
                    end
                end
            end)
            soundIndexLastUpdate = os.clock()
        end

        local function getSoundByName(name)
            if os.clock() - soundIndexLastUpdate > 15 or not next(soundIndexByName) then
                rebuildSoundIndex()
            end
            return soundIndexByName[normalize(name)]
        end

        local function getInstanceAttribute(instance, names)
            if typeof(instance) ~= "Instance" then return nil end
            for _, name in ipairs(names) do
                local ok, value = pcall(function()
                    return instance:GetAttribute(name)
                end)
                if ok and value ~= nil and tostring(value) ~= "" then
                    return value
                end
            end
            return nil
        end

        local function getEntryAttribute(entry, names)
            if entry and entry.Attributes then
                for _, name in ipairs(names) do
                    local value = entry.Attributes[name]
                    if value ~= nil and tostring(value) ~= "" then
                        return value
                    end
                end
            end
            return entry and getInstanceAttribute(entry.Animation, names) or nil
        end

        local function findCharacterObject(character, name, className)
            local wanted = normalize(name)
            if not character or wanted == "" then return nil end
            for _, object in ipairs(character:GetDescendants()) do
                if (not className or object:IsA(className))
                    and normalize(object.Name) == wanted then
                    return object
                end
            end
            return nil
        end

        local function findCharacterPart(character, names)
            if not character then return nil end
            for _, name in ipairs(names) do
                local part = character:FindFirstChild(name)
                if part and part:IsA("BasePart") then return part end
            end
            for _, name in ipairs(names) do
                local wanted = normalize(name)
                for _, object in ipairs(character:GetDescendants()) do
                    if object:IsA("BasePart") and normalize(object.Name) == wanted then
                        return object
                    end
                end
            end
            return nil
        end

        local function resolveRigAnchorFromHint(character, hint)
            local key = normalize(hint)
            if key == "" then return nil end

            local exactAttachment = findCharacterObject(character, hint, "Attachment")
            if exactAttachment then return exactAttachment end
            local exactPart = findCharacterObject(character, hint, "BasePart")
            if exactPart then return exactPart end

            local function has(text)
                return key:find(text, 1, true) ~= nil
            end

            if has("righthand") or (has("right") and (has("hand") or has("palm") or has("grip"))) then
                return findCharacterPart(character, {"RightHand", "Right Arm", "RightLowerArm", "RightUpperArm"})
            end
            if has("lefthand") or (has("left") and (has("hand") or has("palm") or has("grip"))) then
                return findCharacterPart(character, {"LeftHand", "Left Arm", "LeftLowerArm", "LeftUpperArm"})
            end
            if has("rightarm") or (has("right") and has("arm")) then
                return findCharacterPart(character, {"RightLowerArm", "RightUpperArm", "Right Arm", "RightHand"})
            end
            if has("leftarm") or (has("left") and has("arm")) then
                return findCharacterPart(character, {"LeftLowerArm", "LeftUpperArm", "Left Arm", "LeftHand"})
            end
            if has("rightfoot") or (has("right") and (has("foot") or has("leg"))) then
                return findCharacterPart(character, {"RightFoot", "Right Leg", "RightLowerLeg", "RightUpperLeg"})
            end
            if has("leftfoot") or (has("left") and (has("foot") or has("leg"))) then
                return findCharacterPart(character, {"LeftFoot", "Left Leg", "LeftLowerLeg", "LeftUpperLeg"})
            end
            if has("head") or has("face") then
                return findCharacterPart(character, {"Head"})
            end
            if has("torso") or has("chest") or has("body") then
                return findCharacterPart(character, {"UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart"})
            end
            if has("root") or has("hrp") or has("waist") then
                return findCharacterPart(character, {"HumanoidRootPart", "LowerTorso", "Torso"})
            end
            return nil
        end

        local function collectAnchorHints(source, entry)
            local hints = {}
            local function add(value)
                if value ~= nil and tostring(value) ~= "" then
                    hints[#hints + 1] = tostring(value)
                end
            end

            add(getEntryAttribute(entry, {
                "IceHubAttachTo",
                "IceHubBindTo",
                "IceHubVFXAttach",
                "VFXAttachTo",
                "AttachTo",
                "TargetPart",
                "TargetAttachment",
                "AttachmentName",
            }))

            if typeof(source) == "Instance" then
                add(getInstanceAttribute(source, {
                    "IceHubAttachTo",
                    "IceHubBindTo",
                    "AttachTo",
                    "TargetPart",
                    "TargetAttachment",
                    "AttachmentName",
                }))
                add(source.Name)
                local scanned = 0
                for _, object in ipairs(source:GetDescendants()) do
                    if object:IsA("Attachment") or object:IsA("BasePart") or object:IsA("Bone") then
                        add(object.Name)
                        scanned += 1
                        if scanned >= 24 then break end
                    end
                end
            end

            return hints
        end

        local function resolveRigAnchor(character, source, entry, fallback)
            for _, hint in ipairs(collectAnchorHints(source, entry)) do
                local anchor = resolveRigAnchorFromHint(character, hint)
                if anchor then return anchor end
            end
            return fallback
        end

        local function getAnchorPart(anchor, fallback)
            if typeof(anchor) == "Instance" then
                if anchor:IsA("BasePart") then return anchor end
                if anchor:IsA("Attachment") and anchor.Parent and anchor.Parent:IsA("BasePart") then
                    return anchor.Parent
                end
            end
            return fallback
        end

        local function getAnchorCFrame(anchor, fallback)
            if typeof(anchor) == "Instance" then
                if anchor:IsA("BasePart") then return anchor.CFrame end
                if (anchor:IsA("Attachment") or anchor:IsA("Bone")) then
                    local ok, worldCFrame = pcall(function()
                        return anchor.WorldCFrame
                    end)
                    if ok and worldCFrame then return worldCFrame end
                end
            end
            return fallback and fallback.CFrame or CFrame.new()
        end

        local function getEmotesFolder()
            local misc = ReplicatedStorage:FindFirstChild("Misc")
            local emotes = misc and misc:FindFirstChild("Emotes")
            if emotes then return emotes end

            local shared = ReplicatedStorage:FindFirstChild("Shared")
            local replicatedInstances = ReplicatedStorage:FindFirstChild("ReplicatedInstances") or (shared and shared:FindFirstChild("ReplicatedInstances"))
            if replicatedInstances then
                emotes = replicatedInstances:FindFirstChild("Emotes")
                if emotes then return emotes end
            end
            return nil
        end

        local isEmoteVFXCache = {}
        local function isEmoteVFXRequest(instance)
            if typeof(instance) ~= "Instance" then return false end
            local cached = isEmoteVFXCache[instance]
            if cached ~= nil then return cached end

            local function compute()
                local nameKey = normalize(instance.Name)
                if nameKey == "getemotevfx" or nameKey == "getemoteeffect" then return true end
                local ok, fullName = pcall(function() return instance:GetFullName() end)
                if not ok then return false end
                local pathKey = normalize(fullName)
                if pathKey:find("replicatedinstancesemotevfx", 1, true) then return true end
                if pathKey:find("replicatedinstancesemotes", 1, true)
                    or pathKey:find("miscemotes", 1, true) then
                    return true
                end
                if pathKey:find("emote", 1, true) then
                    return true
                end
                return nameKey:find("emote", 1, true) ~= nil
            end
            
            local result = compute()
            isEmoteVFXCache[instance] = result
            return result
        end

        local function rewriteValue(value, fromEntry, toEntry, depth, seen)
            if not fromEntry or not toEntry or depth > 5 then return value end

            if type(value) == "string" then
                local key = normalize(value)
                if key == normalize(fromEntry.Name) then return toEntry.Name end
                if key == normalize(fromEntry.Id) then return toEntry.Id end
                if key == normalize(fromEntry.Animation.AnimationId) then
                    return toEntry.Animation.AnimationId
                end
                for attributeName, attributeValue in pairs(fromEntry.Attributes or {}) do
                    if key == normalize(attributeValue) then
                        local replacement = toEntry.Attributes
                            and toEntry.Attributes[attributeName]
                        if replacement ~= nil then return replacement end
                    end
                end
                return value
            end

            if type(value) == "number" then
                if tonumber(fromEntry.Id) and value == tonumber(fromEntry.Id) then
                    return tonumber(toEntry.Id) or value
                end
                local selectedAnimationId = tonumber(assetId(toEntry.Animation.AnimationId))
                if value == tonumber(assetId(fromEntry.Animation.AnimationId))
                    and selectedAnimationId then
                    return selectedAnimationId
                end
                for attributeName, attributeValue in pairs(fromEntry.Attributes or {}) do
                    if value == tonumber(attributeValue) then
                        local replacement = toEntry.Attributes
                            and tonumber(toEntry.Attributes[attributeName])
                        if replacement then return replacement end
                    end
                end
                return value
            end

            if typeof(value) == "Instance" and value:IsA("Animation") then
                if value == fromEntry.Animation
                    or normalize(value.Name) == normalize(fromEntry.Id)
                    or normalize(value.AnimationId) == normalize(fromEntry.Animation.AnimationId) then
                    return toEntry.Animation
                end
                return value
            end

            if type(value) ~= "table" then return value end
            seen = seen or {}
            if seen[value] then return seen[value] end

            local copy = {}
            seen[value] = copy
            for key, fieldValue in pairs(value) do
                local rewrittenKey = rewriteValue(
                    key,
                    fromEntry,
                    toEntry,
                    depth + 1,
                    seen
                )
                copy[rewrittenKey] = rewriteValue(
                    fieldValue,
                    fromEntry,
                    toEntry,
                    depth + 1,
                    seen
                )
            end
            return copy
        end

        local function getActiveOverride()
            local active = hooks.activeState
            if not active
                or active.destroyed
                or not active.activeOriginal
                or not active.activeSelected
                or os.clock() > active.overrideUntil then
                return nil
            end
            return active
        end

        local function installHooks()
            if hooks.animator
                or hooks.humanoid
                or hooks.clone
                or hooks.bindableFunction
                or hooks.bindableEvent
                or hooks.remoteEvent
                or hooks.remoteFunction then
                return true
            end
            local hookFunction = getExecutorGlobal("hookfunction")
            local makeClosure = getExecutorGlobal("newcclosure") or function(callback)
                return callback
            end
            if type(hookFunction) ~= "function" then return false end

            local function rewriteActiveArguments(...)
                local args = {...}
                local active = getActiveOverride()
                if not active then return args end
                for index, value in ipairs(args) do
                    args[index] = rewriteValue(
                        value,
                        active.activeOriginal,
                        active.activeSelected,
                        0,
                        {}
                    )
                end
                return args
            end

            local dummyBindableFunction = Instance.new("BindableFunction")
            local dummyBindableEvent = Instance.new("BindableEvent")
            local dummyRemoteEvent = Instance.new("RemoteEvent")
            local dummyRemoteFunction = Instance.new("RemoteFunction")
            local dummyAnimator = Instance.new("Animator")
            local dummyHumanoid = Instance.new("Humanoid")
            local dummyInstance = Instance.new("Folder")

            if not hooks.bindableFunction then
                local bindableFunctionOriginal
                hooks.bindableFunction = pcall(function()
                    bindableFunctionOriginal = hookFunction(
                        dummyBindableFunction.Invoke,
                        makeClosure(function(self, ...)
                            if not getgenv().emoteVFXEnabled then return bindableFunctionOriginal(self, ...) end
                            local active = getActiveOverride()
                            if active and isEmoteVFXRequest(self) then
                                local args = rewriteActiveArguments(...)
                                return bindableFunctionOriginal(self, unpack(args))
                            end
                            return bindableFunctionOriginal(self, ...)
                        end)
                    )
                end)
            end

            if not hooks.bindableEvent then
                local bindableEventOriginal
                hooks.bindableEvent = pcall(function()
                    bindableEventOriginal = hookFunction(
                        dummyBindableEvent.Fire,
                        makeClosure(function(self, ...)
                            if not getgenv().emoteVFXEnabled then return bindableEventOriginal(self, ...) end
                            local active = getActiveOverride()
                            if active and isEmoteVFXRequest(self) then
                                local args = rewriteActiveArguments(...)
                                return bindableEventOriginal(self, unpack(args))
                            end
                            return bindableEventOriginal(self, ...)
                        end)
                    )
                end)
            end

            if not hooks.remoteEvent then
                local remoteEventOriginal
                hooks.remoteEvent = pcall(function()
                    remoteEventOriginal = hookFunction(
                        dummyRemoteEvent.FireServer,
                        makeClosure(function(self, ...)
                            if not getgenv().emoteVFXEnabled then return remoteEventOriginal(self, ...) end
                            local active = getActiveOverride()
                            if active and isEmoteVFXRequest(self) then
                                local args = rewriteActiveArguments(...)
                                return remoteEventOriginal(self, unpack(args))
                            end
                            return remoteEventOriginal(self, ...)
                        end)
                    )
                end)
            end

            if not hooks.remoteFunction then
                local remoteFunctionOriginal
                hooks.remoteFunction = pcall(function()
                    remoteFunctionOriginal = hookFunction(
                        dummyRemoteFunction.InvokeServer,
                        makeClosure(function(self, ...)
                            if not getgenv().emoteVFXEnabled then return remoteFunctionOriginal(self, ...) end
                            local active = getActiveOverride()
                            if active and isEmoteVFXRequest(self) then
                                local args = rewriteActiveArguments(...)
                                return remoteFunctionOriginal(self, unpack(args))
                            end
                            return remoteFunctionOriginal(self, ...)
                        end)
                    )
                end)
            end

            local function resolveAnimation(owner, animation)
                local active = getActiveOverride()
                if not active
                    or typeof(animation) ~= "Instance"
                    or not animation:IsA("Animation") then
                    return animation
                end

                local character = LocalPlayer.Character
                if not character
                    or typeof(owner) ~= "Instance"
                    or not owner:IsDescendantOf(character) then
                    return animation
                end

                local original = active.activeOriginal
                if animation == original.Animation
                    or normalize(animation.Name) == normalize(original.Id)
                    or normalize(animation.AnimationId) == normalize(original.Animation.AnimationId) then
                    return active.activeSelected.Animation
                end
                return animation
            end

            local function resolveVFXCloneSource(source)
                local active = getActiveOverride()
                if not active
                    or typeof(source) ~= "Instance"
                    or type(state.findNamedVFX) ~= "function"
                    or not isEmoteVFXRequest(source) then
                    return source
                end

                local originalAliases = {
                    [normalize(active.activeOriginal.Name)] = true,
                    [normalize(active.activeOriginal.Id)] = true,
                    [normalize(active.activeOriginal.Animation.AnimationId)] = true,
                }
                for _, value in pairs(active.activeOriginal.Attributes or {}) do
                    originalAliases[normalize(tostring(value))] = true
                end

                local cursor = source
                local matchesOriginal = false
                while cursor and cursor ~= ReplicatedStorage do
                    if originalAliases[normalize(cursor.Name)] then
                        matchesOriginal = true
                        break
                    end
                    cursor = cursor.Parent
                end
                if not matchesOriginal then return source end

                local matches = state.findNamedVFX(active.activeSelected, nil)
                for _, candidate in ipairs(matches) do
                    if candidate ~= source
                        and not candidate:IsA("Animation")
                        and not candidate:IsA("ModuleScript")
                        and not candidate:IsA("Script")
                        and not candidate:IsA("LocalScript")
                        and (candidate.ClassName == source.ClassName or candidate:IsA(source.ClassName)) then
                        return candidate
                    end
                end
                return source
            end

            if not hooks.animator then
                local animatorOriginal
                hooks.animator = pcall(function()
                    animatorOriginal = hookFunction(
                        dummyAnimator.LoadAnimation,
                        makeClosure(function(self, animation, ...)
                            return animatorOriginal(self, resolveAnimation(self, animation), ...)
                        end)
                    )
                end)
            end

            if not hooks.humanoid then
                local humanoidOriginal
                hooks.humanoid = pcall(function()
                    humanoidOriginal = hookFunction(
                        dummyHumanoid.LoadAnimation,
                        makeClosure(function(self, animation, ...)
                            return humanoidOriginal(self, resolveAnimation(self, animation), ...)
                        end)
                    )
                end)
            end

            if not hooks.clone then
                local cloneOriginal
                hooks.clone = pcall(function()
                    cloneOriginal = hookFunction(
                        dummyInstance.Clone,
                        makeClosure(function(self, ...)
                            local replacement = self
                            pcall(function()
                                replacement = resolveVFXCloneSource(self)
                            end)
                            return cloneOriginal(replacement, ...)
                        end)
                    )
                end)
            end

            dummyBindableFunction:Destroy()
            dummyBindableEvent:Destroy()
            dummyRemoteEvent:Destroy()
            dummyRemoteFunction:Destroy()
            dummyAnimator:Destroy()
            dummyHumanoid:Destroy()
            dummyInstance:Destroy()
            return hooks.animator
                or hooks.humanoid
                or hooks.clone
                or hooks.bindableFunction
                or hooks.bindableEvent
                or hooks.remoteEvent
                or hooks.remoteFunction
        end

        local function refreshCatalog()
            table.clear(state.catalog)
            table.clear(state.byName)
            table.clear(state.namedVFXCache)
            table.clear(state.emoteAccessoryCache)
            table.clear(state.entrySoundCache)
            table.clear(state.vfxPayloadCache)
            state.vfxRootCache = nil
            state.vfxRootCacheAt = 0

            local folder = getEmotesFolder()
            if folder then
                for _, object in ipairs(folder:GetDescendants()) do
                    if object:IsA("Animation") then
                        local name = object:GetAttribute("EmoteName") or object.Name
                        if type(name) == "string" and name ~= "" and not state.byName[name] then
                            local entry = {
                                Name = name,
                                Id = object.Name,
                                Animation = object,
                                Attributes = object:GetAttributes(),
                            }
                            state.catalog[#state.catalog + 1] = entry
                            state.byName[name] = entry
                        end
                    end
                end
            end

            table.sort(state.catalog, function(left, right)
                return left.Name:lower() < right.Name:lower()
            end)

            local names = {}
            for _, entry in ipairs(state.catalog) do
                names[#names + 1] = entry.Name
            end
            getgenv().emoteNames = names
            state.catalogSignature = table.concat(names, "|")

            if #names > 0 and not state.byName[getgenv().selectedEmote] then
                getgenv().selectedEmote = names[1]
            end
            if state.emoteWheelEnabled and state.applyEmoteWheelList then task.defer(state.applyEmoteWheelList) end
            return names
        end

        local function resolveEntry(value)
            if not value then return nil end
            if state.byName[value] then return state.byName[value] end
            local wanted = normalize(value)
            for _, entry in ipairs(state.catalog) do
                if normalize(entry.Name) == wanted
                    or normalize(entry.Id) == wanted
                    or normalize(entry.Animation.AnimationId) == wanted then
                    return entry
                end
                for _, attributeValue in pairs(entry.Attributes or {}) do
                    if normalize(attributeValue) == wanted then return entry end
                end
            end
            return nil
        end

        local function sameEntry(left, right)
            if not left or not right then return false end
            if left == right then return true end
            return normalize(left.Name) == normalize(right.Name)
                or normalize(left.Id) == normalize(right.Id)
                or assetId(left.Animation and left.Animation.AnimationId) == assetId(right.Animation and right.Animation.AnimationId)
        end

        local cachedContents = nil
        local function getAllWheelContents()
            if cachedContents then
                local valid = true
                for _, c in ipairs(cachedContents) do
                    if not c or not c.Parent then valid = false; break end
                end
                if valid and #cachedContents > 0 then return cachedContents end
            end
            local contents = {}
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                for _, wheel in ipairs(playerGui:GetDescendants()) do
                    if wheel.Name == "EmoteWheel" then
                        local list = wheel:FindFirstChild("List", true)
                        local content = list and list:FindFirstChild("Content", true)
                        if content and not table.find(contents, content) then
                            contents[#contents + 1] = content
                        end
                    end
                end
            end
            cachedContents = contents
            return contents
        end

        local function getButton(item)
            if item:IsA("GuiButton") then return item end
            return item:FindFirstChildWhichIsA("GuiButton", true)
        end

        do
        local function createUICorner(parent, radius)
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, radius)
            corner.Parent = parent
            return corner
        end

        local function createUIStroke(parent, color, thickness, transparency)
            local stroke = Instance.new("UIStroke")
            stroke.Color = color
            stroke.Thickness = thickness or 1
            stroke.Transparency = transparency or 0
            stroke.Parent = parent
            return stroke
        end

        local function getEntryImage(entry)
            local image = getEntryAttribute(entry, {
                "Icon",
                "Image",
                "ImageId",
                "Thumbnail",
                "ThumbnailId",
                "EmoteIcon",
                "EmoteImage",
            })
            if not image then return nil end
            local text = tostring(image)
            if text:find("rbxassetid://", 1, true) then return text end
            local id = assetId(text)
            return id and ("rbxassetid://" .. id) or nil
        end

        local function fitText(label, minSize, maxSize)
            label.TextScaled = true
            local limit = Instance.new("UITextSizeConstraint")
            limit.MinTextSize = minSize or 9
            limit.MaxTextSize = maxSize or 18
            limit.Parent = label
        end

        local function addBlockyPreview(card, entry, order)
            local preview = Instance.new("Frame")
            preview.BackgroundTransparency = 1
            preview.Position = UDim2.fromScale(0.08, 0.06)
            preview.Size = UDim2.fromScale(0.84, 0.62)
            preview.ClipsDescendants = false
            preview.Parent = card

            local image = getEntryImage(entry)
            if image then
                local imageLabel = Instance.new("ImageLabel")
                imageLabel.BackgroundTransparency = 1
                imageLabel.Image = image
                imageLabel.ScaleType = Enum.ScaleType.Fit
                imageLabel.Size = UDim2.fromScale(1, 1)
                imageLabel.Parent = preview
                return
            end

            local pose = (order % 5) + 1
            local function part(name, color, pos, size, rotation, zIndex)
                local frame = Instance.new("Frame")
                frame.Name = name
                frame.BackgroundColor3 = color
                frame.BorderSizePixel = 0
                frame.Position = pos
                frame.Size = size
                frame.Rotation = rotation or 0
                frame.ZIndex = zIndex or 2
                frame.Parent = preview
                createUICorner(frame, 4)
                return frame
            end

            local yellow = Color3.fromRGB(245, 205, 48)
            local blue = Color3.fromRGB(13, 105, 172)
            local green = Color3.fromRGB(75, 175, 75)

            part("LeftLeg", green, UDim2.fromScale(0.34, 0.62), UDim2.fromScale(0.18, 0.30), pose == 2 and -24 or 13, 1)
            part("RightLeg", green, UDim2.fromScale(0.50, 0.62), UDim2.fromScale(0.18, 0.30), pose == 3 and 28 or -10, 1)
            part("Body", blue, UDim2.fromScale(0.37, 0.32), UDim2.fromScale(0.31, 0.38), pose == 4 and -13 or 8, 3)
            part("Head", yellow, UDim2.fromScale(0.46, 0.12), UDim2.fromScale(0.20, 0.20), pose == 5 and 12 or 0, 4)
            part("LeftArm", yellow, UDim2.fromScale(0.14, 0.32), UDim2.fromScale(0.30, 0.16), pose == 1 and -34 or -18, 3)
            part("RightArm", yellow, UDim2.fromScale(0.62, 0.34), UDim2.fromScale(0.30, 0.16), pose == 2 and 38 or 22, 3)
        end

        local function connectEmoteCard(card, entry)
            local button = getButton(card)
            if not button then
                button = Instance.new("TextButton")
                button.Name = "IceHubEmoteHitbox"
                button.BackgroundTransparency = 1
                button.Text = ""
                button.Size = UDim2.fromScale(1, 1)
                button.ZIndex = 100
                button.Parent = card
            end
            button.Activated:Connect(function()
                getgenv().selectedEmote = entry.Name
                task.defer(function()
                    if type(getgenv().playEmote) == "function" then
                        getgenv().playEmote(entry.Name)
                    end
                end)
            end)
        end

        local function makeEmoteWheelCard(content, entry, order)
            local card = Instance.new("TextButton")
            card.Name = "IceHubEmote_" .. tostring(order)
            card:SetAttribute("IceHubEmoteCard", true)
            card:SetAttribute("EmoteName", entry.Name)
            card:SetAttribute("AnimationId", entry.Animation.AnimationId)
            card.LayoutOrder = order
            card.AutoButtonColor = false
            card.Text = ""
            card.BackgroundColor3 = Color3.fromRGB(16, 24, 55)
            card.BackgroundTransparency = 0
            card.BorderSizePixel = 0
            card.ClipsDescendants = true
            card.Parent = content
            createUICorner(card, 12)

            addBlockyPreview(card, entry, order)

            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 1
            nameLabel.Position = UDim2.fromScale(0.04, 0.64)
            nameLabel.Size = UDim2.fromScale(0.92, 0.33)
            nameLabel.Font = Enum.Font.FredokaOne
            nameLabel.Text = entry.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeTransparency = 1
            nameLabel.TextWrapped = true
            nameLabel.ZIndex = 5
            nameLabel.Parent = card
            fitText(nameLabel, 10, 18)

            local textStroke = Instance.new("UIStroke")
            textStroke.Color = Color3.fromRGB(12, 18, 40)
            textStroke.Thickness = 3
            textStroke.Transparency = 0
            textStroke.Parent = nameLabel

            local starBtn = Instance.new("TextButton")
            starBtn.Name = "FavoriteStar"
            starBtn.BackgroundTransparency = 1
            starBtn.Position = UDim2.new(1, -28, 0, 4)
            starBtn.Size = UDim2.new(0, 24, 0, 24)
            starBtn.Font = Enum.Font.GothamBold
            starBtn.TextSize = 22
            starBtn.TextStrokeTransparency = 0
            starBtn.ZIndex = 10
            starBtn.Parent = card

            local function updateStar()
                if state.favorites[entry.Name] then
                    starBtn.Text = "★"
                    starBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
                else
                    starBtn.Text = "☆"
                    starBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
            end
            updateStar()

            starBtn.MouseButton1Click:Connect(function()
                if state.favorites[entry.Name] then
                    state.favorites[entry.Name] = nil
                else
                    local count = 0
                    for k in pairs(state.favorites) do count = count + 1 end
                    if count < 8 then
                        state.favorites[entry.Name] = true
                    else
                        if WindUI and WindUI.Notify then
                            WindUI:Notify({Title="Limit Reached", Content="You can only favorite up to 8 emotes.", Duration=2})
                        end
                    end
                end
                updateStar()
                saveEmoteFavorites(state.favorites)
                if state.updateCustomWheel then state.updateCustomWheel() end
            end)

            card.MouseEnter:Connect(function()
                pcall(function()
                    card.BackgroundTransparency = 0
                    card.BackgroundColor3 = Color3.fromRGB(26, 38, 85)
                end)
            end)
            card.MouseLeave:Connect(function()
                pcall(function()
                    card.BackgroundTransparency = 0
                    card.BackgroundColor3 = Color3.fromRGB(16, 24, 55)
                end)
            end)
            connectEmoteCard(card, entry)
        end

        local function entryFromWheelItem(item)
            local candidates = {
                item:GetAttribute("EmoteName"),
                item:GetAttribute("AnimationId"),
                item.Name,
            }
            for _, object in ipairs(item:GetDescendants()) do
                if object:IsA("TextLabel") or object:IsA("TextButton") then
                    candidates[#candidates + 1] = object.Text
                elseif object:IsA("Animation") then
                    candidates[#candidates + 1] = object.Name
                    candidates[#candidates + 1] = object.AnimationId
                end
                for key, value in pairs(object:GetAttributes()) do
                    local lowered = tostring(key):lower()
                    if lowered:find("emote", 1, true)
                        or lowered:find("animation", 1, true)
                        or lowered == "id"
                        or lowered == "name" then
                        candidates[#candidates + 1] = value
                    end
                end
            end
            for _, candidate in ipairs(candidates) do
                local entry = resolveEntry(candidate)
                if entry then return entry end
            end
            return nil
        end

        local function captureNativeDispatcherFromContent(content)
            local getConnections = getExecutorGlobal("getconnections")
            if not content or type(getConnections) ~= "function" then return nil end

            local scanLimit = 0
            for _, item in ipairs(content:GetChildren()) do
                if item:IsA("GuiObject") and not item:GetAttribute("IceHubEmoteCard") then
                    scanLimit += 1
                    if scanLimit > 6 then break end

                    local button = getButton(item)
                    if button then
                        for _, signal in ipairs({button.Activated, button.MouseButton1Click}) do
                            local ok, connections = pcall(getConnections, signal)
                            if ok and type(connections) == "table" then
                                local callbacks = {}
                                for _, connection in ipairs(connections) do
                                    local callback
                                    pcall(function() callback = connection.Function end)
                                    if type(callback) == "function"
                                        and not (isourclosure and isourclosure(callback)) then
                                        callbacks[#callbacks + 1] = callback
                                    end
                                end
                                if #callbacks > 0 then
                                    local original = entryFromWheelItem(item)
                                    if original then
                                        state.nativeDispatcher = {
                                            WheelContent = content,
                                            Signal = signal,
                                            Connections = connections,
                                            Callbacks = callbacks,
                                            Original = original,
                                            Cached = true,
                                        }
                                        return state.nativeDispatcher
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return nil
        end

        local function preserveNativeWheelItems(content)
            state.contentAddedConns = state.contentAddedConns or {}
            local function checkAndDestroy(child)
                if child:IsA("UIComponent") then return end
                if child:GetAttribute("IceHubEmoteCard") then return end
                pcall(function()
                    if child:IsA("GuiObject") then child.Visible = false end
                    child:Destroy()
                end)
            end

            for _, child in ipairs(content:GetChildren()) do
                checkAndDestroy(child)
            end
            if state.nativeWheelCache then
                pcall(function() state.nativeWheelCache:Destroy() end)
                state.nativeWheelCache = nil
            end
            if state.contentAddedConns[content] then
                pcall(function() state.contentAddedConns[content]:Disconnect() end)
                state.contentAddedConns[content] = nil
            end
            pcall(function()
                state.contentAddedConns[content] = content.ChildAdded:Connect(function(child)
                    task.defer(checkAndDestroy, child)
                end)
            end)

            pcall(function()
                local list = content.Parent
                if list then
                    for _, child in ipairs(list:GetChildren()) do
                        if child ~= content and child:IsA("GuiObject") then
                            local isCard = child:GetAttribute("EmoteName")
                                        or child:GetAttribute("AnimationId")
                                        or child.Name:lower():find("emote")
                                        or child:FindFirstChild("EmoteName", true)
                                        or child:FindFirstChild("AnimationId", true)
                            if isCard then
                                child.Visible = false
                                child:Destroy()
                            end
                        end
                    end
                end
            end)
        end

        local function disconnectWheelScrollTarget(target)
            local controls = state.wheelScrollControls and state.wheelScrollControls[target]
            if controls then
                for _, control in ipairs(controls) do
                    if control and control.Parent then
                        pcall(function() control:Destroy() end)
                    end
                end
                state.wheelScrollControls[target] = nil
            end

            local connections = state.wheelScrollConnections and state.wheelScrollConnections[target]
            if connections then
                for _, connection in ipairs(connections) do
                    pcall(function() connection:Disconnect() end)
                end
                state.wheelScrollConnections[target] = nil
            end
        end

        local function getWheelScrollFrame(content)
            if not content then return nil end
            if content:IsA("ScrollingFrame") then return content end

            local current = content.Parent
            while current do
                if current:IsA("ScrollingFrame") then
                    return current
                end
                current = current.Parent
            end
            return nil
        end

        local function installWheelScrollBar(content)
            local scrollFrame = getWheelScrollFrame(content)
            if not scrollFrame then return end

            local existing = state.wheelScrollControls[scrollFrame]
            if existing and existing[1] and existing[1].Parent then return end

            disconnectWheelScrollTarget(scrollFrame)

            local host = scrollFrame.Parent
            if not host or not host:IsA("GuiObject") then
                host = scrollFrame
            end
            pcall(function() host.ClipsDescendants = false end)

            local hitbox = Instance.new("TextButton")
            hitbox.Name = "IceHubWheelScrollBar"
            hitbox.AnchorPoint = Vector2.new(1, 0.5)
            hitbox.Position = UDim2.new(1, -4, 0.5, 0)
            hitbox.Size = UDim2.new(0, 24, 1, -22)
            hitbox.BackgroundTransparency = 1
            hitbox.BorderSizePixel = 0
            hitbox.AutoButtonColor = false
            hitbox.Text = ""
            hitbox.ZIndex = 260
            hitbox.Parent = host

            local thumb = Instance.new("Frame")
            thumb.Name = "Thumb"
            thumb.AnchorPoint = Vector2.new(0.5, 0)
            thumb.Position = UDim2.new(0.5, 0, 0, 0)
            thumb.Size = UDim2.fromOffset(8, 76)
            thumb.BackgroundColor3 = Color3.fromRGB(36, 38, 48)
            thumb.BackgroundTransparency = 0
            thumb.BorderSizePixel = 0
            thumb.ZIndex = 261
            thumb.Parent = hitbox
            createUICorner(thumb, 8)
            createUIStroke(thumb, Color3.fromRGB(245, 246, 255), 1, 0.72)

            local dragging = false

            local function getMetrics()
                local canvas = scrollFrame.AbsoluteCanvasSize
                local window = scrollFrame.AbsoluteWindowSize
                local maxX = math.max(canvas.X - window.X, 0)
                local maxY = math.max(canvas.Y - window.Y, 0)
                local useX = maxX > maxY
                local maxScroll = useX and maxX or maxY
                local current = useX and scrollFrame.CanvasPosition.X or scrollFrame.CanvasPosition.Y
                return useX, maxScroll, current
            end

            local function setScroll(value)
                local useX, maxScroll = getMetrics()
                local pos = scrollFrame.CanvasPosition
                value = math.clamp(value, 0, maxScroll)
                if useX then
                    scrollFrame.CanvasPosition = Vector2.new(value, pos.Y)
                else
                    scrollFrame.CanvasPosition = Vector2.new(pos.X, value)
                end
            end

            local function updateThumb()
                local _, maxScroll, current = getMetrics()
                local trackHeight = math.max(hitbox.AbsoluteSize.Y, 1)
                local visibleRatio = 1
                pcall(function()
                    local canvas = scrollFrame.AbsoluteCanvasSize
                    local window = scrollFrame.AbsoluteWindowSize
                    visibleRatio = math.clamp(window.Y / math.max(canvas.Y, 1), 0.16, 1)
                end)

                local thumbHeight = math.clamp(trackHeight * visibleRatio, 42, trackHeight)
                local travel = math.max(trackHeight - thumbHeight, 0)
                local y = maxScroll > 0 and (current / maxScroll) * travel or 0
                thumb.Size = UDim2.fromOffset(8, thumbHeight)
                thumb.Position = UDim2.new(0.5, 0, 0, y)
                thumb.Visible = maxScroll > 1
            end

            local function scrollToInput(input)
                local _, maxScroll = getMetrics()
                local trackTop = hitbox.AbsolutePosition.Y
                local trackHeight = math.max(hitbox.AbsoluteSize.Y, 1)
                local thumbHeight = thumb.AbsoluteSize.Y
                local travel = math.max(trackHeight - thumbHeight, 1)
                local relativeY = math.clamp(input.Position.Y - trackTop - (thumbHeight * 0.5), 0, travel)
                setScroll((relativeY / travel) * maxScroll)
                updateThumb()
            end

            local connections = {}
            connections[#connections + 1] = hitbox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    thumb.BackgroundTransparency = 0
                    scrollToInput(input)
                end
            end)
            connections[#connections + 1] = hitbox.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    thumb.BackgroundTransparency = 0
                end
            end)
            connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    scrollToInput(input)
                end
            end)
            connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    thumb.BackgroundTransparency = 0
                end
            end)
            connections[#connections + 1] = scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateThumb)
            connections[#connections + 1] = scrollFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateThumb)
            connections[#connections + 1] = scrollFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateThumb)
            connections[#connections + 1] = hitbox:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateThumb)
            connections[#connections + 1] = scrollFrame.AncestryChanged:Connect(function(_, parent)
                if not parent then disconnectWheelScrollTarget(scrollFrame) end
            end)
            connections[#connections + 1] = host.AncestryChanged:Connect(function(_, parent)
                if not parent then disconnectWheelScrollTarget(scrollFrame) end
            end)

            task.defer(updateThumb)

            state.wheelScrollControls[scrollFrame] = {hitbox}
            state.wheelScrollConnections[scrollFrame] = connections
        end

        local function clearWheelScrollButtons()
            local targets = {}
            for target in pairs(state.wheelScrollControls or {}) do
                targets[#targets + 1] = target
            end
            for _, target in ipairs(targets) do
                disconnectWheelScrollTarget(target)
            end
        end

        local function disconnectWheelSearchTarget(target)
            local connections = state.wheelSearchConnections and state.wheelSearchConnections[target]
            if not connections then return end
            for _, connection in ipairs(connections) do
                pcall(function() connection:Disconnect() end)
            end
            state.wheelSearchConnections[target] = nil
        end

        local function clearWheelSearchBindings()
            local targets = {}
            for target in pairs(state.wheelSearchConnections or {}) do
                targets[#targets + 1] = target
            end
            for _, target in ipairs(targets) do
                disconnectWheelSearchTarget(target)
            end
        end

        local function getWheelSearchRoot(content)
            local current = content
            while current do
                if current.Name == "EmoteWheel" then
                    return current
                end
                current = current.Parent
            end
            local parent = content and content.Parent
            return parent and parent.Parent or parent or content
        end

        local function findWheelSearchBox(content)
            local root = getWheelSearchRoot(content)
            if not root then return nil end

            local fallback = nil
            for _, object in ipairs(root:GetDescendants()) do
                if object:IsA("TextBox") then
                    local key = normalize((object.Name or "") .. " " .. (object.PlaceholderText or ""))
                    if key:find("search", 1, true) or key:find("ara", 1, true) then
                        return object
                    end
                    fallback = fallback or object
                end
            end
            return fallback
        end

        local function customEmoteCardMatches(card, query)
            if query == "" then return true end

            local candidates = {
                card:GetAttribute("EmoteName"),
                card:GetAttribute("AnimationId"),
                card.Name,
            }
            local entry = resolveEntry(card:GetAttribute("EmoteName"))
                or resolveEntry(card:GetAttribute("AnimationId"))
            if entry then
                candidates[#candidates + 1] = entry.Name
                candidates[#candidates + 1] = entry.DisplayName
                candidates[#candidates + 1] = entry.Animation and entry.Animation.AnimationId
            end

            for _, object in ipairs(card:GetDescendants()) do
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                    candidates[#candidates + 1] = object.Text
                elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
                    candidates[#candidates + 1] = object.Image
                elseif object:IsA("Animation") then
                    candidates[#candidates + 1] = object.Name
                    candidates[#candidates + 1] = object.AnimationId
                end
                for key, value in pairs(object:GetAttributes()) do
                    local lowered = normalize(key)
                    if lowered:find("emote", 1, true)
                        or lowered:find("animation", 1, true)
                        or lowered == "id"
                        or lowered == "name" then
                        candidates[#candidates + 1] = value
                    end
                end
            end

            for _, candidate in ipairs(candidates) do
                local key = normalize(candidate)
                if key ~= "" and key:find(query, 1, true) then
                    return true
                end
            end
            return false
        end

        local function applyCustomWheelSearch(content, searchText)
            local query = normalize(searchText)
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("GuiObject") and child:GetAttribute("IceHubEmoteCard") then
                    child.Visible = customEmoteCardMatches(child, query)
                end
            end
        end

        local function bindCustomWheelSearch(content)
            if not content then return end
            disconnectWheelSearchTarget(content)

            local searchBox = findWheelSearchBox(content)
            local connections = {}
            local function refresh()
                if not content.Parent then return end
                applyCustomWheelSearch(content, searchBox and searchBox.Text or "")
            end

            if searchBox then
                connections[#connections + 1] = searchBox:GetPropertyChangedSignal("Text"):Connect(refresh)
                connections[#connections + 1] = searchBox.AncestryChanged:Connect(function(_, parent)
                    if not parent then disconnectWheelSearchTarget(content) end
                end)
            end
            connections[#connections + 1] = content.ChildAdded:Connect(function(child)
                if child:IsA("GuiObject") and child:GetAttribute("IceHubEmoteCard") then
                    task.defer(refresh)
                end
            end)
            connections[#connections + 1] = content.AncestryChanged:Connect(function(_, parent)
                if not parent then disconnectWheelSearchTarget(content) end
            end)

            state.wheelSearchConnections[content] = connections
            task.defer(refresh)
        end

        state.applyEmoteWheelList = function()
            if state.destroyed or state.applyingEmoteWheel then return false end
            local contents = getAllWheelContents()
            if #contents == 0 then return false end

            state.applyingEmoteWheel = true
            local ok, err = pcall(function()
                for _, content in ipairs(contents) do
                    installWheelScrollBar(content)
                    bindCustomWheelSearch(content)
                    local alreadyCurrent = false
                    pcall(function()
                        if content:GetAttribute("IceHubCatalogSignature") == state.catalogSignature then
                            local cardCount = 0
                            for _, child in ipairs(content:GetChildren()) do
                                if child:IsA("GuiObject") and child:GetAttribute("IceHubEmoteCard") then
                                    cardCount += 1
                                end
                            end
                            alreadyCurrent = cardCount >= #state.catalog
                        end
                    end)
                    if alreadyCurrent then continue end

                    if not state.nativeDispatcher then
                        captureNativeDispatcherFromContent(content)
                    end
                    pcall(function()
                        local wheelFrame = content.Parent and content.Parent.Parent
                        if wheelFrame and wheelFrame.Name == "EmoteWheel" and not wheelFrame:FindFirstChild("IceHubEHint") then
                            local eHint = Instance.new("TextLabel")
                            eHint.Name = "IceHubEHint"
                            eHint.BackgroundTransparency = 1
                            eHint.Position = UDim2.new(0.5, -150, 0, -25)
                            eHint.Size = UDim2.new(0, 300, 0, 20)
                            eHint.Font = Enum.Font.GothamBold
                            eHint.Text = "★ Custom Emote Wheel: Press [ E ]"
                            eHint.TextColor3 = Color3.fromRGB(255, 215, 0)
                            eHint.TextSize = 16
                            eHint.TextStrokeTransparency = 0
                            eHint.ZIndex = 100
                            eHint.Parent = wheelFrame
                        end
                    end)

                    preserveNativeWheelItems(content)

                    for _, child in ipairs(content:GetChildren()) do
                        if child:IsA("GuiObject") and child:GetAttribute("IceHubEmoteCard") then
                            pcall(function() child:Destroy() end)
                        end
                    end

                    local grid = content:FindFirstChildOfClass("UIGridLayout")
                    if not grid then
                        grid = Instance.new("UIGridLayout")
                        grid.Parent = content
                    end
                    grid.CellSize = UDim2.fromOffset(118, 118)
                    grid.CellPadding = UDim2.fromOffset(8, 8)
                    grid.SortOrder = Enum.SortOrder.LayoutOrder
                    grid.FillDirection = Enum.FillDirection.Horizontal
                    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center

                    local padding = content:FindFirstChildOfClass("UIPadding")
                    if not padding then
                        padding = Instance.new("UIPadding")
                        padding.Parent = content
                    end
                    padding.PaddingTop = UDim.new(0, 8)
                    padding.PaddingBottom = UDim.new(0, 8)
                    padding.PaddingLeft = UDim.new(0, 8)
                    padding.PaddingRight = UDim.new(0, 8)

                    pcall(function()
                        content.BackgroundColor3 = Color3.fromRGB(37, 68, 155)
                        content.BackgroundTransparency = 1
                        content.BorderSizePixel = 0
                    end)

                    if content:IsA("ScrollingFrame") then
                        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
                        content.CanvasSize = UDim2.fromScale(0, 0)
                        content.ScrollBarThickness = 0
                    end

                    for index, entry in ipairs(state.catalog) do
                        makeEmoteWheelCard(content, entry, index)
                        if index % 24 == 0 then task.wait() end
                    end
                    pcall(function()
                        content:SetAttribute("IceHubCatalogSignature", state.catalogSignature)
                    end)
                end
            end)
            state.applyingEmoteWheel = false
            if not ok then
                warn("IceHub EmoteWheel install failed:", err)
                return false
            end
            return true
        end

        state.buildCustomWheel = function()
            if state.customWheelGui then
                pcall(function() state.customWheelGui:Destroy() end)
                state.customWheelGui = nil
            end
            if state.customWheelConn then
                pcall(function() state.customWheelConn:Disconnect() end)
                state.customWheelConn = nil
            end
            if state.customWheelButtonGui then
                pcall(function() state.customWheelButtonGui:Destroy() end)
                state.customWheelButtonGui = nil
            end

            local UserInputService = game:GetService("UserInputService")
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "IceHubCustomRadialWheel"
            screenGui.Enabled = false
            screenGui.IgnoreGuiInset = true
            screenGui.DisplayOrder = 1000
            screenGui.Parent = game.CoreGui or LocalPlayer:FindFirstChildOfClass("PlayerGui")
            state.customWheelGui = screenGui

            local overlay = Instance.new("Frame")
            overlay.Name = "Overlay"
            overlay.Size = UDim2.fromScale(1, 1)
            overlay.BackgroundColor3 = Color3.fromRGB(5, 7, 12)
            overlay.BackgroundTransparency = 0.4
            overlay.BorderSizePixel = 0
            overlay.Parent = screenGui

            local center = Instance.new("Frame")
            center.Name = "CenterAnchor"
            center.BackgroundTransparency = 1
            center.Position = UDim2.fromScale(0.5, 0.5)
            center.Size = UDim2.fromOffset(0, 0)
            center.Parent = overlay

            local closeBtn = Instance.new("TextButton")
            closeBtn.Name = "CloseButton"
            closeBtn.Size = UDim2.fromOffset(50, 50)
            closeBtn.Position = UDim2.fromOffset(-25, -25)
            closeBtn.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
            closeBtn.BackgroundTransparency = 0.2
            closeBtn.Text = "X"
            closeBtn.Font = Enum.Font.GothamBlack
            closeBtn.TextSize = 22
            closeBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
            closeBtn.Parent = center
            createUICorner(closeBtn, 25)
            createUIStroke(closeBtn, Color3.fromRGB(255, 255, 255), 1, 0.85)

            local eHintCenter = Instance.new("TextLabel")
            eHintCenter.Name = "EHint"
            eHintCenter.BackgroundTransparency = 1
            eHintCenter.Position = UDim2.fromOffset(-50, 35)
            eHintCenter.Size = UDim2.fromOffset(100, 20)
            eHintCenter.Font = Enum.Font.GothamBold
            eHintCenter.Text = "[ E ] to close"
            eHintCenter.TextColor3 = Color3.fromRGB(255, 255, 255)
            eHintCenter.TextStrokeTransparency = 0
            eHintCenter.TextSize = 12
            eHintCenter.Parent = center

            closeBtn.MouseEnter:Connect(function()
                pcall(function()
                    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
                    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end)
            end)
            closeBtn.MouseLeave:Connect(function()
                pcall(function()
                    closeBtn.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
                    closeBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
                end)
            end)

            closeBtn.Activated:Connect(function()
                screenGui.Enabled = false
            end)

            if UserInputService.TouchEnabled then
                local buttonGui = Instance.new("ScreenGui")
                buttonGui.Name = "IceHubEmoteMobileButton"
                buttonGui.Enabled = true
                buttonGui.IgnoreGuiInset = true
                buttonGui.ResetOnSpawn = false
                buttonGui.DisplayOrder = 1001
                buttonGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
                buttonGui.Parent = game.CoreGui or LocalPlayer:FindFirstChildOfClass("PlayerGui")
                state.customWheelButtonGui = buttonGui

                local button = Instance.new("TextButton")
                button.Name = "OpenFavorites"
                button.AnchorPoint = Vector2.new(1, 0.5)
                button.Position = UDim2.new(1, -18, 0.5, 72)
                button.Size = UDim2.fromOffset(62, 62)
                button.BackgroundColor3 = Color3.fromRGB(9, 11, 18)
                button.BackgroundTransparency = 0
                button.BorderSizePixel = 0
                button.AutoButtonColor = false
                button.Text = ""
                button.Parent = buttonGui
                createUICorner(button, 31)
                createUIStroke(button, Color3.fromRGB(112, 119, 255), 1.6, 0.04)

                local shadow = Instance.new("ImageLabel")
                shadow.Position = UDim2.fromOffset(-14, -14)
                shadow.Size = UDim2.new(1, 28, 1, 28)
                shadow.BackgroundTransparency = 1
                shadow.Image = "rbxassetid://6014261993"
                shadow.ImageColor3 = Color3.new(0, 0, 0)
                shadow.ImageTransparency = 0.22
                shadow.ScaleType = Enum.ScaleType.Slice
                shadow.SliceCenter = Rect.new(49, 49, 450, 450)
                shadow.ZIndex = 0
                shadow.Parent = button

                local ring = Instance.new("Frame")
                ring.AnchorPoint = Vector2.new(0.5, 0.5)
                ring.Position = UDim2.fromScale(0.5, 0.5)
                ring.Size = UDim2.fromOffset(46, 46)
                ring.BackgroundColor3 = Color3.fromRGB(22, 25, 39)
                ring.BorderSizePixel = 0
                ring.Parent = button
                createUICorner(ring, 23)

                local ringStroke = Instance.new("UIStroke")
                ringStroke.Color = Color3.fromRGB(71, 79, 238)
                ringStroke.Thickness = 1
                ringStroke.Transparency = 0.35
                ringStroke.Parent = ring

                local icon = Instance.new("TextLabel")
                icon.BackgroundTransparency = 1
                icon.Size = UDim2.fromScale(1, 1)
                icon.Font = Enum.Font.GothamBlack
                icon.Text = "★"
                icon.TextColor3 = Color3.fromRGB(255, 215, 88)
                icon.TextSize = 24
                icon.Parent = ring

                local keyBadge = Instance.new("TextLabel")
                keyBadge.AnchorPoint = Vector2.new(1, 1)
                keyBadge.Position = UDim2.new(1, 1, 1, 1)
                keyBadge.Size = UDim2.fromOffset(22, 18)
                keyBadge.BackgroundColor3 = Color3.fromRGB(71, 79, 238)
                keyBadge.BorderSizePixel = 0
                keyBadge.Font = Enum.Font.GothamBlack
                keyBadge.Text = "E"
                keyBadge.TextColor3 = Color3.fromRGB(245, 246, 255)
                keyBadge.TextSize = 10
                keyBadge.Parent = button
                createUICorner(keyBadge, 8)

                local sub = Instance.new("TextLabel")
                sub.AnchorPoint = Vector2.new(0.5, 0)
                sub.BackgroundColor3 = Color3.fromRGB(9, 11, 18)
                sub.BackgroundTransparency = 0.08
                sub.BorderSizePixel = 0
                sub.Position = UDim2.new(0.5, 0, 1, 6)
                sub.Size = UDim2.fromOffset(76, 19)
                sub.Font = Enum.Font.GothamBold
                sub.Text = "FAVORITES"
                sub.TextColor3 = Color3.fromRGB(191, 194, 210)
                sub.TextSize = 8
                sub.Parent = button
                createUICorner(sub, 9)

                button.Activated:Connect(function()
                    screenGui.Enabled = not screenGui.Enabled
                    if screenGui.Enabled and state.updateCustomWheel then
                        state.updateCustomWheel()
                    end
                end)
                button.MouseEnter:Connect(function()
                    pcall(function()
                        button.BackgroundColor3 = Color3.fromRGB(17, 20, 32)
                        ring.BackgroundColor3 = Color3.fromRGB(31, 35, 56)
                        ringStroke.Transparency = 0.1
                    end)
                end)
                button.MouseLeave:Connect(function()
                    pcall(function()
                        button.BackgroundColor3 = Color3.fromRGB(9, 11, 18)
                        ring.BackgroundColor3 = Color3.fromRGB(22, 25, 39)
                        ringStroke.Transparency = 0.35
                    end)
                end)
            end

            state.updateCustomWheel = function()
                for _, child in ipairs(center:GetChildren()) do
                    if child.Name ~= "CloseButton" and child.Name ~= "EHint" then
                        child:Destroy()
                    end
                end

                local favEntries = {}
                for name in pairs(state.favorites) do
                    local entry = resolveEntry(name)
                    if entry then table.insert(favEntries, entry) end
                end

                local radius = 150
                local count = #favEntries
                for i, entry in ipairs(favEntries) do
                    local angle = math.rad((i - 1) * (360 / math.max(count, 1)) - 90)
                    local x = math.cos(angle) * radius
                    local y = math.sin(angle) * radius

                    local btn = Instance.new("TextButton")
                    btn.Name = "Fav_" .. entry.Name
                    btn.Size = UDim2.fromOffset(86, 86)
                    btn.Position = UDim2.fromOffset(x - 43, y - 43)
                    btn.BackgroundColor3 = Color3.fromRGB(30, 34, 50)
                    btn.BackgroundTransparency = 0.15
                    btn.ClipsDescendants = true
                    btn.Text = ""
                    btn.AutoButtonColor = false
                    btn.Parent = center
                    createUICorner(btn, 24)
                    createUIStroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.85)

                    addBlockyPreview(btn, entry, i)

                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Position = UDim2.fromScale(0.05, 0.65)
                    nameLabel.Size = UDim2.fromScale(0.9, 0.3)
                    nameLabel.Font = Enum.Font.GothamBold
                    nameLabel.Text = entry.Name
                    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    nameLabel.TextWrapped = true
                    nameLabel.ZIndex = 5
                    nameLabel.Parent = btn
                    fitText(nameLabel, 10, 13)

                    local textStroke = Instance.new("UIStroke")
                    textStroke.Color = Color3.fromRGB(0, 0, 0)
                    textStroke.Thickness = 1.5
                    textStroke.Transparency = 0.3
                    textStroke.Parent = nameLabel

                    btn.MouseEnter:Connect(function()
                        pcall(function()
                            btn.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
                            btn.BackgroundTransparency = 0.05
                            btn.Size = UDim2.fromOffset(94, 94)
                            btn.Position = UDim2.fromOffset(x - 47, y - 47)
                        end)
                    end)
                    btn.MouseLeave:Connect(function()
                        pcall(function()
                            btn.BackgroundColor3 = Color3.fromRGB(30, 34, 50)
                            btn.BackgroundTransparency = 0.15
                            btn.Size = UDim2.fromOffset(86, 86)
                            btn.Position = UDim2.fromOffset(x - 43, y - 43)
                        end)
                    end)

                    btn.Activated:Connect(function()
                        getgenv().selectedEmote = entry.Name
                        screenGui.Enabled = false
                        task.defer(function()
                            if type(getgenv().playEmote) == "function" then
                                getgenv().playEmote(entry.Name)
                            end
                        end)
                    end)
                end
            end

            state.updateCustomWheel()

            state.customWheelConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Enum.KeyCode.E then
                    screenGui.Enabled = not screenGui.Enabled
                    if screenGui.Enabled then
                        state.updateCustomWheel()
                    end
                end
            end)
        end

        state.initializeEmoteWheelList = function()
            state.emoteWheelEnabled = true
            if state.customWheelGui then
                if state.updateCustomWheel then state.updateCustomWheel() end
            else
                state.buildCustomWheel()
            end
            local function tryApply()
                if state.destroyed or not state.emoteWheelEnabled then return end
                if #state.catalog == 0 then refreshCatalog() end
                local now = os.clock()
                if now - (state.lastWheelApply or 0) < 0.35 then return end
                state.lastWheelApply = now
                state.applyEmoteWheelList()
            end

            task.defer(tryApply)
            if state.wheelInitialized then return end
            state.wheelInitialized = true
            for i = 1, 6 do
                task.delay(i * 0.5, function()
                    if not state.destroyed and state.emoteWheelEnabled then tryApply() end
                end)
            end

            if state.wheelConnection then
                pcall(function() state.wheelConnection:Disconnect() end)
                state.wheelConnection = nil
            end
            
            local runningThread
            runningThread = task.spawn(function()
                while not state.destroyed and state.emoteWheelEnabled do
                    task.wait(1.5)
                    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    if pGui then
                        local hasWheel = false
                        for _, wheel in ipairs(pGui:GetChildren()) do
                            if wheel.Name == "EmoteWheel" or wheel:FindFirstChild("EmoteWheel") then
                                hasWheel = true
                                break
                            end
                        end
                        if not hasWheel and pGui:FindFirstChild("EmoteWheel", true) then
                            hasWheel = true
                        end
                        if hasWheel then
                            tryApply()
                        end
                    end
                end
            end)
            
            state.wheelConnection = {
                Disconnect = function()
                    pcall(task.cancel, runningThread)
                end
            }
        end
        end

        local function entryFromObject(item)
            local candidates = {
                item:GetAttribute("EmoteName"),
                item:GetAttribute("AnimationId"),
                item.Name,
            }
            for _, object in ipairs(item:GetDescendants()) do
                if object:IsA("TextLabel") or object:IsA("TextButton") then
                    candidates[#candidates + 1] = object.Text
                elseif object:IsA("Animation") then
                    candidates[#candidates + 1] = object.Name
                    candidates[#candidates + 1] = object.AnimationId
                end
                for key, value in pairs(object:GetAttributes()) do
                    local lowered = tostring(key):lower()
                    if lowered:find("emote", 1, true)
                        or lowered:find("animation", 1, true)
                        or lowered == "id"
                        or lowered == "name" then
                        candidates[#candidates + 1] = value
                    end
                end
            end
            for _, candidate in ipairs(candidates) do
                local entry = resolveEntry(candidate)
                if entry then return entry end
            end
            return nil
        end

        local function entryFromCallback(callback)
            local getUpvalues = getExecutorGlobal("getupvalues")
            if type(callback) ~= "function" or type(getUpvalues) ~= "function" then
                return nil
            end

            local ok, upvalues = pcall(getUpvalues, callback)
            if not ok or type(upvalues) ~= "table" then return nil end
            for _, value in pairs(upvalues) do
                local entry = resolveEntry(value)
                if entry then return entry end
                if typeof(value) == "Instance" and value:IsA("Animation") then
                    entry = resolveEntry(value.AnimationId) or resolveEntry(value.Name)
                    if entry then return entry end
                elseif type(value) == "table" then
                    for key, fieldValue in pairs(value) do
                        local lowered = normalize(key)
                        if lowered:find("emote", 1, true)
                            or lowered:find("animation", 1, true)
                            or lowered == "id"
                            or lowered == "name" then
                            entry = resolveEntry(fieldValue)
                            if entry then return entry end
                        end
                    end
                end
            end
            return nil
        end

        local function findNativeDispatcher(wantedEntry)
            if state.nativeDispatcher then
                if type(state.nativeDispatcher.Callbacks) == "table"
                    and #state.nativeDispatcher.Callbacks > 0
                    and (not wantedEntry or sameEntry(state.nativeDispatcher.Original, wantedEntry)) then
                    return state.nativeDispatcher
                end
                if wantedEntry then
                    state.nativeDispatcher = nil
                end
            end

            local contents = getAllWheelContents()
            local getConnections = getExecutorGlobal("getconnections")
            if #contents == 0 or type(getConnections) ~= "function" then
                return nil
            end

            for _, content in ipairs(contents) do
                for _, item in ipairs(content:GetChildren()) do
                    if item:IsA("GuiObject") and not item:GetAttribute("IceHubEmoteCard") then
                        local button = getButton(item)
                        if button then
                            for _, signal in ipairs({button.Activated, button.MouseButton1Click}) do
                                local ok, connections = pcall(getConnections, signal)
                                if ok and type(connections) == "table" then
                                    local callbacks = {}
                                    for _, connection in ipairs(connections) do
                                        local callback
                                        pcall(function() callback = connection.Function end)
                                        if type(callback) == "function"
                                            and not (isourclosure and isourclosure(callback)) then
                                            callbacks[#callbacks + 1] = callback
                                        end
                                    end
                                    if #callbacks > 0 then
                                        local original = entryFromObject(item)
                                        for _, callback in ipairs(callbacks) do
                                            original = original or entryFromCallback(callback)
                                        end
                                        if original and (not wantedEntry or sameEntry(original, wantedEntry)) then
                                            state.nativeDispatcher = {
                                                WheelContent = content,
                                                Signal = signal,
                                                Connections = connections,
                                                Callbacks = callbacks,
                                                Original = original,
                                                Cached = false,
                                            }
                                            return state.nativeDispatcher
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return nil
        end

        local function trackSound(sound)
            if not sound or not sound:IsA("Sound") then return end
            state.activeSounds[#state.activeSounds + 1] = sound
            pcall(function()
                if sound.Volume <= 0 then
                    sound.Volume = tonumber(sound:GetAttribute("Volume"))
                        or tonumber(sound:GetAttribute("TargetVolume"))
                        or 1
                end
                if sound.RollOffMaxDistance < 40 then
                    sound.RollOffMaxDistance = 80
                end
                if not sound.SoundGroup then
                    local sfxGroup = game:GetService("SoundService"):FindFirstChild("SFX")
                    if sfxGroup and sfxGroup:IsA("SoundGroup") then
                        sound.SoundGroup = sfxGroup
                    end
                end
                sound.TimePosition = 0
                sound:Play()
            end)
            task.delay(0.25, function()
                if state.destroyed or not sound or not sound.Parent then return end
                pcall(function()
                    if not sound.IsPlaying and sound.SoundId ~= "" then
                        sound.TimePosition = 0
                        sound:Play()
                    end
                end)
            end)
        end

        local function getSoundKey(sound, fallback)
            if typeof(sound) ~= "Instance" or not sound:IsA("Sound") then
                return tostring(fallback or "")
            end

            local fullName = sound.Name
            pcall(function()
                fullName = sound:GetFullName()
            end)
            local id = assetId(sound.SoundId)
            return table.concat({
                "template",
                fullName or sound.Name,
                id or normalize(sound.SoundId),
                fallback or "",
            }, ":")
        end

        local function playSoundTemplate(template, parent, allowReplay, customKey)
            if typeof(template) ~= "Instance" or not template:IsA("Sound") then return false end
            local key = customKey or getSoundKey(template)
            if not allowReplay and state.playedSoundKeys[key] then return false end

            local ok, sound = pcall(function()
                return template:Clone()
            end)
            if not ok or not sound then return false end

            if not allowReplay then state.playedSoundKeys[key] = true end
            sound.Parent = parent
            trackSound(sound)
            return true
        end

        local function playSoundValue(value, parent, allowReplay, customKey)
            if typeof(value) == "Instance" and value:IsA("Sound") then
                return playSoundTemplate(value, parent, allowReplay, customKey)
            end

            local text = tostring(value or "")
            if text == "" then return false end

            local id = assetId(text)
        local key = customKey or (id and ("id:" .. id) or ("name:" .. normalize(text)))
        if not allowReplay and state.playedSoundKeys[key] then return false end

        local template
        if not id then
            template = getSoundByName(text)
        end

        local sound
        if template then
            return playSoundTemplate(template, parent, allowReplay, key)
        elseif id then
            sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://" .. id
            sound.Volume = 1
        end
        if not sound then return false end

        if not allowReplay then state.playedSoundKeys[key] = true end
        sound.Parent = parent
        trackSound(sound)
        return true
    end

    state.collectNativeSoundCues = state.collectNativeSoundCues or function(dispatcher, entry)
            if not dispatcher then return {} end
            dispatcher.SoundCuesCache = dispatcher.SoundCuesCache or {}
            local cacheKey = tostring(entry.Name)
            if dispatcher.SoundCuesCache[cacheKey] then
                return dispatcher.SoundCuesCache[cacheKey]
            end

            local getUpvalues = getExecutorGlobal("getupvalues")
            if type(getUpvalues) ~= "function" then return {} end

            local aliases = {
                [normalize(entry.Name)] = true,
                [normalize(entry.Id)] = true,
                [normalize(entry.Animation.AnimationId)] = true,
            }
            for _, value in pairs(entry.Attributes or {}) do
                aliases[normalize(tostring(value))] = true
            end

            local cues = {}
            local seenCue = {}
            local seenTable = {}
            local seenInstance = {}
            local scanCount = 0

            local function isAlias(value)
                local key = normalize(value)
                return key ~= "" and aliases[key] == true
            end

            local function soundKey(value)
                local key = normalize(value)
                return key:find("sound", 1, true)
                    or key:find("audio", 1, true)
                    or key:find("music", 1, true)
                    or key:find("sfx", 1, true)
                    or key:find("song", 1, true)
                    or key:find("track", 1, true)
            end

            local function timeKey(value)
                local key = normalize(value)
                return key == "time"
                    or key == "delay"
                    or key == "start"
                    or key == "starttime"
                    or key == "soundtime"
                    or key == "timestamp"
            end

            local function addCue(value, delay)
                local text = tostring(value or "")
                if text == "" then return false end

                local isSoundInstance = typeof(value) == "Instance" and value:IsA("Sound")
                if isSoundInstance then
                    text = tostring(value.SoundId or value.Name or "")
                end

                local id = assetId(text)
                local cueValue = text
                if isSoundInstance then
                    cueValue = value
                elseif id and #id >= 5 then
                    cueValue = "rbxassetid://" .. id
                elseif type(value) == "number" and value >= 10000 then
                    cueValue = "rbxassetid://" .. tostring(math.floor(value + 0.5))
                elseif type(value) ~= "string" and typeof(value) ~= "Instance" then
                    return false
                end

                delay = tonumber(delay)
                if delay then
                    delay = math.clamp(delay, 0, 30)
                else
                    delay = 0.45 + (#cues * 0.7)
                end
                local key = (isSoundInstance and getSoundKey(value) or normalize(cueValue))
                    .. ":"
                    .. tostring(math.floor(delay * 100 + 0.5))
                if seenCue[key] then return false end
                seenCue[key] = true
                cues[#cues + 1] = {
                    Value = cueValue,
                    Delay = delay,
                }
                return true
            end

            local function scan(value, depth, inSoundBranch, delayHint, matchedBranch)
                if depth > 4 or scanCount > 400 then return end
                scanCount += 1

                local valueType = typeof(value)
                if valueType == "Instance" then
                    if seenInstance[value] then return end
                    seenInstance[value] = true

                    local nameMatches = isAlias(value.Name)
                    if value:IsA("Sound") then
                        if inSoundBranch or matchedBranch or nameMatches or soundKey(value.Name) then
                            addCue(value, delayHint)
                        end
                        return
                    end

                    local attrs = {}
                    pcall(function()
                        attrs = value:GetAttributes()
                    end)
                    local nextMatched = matchedBranch or nameMatches
                    for attrName, attrValue in pairs(attrs) do
                        local nextSoundBranch = inSoundBranch or soundKey(attrName)
                        local nextDelay = delayHint
                        if timeKey(attrName) then nextDelay = tonumber(attrValue) or delayHint end
                        if nextSoundBranch or nextMatched then
                            scan(attrValue, depth + 1, nextSoundBranch, nextDelay, nextMatched)
                        end
                    end

                    if nextMatched or soundKey(value.Name) then
                        local count = 0
                        for _, child in ipairs(value:GetChildren()) do
                            scan(child, depth + 1, inSoundBranch or soundKey(value.Name), delayHint, nextMatched)
                            count += 1
                            if count >= 80 then break end
                        end
                    end
                    return
                end

                if type(value) == "table" then
                    if seenTable[value] then return end
                    seenTable[value] = true

                    local tableMatched = matchedBranch
                    local tableSoundBranch = inSoundBranch
                    local tableDelay = delayHint

                    local tCount = 0
                    for key, fieldValue in pairs(value) do
                        tCount += 1
                        if tCount > 150 then break end
                        if isAlias(key) or isAlias(fieldValue) then
                            tableMatched = true
                        end
                        if soundKey(key) then
                            tableSoundBranch = true
                        end
                        if timeKey(key) then
                            tableDelay = tonumber(fieldValue) or tableDelay
                        elseif type(key) == "number" and key >= 0 and key <= 30 then
                            tableDelay = key
                        end
                    end

                    tCount = 0
                    for key, fieldValue in pairs(value) do
                        tCount += 1
                        if tCount > 150 then break end
                        local nextSoundBranch = tableSoundBranch or soundKey(key)
                        local nextMatched = tableMatched or isAlias(key) or isAlias(fieldValue)
                        local nextDelay = tableDelay
                        if timeKey(key) then
                            nextDelay = tonumber(fieldValue) or nextDelay
                        elseif type(key) == "number" and key >= 0 and key <= 30 then
                            nextDelay = key
                        end

                        if nextSoundBranch or nextMatched then
                            if not addCue(fieldValue, nextDelay) then
                                scan(fieldValue, depth + 1, nextSoundBranch, nextDelay, nextMatched)
                            end
                        elseif type(fieldValue) == "table" or typeof(fieldValue) == "Instance" then
                            scan(fieldValue, depth + 1, false, nextDelay, false)
                        end
                    end
                    return
                end

                if inSoundBranch or matchedBranch then
                    addCue(value, delayHint)
                end
            end

            for _, callback in ipairs(dispatcher.Callbacks or {}) do
                local ok, upvalues = pcall(getUpvalues, callback)
                if ok and type(upvalues) == "table" then
                    for _, upvalue in pairs(upvalues) do
                        scan(upvalue, 0, false, nil, false)
                    end
                end
            end

            table.sort(cues, function(left, right)
                return (left.Delay or 0) < (right.Delay or 0)
            end)
            dispatcher.SoundCuesCache[cacheKey] = cues
            return cues
        end

        state.scheduleNativeSoundCues = state.scheduleNativeSoundCues or function(dispatcher, entry, playToken)
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then return 0 end

            local cues = state.collectNativeSoundCues(dispatcher, entry)
            if #cues == 0 then return 0 end

            local maxCues = math.min(#cues, 18)
            for index = 1, maxCues do
                local cue = cues[index]
                local delayTime = tonumber(cue.Delay) or (0.45 + (index - 1) * 0.7)
                if delayTime < 0.18 then delayTime = 0.18 end
                task.delay(delayTime, function()
                    if state.destroyed or state.playToken ~= playToken then return end
                    local valueKey = typeof(cue.Value) == "Instance"
                        and getSoundKey(cue.Value)
                        or tostring(cue.Value)
                    playSoundValue(cue.Value, root, false, valueKey .. ":" .. tostring(math.floor(delayTime * 1000 + 0.5)))
                end)
            end
            return maxCues
        end

        local function initializeEmoteObservers()
            if state.observersInitialized then return end

            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local observers = playerGui and playerGui:FindFirstChild("Observers", true)
            local emoteObservers = observers and observers:FindFirstChild("Emotes")
            if not emoteObservers then return end
            state.observersInitialized = true

            for _, moduleScript in ipairs(emoteObservers:GetDescendants()) do
                if moduleScript:IsA("ModuleScript") then
                    local ok, observer = pcall(require, moduleScript)
                    if ok and (type(observer) == "function" or type(observer) == "table") then
                        state.observerExports[#state.observerExports + 1] = observer
                    end
                end
            end
        end

        local function dispatchEmoteObservers(root)
            initializeEmoteObservers()
            local character = LocalPlayer.Character
            for _, observer in ipairs(state.observerExports) do
                if type(observer) == "function" then
                    pcall(observer, root, character)
                elseif type(observer) == "table" then
                    for _, methodName in ipairs({
                        "Observe",
                        "Apply",
                        "Start",
                        "Create",
                        "OnAdded",
                    }) do
                        local method = observer[methodName]
                        if type(method) == "function" then
                            local ok = pcall(method, observer, root, character)
                            if not ok then pcall(method, root, character) end
                            break
                        end
                    end
                end
            end
        end

        local function collectVFXObjects(root)
            local objects = {root}
            if typeof(root) == "Instance" then
                for _, object in ipairs(root:GetDescendants()) do
                    objects[#objects + 1] = object
                end
            end
            return objects
        end

        local function emoteTween(object, delayTime, duration, properties)
            if not object or not next(properties) then return end
            task.delay(math.max(tonumber(delayTime) or 0, 0), function()
                if not object or not object.Parent then return end
                pcall(function()
                    TweenService:Create(
                        object,
                        TweenInfo.new(math.max(tonumber(duration) or 0.18, 0.05), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        properties
                    ):Play()
                end)
            end)
        end

        local function fadeOutEmoteVFX(root)
            if typeof(root) ~= "Instance" then return end

            local fadeTime = 0.28
            for _, object in ipairs(collectVFXObjects(root)) do
                if object and object.Parent then
                    if object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail") then
                        pcall(function() object.Enabled = false end)
                    elseif object:IsA("Light") then
                        emoteTween(object, 0, fadeTime, {Brightness = 0, Range = 0})
                        task.delay(fadeTime, function()
                            if object and object.Parent then object.Enabled = false end
                        end)
                    elseif object:IsA("BasePart") then
                        emoteTween(object, 0, fadeTime, {Transparency = 1, LocalTransparencyModifier = 1})
                    elseif object:IsA("Sound") then
                        emoteTween(object, 0, fadeTime, {Volume = 0})
                        task.delay(fadeTime, function()
                            if object and object.Parent then pcall(function() object:Stop() end) end
                        end)
                    end
                end
            end

            task.delay(fadeTime + 0.12, function()
                if root and root.Parent then
                    pcall(function() root:Destroy() end)
                end
            end)
        end

        local function activateVFX(root, entry)
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not root or not rootPart then return end
            local playToken = state.playToken

            dispatchEmoteObservers(root)

            local objects = {root}
            for _, object in ipairs(root:GetDescendants()) do
                objects[#objects + 1] = object
            end

            local function applyObject(object)
                if state.destroyed or state.playToken ~= playToken then return end
                if not object or not object.Parent then return end
                if object:IsA("Sound") then
                    if not object:GetAttribute("IceHubPlayed") then
                        object:SetAttribute("IceHubPlayed", true)
                        trackSound(object)
                    end
                elseif object:IsA("ParticleEmitter") then
                    local isEmit = false
                    local p = object.Parent
                    while p and p ~= root do
                        if string.match(string.lower(p.Name), "emit") then
                            isEmit = true
                            break
                        end
                        p = p.Parent
                    end

                    if isEmit then
                        object.Enabled = false
                        object:Emit(30)
                    else
                        object.Enabled = true
                        local emitCount = object:GetAttribute("EmitCount")
                            or object:GetAttribute("ParticleCount")
                            or object:GetAttribute("Count")
                        if tonumber(emitCount) then
                            pcall(function() object:Emit(tonumber(emitCount)) end)
                        elseif object.Rate <= 0 then
                            pcall(function() object:Emit(25) end)
                        end
                    end
                elseif object:IsA("Beam") or object:IsA("Trail") then
                    object.Enabled = true
                elseif object:IsA("Light") then
                    object.Enabled = true
                elseif object:IsA("BasePart") then
                    object.CanCollide = false
                    object.CanTouch = false
                    object.CanQuery = false
                    object.Massless = true
                end
            end

            local function cleanupObject(object)
                if state.destroyed or state.playToken ~= playToken then return end
                if not object or not object.Parent then return end
                if object:IsA("Sound") then
                    pcall(function() object:Stop() end)
                elseif object:IsA("ParticleEmitter")
                    or object:IsA("Beam")
                    or object:IsA("Trail") then
                    pcall(function() object.Enabled = false end)
                elseif object:IsA("Light") then
                    pcall(function() object.Enabled = false end)
                end
            end

            for _, object in ipairs(objects) do
                local cueSpec = state.getVFXObjectCueSpec(object, entry)
                local delayTime = cueSpec.Time or 0
                if delayTime > 0 then
                    task.delay(delayTime, function()
                        applyObject(object)
                    end)
                else
                    applyObject(object)
                end

                if cueSpec.CleanupTime then
                    local cleanupDelay = math.max((cueSpec.Time or 0) + cueSpec.CleanupTime, 0)
                    task.delay(cleanupDelay, function()
                        cleanupObject(object)
                    end)
                elseif object:IsA("Sound") then
                    local soundStartDelay = cueSpec.Time or 0
                    task.delay(soundStartDelay, function()
                        if state.destroyed
                            or state.playToken ~= playToken
                            or not object.Parent
                            or object.Looped then
                            return
                        end

                        pcall(function()
                            if not object.IsLoaded then
                                object.Loaded:Wait()
                            end
                        end)

                        local length = tonumber(object.TimeLength) or 0
                        if length <= 0 then return end
                        task.wait(length + 0.5)
                        if state.destroyed
                            or state.playToken ~= playToken
                            or not object.Parent
                            or object.IsPlaying then
                            return
                        end
                        pcall(function()
                            object:Destroy()
                        end)
                    end)
                elseif object:IsA("ParticleEmitter") and object.Rate <= 0 then
                    task.delay(math.max((cueSpec.Time or 0) + 2.5, 0), function()
                        cleanupObject(object)
                    end)
                end
            end
        end


        local function collectPayloadInstances(value, output, seenTables, seenInstances)
            if typeof(value) == "Instance" then
                if value:IsA("Animation")
                    or value:IsA("ModuleScript")
                    or value:IsA("Script")
                    or value:IsA("LocalScript")
                    or value:IsA("BindableFunction")
                    or value:IsA("BindableEvent")
                    or value:IsA("RemoteEvent")
                    or value:IsA("RemoteFunction") then
                    return
                end
                if not seenInstances[value] then
                    seenInstances[value] = true
                    output[#output + 1] = value
                end
                return
            end
            if type(value) ~= "table" or seenTables[value] then return end
            seenTables[value] = true
            for _, fieldValue in pairs(value) do
                collectPayloadInstances(fieldValue, output, seenTables, seenInstances)
            end
        end




        local function getEmoteVFXRoots()
            local now = os.clock()
            if state.vfxRootCache and now - (state.vfxRootCacheAt or 0) < 5 then
                local valid = {}
                for _, root in ipairs(state.vfxRootCache) do
                    if typeof(root) == "Instance" and root.Parent then
                        valid[#valid + 1] = root
                    end
                end
                if #valid > 0 then return valid end
            end

            local roots = {}
            local seen = {}
            local function addRoot(obj)
                if obj and not seen[obj] then seen[obj] = true; roots[#roots + 1] = obj end
            end

            -- Standart path: ReplicatedStorage/Shared/ReplicatedInstances/EmoteVFX
            local shared = ReplicatedStorage:FindFirstChild("Shared")
            local replicatedInstances = ReplicatedStorage:FindFirstChild("ReplicatedInstances") or (shared and shared:FindFirstChild("ReplicatedInstances"))
            if replicatedInstances then
                addRoot(replicatedInstances:FindFirstChild("EmoteVFX"))
                addRoot(replicatedInstances:FindFirstChild("Emotes"))
                addRoot(replicatedInstances:FindFirstChild("Effects"))
                addRoot(replicatedInstances:FindFirstChild("EmoteAccessory"))
            end
            if shared then
                addRoot(shared:FindFirstChild("EmoteVFX", true))
            end

            -- Misc/Emotes klasörü içinde VFX olabilir
            local misc = ReplicatedStorage:FindFirstChild("Misc")
            local emotesFolder = misc and misc:FindFirstChild("Emotes")
            if emotesFolder then
                addRoot(emotesFolder:FindFirstChild("VFX"))
                addRoot(emotesFolder:FindFirstChild("Effects"))
                addRoot(emotesFolder)
            end

            -- ReplicatedStorage altında herhangi bir EmoteVFX klasörü
            local scanned = 0
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                scanned += 1
                if scanned > 2500 or #roots >= 12 then break end
                if obj:IsA("Folder") or obj:IsA("Model") then
                    local lname = obj.Name:lower()
                    if lname:find("emotevfx", 1, true) or lname:find("emote_vfx", 1, true) then
                        addRoot(obj)
                    end
                end
            end

            -- PlayerGui içinde
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                local playerInstances = playerGui:FindFirstChild("ReplicatedInstances", true)
                if playerInstances then
                    addRoot(playerInstances:FindFirstChild("EmoteVFX"))
                    addRoot(playerInstances:FindFirstChild("Emotes"))
                end
                local playerVFX = playerGui:FindFirstChild("EmoteVFX", true)
                addRoot(playerVFX)
            end

            state.vfxRootCache = roots
            state.vfxRootCacheAt = now
            return roots
        end

        state.getEmoteAccessoryPayload = state.getEmoteAccessoryPayload or function(entry)
            state.emoteAccessoryCache = state.emoteAccessoryCache or {}
            local cacheKey = tostring(entry and (entry.Animation and entry.Animation.AnimationId or entry.Id or entry.Name) or "")
            if state.emoteAccessoryCache[cacheKey] ~= nil then
                local cached = state.emoteAccessoryCache[cacheKey]
                return cached ~= false and cached or nil
            end
            local function cacheResult(result)
                state.emoteAccessoryCache[cacheKey] = result or false
                return result
            end

            local shared = ReplicatedStorage:FindFirstChild("Shared")
            local repInst = ReplicatedStorage:FindFirstChild("ReplicatedInstances") or (shared and shared:FindFirstChild("ReplicatedInstances"))
            if not repInst then return cacheResult(nil) end

            local emoteAccFolder = repInst:FindFirstChild("EmoteAccessories")
            if not emoteAccFolder then return cacheResult(nil) end

            local values = {entry.Id, entry.Name, tostring(entry.Id), tostring(entry.Name)}

            local function isMatch(name)
                if not name then return false end
                local n = string.lower(string.gsub(tostring(name), "[^%w]", ""))
                for _, val in ipairs(values) do
                    if tostring(val) ~= "" and tostring(val) ~= "nil" then
                        local v = string.lower(string.gsub(tostring(val), "[^%w]", ""))
                        if n == v or string.find(n, v, 1, true) or string.find(v, n, 1, true) then
                            return true
                        end
                    end
                end
                return false
            end

            emoteDebugWarn("IceHub Debug -> Searching EmoteAccessories for:", entry.Name)

            -- 1. Try BindableFunctions
            for _, bf in ipairs(emoteAccFolder:GetDescendants()) do
                if bf:IsA("BindableFunction") then
                    emoteDebugWarn("IceHub Debug -> Found BindableFunction:", bf.Name)
                    for _, val in ipairs(values) do
                        local ok, result = pcall(function() return bf:Invoke(val) end)
                        if ok and result and typeof(result) == "Instance" then
                            emoteDebugWarn("IceHub Debug -> BindableFunction RETURNED SUCCESS:", result.Name)
                            return cacheResult(result)
                        end
                    end
                end
            end

            -- 2. Try ModuleScripts
            for _, ms in ipairs(emoteAccFolder:GetDescendants()) do
                if ms:IsA("ModuleScript") then
                    emoteDebugWarn("IceHub Debug -> Found ModuleScript:", ms.Name, ms.ClassName)
                    local ok, module = pcall(require, ms)
                    if not ok then
                        emoteDebugWarn("IceHub Debug -> Require FAILED for", ms.Name, ":", tostring(module))
                        continue
                    end

                    if type(module) == "function" then
                        for _, val in ipairs(values) do
                            local called, result = pcall(module, val)
                            if called and result and typeof(result) == "Instance" then return cacheResult(result) end
                        end
                    elseif type(module) == "table" then
                        for k, result in pairs(module) do
                            if typeof(result) == "Instance" and isMatch(k) then
                                emoteDebugWarn("IceHub Debug -> Module matched key:", k)
                                return cacheResult(result)
                            end
                        end
                    end
                end
            end

            -- 3. Try Direct Instances
            for _, inst in ipairs(emoteAccFolder:GetChildren()) do
                if inst:IsA("Model") or inst:IsA("Folder") or inst:IsA("Accessory") then
                    if isMatch(inst.Name) then
                        emoteDebugWarn("IceHub Debug -> Found DIRECT INSTANCE match:", inst.Name)
                        return cacheResult(inst)
                    end
                end
            end

            emoteDebugWarn("IceHub Debug -> getEmoteAccessoryPayload NOTHING FOUND")
            return cacheResult(nil)
        end

        state.invokeGetEmoteVFX = state.invokeGetEmoteVFX or function(entry)
            local character = LocalPlayer.Character
            local values = {
                entry.Id,
                entry.Name,
                entry.Animation,
                entry.Animation.AnimationId,
            }
            for attributeName, attributeValue in pairs(entry.Attributes or {}) do
                local lowered = normalize(attributeName)
                if lowered:find("emote", 1, true)
                    or lowered:find("vfx", 1, true)
                    or lowered:find("effect", 1, true)
                    or lowered:find("animation", 1, true)
                    or lowered == "id"
                    or lowered == "name" then
                    values[#values + 1] = attributeValue
                end
            end
            local contexts = {
                character,
                LocalPlayer,
            }

            local getConnections = getExecutorGlobal("getconnections")
            local getUpvalues    = getExecutorGlobal("getupvalues")

            -- BindableFunction'ın OnInvoke callback'ini getconnections ile bul ve direkt çağır.
            -- Handler'ın server Script'inde bağlı olduğu durumda :Invoke() nil döner ama
            -- getconnections ile handler direkt erişilebilir.
            local function callBindableViaConnections(bf, ...)
                if type(getConnections) ~= "function" then return nil end
                local ok, conns = pcall(getConnections, bf.OnInvoke)
                if not ok or type(conns) ~= "table" then return nil end
                for _, conn in ipairs(conns) do
                    local callback
                    pcall(function() callback = conn.Function end)
                    if type(callback) == "function" then
                        local called, result = pcall(callback, ...)
                        if called and result ~= nil then return result end
                    end
                end
                return nil
            end

            for _, root in ipairs(getEmoteVFXRoots()) do

                -- GetInstance BindableFunction: VFX template instance'ı getiriyor olabilir
                local getInstance = root:FindFirstChild("GetInstance", true)
                if getInstance and getInstance:IsA("BindableFunction") then
                    for _, value in ipairs(values) do
                        local argumentSets = {{value}}
                        for _, context in ipairs(contexts) do
                            if context then
                                argumentSets[#argumentSets + 1] = {value, context}
                                argumentSets[#argumentSets + 1] = {context, value}
                            end
                        end
                        for _, args in ipairs(argumentSets) do
                            local ok, payload = pcall(function()
                                return getInstance:Invoke(unpack(args))
                            end)
                            if ok and payload ~= nil then return payload end
                            -- getconnections ile direkt handler çağrısı
                            local directResult = callBindableViaConnections(getInstance, unpack(args))
                            if directResult ~= nil then return directResult end
                        end
                    end
                end

                -- GetEmoteVFX BindableFunction
                local getter = root:FindFirstChild("GetEmoteVFX", true)
                if getter and getter:IsA("BindableFunction") then
                    for _, value in ipairs(values) do
                        local argumentSets = {{value}}
                        for _, context in ipairs(contexts) do
                            if context then
                                argumentSets[#argumentSets + 1] = {value, context}
                                argumentSets[#argumentSets + 1] = {context, value}
                            end
                        end
                        for _, args in ipairs(argumentSets) do
                            -- Normal Invoke dene
                            local ok, payload = pcall(function()
                                return getter:Invoke(unpack(args))
                            end)
                            if ok and payload ~= nil then return payload end
                            -- getconnections ile OnInvoke handler'ını direkt çağır
                            local directResult = callBindableViaConnections(getter, unpack(args))
                            if directResult ~= nil then return directResult end
                        end
                    end
                end

                -- EmoteVFX Script/ModuleScript
                local emoteVFXScript = root:FindFirstChild("EmoteVFX", true)
                if emoteVFXScript then
                    if emoteVFXScript:IsA("ModuleScript") then
                        local ok, module = pcall(require, emoteVFXScript)
                        if ok then
                            if type(module) == "function" then
                                for _, value in ipairs(values) do
                                    local argumentSets = {{value}}
                                    for _, context in ipairs(contexts) do
                                        if context then
                                            argumentSets[#argumentSets + 1] = {value, context}
                                            argumentSets[#argumentSets + 1] = {context, value}
                                        end
                                    end
                                    for _, args in ipairs(argumentSets) do
                                        local called, payload = pcall(module, unpack(args))
                                        if called and payload ~= nil then return payload end
                                    end
                                end
                            elseif type(module) == "table" then
                                -- EmoteVFX tablolarını güvenli şekilde tara; bazı executor'lar table için getupvalues hata basıyor.
                                if type(getUpvalues) == "function" then
                                    for _, maybeFunction in pairs(module) do
                                        if type(maybeFunction) == "function" then
                                            local okUvs, uvs = pcall(getUpvalues, maybeFunction)
                                            if okUvs and type(uvs) == "table" then
                                                for _, uv in ipairs(uvs) do
                                                    if type(uv) == "table" and type(uv.VFX) == "table" then
                                                        for _, value in ipairs(values) do
                                                            local direct = uv.VFX[value] or uv.VFX[normalize(tostring(value))]
                                                            if direct ~= nil then return direct end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                for _, value in ipairs(values) do
                                    local direct = module[value]
                                    if direct ~= nil then return direct end
                                    direct = module[normalize(tostring(value))]
                                    if direct ~= nil then return direct end
                                end
                                for _, methodName in ipairs({
                                    "GetEmoteVFX", "GetVFX", "Get", "Find", "Resolve",
                                }) do
                                    local method = module[methodName]
                                    if type(method) == "function" then
                                        for _, value in ipairs(values) do
                                            local argumentSets = {
                                                {module, value},
                                                {value},
                                            }
                                            for _, context in ipairs(contexts) do
                                                if context then
                                                    argumentSets[#argumentSets + 1] = {module, value, context}
                                                    argumentSets[#argumentSets + 1] = {module, context, value}
                                                    argumentSets[#argumentSets + 1] = {value, context}
                                                    argumentSets[#argumentSets + 1] = {context, value}
                                                end
                                            end
                                            for _, args in ipairs(argumentSets) do
                                                local called, payload = pcall(method, unpack(args))
                                                if called and payload ~= nil then return payload end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    elseif emoteVFXScript:IsA("Script") or emoteVFXScript:IsA("LocalScript") then
                        -- Script'in içindeki BindableFunction'ları getconnections ile çağır
                        for _, bf in ipairs(root:GetDescendants()) do
                            if bf:IsA("BindableFunction") then
                                for _, value in ipairs(values) do
                                    local directResult = callBindableViaConnections(bf, value)
                                    if directResult ~= nil then return directResult end
                                    for _, context in ipairs(contexts) do
                                        if context then
                                            directResult = callBindableViaConnections(bf, value, context)
                                            if directResult ~= nil then return directResult end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- Geriye dönük uyumluluk: diğer ModuleScript'ler
                for _, ms in ipairs(root:GetDescendants()) do
                    if ms:IsA("ModuleScript") and ms ~= emoteVFXScript then
                        local ok, module = pcall(require, ms)
                        if ok and type(module) == "table" then
                            for _, value in ipairs(values) do
                                local direct = module[value]
                                if direct ~= nil then return direct end
                            end
                        end
                    end
                end
            end
            return nil
        end

        state.collectPayloadAliases = state.collectPayloadAliases or function(value, aliases, seen)
            if type(value) == "string" then
                local key = normalize(value)
                if key ~= "" then aliases[key] = true end
                return
            end
            if type(value) ~= "table" then return end
            seen = seen or {}
            if seen[value] then return end
            seen[value] = true
            for key, fieldValue in pairs(value) do
                state.collectPayloadAliases(key, aliases, seen)
                state.collectPayloadAliases(fieldValue, aliases, seen)
            end
        end

        state.findNamedVFX = state.findNamedVFX or function(entry, payload)
            state.namedVFXCache = state.namedVFXCache or {}
            local cacheKey = tostring(entry and (entry.Animation and entry.Animation.AnimationId or entry.Id or entry.Name) or "")
                .. ":"
                .. tostring(payload)
            if state.namedVFXCache[cacheKey] then
                return state.namedVFXCache[cacheKey]
            end

            local aliases = {
                [normalize(entry.Name)] = true,
                [normalize(entry.Id)] = true,
            }
            for attributeName, attributeValue in pairs(entry.Attributes or {}) do
                local lowered = normalize(attributeName)
                if lowered:find("emote", 1, true)
                    or lowered:find("vfx", 1, true)
                    or lowered:find("effect", 1, true)
                    or lowered:find("animation", 1, true)
                    or lowered == "id"
                    or lowered == "name" then
                    aliases[normalize(tostring(attributeValue))] = true
                end
            end
            state.collectPayloadAliases(payload, aliases)
            local matches = {}
            for _, root in ipairs(getEmoteVFXRoots()) do
                for _, object in ipairs(root:GetDescendants()) do
                    if not object:IsA("Animation")
                        and not object:IsA("ModuleScript")
                        and not object:IsA("Script")
                        and not object:IsA("LocalScript") then
                        -- Ä°sim eÅŸleÅŸmesi
                        if aliases[normalize(object.Name)] then
                            matches[#matches + 1] = object
                            continue
                        end
                        -- Attribute tabanlÄ± eÅŸleÅŸme: nesnenin herhangi bir attribute'u alias ise
                        local ok, attrs = pcall(function() return object:GetAttributes() end)
                        if ok and attrs then
                            for attrKey, attrVal in pairs(attrs) do
                                local lk = normalize(attrKey)
                                if lk:find("emote", 1, true) or lk:find("id", 1, true) or lk:find("name", 1, true) then
                                    if aliases[normalize(tostring(attrVal))] then
                                        matches[#matches + 1] = object
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            state.namedVFXCache[cacheKey] = matches
            return matches
        end

        state.runVFXModule = state.runVFXModule or function(entry, payload)
            local character = LocalPlayer.Character
            if not character then return false end

            for _, root in ipairs(getEmoteVFXRoots()) do
                local moduleScript = root:IsA("ModuleScript") and root
                    or root:FindFirstChild("EmoteVFX", true)
                if moduleScript and moduleScript:IsA("ModuleScript") then
                    local loaded, module = pcall(require, moduleScript)
                    if loaded and type(module) == "table" then
                        for _, methodName in ipairs({
                            "Play",
                            "Create",
                            "Spawn",
                            "Start",
                            "Apply",
                            "Emit",
                            "PlayEmoteVFX",
                            "CreateEmoteVFX",
                        }) do
                            local method = module[methodName]
                            if type(method) == "function" then
                                local argumentSets = {}
                                if payload then
                                    argumentSets[#argumentSets + 1] = {module, character, payload}
                                    argumentSets[#argumentSets + 1] = {module, payload, character}
                                    argumentSets[#argumentSets + 1] = {character, payload}
                                    argumentSets[#argumentSets + 1] = {payload, character}
                                end
                                argumentSets[#argumentSets + 1] = {module, character, entry.Id}
                                argumentSets[#argumentSets + 1] = {module, entry.Id, character}
                                argumentSets[#argumentSets + 1] = {module, character, entry.Name}
                                argumentSets[#argumentSets + 1] = {module, entry.Name, character}
                                argumentSets[#argumentSets + 1] = {character, entry.Id}
                                argumentSets[#argumentSets + 1] = {entry.Id, character}

                                for _, args in ipairs(argumentSets) do
                                    local ok, result = pcall(method, unpack(args))
                                    if ok then return true end
                                end
                            end
                        end
                    end
                end
            end
            return false
        end

        state.materializeVFXPayload = state.materializeVFXPayload or function(payload, entry)
            if not payload then return false end
            local character = LocalPlayer.Character
            if not character then return false end

            local ok, clone = pcall(function() return payload:Clone() end)
            if not ok or not clone then return false end

            clone:SetAttribute("IceHubEmoteVFX", true)

            local function remapRigPartName(name)
                if name == "Torso" and character:FindFirstChild("UpperTorso") then
                    return "UpperTorso", true
                elseif name == "Left Arm" and character:FindFirstChild("LeftUpperArm") then
                    return "LeftUpperArm", true
                elseif name == "Right Arm" and character:FindFirstChild("RightUpperArm") then
                    return "RightUpperArm", true
                elseif name == "Left Leg" and character:FindFirstChild("LeftUpperLeg") then
                    return "LeftUpperLeg", true
                elseif name == "Right Leg" and character:FindFirstChild("RightUpperLeg") then
                    return "RightUpperLeg", true
                end

                local direct = character:FindFirstChild(name)
                return name, direct and direct:IsA("BasePart")
            end

            local function hideRigAnchor(part)
                part.Transparency = 1
                part.LocalTransparencyModifier = 1
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.Massless = true
                part.CastShadow = false
                for _, child in ipairs(part:GetDescendants()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        child.Transparency = 1
                    elseif child:IsA("SpecialMesh") then
                        child.VertexColor = Vector3.new(0, 0, 0)
                    end
                end
            end

            local function attachToCharacter(vfxRoot)
                -- 1. Pass: Fix existing joints (Welds, Motor6Ds, WeldConstraints)
                for _, joint in ipairs(vfxRoot:GetDescendants()) do
                    if joint:IsA("Weld") or joint:IsA("Motor6D") or joint:IsA("WeldConstraint") then
                        local p = joint.Parent
                        if p and p:IsA("BasePart") then
                            local target = remapRigPartName(p.Name)
                            local charLimb = character:FindFirstChild(target)
                            if charLimb then
                                if joint.Part0 == nil or joint.Part0 == p then joint.Part0 = charLimb end
                                if joint.Part1 == p then joint.Part1 = charLimb end
                            end
                        end
                    end
                end

                -- 2. Pass: Map dummy parts and apply fallback welds
                for _, descendant in ipairs(vfxRoot:GetDescendants()) do
                    -- VERY IMPORTANT: If it's part of an Accessory, let Roblox handle it natively!
                    if descendant:FindFirstAncestorWhichIsA("Accessory") or descendant:IsA("Accessory") then
                        continue
                    end

                    if descendant:IsA("BasePart") then
                        descendant.CanCollide = false
                        descendant.CanTouch = false
                        descendant.CanQuery = false
                        descendant.Massless = true
                        descendant.CastShadow = false

                        local limbName, isRigPart = remapRigPartName(descendant.Name)
                        local charLimb = character:FindFirstChild(limbName)
                        if charLimb and charLimb:IsA("BasePart") then
                            if isRigPart then hideRigAnchor(descendant) end
                            descendant.CFrame = charLimb.CFrame
                            local weld = Instance.new("WeldConstraint")
                            weld.Part0 = charLimb
                            weld.Part1 = descendant
                            weld.Parent = descendant
                        else
                            local hrp = character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local hasJoint = false
                                for _, j in ipairs(vfxRoot:GetDescendants()) do
                                    if (j:IsA("Weld") or j:IsA("Motor6D") or j:IsA("WeldConstraint")) and (j.Part0 == descendant or j.Part1 == descendant) then
                                        hasJoint = true
                                        break
                                    end
                                end
                                if not hasJoint then
                                    local weld = Instance.new("WeldConstraint")
                                    weld.Part0 = hrp
                                    weld.Part1 = descendant
                                    weld.Parent = descendant
                                end
                            end
                        end

                        descendant.Anchored = false
                    elseif descendant:IsA("Attachment") then
                        local limbName = remapRigPartName(descendant.Name)
                        local charLimb = character:FindFirstChild(limbName)
                        if charLimb and charLimb:IsA("BasePart") and not descendant.Parent:IsA("BasePart") then
                            descendant.Parent = charLimb
                        end
                    end
                end
            end

            attachToCharacter(clone)

            local humanoid = character:FindFirstChildOfClass("Humanoid")

            -- PREVENT SELF DESTRUCTION BY NATIVE SCRIPTS
            for _, desc in ipairs(clone:GetDescendants()) do
                if desc:IsA("Script") or desc:IsA("LocalScript") then
                    pcall(function() desc:Destroy() end)
                end
                if desc:IsA("BasePart") then
                    desc.CanCollide = false
                    desc.CanTouch = false
                    desc.CanQuery = false
                    desc.Massless = true
                    desc.CastShadow = false
                end
            end

            local function manualWeldAccessory(acc)
                local handle = acc:FindFirstChild("Handle")
                if not handle then return end

                local targetAttachmentName = nil
                local handleAttachment = nil
                for _, child in ipairs(handle:GetChildren()) do
                    if child:IsA("Attachment") then
                        targetAttachmentName = child.Name
                        handleAttachment = child
                        break
                    end
                end

                if targetAttachmentName then
                    -- Find matching attachment in character
                    local charAttachment = nil
                    for _, desc in ipairs(character:GetDescendants()) do
                        if desc:IsA("Attachment") and desc.Name == targetAttachmentName and desc.Parent:IsA("BasePart") then
                            charAttachment = desc
                            break
                        end
                    end

                    if charAttachment then
                        handle.CFrame = charAttachment.Parent.CFrame * charAttachment.CFrame * handleAttachment.CFrame:Inverse()
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = charAttachment.Parent
                        weld.Part1 = handle
                        weld.Parent = handle
                        handle.Anchored = false
                    end
                end
            end

            if clone:IsA("Accessory") then
                manualWeldAccessory(clone)
            else
                for _, child in ipairs(clone:GetChildren()) do
                    if child:IsA("Accessory") then
                        manualWeldAccessory(child)
                    end
                end
            end

            -- Wrap in a Folder instead of directly parenting the Accessory to Character
            -- This prevents Native Anti-Cheat from detecting unauthorized Accessories in Character!
            local localFolder = Instance.new("Folder")
            localFolder.Name = "IceHubEmoteHolder"
            localFolder.Parent = character
            clone.Parent = localFolder

            -- DEBUG TO SEE WHEN IT DESTROYS
            clone.AncestryChanged:Connect(function(_, newParent)
                if not newParent then
                    emoteDebugWarn("IceHub Debug -> Accessory DESTROYED OR REMOVED FROM WORKSPACE!")
                end
            end)

            state.activeVFX[#state.activeVFX + 1] = localFolder
            activateVFX(clone, entry)
            return true
        end

        state.startDirectVFX = state.startDirectVFX or function(entry)
            if not getgenv().emoteVFXEnabled then return false end
            local payload = nil
            state.vfxPayloadCache = state.vfxPayloadCache or {}
            local payloadCacheKey = tostring(entry and (entry.Animation and entry.Animation.AnimationId or entry.Id or entry.Name) or "")
            if state.vfxPayloadCache[payloadCacheKey] ~= nil then
                local cached = state.vfxPayloadCache[payloadCacheKey]
                payload = cached ~= false and cached or nil
            else
                pcall(function() payload = state.invokeGetEmoteVFX(entry) end)
                state.vfxPayloadCache[payloadCacheKey] = payload or false
            end

            emoteDebugWarn("IceHub Debug -> startDirectVFX called!")
            emoteDebugWarn("   entry.Name:", tostring(entry.Name))
            emoteDebugWarn("   entry.Id:", tostring(entry.Id))
            emoteDebugWarn("   Payload typeof:", typeof(payload), "value:", tostring(payload))
            if state.debugEmotes and payload then
                emoteDebugWarn("IceHub Debug -> Payload children:")
                local function printTree(node, depth)
                    for _, c in ipairs(node:GetChildren()) do
                        emoteDebugWarn(string.rep("  ", depth) .. "- " .. c.Name .. " (" .. c.ClassName .. ")")
                        printTree(c, depth + 1)
                    end
                end
                printTree(payload, 1)
            end

            local runVFX = state.runVFXModule(entry, payload)
            emoteDebugWarn("IceHub Debug -> runVFXModule result:", runVFX)
            if runVFX then return true end

            local success = false
            if payload and typeof(payload) == "Instance" then
                if state.materializeVFXPayload(payload, entry) then
                    emoteDebugWarn("IceHub Debug -> materializeVFXPayload SUCCESS")
                    success = true
                end
            end

            local accPayload = state.getEmoteAccessoryPayload(entry)
            if accPayload then
                emoteDebugWarn("IceHub Debug -> getEmoteAccessoryPayload FOUND:", accPayload.Name)
                if state.materializeVFXPayload(accPayload, entry) then
                    success = true
                end
            end

            if success then return true end

            local namedPayloads = state.findNamedVFX(entry, payload)

            -- DEBUG: Check EmoteAccessory ANYWHERE
            if state.debugEmotes then pcall(function()
                if not _G.DumpedEmoteAcc then
                    _G.DumpedEmoteAcc = true
                    local found = false
                    for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                        if obj.Name == "EmoteAccessory" or obj.Name == "EmoteAccessories" then
                            emoteDebugWarn("IceHub Debug -> FOUND EmoteAccessory AT:", obj:GetFullName())
                            found = true
                            local count = 0
                            for _, acc in ipairs(obj:GetChildren()) do
                                if count < 15 then
                                    emoteDebugWarn("   ", acc.Name, acc.ClassName)
                                    count = count + 1
                                end
                            end
                            break
                        end
                    end
                    if not found then
                        emoteDebugWarn("IceHub Debug -> EmoteAccessory NOT FOUND IN ReplicatedStorage!")
                    end
                end
            end) end

            emoteDebugWarn("IceHub Debug -> startDirectVFX found", type(namedPayloads) == "table" and #namedPayloads or 0, "payloads!")
            if state.debugEmotes and type(namedPayloads) == "table" then
                for i, p in ipairs(namedPayloads) do
                    emoteDebugWarn("IceHub Debug -> Payload", i, ":", p.Name, p.ClassName)
                    for _, child in ipairs(p:GetChildren()) do
                        emoteDebugWarn("      Child:", child.Name, child.ClassName)
                    end
                end
            end

            local success = false
            if type(namedPayloads) == "table" then
                for _, p in ipairs(namedPayloads) do
                    if state.materializeVFXPayload(p, entry) then
                        emoteDebugWarn("IceHub Debug -> materialize namedPayload SUCCESS:", p.Name)
                        success = true
                    end
                end
            end
            if success then return true end

            emoteDebugWarn("IceHub Debug -> EVERYTHING FAILED")
            return false
        end
        state.clearVFXStorage = state.clearVFXStorage or function()
            local objects = {}
            for _, object in ipairs(state.activeVFX) do
                objects[#objects + 1] = object
            end
            table.clear(state.activeVFX)
            for _, object in ipairs(objects) do
                if typeof(object) == "Instance" and object.Parent then
                    fadeOutEmoteVFX(object)
                end
            end
        end

        state.stopEmote = state.stopEmote or function()
            state.playToken += 1

            -- Kritik state'leri hemen sıfırla (senkron, hafif)
            local prevRunningConn = state.runningConnection
            state.runningConnection = nil
            local prevActiveTrack = state.activeTrack
            state.activeTrack = nil
            local prevMarkerConns = {}
            for i, c in ipairs(state.markerConnections) do prevMarkerConns[i] = c end
            table.clear(state.markerConnections)
            local prevSounds = {}
            for i, s in ipairs(state.activeSounds) do prevSounds[i] = s end
            table.clear(state.activeSounds)
            table.clear(state.firedMediaCues)
            table.clear(state.playedSoundKeys)
            local prevSelected = state.activeSelected
            local prevOriginal = state.activeOriginal
            state.activeOriginal = nil
            state.activeSelected = nil
            state.capturedVFXPayload = nil
            state.overrideUntil = 0
            state.boundCueTrack = nil
            state.boundCueToken = 0

            -- Ağır temizlik işlemlerini SONRAKİ FRAME'e taşı (task.defer = gerçek async)
            task.defer(function()
                if prevRunningConn then
                    pcall(function() prevRunningConn:Disconnect() end)
                end

                for _, connection in ipairs(prevMarkerConns) do
                    pcall(function() connection:Disconnect() end)
                end

                -- Aktif track'i durdur
                if prevActiveTrack then
                    pcall(function()
                        prevActiveTrack.Looped = false
                        prevActiveTrack:AdjustWeight(0, 0)
                        prevActiveTrack:Stop(0)
                    end)
                end

                -- Animator'daki emote track'lerini durdur
                pcall(function()
                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
                    if animator then
                        local activeIds = {}
                        if prevSelected and prevSelected.Animation then
                            local id = assetId(prevSelected.Animation.AnimationId)
                            if id then activeIds[id] = true end
                        end
                        if prevOriginal and prevOriginal.Animation then
                            local id = assetId(prevOriginal.Animation.AnimationId)
                            if id then activeIds[id] = true end
                        end
                        if prevActiveTrack and prevActiveTrack.Animation then
                            local id = assetId(prevActiveTrack.Animation.AnimationId)
                            if id then activeIds[id] = true end
                        end

                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            local trackId = assetId(track.Animation and track.Animation.AnimationId)
                            local trackName = normalize(track.Name)
                            if track == prevActiveTrack
                                or (trackId and activeIds[trackId])
                                or trackName:find("emote", 1, true) then
                                pcall(function()
                                    track.Looped = false
                                    track:AdjustWeight(0, 0)
                                    track:Stop(0)
                                end)
                            end
                        end
                    end
                end)

                -- Sesleri durdur ve yok et
                for _, sound in ipairs(prevSounds) do
                    pcall(function()
                        sound:Stop()
                        sound:Destroy()
                    end)
                end

                -- VFX temizliği
                state.clearVFXStorage()
            end)
        end

        state.playAssociatedSounds = state.playAssociatedSounds or function(entry, allowReplay)
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local playToken = state.playToken
            local played = false
            local aliases = {
                [normalize(entry.Name)] = true,
                [normalize(entry.Id)] = true,
                [normalize(entry.Animation.AnimationId)] = true,
            }
            for _, value in pairs(entry.Attributes or {}) do
                aliases[normalize(tostring(value))] = true
            end

            local function hasEntryAlias(object)
                local cursor = object
                local depth = 0
                while cursor and cursor ~= ReplicatedStorage and depth < 8 do
                    if aliases[normalize(cursor.Name)] then return true end
                    local ok, attrs = pcall(function()
                        return cursor:GetAttributes()
                    end)
                    if ok and attrs then
                        for key, value in pairs(attrs) do
                            local lowered = normalize(key)
                            if (lowered:find("emote", 1, true)
                                or lowered:find("animation", 1, true)
                                or lowered:find("id", 1, true)
                                or lowered:find("name", 1, true))
                                and aliases[normalize(tostring(value))] then
                                return true
                            end
                        end
                    end
                    cursor = cursor.Parent
                    depth += 1
                end
                return false
            end

            local function getSoundDelay(sound)
                local names = {
                    "IceHubSoundTime",
                    "IceHubSoundDelay",
                    "SoundTime",
                    "SoundDelay",
                    "SFXTime",
                    "AudioTime",
                    "MusicTime",
                    "StartTime",
                    "Delay",
                    "Time",
                    "CueTime",
                }
                local cursor = sound
                local depth = 0
                while cursor and cursor ~= ReplicatedStorage and depth < 5 do
                    local value = getInstanceAttribute(cursor, names)
                    if value ~= nil then
                        if type(value) == "string" then
                            value = tonumber(value:gsub(",", "."))
                        else
                            value = tonumber(value)
                        end
                        if value then return math.max(value, 0) end
                    end
                    cursor = cursor.Parent
                    depth += 1
                end
                return 0
            end

            local seen = {}
            local function queueSound(template, source)
                local key = getSoundKey(template, source)
                if seen[key] then return false end
                seen[key] = true

                local delayTime = getSoundDelay(template)
                if delayTime > 0 then
                    task.delay(delayTime, function()
                        if state.destroyed or state.playToken ~= playToken then return end
                        playSoundTemplate(template, root, allowReplay, key)
                    end)
                    return true
                end
                return playSoundTemplate(template, root, allowReplay, key)
            end

            for _, object in ipairs(entry.Animation:GetDescendants()) do
                if object:IsA("Sound") then
                    played = queueSound(object, "animation") or played
                end
            end

            for key, value in pairs(entry.Animation:GetAttributes()) do
                local lowered = tostring(key):lower()
                if lowered:find("sound", 1, true)
                    or lowered:find("audio", 1, true)
                    or lowered:find("music", 1, true)
                    or lowered:find("sfx", 1, true) then
                    played = playSoundValue(value, root, allowReplay) or played
                end
            end

            state.entrySoundCache = state.entrySoundCache or {}
            local soundCacheKey = tostring(entry.Animation and entry.Animation.AnimationId or entry.Id or entry.Name)
            local cachedSounds = state.entrySoundCache[soundCacheKey]
            if not cachedSounds then
                cachedSounds = {}
                if os.clock() - soundIndexLastUpdate > 15 or not next(soundIndexByName) then
                    rebuildSoundIndex()
                end
                for _, sound in pairs(soundIndexByName) do
                    if hasEntryAlias(sound) then
                        cachedSounds[#cachedSounds + 1] = sound
                    end
                end
                state.entrySoundCache[soundCacheKey] = cachedSounds
            end
            for _, object in ipairs(cachedSounds) do
                if typeof(object) == "Instance" and object.Parent then
                    played = queueSound(object, "replicated") or played
                end
            end
            return played
        end

        state.getMediaCueSpec = state.getMediaCueSpec or function(entry, kind)
            local timeNames
            local markerNames
            if kind == "VFX" then
                timeNames = {
                    "IceHubVFXTime",
                    "IceHubVFXDelay",
                    "VFXTime",
                    "VFXDelay",
                    "EffectTime",
                    "EffectDelay",
                    "IceHubCueTime",
                    "CueTime",
                }
                markerNames = {
                    "IceHubVFXMarker",
                    "VFXMarker",
                    "EffectMarker",
                    "PlayVFXMarker",
                    "IceHubCueMarker",
                    "CueMarker",
                }
            else
                timeNames = {
                    "IceHubSoundTime",
                    "IceHubSoundDelay",
                    "SoundTime",
                    "SoundDelay",
                    "SFXTime",
                    "AudioTime",
                    "IceHubCueTime",
                    "CueTime",
                }
                markerNames = {
                    "IceHubSoundMarker",
                    "SoundMarker",
                    "SFXMarker",
                    "AudioMarker",
                    "PlaySoundMarker",
                    "IceHubCueMarker",
                    "CueMarker",
                }
            end

            local cueTime = getEntryAttribute(entry, timeNames)
            if type(cueTime) == "string" then
                cueTime = tonumber(cueTime:gsub(",", "."))
            else
                cueTime = tonumber(cueTime)
            end

            local marker = getEntryAttribute(entry, markerNames)
            if marker ~= nil then marker = tostring(marker) end

            return {
                Time = cueTime and math.max(cueTime, 0) or nil,
                Marker = marker and marker ~= "" and marker or nil,
            }
        end

        state.getVFXObjectCueSpec = state.getVFXObjectCueSpec or function(object, entry)
            local names = {
                "IceHubVFXTime",
                "VFXTime",
                "EffectTime",
                "StartTime",
                "CueTime",
                "EmitDelay",
                "VFXDelay",
                "EffectDelay",
            }
            local cleanupNames = {
                "IceHubVFXDuration",
                "VFXDuration",
                "EffectDuration",
                "Duration",
                "Lifetime",
                "LifeTime",
                "DestroyAfter",
                "RemoveAfter",
                "CleanupTime",
            }
            local markerNames = {
                "IceHubVFXMarker",
                "VFXMarker",
                "EffectMarker",
                "CueMarker",
            }

            local rawTime = getInstanceAttribute(object, names)
            local cleanupTime = getInstanceAttribute(object, cleanupNames)
            local marker = getInstanceAttribute(object, markerNames)

            if type(rawTime) == "string" then
                rawTime = tonumber(rawTime:gsub(",", "."))
            else
                rawTime = tonumber(rawTime)
            end

            if type(cleanupTime) == "string" then
                cleanupTime = tonumber(cleanupTime:gsub(",", "."))
            else
                cleanupTime = tonumber(cleanupTime)
            end

            if marker ~= nil then marker = tostring(marker) end

            return {
                Time = rawTime and math.max(rawTime, 0) or nil,
                CleanupTime = cleanupTime and math.max(cleanupTime, 0) or nil,
                Marker = marker and marker ~= "" and marker or nil,
            }
        end

        state.resetMediaCues = state.resetMediaCues or function(playToken)
            state.mediaCueToken = playToken
            table.clear(state.firedMediaCues)
            state.lastVFXCueKey = nil
        end

        state.mediaCueFired = state.mediaCueFired or function(playToken, key)
            return state.mediaCueToken == playToken
                and state.firedMediaCues
                and key ~= nil
                and state.firedMediaCues[key] == true
        end

        state.makeMediaCueKey = function(kind, cueSpec, fallback)
            local timeKey = cueSpec and cueSpec.Time ~= nil and tostring(math.floor(cueSpec.Time * 1000 + 0.5)) or "na"
            local markerKey = cueSpec and cueSpec.Marker or "na"
            return table.concat({kind, timeKey, markerKey, fallback or ""}, ":")
        end

        state.fireMediaCue = function(kind, entry, playToken, cueKey)
            if state.destroyed or state.playToken ~= playToken then return false end
            if state.mediaCueToken ~= playToken then state.resetMediaCues(playToken) end
            if cueKey and state.mediaCueFired(playToken, cueKey) then return true end

            if kind == "VFX" then
                if not getgenv().emoteVFXEnabled then return false end
                if cueKey and state.lastVFXCueKey and state.lastVFXCueKey ~= cueKey then
                    state.clearVFXStorage()
                end
                local ok = state.startDirectVFX(entry)
                if ok then
                    state.firedMediaCues[cueKey or state.makeMediaCueKey(kind, nil, "direct")] = true
                    state.lastVFXCueKey = cueKey or state.lastVFXCueKey
                    getgenv().emoteVFXStatus = "VFX active: synced cue"
                end
                return ok
            end

            if cueKey then
                state.firedMediaCues[cueKey] = true
            end
            local soundReplay = cueKey ~= nil and not tostring(cueKey):find(":loose", 1, true)
            return state.playAssociatedSounds(entry, soundReplay)
        end

        state.cueNameMatches = function(kind, cueSpec, name)
            local key = normalize(name)
            if key == "" then return false end
            if cueSpec.Marker and normalize(cueSpec.Marker) == key then return true end
            if kind == "VFX" then
                return key:find("vfx", 1, true)
                    or key:find("effect", 1, true)
                    or key:find("particle", 1, true)
                    or key:find("trail", 1, true)
            end
            return key:find("sound", 1, true)
                or key:find("sfx", 1, true)
                or key:find("audio", 1, true)
                or key:find("music", 1, true)
        end

        state.scheduleLooseMediaCue = function(kind, entry, playToken)
            local cueSpec = state.getMediaCueSpec(entry, kind)
            local cueKey = state.makeMediaCueKey(kind, cueSpec, "loose")
            if cueSpec.Marker and not cueSpec.Time then return end
            local elapsed = math.max(os.clock() - (state.mediaStartedAt or os.clock()), 0)
            local delayTime
            if cueSpec.Time then
                delayTime = math.max(cueSpec.Time - elapsed, 0)
            else
                local deadline = os.clock() + 0.2
                while state.playToken == playToken
                    and not state.destroyed
                    and not state.activeTrack
                    and os.clock() < deadline do
                    RunService.Heartbeat:Wait()
                end
                local track = state.activeTrack
                local ratio = kind == "VFX" and 0.52 or 0.24
                if track and tonumber(track.Length) and track.Length > 0 then
                    delayTime = math.max((track.Length * ratio) - elapsed, 0)
                else
                    delayTime = kind == "VFX" and 0.55 or 0.22
                end
            end

            task.delay(delayTime, function()
                state.fireMediaCue(kind, entry, playToken, cueKey)
            end)
        end

        state.getAnimationMarkerSpecs = state.getAnimationMarkerSpecs or function(entry)
            state.animationMarkerCache = state.animationMarkerCache or {}
            local id = entry and entry.Animation and assetId(entry.Animation.AnimationId)
            if not id then return {} end
            if state.animationMarkerCache[id] then return state.animationMarkerCache[id] end

            local specs = {}
            local fetchDone = false
            local sequence = nil
            task.spawn(function()
                local ok2, seq2 = pcall(function()
                    return game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync("rbxassetid://" .. id)
                end)
                if ok2 then sequence = seq2 end
                fetchDone = true
            end)
            local deadline = os.clock() + 1.0
            while not fetchDone and os.clock() < deadline do
                RunService.Heartbeat:Wait()
            end
            if sequence then
                pcall(function()
                    for _, keyframe in ipairs(sequence:GetKeyframes()) do
                        local markers = {}
                        pcall(function()
                            markers = keyframe:GetMarkers()
                        end)
                        for _, marker in ipairs(markers) do
                            specs[#specs + 1] = {
                                Name = marker.Name,
                                Value = marker.Value,
                                Time = keyframe.Time,
                            }
                        end
                    end
                end)
                pcall(function() sequence:Destroy() end)
            end

            table.sort(specs, function(left, right)
                return (left.Time or 0) < (right.Time or 0)
            end)
            state.animationMarkerCache[id] = specs
            return specs
        end

        state.bindTrackMarkers = function(track, playToken, entry)
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then return end

            if state.boundCueTrack == track and state.boundCueToken == playToken then
                return
            end
            state.boundCueTrack = track
            state.boundCueToken = playToken

            local stoppedConnection = track.Stopped:Connect(function()
                -- Native emote VFX can outlive the animation; stopEmote handles explicit cleanup.
            end)
            state.markerConnections[#state.markerConnections + 1] = stoppedConnection



            local vfxCue = state.getMediaCueSpec(entry, "VFX")
            local soundCue = state.getMediaCueSpec(entry, "Sound")

            local function bindTimedCue(kind, cueSpec)
                if not cueSpec.Time then return end
                local cueKey = state.makeMediaCueKey(kind, cueSpec, "time")
                task.spawn(function()
                    while state.playToken == playToken and not state.destroyed and track do
                        if track.TimePosition >= cueSpec.Time then break end
                        if not track.IsPlaying and track.TimePosition > 0 then return end
                        RunService.Heartbeat:Wait()
                    end
                    if state.playToken == playToken and not state.destroyed then
                        state.fireMediaCue(kind, entry, playToken, cueKey)
                    end
                end)
            end

            bindTimedCue("VFX", vfxCue)
            bindTimedCue("Sound", soundCue)

            local keyframeConnection = track.KeyframeReached:Connect(function(keyframeName)
                if state.playToken ~= playToken then return end
                if state.cueNameMatches("VFX", vfxCue, keyframeName) then
                    state.fireMediaCue("VFX", entry, playToken, state.makeMediaCueKey("VFX", vfxCue, keyframeName))
                end
                if state.cueNameMatches("Sound", soundCue, keyframeName) then
                    state.fireMediaCue("Sound", entry, playToken, state.makeMediaCueKey("Sound", soundCue, keyframeName))
                end
            end)
            state.markerConnections[#state.markerConnections + 1] = keyframeConnection

            for _, markerName in ipairs({
                "Sound",
                "SFX",
                "Audio",
                "Music",
                "PlaySound",
                "VFX",
                "Effect",
                "PlayVFX",
            }) do
                local connection = track:GetMarkerReachedSignal(markerName):Connect(function(value)
                    if state.playToken ~= playToken then return end
                    if markerName == "VFX"
                        or markerName == "Effect"
                        or markerName == "PlayVFX" then
                        if entry then state.fireMediaCue("VFX", entry, playToken, state.makeMediaCueKey("VFX", vfxCue, markerName)) end
                    else
                        if value ~= nil and tostring(value) ~= "" then
                            playSoundValue(value, root, true)
                            if state.mediaCueToken ~= playToken then state.resetMediaCues(playToken) end
                            state.firedMediaCues[state.makeMediaCueKey("Sound", soundCue, markerName .. ":" .. tostring(value))] = true
                        else
                            state.fireMediaCue("Sound", entry, playToken, state.makeMediaCueKey("Sound", soundCue, markerName))
                        end
                    end
                end)
                state.markerConnections[#state.markerConnections + 1] = connection
            end

            for _, markerSpec in ipairs(state.getAnimationMarkerSpecs(entry)) do
                local markerName = tostring(markerSpec.Name or "")
                if markerName ~= "" then
                    local cueKey = state.makeMediaCueKey("Sound", soundCue, "anim:" .. markerName .. ":" .. tostring(markerSpec.Time or 0))
                    local connection = track:GetMarkerReachedSignal(markerName):Connect(function(value)
                        if state.playToken ~= playToken then return end
                        local payload = value
                        if payload == nil or tostring(payload) == "" then
                            payload = markerSpec.Value
                        end
                        local played = false
                        if payload ~= nil and tostring(payload) ~= "" then
                            played = playSoundValue(payload, root, true)
                        end
                        if not played then
                            played = playSoundValue(markerName, root, true)
                        end
                        if played then
                            if state.mediaCueToken ~= playToken then state.resetMediaCues(playToken) end
                            state.firedMediaCues[cueKey] = true
                        elseif state.cueNameMatches("Sound", soundCue, markerName) then
                            state.fireMediaCue("Sound", entry, playToken, cueKey)
                        end
                    end)
                    state.markerConnections[#state.markerConnections + 1] = connection

                    if markerSpec.Time and markerSpec.Time > 0 then
                        task.spawn(function()
                            while state.playToken == playToken and not state.destroyed and track do
                                if track.TimePosition >= markerSpec.Time then break end
                                if not track.IsPlaying and track.TimePosition > 0 then return end
                                RunService.Heartbeat:Wait()
                            end
                            if state.playToken ~= playToken
                                or state.destroyed
                                or state.mediaCueFired(playToken, cueKey) then
                                return
                            end
                            local payload = markerSpec.Value
                            local played = false
                            if payload ~= nil and tostring(payload) ~= "" then
                                played = playSoundValue(payload, root, true)
                            end
                            if not played then
                                played = playSoundValue(markerName, root, true)
                            end
                            if played then
                                if state.mediaCueToken ~= playToken then state.resetMediaCues(playToken) end
                                state.firedMediaCues[cueKey] = true
                            elseif state.cueNameMatches("Sound", soundCue, markerName) then
                                state.fireMediaCue("Sound", entry, playToken, cueKey)
                            end
                        end)
                    end
                end
            end

            if vfxCue.Marker then
                local connection = track:GetMarkerReachedSignal(vfxCue.Marker):Connect(function()
                    state.fireMediaCue("VFX", entry, playToken, state.makeMediaCueKey("VFX", vfxCue, "explicit"))
                end)
                state.markerConnections[#state.markerConnections + 1] = connection
            end
            if soundCue.Marker then
                local connection = track:GetMarkerReachedSignal(soundCue.Marker):Connect(function(value)
                    if value ~= nil and tostring(value) ~= "" then
                        playSoundValue(value, root, true)
                        if state.mediaCueToken ~= playToken then state.resetMediaCues(playToken) end
                        state.firedMediaCues[state.makeMediaCueKey("Sound", soundCue, "explicit:" .. tostring(value))] = true
                    else
                        state.fireMediaCue("Sound", entry, playToken, state.makeMediaCueKey("Sound", soundCue, "explicit"))
                    end
                end)
                state.markerConnections[#state.markerConnections + 1] = connection
            end
        end

        state.captureTrack = function(entry, playToken)
            task.spawn(function()
                local deadline = os.clock() + 1.5
                while not state.destroyed and state.playToken == playToken and os.clock() <= deadline do
                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
                    if animator then
                        local wantedId = assetId(entry.Animation.AnimationId)
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            local trackId = assetId(track.Animation and track.Animation.AnimationId)
                            if wantedId and trackId == wantedId then
                                state.activeTrack = track
                                track.Looped = true
                                state.bindTrackMarkers(track, playToken, entry)
                                task.spawn(function()
                                    while state.playToken == playToken and not state.destroyed and track and track.Length <= 0 do
                                        task.wait(0.1)
                                    end
                                    if state.playToken == playToken and not state.destroyed and track and track.Length > 0 then
                                        local loopStart = math.max(track.Length - 2.5, track.Length * 0.5)
                                        while state.playToken == playToken and not state.destroyed and track.IsPlaying do
                                            if not getgenv().emoteLooped and track.TimePosition >= track.Length - 0.08 then
                                                track.TimePosition = loopStart
                                            end
                                            task.wait(0.03)
                                        end
                                    end
                                end)
                                return
                            end
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end

        state.playLocalFallback = function(entry, playToken)
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and (
                humanoid:FindFirstChildOfClass("Animator")
                or Instance.new("Animator", humanoid)
            )
            if not animator then return false end

            local wantedId = assetId(entry.Animation and entry.Animation.AnimationId)
            local originalId = state.activeOriginal and state.activeOriginal.Animation and assetId(state.activeOriginal.Animation.AnimationId)
            for _, playingTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                local trackId = assetId(playingTrack.Animation and playingTrack.Animation.AnimationId)
                local trackName = normalize(playingTrack.Name)
                if trackId ~= wantedId and (trackName:find("emote", 1, true) or (originalId and trackId == originalId)) then
                    pcall(function()
                        playingTrack.Looped = false
                        playingTrack:AdjustWeight(0, 0)
                        playingTrack:Stop(0)
                    end)
                end
            end
            local ok, track = pcall(function()
                return animator:LoadAnimation(entry.Animation)
            end)
            if not ok or not track then return false end

            state.activeTrack = track
            track.Priority = Enum.AnimationPriority.Action4
            track.Looped = true
            track:Play(0.15)
            state.bindTrackMarkers(track, playToken, entry)
            task.spawn(function()
                while state.playToken == playToken and not state.destroyed and track and track.Length <= 0 do
                    task.wait(0.1)
                end
                if state.playToken == playToken and not state.destroyed and track and track.Length > 0 then
                    local loopStart = math.max(track.Length - 2.5, track.Length * 0.5)
                    while state.playToken == playToken and not state.destroyed and track.IsPlaying do
                        if not getgenv().emoteLooped and track.TimePosition >= track.Length - 0.08 then
                            track.TimePosition = loopStart
                        end
                        task.wait(0.03)
                    end
                end
            end)

            return true
        end

        state.fireNative = function(dispatcher)
            -- Önce callback'leri dene (en hızlı yol, executor overhead'i yok)
            for _, callback in ipairs(dispatcher.Callbacks) do
                if pcall(callback) then return true end
            end
            -- Sonra connection.Fire dene
            for _, connection in ipairs(dispatcher.Connections) do
                local ok = pcall(function()
                    if type(connection.Fire) == "function" then
                        connection:Fire()
                    end
                end)
                if ok then return true end
            end
            -- En son firesignal dene (bazı executörlerde yavaş)
            local fireSignal = getExecutorGlobal("firesignal")
            if type(fireSignal) == "function" and pcall(fireSignal, dispatcher.Signal) then
                return true
            end
            return false
        end
        state.playEmote = function(name)
            state.stopEmote()
            if #state.catalog == 0 then refreshCatalog() end

            local entry = resolveEntry(name)
            if not entry then return false, "Emote not found" end
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                return false, "Character is not ready"
            end

            state.playToken += 1
            local playToken = state.playToken
            state.activeSelected = entry
            state.capturedVFXPayload = nil
            state.mediaStartedAt = os.clock()
            state.resetMediaCues(playToken)

            -- Running bağlantısı (hafif, senkron kalabilir)
            if state.runningConnection then pcall(function() state.runningConnection:Disconnect() end) end
            state.runningConnection = humanoid.Running:Connect(function(speed)
                if speed > 0.1 then
                    state.stopEmote()
                end
            end)

            -- TÜM ağır işleri sonraki frame'e taşı (task.defer = gerçek async, task.spawn DEĞİL)
            task.defer(function()
                if state.destroyed or state.playToken ~= playToken then return end

                -- Observers'u başlat
                pcall(initializeEmoteObservers)

                -- Hooks kontrolü
                local hooksReady = hooks.animator
                    or hooks.humanoid
                    or hooks.clone
                    or hooks.bindableFunction
                    or hooks.bindableEvent
                    or hooks.remoteEvent
                    or hooks.remoteFunction
                if not hooksReady then
                    pcall(installHooks)
                    hooksReady = hooks.animator
                        or hooks.humanoid
                        or hooks.clone
                        or hooks.bindableFunction
                        or hooks.bindableEvent
                        or hooks.remoteEvent
                        or hooks.remoteFunction
                end
                local nativeAnimationHooksReady = hooks.animator or hooks.humanoid

                if state.destroyed or state.playToken ~= playToken then return end

                -- Dispatcher kontrolü (cache'den)
                local dispatcher = state.nativeDispatcher
                if dispatcher then
                    local valid = false
                    pcall(function()
                        valid = dispatcher.WheelContent and dispatcher.WheelContent.Parent ~= nil
                    end)
                    if not (valid and type(dispatcher.Callbacks) == "table" and #dispatcher.Callbacks > 0 and sameEntry(dispatcher.Original, entry)) then
                        dispatcher = nil
                    end
                end

                -- Dispatcher yoksa arka planda ara
                if not dispatcher then
                    dispatcher = findNativeDispatcher(entry)
                end

                if state.destroyed or state.playToken ~= playToken then return end

                local nativeStarted = false
                getgenv().emoteVFXStatus = "Waiting for native VFX"

                if dispatcher and nativeAnimationHooksReady then
                    state.activeOriginal = dispatcher.Original
                    state.overrideUntil = os.clock() + 8

                    -- Sound cue'ları sonraki frame'e taşı (getUpvalues ağır)
                    task.defer(function()
                        if state.destroyed or state.playToken ~= playToken then return end
                        state.scheduleNativeSoundCues(dispatcher, entry, playToken)
                    end)

                    nativeStarted = state.fireNative(dispatcher)
                    state.captureTrack(entry, playToken)
                elseif not dispatcher then
                    getgenv().emoteVFXStatus = "Native emote dispatcher not found — direct VFX mode"
                    state.scheduleLooseMediaCue("Sound", entry, playToken)
                else
                    getgenv().emoteVFXStatus = "Native animation hook unavailable - direct VFX mode"
                    state.scheduleLooseMediaCue("Sound", entry, playToken)
                end

                -- Dispatcher bulunamasa bile VFX'i cue zamanina gore direkt dene
                if not nativeStarted and getgenv().emoteVFXEnabled then
                    state.scheduleLooseMediaCue("VFX", entry, playToken)
                end

                task.delay(0.18, function()
                    if state.destroyed or state.playToken ~= playToken then return end
                    state.playAssociatedSounds(entry, false)
                end)

                local nativeProbeDelay = nativeStarted and 0.85 or 0.3
                task.delay(nativeProbeDelay, function()
                    if state.destroyed
                        or state.playToken ~= playToken
                        or not getgenv().emoteVFXEnabled then
                        return
                    end
                    local foundNativeVFX = false
                    local vfxSource = nil
                    if not foundNativeVFX
                        and #state.activeVFX == 0
                        and not state.mediaCueFired(playToken, state.makeMediaCueKey("VFX", state.getMediaCueSpec(entry, "VFX"), "loose")) then
                        if nativeStarted and state.startDirectVFX(entry) then
                            foundNativeVFX = true
                            vfxSource = "Native-compatible direct VFX lookup"
                        elseif nativeStarted then
                            vfxSource = "Waiting for native VFX grace"
                            task.delay(0.65, function()
                                if state.destroyed
                                    or state.playToken ~= playToken
                                    or #state.activeVFX > 0
                                    or state.mediaCueFired(playToken, state.makeMediaCueKey("VFX", state.getMediaCueSpec(entry, "VFX"), "loose")) then
                                    return
                                end
                                state.scheduleLooseMediaCue("VFX", entry, playToken)
                            end)
                        else
                            state.scheduleLooseMediaCue("VFX", entry, playToken)
                            vfxSource = "Direct GetEmoteVFX lookup (synced fallback)"
                        end
                    end
                    if foundNativeVFX then
                        state.lastVFXCueKey = state.lastVFXCueKey or state.makeMediaCueKey("VFX", state.getMediaCueSpec(entry, "VFX"), "native")
                        getgenv().emoteVFXStatus = "VFX active: " .. tostring(vfxSource)
                    elseif vfxSource then
                        getgenv().emoteVFXStatus = "Waiting for synced VFX cue: " .. tostring(vfxSource)
                    else
                        getgenv().emoteVFXStatus = "VFX not found | roots=" .. tostring(#getEmoteVFXRoots())
                            .. " BF=" .. tostring(hooks.bindableFunction)
                            .. " BE=" .. tostring(hooks.bindableEvent)
                            .. " RE=" .. tostring(hooks.remoteEvent)
                            .. " RF=" .. tostring(hooks.remoteFunction)
                    end
                end)

                task.delay(8, function()
                    if state.destroyed or state.playToken ~= playToken then return end
                    state.activeOriginal = nil
                    state.overrideUntil = 0
                end)

                -- Fallback animasyonu
                task.delay(nativeStarted and 0.35 or 0.15, function()
                    if state.destroyed or state.playToken ~= playToken then return end
                    if not state.activeTrack then state.playLocalFallback(entry, playToken) end
                end)
            end)

            return true, "Starting emote"
        end

        getgenv().refreshBladeBallEmotes = refreshCatalog
        getgenv().playEmote = state.playEmote
        getgenv().stopEmote = state.stopEmote
        getgenv().setBladeBallEmoteUnlock = function(enabled)
            local wasEnabled = state.emoteWheelEnabled == true
            getgenv().emoteVFXEnabled = enabled == true
            state.emoteWheelEnabled = enabled == true

            if state.emoteWheelEnabled then
                if #state.catalog == 0 then refreshCatalog() end
                -- Hooks ve observers'ı arka planda önceden hazırla (lag fix)
                task.defer(function()
                    pcall(installHooks)
                end)
                task.defer(function()
                    pcall(initializeEmoteObservers)
                end)
                task.defer(function()
                    pcall(findNativeDispatcher)
                end)
                if wasEnabled then
                    if state.updateCustomWheel then state.updateCustomWheel() end
                    task.defer(state.applyEmoteWheelList)
                else
                    state.initializeEmoteWheelList()
                end
            else
                state.stopEmote()
                state.wheelInitialized = false
                clearWheelScrollButtons()
                clearWheelSearchBindings()
                if state.customWheelConn then
                    pcall(function() state.customWheelConn:Disconnect() end)
                    state.customWheelConn = nil
                end
                if state.customWheelGui then
                    pcall(function() state.customWheelGui:Destroy() end)
                    state.customWheelGui = nil
                end
                if state.customWheelButtonGui then
                    pcall(function() state.customWheelButtonGui:Destroy() end)
                    state.customWheelButtonGui = nil
                end
                if state.wheelConnection then
                    pcall(function() state.wheelConnection:Disconnect() end)
                    state.wheelConnection = nil
                end
            end
        end
        getgenv().installBladeBallEmoteWheel = function()
            getgenv().setBladeBallEmoteUnlock(true)
            return state.applyEmoteWheelList()
        end

        state.Destroy = function()
            state.destroyed = true
            state.stopEmote()
            if state.diedConnection then state.diedConnection:Disconnect() end
            if state.characterConnection then state.characterConnection:Disconnect() end
            if state.runningConnection then pcall(function() state.runningConnection:Disconnect() end) end
            if state.wheelConnection then pcall(function() state.wheelConnection:Disconnect() end) end
            if state.customWheelConn then pcall(function() state.customWheelConn:Disconnect() end) end
            if state.customWheelGui then pcall(function() state.customWheelGui:Destroy() end) end
            if state.customWheelButtonGui then pcall(function() state.customWheelButtonGui:Destroy() end) end
            clearWheelScrollButtons()
            clearWheelSearchBindings()
            if hooks.activeState == state then hooks.activeState = nil end
        end

        state.bindCharacter = function(character)
            if state.diedConnection then state.diedConnection:Disconnect() end
            local humanoid = character:WaitForChild("Humanoid", 10)
            if humanoid then state.diedConnection = humanoid.Died:Connect(state.stopEmote) end
        end

        state.characterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
            state.stopEmote()
            task.defer(state.bindCharacter, character)
        end)
        if LocalPlayer.Character then task.defer(state.bindCharacter, LocalPlayer.Character) end
    end)()



    getgenv().playerCosmeticsEnabled = getgenv().playerCosmeticsEnabled or false
    do
        local cosmeticsActive=false
        local headLoop=nil
        local cosmeticsCharacterAddedConnection=nil
        getgenv().PlayerCosmeticsCleanup=getgenv().PlayerCosmeticsCleanup or {}

        local function applyKorblox(character)
            local rightLeg=character and (character:FindFirstChild("RightLeg") or character:FindFirstChild("Right Leg"))
            if not rightLeg then return end
            for _,child in pairs(rightLeg:GetChildren()) do
                if child:IsA("SpecialMesh") then child:Destroy() end
            end
            local specialMesh=Instance.new("SpecialMesh")
            specialMesh.MeshId="rbxassetid://101851696"
            specialMesh.TextureId="rbxassetid://115727863"
            specialMesh.Scale=Vector3.new(1,1,1)
            specialMesh.Parent=rightLeg
        end

        local function saveRightLegProperties(char)
            local rightLeg=char and (char:FindFirstChild("RightLeg") or char:FindFirstChild("Right Leg"))
            if not rightLeg then return end
            local originalMesh=rightLeg:FindFirstChildOfClass("SpecialMesh")
            if originalMesh then
                getgenv().PlayerCosmeticsCleanup.originalMeshId=originalMesh.MeshId
                getgenv().PlayerCosmeticsCleanup.originalTextureId=originalMesh.TextureId
                getgenv().PlayerCosmeticsCleanup.originalScale=originalMesh.Scale
            else
                getgenv().PlayerCosmeticsCleanup.hadNoMesh=true
            end
            getgenv().PlayerCosmeticsCleanup.rightLegChildren={}
            for _,child in pairs(rightLeg:GetChildren()) do
                if child:IsA("SpecialMesh") then
                    table.insert(getgenv().PlayerCosmeticsCleanup.rightLegChildren,{
                        ClassName=child.ClassName,
                        Properties={MeshId=child.MeshId,TextureId=child.TextureId,Scale=child.Scale},
                    })
                end
            end
        end

        local function restoreRightLeg(char)
            local rightLeg=char and (char:FindFirstChild("RightLeg") or char:FindFirstChild("Right Leg"))
            if not rightLeg or not getgenv().PlayerCosmeticsCleanup.rightLegChildren then return end
            for _,child in pairs(rightLeg:GetChildren()) do
                if child:IsA("SpecialMesh") then child:Destroy() end
            end
            if getgenv().PlayerCosmeticsCleanup.hadNoMesh then return end
            for _,childData in ipairs(getgenv().PlayerCosmeticsCleanup.rightLegChildren) do
                if childData.ClassName=="SpecialMesh" then
                    local newMesh=Instance.new("SpecialMesh")
                    newMesh.MeshId=childData.Properties.MeshId
                    newMesh.TextureId=childData.Properties.TextureId
                    newMesh.Scale=childData.Properties.Scale
                    newMesh.Parent=rightLeg
                end
            end
        end

        getgenv().updatePlayerCosmetics=function()
            if not getgenv().playerCosmeticsEnabled then
                cosmeticsActive=false
                if cosmeticsCharacterAddedConnection then cosmeticsCharacterAddedConnection:Disconnect(); cosmeticsCharacterAddedConnection=nil end
                if headLoop then task.cancel(headLoop); headLoop=nil end
                local char=LocalPlayer.Character
                if char then
                    local head=char:FindFirstChild("Head")
                    if head and getgenv().PlayerCosmeticsCleanup.headTransparency~=nil then
                        head.Transparency=getgenv().PlayerCosmeticsCleanup.headTransparency
                        if getgenv().PlayerCosmeticsCleanup.faceDecalId then
                            local newDecal=head:FindFirstChildOfClass("Decal") or Instance.new("Decal",head)
                            newDecal.Name=getgenv().PlayerCosmeticsCleanup.faceDecalName or "face"
                            newDecal.Texture=getgenv().PlayerCosmeticsCleanup.faceDecalId
                            newDecal.Face=Enum.NormalId.Front
                        end
                    end
                    restoreRightLeg(char)
                end
                getgenv().PlayerCosmeticsCleanup={}
                return
            end

            cosmeticsActive=true
            getgenv().Config=getgenv().Config or {}
            getgenv().Config.Headless=true
            if LocalPlayer.Character then
                local head=LocalPlayer.Character:FindFirstChild("Head")
                if head and getgenv().Config.Headless then
                    getgenv().PlayerCosmeticsCleanup.headTransparency=head.Transparency
                    local decal=head:FindFirstChildOfClass("Decal")
                    if decal then
                        getgenv().PlayerCosmeticsCleanup.faceDecalId=decal.Texture
                        getgenv().PlayerCosmeticsCleanup.faceDecalName=decal.Name
                    end
                end
                saveRightLegProperties(LocalPlayer.Character)
                applyKorblox(LocalPlayer.Character)
            end

            cosmeticsCharacterAddedConnection=LocalPlayer.CharacterAdded:Connect(function(char)
                local head=char:WaitForChild("Head",5)
                if head and getgenv().Config.Headless then
                    getgenv().PlayerCosmeticsCleanup.headTransparency=head.Transparency
                    local decal=head:FindFirstChildOfClass("Decal")
                    if decal then
                        getgenv().PlayerCosmeticsCleanup.faceDecalId=decal.Texture
                        getgenv().PlayerCosmeticsCleanup.faceDecalName=decal.Name
                    end
                end
                local rightLeg=char:WaitForChild("RightLeg",0.1) or char:WaitForChild("Right Leg",0.1)
                if rightLeg then applyKorblox(char) end
            end)

            if getgenv().Config.Headless then
                headLoop=task.spawn(function()
                    while cosmeticsActive do
                        local char=LocalPlayer.Character
                        if char then
                            local head=char:FindFirstChild("Head")
                            if head then
                                head.Transparency=1
                                local decal=head:FindFirstChildOfClass("Decal")
                                if decal then decal:Destroy() end
                            end
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end
    end

    -- ═══ BACKEND: HIT SOUNDS ══════════════════════════════════════════
    getgenv().hitSoundsEnabled = getgenv().hitSoundsEnabled or false
    getgenv().hitSoundVolume = getgenv().hitSoundVolume or 5
    getgenv().hitSoundType = getgenv().hitSoundType or "Medal"
    getgenv()._lhxHitSoundIds = {
        ["Medal"]           = "rbxassetid://6607336718",
        ["Fatality"]        = "rbxassetid://6607113255",
        ["Skeet"]           = "rbxassetid://6607204501",
        ["Switches"]        = "rbxassetid://6607173363",
        ["Rust Headshot"]   = "rbxassetid://138750331387064",
        ["Neverlose Sound"] = "rbxassetid://110168723447153",
        ["Bubble"]          = "rbxassetid://6534947588",
        ["Laser"]           = "rbxassetid://7837461331",
        ["Steve"]           = "rbxassetid://4965083997",
        ["Call of Duty"]    = "rbxassetid://5952120301",
        ["Bat"]             = "rbxassetid://3333907347",
        ["TF2 Critical"]    = "rbxassetid://296102734",
        ["Saber"]           = "rbxassetid://8415678813",
        ["Bameware"]        = "rbxassetid://3124331820",
    }
    getgenv()._lhxInitializeHitSounds = function()
        if not getgenv()._lhxHitSoundFolder or not getgenv()._lhxHitSoundFolder.Parent then
            getgenv()._lhxHitSoundFolder = Instance.new("Folder")
            getgenv()._lhxHitSoundFolder.Name = "Useful Utility"
            getgenv()._lhxHitSoundFolder.Parent = workspace
        end
        if not getgenv()._lhxHitSound or not getgenv()._lhxHitSound.Parent then
            getgenv()._lhxHitSound = Instance.new("Sound")
            getgenv()._lhxHitSound.Name = "IceHubHitSound"
            getgenv()._lhxHitSound.Parent = getgenv()._lhxHitSoundFolder
        end
        getgenv()._lhxHitSound.Volume = getgenv().hitSoundVolume or 5
        getgenv()._lhxHitSound.SoundId = getgenv()._lhxHitSoundIds[getgenv().hitSoundType] or getgenv()._lhxHitSoundIds["Medal"]
        return getgenv()._lhxHitSound
    end
    getgenv().updateHitSounds = function()
        pcall(getgenv()._lhxInitializeHitSounds)
    end
    if not getgenv()._lhxHitSoundConn then
        getgenv()._lhxHitSoundConn = ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
            if getgenv().hitSoundsEnabled then
                pcall(function()
                    local sound = getgenv()._lhxInitializeHitSounds()
                    if sound then
                        sound.TimePosition = 0
                        sound:Play()
                    end
                end)
            end
        end)
    end
    getgenv().updateHitSounds()

    -- ═══ BACKEND: SKY ══════════════════════════════════════════════════
    getgenv().customSky = getgenv().customSky or false
    getgenv().selectedSky = getgenv().selectedSky or "Default"
    local SKY_IDS = {
        ["Default"] = { bk="rbxassetid://591058823", dn="rbxassetid://591059876", ft="rbxassetid://591058104", lf="rbxassetid://591057861", rt="rbxassetid://591057625", up="rbxassetid://591059642" },
        ["Vaporwave"] = { bk="rbxassetid://1417494030", dn="rbxassetid://1417494146", ft="rbxassetid://1417494253", lf="rbxassetid://1417494402", rt="rbxassetid://1417494499", up="rbxassetid://1417494643" },
        ["Redshift"] = { bk="rbxassetid://401664839", dn="rbxassetid://401664862", ft="rbxassetid://401664960", lf="rbxassetid://401664881", rt="rbxassetid://401664901", up="rbxassetid://401664936" },
        ["Desert"] = { bk="rbxassetid://1013852", dn="rbxassetid://1013853", ft="rbxassetid://1013850", lf="rbxassetid://1013851", rt="rbxassetid://1013849", up="rbxassetid://1013854" },
        ["DaBaby"] = { bk="rbxassetid://7245418472", dn="rbxassetid://7245418472", ft="rbxassetid://7245418472", lf="rbxassetid://7245418472", rt="rbxassetid://7245418472", up="rbxassetid://7245418472" },
        ["Minecraft"] = { bk="rbxassetid://1876545003", dn="rbxassetid://1876544331", ft="rbxassetid://1876542941", lf="rbxassetid://1876543392", rt="rbxassetid://1876543764", up="rbxassetid://1876544642" },
        ["SpongeBob"] = { bk="rbxassetid://7633178166", dn="rbxassetid://7633178166", ft="rbxassetid://7633178166", lf="rbxassetid://7633178166", rt="rbxassetid://7633178166", up="rbxassetid://7633178166" },
        ["Skibidi"] = { bk="rbxassetid://14952256113", dn="rbxassetid://14952256113", ft="rbxassetid://14952256113", lf="rbxassetid://14952256113", rt="rbxassetid://14952256113", up="rbxassetid://14952256113" },
        ["Blaze"] = { bk="rbxassetid://150939022", dn="rbxassetid://150939038", ft="rbxassetid://150939047", lf="rbxassetid://150939056", rt="rbxassetid://150939063", up="rbxassetid://150939082" },
        ["Pussy Cat"] = { bk="rbxassetid://11154422902", dn="rbxassetid://11154422902", ft="rbxassetid://11154422902", lf="rbxassetid://11154422902", rt="rbxassetid://11154422902", up="rbxassetid://11154422902" },
        ["Among Us"] = { bk="rbxassetid://5752463190", dn="rbxassetid://5752463190", ft="rbxassetid://5752463190", lf="rbxassetid://5752463190", rt="rbxassetid://5752463190", up="rbxassetid://5752463190" },
        ["Space Wave"] = { bk="rbxassetid://16262356578", dn="rbxassetid://16262358026", ft="rbxassetid://16262360469", lf="rbxassetid://16262362003", rt="rbxassetid://16262363873", up="rbxassetid://16262366016" },
        ["Space Wave2"] = { bk="rbxassetid://1233158420", dn="rbxassetid://1233158838", ft="rbxassetid://1233157105", lf="rbxassetid://1233157640", rt="rbxassetid://1233157995", up="rbxassetid://1233159158" },
        ["Turquoise Wave"] = { bk="rbxassetid://47974894", dn="rbxassetid://47974690", ft="rbxassetid://47974821", lf="rbxassetid://47974776", rt="rbxassetid://47974859", up="rbxassetid://47974909" },
        ["Dark Night"] = { bk="rbxassetid://6285719338", dn="rbxassetid://6285721078", ft="rbxassetid://6285722964", lf="rbxassetid://6285724682", rt="rbxassetid://6285726335", up="rbxassetid://6285730635" },
        ["Bright Pink"] = { bk="rbxassetid://271042516", dn="rbxassetid://271077243", ft="rbxassetid://271042556", lf="rbxassetid://271042310", rt="rbxassetid://271042467", up="rbxassetid://271077958" },
        ["White Galaxy"] = { bk="rbxassetid://5540798456", dn="rbxassetid://5540799894", ft="rbxassetid://5540801779", lf="rbxassetid://5540801192", rt="rbxassetid://5540799108", up="rbxassetid://5540800635" },
        ["Blue Galaxy"] = { bk="rbxassetid://14961495673", dn="rbxassetid://14961494492", ft="rbxassetid://14961492844", lf="rbxassetid://14961491298", rt="rbxassetid://14961490439", up="rbxassetid://14961489508" },
    }
    local _customSkyObj = nil
    getgenv().applySkybox = function(name)
        local ids = SKY_IDS[name]
        if not ids then return end
        local Lighting = game:GetService("Lighting")
        local Sky = Lighting:FindFirstChildOfClass("Sky")
        if not Sky then
            Sky = Instance.new("Sky")
            Sky.Parent = Lighting
        end
        Sky.SkyboxBk = ids.bk
        Sky.SkyboxDn = ids.dn
        Sky.SkyboxFt = ids.ft
        Sky.SkyboxLf = ids.lf
        Sky.SkyboxRt = ids.rt
        Sky.SkyboxUp = ids.up
        Lighting.GlobalShadows = (name == "Default")
        _customSkyObj = Sky
    end
    getgenv().updateSky = function()
        if getgenv().customSky then
            getgenv().applySkybox(getgenv().selectedSky)
        else
            if _customSkyObj then
                _customSkyObj:Destroy()
                _customSkyObj = nil
            end
        end
    end

    -- ═══ BACKEND: ESP (Billboard) ══════════════════════════════════════
    do
    getgenv().espEnabled = false
    getgenv().espTracers = false
    getgenv().espNames = false
    getgenv().espBoxes = false
    getgenv().espAbility = false
    local Camera2 = workspace.CurrentCamera
    local espObjects = {}
    local ABILITY_ICONS = {}
    local playerAbilityCache = {}
    function getPlayerAbility(player)
        pcall(function()
            local char = player.Character; if not char then return end
            local ability = char:GetAttribute("CurrentAbility") or char:GetAttribute("ActiveAbility") or char:GetAttribute("Ability")
            if ability then playerAbilityCache[player] = tostring(ability) end
        end)
        return playerAbilityCache[player]
    end
    local CoreGui = game:GetService("CoreGui")
    local espFolder = CoreGui:FindFirstChild("IceHubX_ESP")
    if not espFolder then
        espFolder = Instance.new("Folder")
        espFolder.Name = "IceHubX_ESP"
        espFolder.Parent = CoreGui
    end

    function createESP(player)
        if player == LocalPlayer then return end
        if not espObjects[player] then espObjects[player] = {} end
    end

    function removeESP(player)
        if espObjects[player] then
            if espObjects[player].highlight then espObjects[player].highlight:Destroy() end
            if espObjects[player].billboard then espObjects[player].billboard:Destroy() end
            if espObjects[player].beam then espObjects[player].beam:Destroy() end
            if espObjects[player].att1 then espObjects[player].att1:Destroy() end
            if espObjects[player].att2 then espObjects[player].att2:Destroy() end
            espObjects[player] = nil
        end
    end

    getgenv().updateESP = function() end -- Keep it so existing toggles don't error

    function updateESPDraw()
        if not getgenv().espEnabled then 
            for _,esp in pairs(espObjects) do 
                if esp.highlight then esp.highlight.Enabled = false end
                if esp.billboard then esp.billboard.Enabled = false end
                if esp.beam then esp.beam.Enabled = false end
            end
            return 
        end
        for player,esp in pairs(espObjects) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                -- Highlight for Boxes/Tracers
                if not esp.highlight then
                    esp.highlight = Instance.new("Highlight")
                    esp.highlight.FillTransparency = 1
                    esp.highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    esp.highlight.Parent = espFolder
                end
                esp.highlight.Adornee = char
                esp.highlight.Enabled = getgenv().espBoxes
                
                -- Billboard for Name and Ability
                if not esp.billboard then
                    esp.billboard = Instance.new("BillboardGui")
                    esp.billboard.Size = UDim2.new(0, 200, 0, 50)
                    esp.billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                    esp.billboard.AlwaysOnTop = true
                    
                    local textLabel = Instance.new("TextLabel", esp.billboard)
                    textLabel.Name = "NameLabel"
                    textLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    textLabel.TextStrokeTransparency = 0.5
                    textLabel.Font = Enum.Font.SourceSansBold
                    textLabel.TextSize = 14
                    
                    local abilityLabel = Instance.new("TextLabel", esp.billboard)
                    abilityLabel.Name = "AbilityLabel"
                    abilityLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    abilityLabel.Position = UDim2.new(0, 0, 0.5, 0)
                    abilityLabel.BackgroundTransparency = 1
                    abilityLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
                    abilityLabel.TextStrokeTransparency = 0.5
                    abilityLabel.Font = Enum.Font.SourceSansBold
                    abilityLabel.TextSize = 13
                    
                    esp.billboard.Parent = espFolder
                end
                esp.billboard.Adornee = char.Head
                esp.billboard.Enabled = getgenv().espAbility
                
                if esp.billboard.Enabled then
                    local nameLabel = esp.billboard:FindFirstChild("NameLabel")
                    if nameLabel then
                        nameLabel.Visible = false
                    end
                    local abilityLabel = esp.billboard:FindFirstChild("AbilityLabel")
                    if abilityLabel then
                        abilityLabel.Visible = getgenv().espAbility
                        if getgenv().espAbility then
                            local ab = getPlayerAbility(player)
                            abilityLabel.Text = ab and ("["..ab.."]") or ""
                        end
                    end
                end
                
                if esp.beam then esp.beam.Enabled = false end
            else
                if esp.highlight then esp.highlight.Enabled = false end
                if esp.billboard then esp.billboard.Enabled = false end
                if esp.beam then esp.beam.Enabled = false end
            end
        end
    end

    for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
    Players.PlayerAdded:Connect(function(p) createESP(p) end)
    Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
    local espCtr=0
    RunService.Heartbeat:Connect(function() espCtr+=1; if espCtr%2==0 and getgenv().espEnabled then updateESPDraw() end end)
    end

    -- ═══ BACKEND: AUTO PLAY ════════════════════════════════════════════
    getgenv().autoPlay = false
    getgenv().autoVote = false
    local AutoPlayModule = {}
    AutoPlayModule.CONFIG = { DEFAULT_DISTANCE=30, MULTIPLIER_THRESHOLD=70, TRAVERSING=25, DIRECTION=1, JUMP_PERCENTAGE=50, DOUBLE_JUMP_PERCENTAGE=50, JUMPING_ENABLED=false, MOVEMENT_DURATION=0.8, OFFSET_FACTOR=0.7, GENERATION_THRESHOLD=0.25 }
    AutoPlayModule.ball=nil; AutoPlayModule.lobbyChoice=nil; AutoPlayModule.animationCache=nil; AutoPlayModule.doubleJumped=false; AutoPlayModule.ELAPSED=0; AutoPlayModule.CONTROL_POINT=nil; AutoPlayModule.LAST_GENERATION=0; AutoPlayModule.signals={}
    AutoPlayModule.playerHelper = {
        isAlive=function(p) local c=p and p.Character; if not c then return false end; local r=c:FindFirstChild("HumanoidRootPart"); local h=c:FindFirstChild("Humanoid"); if not r or not h then return false end; return h.Health>0 end,
        onGround=function(c) if not c then return false end; return c.Humanoid.FloorMaterial~=Enum.Material.Air end,
    }
    function AutoPlayModule.isLimited() return (tick()-AutoPlayModule.LAST_GENERATION)<AutoPlayModule.CONFIG.GENERATION_THRESHOLD end
    function AutoPlayModule.percentageCheck(lim) if AutoPlayModule.isLimited() then return false end; local p=math.random(100); AutoPlayModule.LAST_GENERATION=tick(); return lim>=p end
    AutoPlayModule.ballUtils = {
        getBall=function() local b=workspace:FindFirstChild("Balls"); if not b then AutoPlayModule.ball=nil; return end; for _,o in pairs(b:GetChildren()) do if o:GetAttribute("realBall") then AutoPlayModule.ball=o; return end end; AutoPlayModule.ball=nil end,
        getDirection=function() if not AutoPlayModule.ball or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end; return (LocalPlayer.Character.HumanoidRootPart.Position-AutoPlayModule.ball.Position).Unit end,
        getVelocity=function() if not AutoPlayModule.ball then return end; local z=AutoPlayModule.ball:FindFirstChild("zoomies"); if not z then return end; return z.VectorVelocity end,
        getSpeed=function() local v=AutoPlayModule.ballUtils.getVelocity(); if not v then return end; return v.Magnitude end,
        isExisting=function() return AutoPlayModule.ball~=nil end,
    }
    AutoPlayModule.lerp=function(s,f,a) return s+(f-s)*a end
    AutoPlayModule.quadratic=function(s,m,f,a) return AutoPlayModule.lerp(AutoPlayModule.lerp(s,m,a),AutoPlayModule.lerp(m,f,a),a) end
    AutoPlayModule.getControlPoint=function(st,fn)
        local mid=(st+fn)*0.5; local diff=st-fn; if diff.Magnitude<5 then return fn end
        local th=math.atan2(diff.Z,diff.X); local ol=diff.Magnitude*AutoPlayModule.CONFIG.OFFSET_FACTOR
        local fst=mid+Vector3.new(math.cos(th+math.pi/2),0,math.sin(th+math.pi/2))*ol
        local snd=mid+Vector3.new(math.cos(th-math.pi/2),0,math.sin(th-math.pi/2))*ol
        local dv=st-mid; if (fst-mid):Dot(dv)<0 then return fst else return snd end
    end
    AutoPlayModule.getCurve=function(st,fn,dt2)
        AutoPlayModule.ELAPSED+=dt2; local te=math.clamp(AutoPlayModule.ELAPSED/AutoPlayModule.CONFIG.MOVEMENT_DURATION,0,1)
        if te>=1 then if (st-fn).Magnitude>=10 then AutoPlayModule.ELAPSED=0 end; AutoPlayModule.CONTROL_POINT=nil; return fn end
        if not AutoPlayModule.CONTROL_POINT then AutoPlayModule.CONTROL_POINT=AutoPlayModule.getControlPoint(st,fn) end
        if not AutoPlayModule.CONTROL_POINT then return fn end
        return AutoPlayModule.quadratic(st,AutoPlayModule.CONTROL_POINT,fn,te)
    end
    AutoPlayModule.map = { getFloor=function() local f=workspace:FindFirstChild("FLOOR"); if not f then for _,p in pairs(workspace:GetChildren()) do if (p:IsA("MeshPart") or p:IsA("BasePart")) and p.Size.X>50 and p.Size.Z>50 and p.Position.Y<5 then return p end end end; return f end }
    AutoPlayModule.getRandomPosition=function()
        local fl=AutoPlayModule.map.getFloor(); if not fl or not AutoPlayModule.ballUtils.isExisting() then return end
        local bd=AutoPlayModule.ballUtils.getDirection()*AutoPlayModule.CONFIG.DIRECTION; local bs=AutoPlayModule.ballUtils.getSpeed(); if not bd or not bs then return end
        local st=math.min(bs/10,AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD); local sm=AutoPlayModule.CONFIG.DEFAULT_DISTANCE+st
        local ct=os.time()/1.2; local tr=Vector3.new(math.sin(ct),0,math.cos(ct))*AutoPlayModule.CONFIG.TRAVERSING
        return fl.Position+bd*sm+tr
    end
    AutoPlayModule.lobby = {
        isChooserAvailable=function()
            local sp=workspace:FindFirstChild("Spawn"); if not sp then return false end
            local npc=sp:FindFirstChild("NewPlayerCounter"); if not npc then return false end
            local gui=npc:FindFirstChild("GUI"); if not gui then return false end
            local sg=gui:FindFirstChild("SurfaceGui"); if not sg then return false end
            local top=sg:FindFirstChild("Top"); if not top then return false end
            local opts=top:FindFirstChild("Options"); return opts and opts.Visible or false
        end,
        updateChoice=function(c) AutoPlayModule.lobbyChoice=c end,
        getMapChoice=function()
            local c=AutoPlayModule.lobbyChoice or math.random(1,3); local sp=workspace:FindFirstChild("Spawn"); if not sp then return end
            local npc=sp:FindFirstChild("NewPlayerCounter"); if not npc then return end
            local col=npc:FindFirstChild("Colliders"); if not col then return end; return col:FindFirstChild(tostring(c))
        end,
        getPadPosition=function()
            if not AutoPlayModule.lobby.isChooserAvailable() then AutoPlayModule.lobbyChoice=nil; return end
            local c=AutoPlayModule.lobby.getMapChoice(); if not c then return end; return c.Position,c.Name
        end,
    }
    AutoPlayModule.movement = {
        removeCache=function() AutoPlayModule.animationCache=nil end,
        move=function(p,pos) if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid:MoveTo(pos) end end,
        stop=function(p) if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then return end; p.Character.Humanoid:MoveTo(p.Character.HumanoidRootPart.Position) end,
        jump=function(p) if not AutoPlayModule.CONFIG.JUMPING_ENABLED then return end; if not AutoPlayModule.playerHelper.onGround(p.Character) then return end; if not AutoPlayModule.percentageCheck(AutoPlayModule.CONFIG.JUMP_PERCENTAGE) then return end; AutoPlayModule.doubleJumped=false; if p.Character and p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end,
    }
    AutoPlayModule.signal = {
        connect=function(n,conn,cb) AutoPlayModule.signals[n]=conn:Connect(cb); return AutoPlayModule.signals[n] end,
        disconnect=function(n) if not n or not AutoPlayModule.signals[n] then return end; AutoPlayModule.signals[n]:Disconnect(); AutoPlayModule.signals[n]=nil end,
        stop=function() for n,conn in pairs(AutoPlayModule.signals) do if typeof(conn)=="RBXScriptConnection" then conn:Disconnect(); AutoPlayModule.signals[n]=nil end end end,
    }
    AutoPlayModule.findPath=function(inLobby,dt2)
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local rp=LocalPlayer.Character.HumanoidRootPart.Position
        if inLobby then
            local pp,pn=AutoPlayModule.lobby.getPadPosition(); local ch=tonumber(pn); if ch then AutoPlayModule.lobby.updateChoice(ch) end; if not pp then return end; return AutoPlayModule.getCurve(rp,pp,dt2)
        end
        local rnd=AutoPlayModule.getRandomPosition(); if not rnd then return end; return AutoPlayModule.getCurve(rp,rnd,dt2)
    end
    AutoPlayModule.followPath=function(dt2)
        if not AutoPlayModule.playerHelper.isAlive(LocalPlayer) then AutoPlayModule.movement.removeCache(); return end
        local inL=LocalPlayer.Character and LocalPlayer.Character.Parent==workspace:FindFirstChild("Dead")
        local path=AutoPlayModule.findPath(inL,dt2); if not path then AutoPlayModule.movement.stop(LocalPlayer); return end
        AutoPlayModule.movement.move(LocalPlayer,path); AutoPlayModule.movement.jump(LocalPlayer)
    end
    AutoPlayModule.finishThread=function()
        AutoPlayModule.signal.disconnect("auto-play"); AutoPlayModule.signal.disconnect("synchronize")
        if AutoPlayModule.playerHelper.isAlive(LocalPlayer) then AutoPlayModule.movement.stop(LocalPlayer) end
    end
    AutoPlayModule.runThread=function()
        AutoPlayModule.signal.connect("auto-play",RunService.PostSimulation,AutoPlayModule.followPath)
        AutoPlayModule.signal.connect("synchronize",RunService.PostSimulation,AutoPlayModule.ballUtils.getBall)
    end

    -- ═══ BACKEND: AUTO ABILITY ════════════════════════════════════════
    -- Shop
    getgenv().autoSwordBuy = getgenv().autoSwordBuy or false
    getgenv().autoExplosionBuy = getgenv().autoExplosionBuy or false
    getgenv().shopBuyInterval = getgenv().shopBuyInterval or 0.35
    local shopLoops={}

    function getShopRemotes()
        return ReplicatedStorage:FindFirstChild("Remotes")
    end
    function isServerRemote(obj)
        return obj and (obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent"))
    end
    function normalizeRemoteName(name)
        return tostring(name):lower():gsub("[^%w]","")
    end
    function findShopRemote(scope,aliases,requiredWords)
        if not scope then return nil end
        local nodes={scope}
        for _,obj in ipairs(scope:GetDescendants()) do table.insert(nodes,obj) end
        for _,obj in ipairs(nodes) do
            if isServerRemote(obj) then
                local normalized=normalizeRemoteName(obj.Name)
                for _,alias in ipairs(aliases or {}) do
                    if normalized==normalizeRemoteName(alias) then return obj end
                end
            end
        end
        for _,obj in ipairs(nodes) do
            if isServerRemote(obj) then
                local normalized=normalizeRemoteName(obj.Name)
                local matches=true
                for _,word in ipairs(requiredWords or {}) do
                    if not normalized:find(normalizeRemoteName(word),1,true) then matches=false; break end
                end
                if matches then return obj end
            end
        end
        return nil
    end
    function invokeShopRemote(remote)
        if not remote then return false,"Remote not found" end
        local result=nil
        local ok,err=pcall(function()
            if remote:IsA("RemoteFunction") then result=remote:InvokeServer() else remote:FireServer() end
        end)
        return ok,ok and remote:GetFullName() or tostring(err),result
    end
    function getStoreFolder()
        local remotes = getShopRemotes()
        return remotes and (remotes:FindFirstChild("Store") or remotes)
    end
    getgenv().openSwordBox = function()
        local scope = getStoreFolder()
        return invokeShopRemote(findShopRemote(scope,{"RequestOpenSwordBox","RequestOpenSwordCrate","OpenSwordBox","OpenSwordCrate"},{"sword","box","crate"}))
            or invokeShopRemote(findShopRemote(getShopRemotes(),{"RequestOpenSwordBox","RequestOpenSwordCrate","OpenSwordBox","OpenSwordCrate"},{"sword","box","crate"}))
    end
    getgenv().openExplosionBox = function()
        local scope = getStoreFolder()
        return invokeShopRemote(findShopRemote(scope,{"RequestOpenExplosionBox","RequestOpenExplosionCrate","OpenExplosionBox","OpenExplosionCrate"},{"explosion","box","crate"}))
            or invokeShopRemote(findShopRemote(getShopRemotes(),{"RequestOpenExplosionBox","RequestOpenExplosionCrate","OpenExplosionBox","OpenExplosionCrate"},{"explosion","box","crate"}))
    end
    function fireGuiSignal(signal)
        local fireSignal=getExecutorGlobal("firesignal")
        if fireSignal then
            local ok=pcall(fireSignal,signal)
            if ok then return true end
        end
        local getConnections=getExecutorGlobal("getconnections")
        if not getConnections then return false end
        local ok,connections=pcall(getConnections,signal)
        if not ok or type(connections)~="table" then return false end
        local fired=false
        for _,connection in ipairs(connections) do
            if connection.Function then
                fired=pcall(connection.Function) or fired
            end
        end
        return fired
    end
    function fireGuiButton(button)
        local getConnections=getExecutorGlobal("getconnections")
        if getConnections then
            for _,signal in ipairs({button.Activated,button.MouseButton1Click}) do
                local ok,connections=pcall(getConnections,signal)
                if ok and type(connections)=="table" and #connections>0 then
                    return fireGuiSignal(signal)
                end
            end
        end
        return fireGuiSignal(button.MouseButton1Click) or fireGuiSignal(button.Activated)
    end
    function getGuiButtonKey(button)
        local parts={button:GetFullName()}
        if button:IsA("TextButton") then table.insert(parts,button.Text) end
        for _,child in ipairs(button:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then table.insert(parts,child.Text) end
        end
        return normalizeRemoteName(table.concat(parts," "))
    end
    function activateDailyRewardButtons()
        local playerGui=LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then return false end
        local function activateClaims()
            local activated=false
            for _,obj in ipairs(playerGui:GetDescendants()) do
                if obj:IsA("GuiButton") then
                    local key=getGuiButtonKey(obj)
                    local isDaily=key:find("daily",1,true) or key:find("login",1,true) or key:find("seven",1,true)
                    local isClaim=key:find("claim",1,true) or key:find("collect",1,true) or key:find("redeem",1,true)
                    if isDaily and isClaim then activated=fireGuiButton(obj) or activated end
                end
            end
            return activated
        end
        if activateClaims() then return true end
        for _,obj in ipairs(playerGui:GetDescendants()) do
            if obj:IsA("GuiButton") then
                local key=getGuiButtonKey(obj)
                local isDaily=key:find("daily",1,true) or key:find("login",1,true) or key:find("seven",1,true)
                local isReward=key:find("reward",1,true)
                local isClaim=key:find("claim",1,true) or key:find("collect",1,true) or key:find("redeem",1,true)
                if isDaily and isReward and not isClaim and fireGuiButton(obj) then
                    task.wait(0.15)
                    return activateClaims()
                end
            end
        end
        return false
    end
    getgenv().claimDailyRewards = function()
        if activateDailyRewardButtons() then return true,"Daily reward claim triggered" end
        local remotes=getShopRemotes()
        local remote=findShopRemote(remotes,{"ClaimDailyReward","ClaimDailyRewards","RequestClaimDailyReward","RequestClaimDailyRewards","ClaimDailyLoginReward","ClaimDailyLoginRewards","ClaimSevenLoginReward","RedeemDailyReward","RedeemDailyRewards"},{"daily","claim"})
        remote=remote or findShopRemote(remotes,{"GetDailyReward","GetDailyRewards","DailyReward","DailyRewards"},{"daily","reward"})
        return invokeShopRemote(remote)
    end
    function updateShopLoop(key,enabled,action)
        if shopLoops[key] then task.cancel(shopLoops[key]); shopLoops[key]=nil end
        if not enabled then return end
        shopLoops[key]=task.spawn(function()
            while getgenv()[key] do
                action()
                task.wait(math.max(tonumber(getgenv().shopBuyInterval) or 0.35,0.1))
            end
        end)
    end
    getgenv().updateAutoSwordBuy = function()
        updateShopLoop("autoSwordBuy",getgenv().autoSwordBuy,getgenv().openSwordBox)
    end
    getgenv().updateAutoExplosionBuy = function()
        updateShopLoop("autoExplosionBuy",getgenv().autoExplosionBuy,getgenv().openExplosionBox)
    end

    getgenv().autoAbility = false
    getgenv().AutoAbility = function()
        if not LocalPlayer.Character then return false end
        local pg=LocalPlayer:FindFirstChild("PlayerGui"); if not pg then return false end
        local hb=pg:FindFirstChild("Hotbar"); if not hb then return false end
        local ab=hb:FindFirstChild("Ability"); if not ab then return false end
        local cd=ab:FindFirstChild("UIGradient"); if not cd then return false end
        if cd.Offset and cd.Offset.Y==0.5 then
            local abs2=LocalPlayer.Character:FindFirstChild("Abilities"); if not abs2 then return false end
            for _,an in ipairs({"Raging Deflection","Dash","Rapture","Calming Deflection","Aerodynamic Slash","Fracture","Death Slash"}) do
                local ao=abs2:FindFirstChild(an); if ao and ao.Enabled then pcall(function() ReplicatedStorage.Remotes.AbilityButtonPress:Fire() end); return true end
            end
        end
        return false
    end
    getgenv().updateAutoAbility = function() end
    local _aaConn = nil
    RunService.Heartbeat:Connect(function()
        if getgenv().autoAbility then pcall(getgenv().AutoAbility) end
    end)

    -- ═══ BACKEND: BALL STATS (updateBallStats/updateBallTrail stubs) ══
    getgenv().ballStatsEnabled = false
    getgenv().updateBallStats = function() end
    getgenv().ballTrailEnabled = false
    getgenv().updateBallTrail = function() end


    -- ═══ WIND UI ══════════════════════════════════════════════════════
function createIceDarkLibrary()

if not game:IsLoaded() then
    game.Loaded:Wait()
end

getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled",
        CheckboxDisabled = "Disabled",
        SliderValue = "Value",
        DropdownSelect = "Select",
        DropdownNone = "None",
        DropdownSelected = "Selected",
        ButtonClick = "Click",
        TextboxEnter = "Enter",
        ModuleEnabled = "Enabled",
        ModuleDisabled = "Disabled",
        TabGeneral = "General",
        TabSettings = "Settings",
        Loading = "Loading...",
        Error = "Error",
        Success = "Success"
    }
}

local SelectedLanguage = GG.Language

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end
    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_ailon = CoreGui:FindFirstChild('ailon')

if old_ailon then
    Debris:AddItem(old_ailon, 0)
end

if not isfolder("ailon") then
    makefolder("ailon")
end


local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end
    
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end
    
            value:Disconnect()
        end
    end
}, Connections)


local Util = setmetatable({
    map = function(self: any, value: number, in_minimum: number, in_maximum: number, out_minimum: number, out_maximum: number)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    viewport_point_to_world = function(self: any, location: any, distance: number)
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)

        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self: any)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y

        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, Util)


local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur


function AcrylicBlur.new(object: GuiObject)
    local self = setmetatable({
        _object = object,
        _folder = nil,
        _frame = nil,
        _root = nil
    }, AcrylicBlur)

    self:setup()

    return self
end


function AcrylicBlur:create_folder()
    local old_folder = workspace.CurrentCamera:FindFirstChild('AcrylicBlur')

    if old_folder then
        Debris:AddItem(old_folder, 0)
    end

    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = workspace.CurrentCamera

    self._folder = folder
end


function AcrylicBlur:create_depth_of_fields()
    local depth_of_fields = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth_of_fields.FarIntensity = 0
    depth_of_fields.FocusDistance = 0.05
    depth_of_fields.InFocusRadius = 0.1
    depth_of_fields.NearIntensity = 1
    depth_of_fields.Name = 'AcrylicBlur'
    depth_of_fields.Parent = Lighting

    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then
            continue
        end

        if object == depth_of_fields then
            continue
        end

        Connections[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
            object.FarIntensity = 0
        end)

        object.FarIntensity = 0
    end
end


function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object

    self._frame = frame
end


function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)  -- Use a thin part
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder

    -- Create a SpecialMesh to simulate the acrylic blur effect
    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick  -- Use Brick mesh or another type suitable for the effect
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)  -- Small offset to prevent z-fighting
    specialMesh.Parent = part

    self._root = part  -- Store the part as root
end


function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    
    self:create_frame()
    self:render(0.001)

    self:check_quality_level()
end


function AcrylicBlur:render(distance: number)
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function update_positions(size: any, position: any)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function update()
        local top_left = positions.top_left
        local top_right = positions.top_right
        local bottom_right = positions.bottom_right

        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)

        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude

        if not self._root then
            return
        end

        self._root.CFrame = CFrame.fromMatrix((top_left3D + bottom_right3D) / 2, workspace.CurrentCamera.CFrame.XVector, workspace.CurrentCamera.CFrame.YVector, workspace.CurrentCamera.CFrame.ZVector)
        local mesh = self._root:FindFirstChildOfClass('SpecialMesh')
        if mesh then mesh.Scale = Vector3.new(width, height, 0) end
    end

    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

        update_positions(size, position)
        task.spawn(update)
    end

    Connections['cframe_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)

    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    
    task.spawn(update)
end


function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then
        self:change_visiblity(false)
    end

    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value

        self:change_visiblity(quality_level >= 8)
    end)
end


function AcrylicBlur:change_visiblity(state: boolean)
    self._root.Transparency = state and 0.98 or 1
end


local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        local success_save, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('ailon/'..file_name..'.json', flags)
        end)
    
        if not success_save then
            warn('failed to save config', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if not isfile('ailon/'..file_name..'.json') then
                self:save(file_name, config)
        
                return
            end
        
            local flags = readfile('ailon/'..file_name..'.json')
        
            if not flags then
                self:save(file_name, config)
        
                return
            end

            return HttpService:JSONDecode(flags)
        end)
    
        if not success_load then
            warn('failed to load config', result)
        end
    
        if not result then
            result = {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end
    
        return result
    end
}, Config)


local Library = {
    _config = Config:load(game.GameId),

    _choosing_keybind = false,
    _device = nil,

    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,

    _dragging = false,
    _drag_start = nil,
    _container_position = nil
}
Library.__index = Library


function Library.new()
    local self = setmetatable({
        _loaded = false,
        _tab = 0,
    }, Library)
    
    self:create_ui()

    return self
end

-- Create Notification Container
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "CondemnedNotifications"
NotificationContainer.Size = UDim2.new(0, 320, 0, 0)
NotificationContainer.Position = UDim2.new(1, -10, 1, -10)
NotificationContainer.AnchorPoint = Vector2.new(1, 1)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.Parent = game:GetService("CoreGui"):FindFirstChild("RobloxGui") or game:GetService("CoreGui")
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
Library._notifications = NotificationContainer

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = NotificationContainer

-- Function to create notifications
function Library.SendNotification(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 0)
    Notification.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    Notification.BackgroundTransparency = 0.02
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer
    Notification.AutomaticSize = Enum.AutomaticSize.Y
    Notification.ClipsDescendants = true
    Notification.AnchorPoint = Vector2.new(1, 1)
    Notification.Position = UDim2.new(1, 360, 1, 0)

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 7)
    UICorner.Parent = Notification

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(71, 79, 238)
    UIStroke.Transparency = 0.7
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Notification

    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 2, 1, 0)
    AccentBar.BackgroundColor3 = Color3.fromRGB(91, 100, 255)
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = Notification

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or settings.Title or "Notification"
    Title.TextColor3 = Color3.fromRGB(236, 237, 245)
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 13
    Title.Size = UDim2.new(1, -18, 0, 18)
    Title.Position = UDim2.new(0, 10, 0, 8)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.Parent = Notification

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or settings.Content or ""
    Body.TextColor3 = Color3.fromRGB(165, 170, 182)
    Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    Body.TextSize = 11
    Body.Size = UDim2.new(1, -18, 0, 0)
    Body.Position = UDim2.new(0, 10, 0, 27)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true
    Body.AutomaticSize = Enum.AutomaticSize.Y
    Body.Parent = Notification

    local Padding = Instance.new("UIPadding")
    Padding.PaddingBottom = UDim.new(0, 9)
    Padding.Parent = Notification

    local NotifScale = Instance.new("UIScale")
    NotifScale.Scale = 0.85
    NotifScale.Parent = Notification

    local appearInfo = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local hideInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    local startPos = UDim2.new(1, 120, 1, 0)
    local shownPos = UDim2.new(1, -2, 1, 0)

    Notification.Position = startPos
    Notification.BackgroundTransparency = 1
    UIStroke.Transparency = 1
    AccentBar.BackgroundTransparency = 1
    Title.TextTransparency = 1
    Body.TextTransparency = 1

    task.spawn(function()
        TweenService:Create(Notification, appearInfo, {
            Position = shownPos,
            BackgroundTransparency = 0.05,
        }):Play()
        TweenService:Create(NotifScale, appearInfo, {Scale = 1}):Play()
        TweenService:Create(UIStroke, appearInfo, {Transparency = 0.4}):Play()
        TweenService:Create(AccentBar, appearInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(Title, appearInfo, {TextTransparency = 0}):Play()
        TweenService:Create(Body, appearInfo, {TextTransparency = 0}):Play()

        task.wait(settings.duration or 3)

        TweenService:Create(Notification, hideInfo, {
            Position = startPos,
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(NotifScale, hideInfo, {Scale = 0.85}):Play()
        TweenService:Create(UIStroke, hideInfo, {Transparency = 1}):Play()
        TweenService:Create(AccentBar, hideInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(Title, hideInfo, {TextTransparency = 1}):Play()
        TweenService:Create(Body, hideInfo, {TextTransparency = 1}):Play()

        task.wait(0.4)
        if Notification then Notification:Destroy() end
    end)
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X

    self._ui_scale = viewport_size_x / 1400
end


function Library:get_device()
    local device = 'Unknown'

    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end

    self._device = device
end


function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action)
end


function Library:flag_type(flag: any, flag_type: any)
    if not Library._config._flags[flag] then
        return
    end

    return typeof(Library._config._flags[flag]) == flag_type
end


function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value ~= table_value then
            continue
        end

        table.remove(__table, index)
    end
end


function Library:create_ui()
    local old_ailon = CoreGui:FindFirstChild('ailon')

    if old_ailon then
        Debris:AddItem(old_ailon, 0)
    end

    local ailon = Instance.new('ScreenGui')
    ailon.ResetOnSpawn = false
    ailon.Name = 'ailon'
    ailon.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ailon.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.05000000074505806
    Container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    
    local ContainerGradient = Instance.new('UIGradient')
    ContainerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(126, 34, 206)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    ContainerGradient.Rotation = 45
    ContainerGradient.Parent = Container

    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = ailon
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(126, 34, 206)
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 680, 0, 460)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container
    
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026097271591424942, 0, 0.1111111119389534, 0)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    local ClientLogo = Instance.new('ImageLabel')
    ClientLogo.Name = 'ClientLogo'
    ClientLogo.Size = UDim2.new(0, 32, 0, 32)
    ClientLogo.AnchorPoint = Vector2.new(0, 0.5)
    ClientLogo.Position = UDim2.new(0.025, -4, 0.055, 0)
    ClientLogo.BackgroundTransparency = 1
    ClientLogo.Image = getgenv().IceHubLogoAsset or ""
    ClientLogo.Parent = Handler
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Color3.fromRGB(200, 200, 200)
    ClientName.TextTransparency = 0.20000000298023224
    ClientName.Text = 'ICEHUB'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 85, 0, 18)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.025, 32, 0.055, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 16
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler
    
    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 90, 230)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 90, 230))
    }
    UIGradient.Parent = ClientName

    local ClientVersion = Instance.new('TextLabel')
    ClientVersion.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    ClientVersion.TextColor3 = Color3.fromRGB(150, 150, 150)
    ClientVersion.Text = 'v1.1.9'
    ClientVersion.Name = 'ClientVersion'
    ClientVersion.Size = UDim2.new(0, 40, 0, 18)
    ClientVersion.AnchorPoint = Vector2.new(0, 0.5)
    ClientVersion.Position = UDim2.new(0.025, 115, 0.055, 0)
    ClientVersion.BackgroundTransparency = 1
    ClientVersion.TextXAlignment = Enum.TextXAlignment.Left
    ClientVersion.BorderSizePixel = 0
    ClientVersion.TextSize = 11
    ClientVersion.Parent = Handler

    task.spawn(function()
        while task.wait() do
            if not ClientName or not ClientName.Parent then break end
            UIGradient.Offset = Vector2.new(math.sin(os.clock() * 1.5), 0)
        end
    end)

    local TopDivider = Instance.new('Frame')
    TopDivider.Name = 'TopDivider'
    TopDivider.Size = UDim2.new(0.85, 0, 0, 1)
    TopDivider.Position = UDim2.new(0.5, 0, 0, 36)
    TopDivider.AnchorPoint = Vector2.new(0.5, 0)
    TopDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TopDivider.BorderSizePixel = 0
    TopDivider.Parent = Handler
    
    local TopDividerGradient = Instance.new('UIGradient')
    TopDividerGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    TopDividerGradient.Parent = TopDivider
    
    local SideDivider = Instance.new('Frame')
    SideDivider.Name = 'SideDivider'
    SideDivider.Size = UDim2.new(0, 2, 0, 340)
    SideDivider.Position = UDim2.new(0.235, 0, 0.5, 0)
    SideDivider.AnchorPoint = Vector2.new(0.5, 0.5)
    SideDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    SideDivider.BorderSizePixel = 0
    SideDivider.Parent = Handler
    
    local SideDividerCorner = Instance.new('UICorner')
    SideDividerCorner.CornerRadius = UDim.new(1, 0)
    SideDividerCorner.Parent = SideDivider
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler


    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.025, -4, 0.055, -4)
    Minimize.Size = UDim2.new(0, 180, 0, 40)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = ailon

    local function on_drag(input: InputObject, process: boolean)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input: any)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input: InputObject, process: boolean)
        if not self._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['minimize_input_began'] = Minimize.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05000000074505806;
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a);
            end);
        end;
    end;

    function self:UIVisiblity()
        ailon.Enabled = not ailon.Enabled;
    end;

    function self:change_visiblity(state: boolean)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(680, 460)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(180, 52)
            }):Play()
        end
    end
    

    function self:load()
        local content = {}
    
        for _, object in ailon:GetDescendants() do
            if not object:IsA('ImageLabel') then
                continue
            end
    
            table.insert(content, object)
        end
    
        ContentProvider:PreloadAsync(content)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
    
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end
    
        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(680, 460)
        }):Play()

        AcrylicBlur.new(Container)
        self._ui_loaded = true
    end

    function self:update_tabs(tab: TextButton)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3)

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.2,
                        TextColor3 = Color3.fromRGB(200, 200, 200)
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Color3.fromRGB(200, 200, 200)
                    }):Play()

                    if object:FindFirstChild("ActiveIndicator") then
                        TweenService:Create(object.ActiveIndicator, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            Size = UDim2.new(0, 3, 0, 16),
                            BackgroundTransparency = 0
                        }):Play()
                    end
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()

                if object:FindFirstChild("ActiveIndicator") then
                    TweenService:Create(object.ActiveIndicator, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 3, 0, 0),
                        BackgroundTransparency = 1
                    }):Play()
                end
            end
        end
    end

    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true

                continue
            end

            object.Visible = false
        end
    end

    function self:create_tab(title: string, icon: string, visible: boolean)
        if visible == nil then visible = true end
        local TabManager = {}

        local LayoutOrder = 0;

        local font_size = Vector2.new(string.len(title) * 8, 16)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
        Tab.Parent = Tabs
        Tab.Visible = visible
        Tab.LayoutOrder = self._tab
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = Tab
        
        local TabGradient = Instance.new('UIGradient')
        TabGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 20, 65)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 5, 25))
        }
        TabGradient.Rotation = 90
        TabGradient.Parent = Tab
        
        local ActiveIndicator = Instance.new('Frame')
        ActiveIndicator.Name = 'ActiveIndicator'
        ActiveIndicator.BackgroundColor3 = Color3.fromRGB(160, 90, 230)
        ActiveIndicator.BorderSizePixel = 0
        ActiveIndicator.AnchorPoint = Vector2.new(0, 0.5)
        ActiveIndicator.Position = UDim2.new(0, 4, 0.5, 0)
        ActiveIndicator.Size = UDim2.new(0, 3, 0, 0)
        ActiveIndicator.BackgroundTransparency = 1
        ActiveIndicator.Parent = Tab

        local IndicatorCorner = Instance.new('UICorner')
        IndicatorCorner.CornerRadius = UDim.new(1, 0)
        IndicatorCorner.Parent = ActiveIndicator
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextTransparency = 0.7 -- 0.800000011920929
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.2400001734495163, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab
        
        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient.Parent = TextLabel
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.800000011920929
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.10000000149011612, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Icon.Parent = Tab
        
        Tab.MouseEnter:Connect(function()
            if Tab.BackgroundTransparency ~= 0.5 then
                TweenService:Create(TextLabel, TweenInfo.new(0.3), {TextTransparency = 0.4}):Play()
                TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 0.4}):Play()
            end
        end)

        Tab.MouseLeave:Connect(function()
            if Tab.BackgroundTransparency ~= 0.5 then
                TweenService:Create(TextLabel, TweenInfo.new(0.3), {TextTransparency = 0.7}):Play()
                TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 0.8}):Play()
            end
        end)

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 374)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.2594326436519623, 0, 0.5, 0)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = LeftSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 374)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.6290000081062317, 0, 0.5, 0)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = RightSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:SetVisible(state: boolean)
            Tab.Visible = state
        end

        function TabManager:create_module(settings: any)

            local LayoutOrderModule = 0;

            local ModuleManager = {
                _state = false,
                _locked = false,
                _size = 0,
                _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(130, 70, 200)
            UIStroke.Transparency = 0.7
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module
    
-- ==================== PER-MODULE LOCK BUTTON (Fixed + Small) ====================
local LockButton = Instance.new('ImageButton')
LockButton.Name = 'LockButton'
LockButton.Size = UDim2.new(0, 13, 0, 13)
LockButton.AnchorPoint = Vector2.new(1, 0)
LockButton.Position = UDim2.new(1, -6, 0, 6)
LockButton.BackgroundTransparency = 1
LockButton.Image = 'rbxassetid://12060512624'
LockButton.ImageColor3 = Color3.fromRGB(160, 90, 230)
LockButton.ZIndex = 10
LockButton.Parent = Header

ModuleManager._locked = false

local function updateLockVisual()
    if ModuleManager._locked then
        LockButton.ImageColor3 = Color3.fromRGB(255, 65, 65)
    else
        LockButton.ImageColor3 = Color3.fromRGB(160, 90, 230)
    end
end

local function setModuleInteractable(state: boolean)
    for _, desc in ipairs(Module:GetDescendants()) do
        if desc == LockButton then continue end
        
        if desc:IsA("TextButton") or desc:IsA("ImageButton") or desc:IsA("TextBox") then
            desc.Active = state
            desc.Selectable = state
            
            if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                desc.AutoButtonColor = state
            end
            
            -- Extra safety for sliders and colorpickers
            if desc.Name == "Circle" or desc.Name == "Swatch" or desc.Name == "HueStrip" or desc.Name == "SvSquare" then
                desc.Active = state
            end
        end
    end
end

LockButton.MouseButton1Click:Connect(function()
    if Library._choosing_keybind then return end
    
    ModuleManager._locked = not ModuleManager._locked
    
    updateLockVisual()
    setModuleInteractable(not ModuleManager._locked)   -- This is the key fix
    
    Library.SendNotification({
        title = ModuleManager._locked and "Module Locked" or "Module Unlocked",
        text = settings.title or "",
        duration = 1.5
    })
end)

-- Hover
LockButton.MouseEnter:Connect(function()
    TweenService:Create(LockButton, TweenInfo.new(0.15), {
        ImageColor3 = ModuleManager._locked and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(220, 220, 220)
    }):Play()
end)

LockButton.MouseLeave:Connect(function()
    updateLockVisual()
end)

-- Initial setup
updateLockVisual()
setModuleInteractable(true)

    LockButton.MouseButton1Click:Connect(function()
        ModuleManager._locked = not ModuleManager._locked
        if ModuleManager._locked then
            game:GetService("TweenService"):Create(LockButton, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        else
            game:GetService("TweenService"):Create(LockButton, TweenInfo.new(0.2), {
                ImageColor3 = Color3.fromRGB(160, 90, 230)
            }):Play()
        end
    end)
            
            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Color3.fromRGB(200, 200, 200)
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.699999988079071
            Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Icon.Parent = Header
            
            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Color3.fromRGB(200, 200, 200)
            ModuleName.TextTransparency = 0.20000000298023224
            if not settings.rich then
                ModuleName.Text = settings.title or "Skibidi"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(200,200,200)'>ICEHUB</font> user"
            end;
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.0729999989271164, 0, 0.23999999463558197, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ModuleName.TextSize = 13
            ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ModuleName.Parent = Header
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Color3.fromRGB(200, 200, 200)
            Description.TextTransparency = 0.699999988079071
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.0729999989271164, 0, 0.41999998688697815, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Description.TextSize = 10
            Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.699999988079071
            Toggle.Position = UDim2.new(0.8199999928474426, 0, 0.7570000290870667, 0)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.20000000298023224
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.Parent = Toggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            local Keybind = Instance.new('Frame')
            Keybind.Name = 'Keybind'
            Keybind.BackgroundTransparency = 0.699999988079071
            Keybind.Position = UDim2.new(0.15000000596046448, 0, 0.7350000143051147, 0)
            Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
            Keybind.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Keybind
            
            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.Text = 'None'
            TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            TextLabel.Size = UDim2.new(0, 25, 0, 13)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.TextSize = 10
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.Parent = Keybind
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(126, 34, 206)
            Divider.Parent = Header
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(126, 34, 206)
            Divider.Parent = Header
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            function ModuleManager:change_state(state: boolean)
                self._state = state

                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(160, 160, 160)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(160, 160, 160),
                        Position = UDim2.fromScale(0.53, 0.5)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Position = UDim2.fromScale(0, 0.5)
                    }):Play()
                end

                if settings.flag ~= "Emotes" and settings.flag ~= "Unlock_All" then
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                end

                settings.callback(self._state)
            end
            
            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end

                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                if ModuleManager._locked then return end
                    if process then
                        return
                    end
                    
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end
                    
                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty: boolean)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')

                    local font_size = Vector2.new(string.len(keybind_string) * 7, 10)
                    
                    Keybind.Size = UDim2.fromOffset(font_size.X + 6, 15)
                    TextLabel.Size = UDim2.fromOffset(font_size.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    TextLabel.Size = UDim2.fromOffset(25, 13)
                end
            end

            if settings.flag ~= "Emotes" and settings.flag ~= "Unlock_All" and Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = true
                settings.callback(ModuleManager._state)

                Toggle.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
                Circle.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
                Circle.Position = UDim2.fromScale(0.53, 0.5)
            end

            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string

                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            Connections[settings.flag..'_input_began'] = Header.InputBegan:Connect(function(input: InputObject)
                if Library._choosing_keybind then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then
                    return
                end
                
                Library._choosing_keybind = true
                
                Connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                if ModuleManager._locked then return end
                    if process then
                        return
                    end
                    
                    if input == Enum.UserInputState or input == Enum.UserInputType then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Backspace then
                        ModuleManager:scale_keybind(true)

                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)

                        TextLabel.Text = 'None'
                        
                        if Connections[settings.flag..'_keybind'] then
                            Connections[settings.flag..'_keybind']:Disconnect()
                            Connections[settings.flag..'_keybind'] = nil
                        end

                        Connections['keybind_choose_start']:Disconnect()
                        Connections['keybind_choose_start'] = nil

                        Library._choosing_keybind = false

                        return
                    end
                    
                    Connections['keybind_choose_start']:Disconnect()
                    Connections['keybind_choose_start'] = nil
                    
                    Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                    Config:save(game.GameId, Library._config)

                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                        Connections[settings.flag..'_keybind'] = nil
                    end

                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()
                    
                    Library._choosing_keybind = false

                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    TextLabel.Text = keybind_string
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_paragraph(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;

                local ParagraphManager = {}
                
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 70
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                -- Container Frame
                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                Paragraph.BackgroundTransparency = 0.1
                Paragraph.Size = UDim2.new(0, 207, 0, 30) -- Initial size, auto-resized later
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y -- Support auto-resizing height
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule;
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Paragraph
            
                -- Title Label
                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(210, 210, 210)
                Title.Text = settings.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextYAlignment = Enum.TextYAlignment.Center
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.Parent = Paragraph
            
                -- Body Text
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(180, 180, 180)
                
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi"
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(200,200,200)'>ICEHUB</font> user"
                end
                
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 30)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = Paragraph
            
                -- Hover effect for Paragraph (optional)
                Paragraph.MouseEnter:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    }):Play()
                end)
            
                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    }):Play()
                end)

                return ParagraphManager
            end

            function ModuleManager:create_colorpicker(settings: any)
    LayoutOrderModule = LayoutOrderModule + 1

    local ColorpickerManager = {
        _color = settings.default or Color3.fromRGB(255, 0, 0),
        _h = 0, _s = 1, _v = 1
    }

    -- Init HSV from default
    do
        local c = ColorpickerManager._color
        local h, s, v = Color3.toHSV(c)
        ColorpickerManager._h = h
        ColorpickerManager._s = s
        ColorpickerManager._v = v
    end

    -- Load saved color
    if Library._config._flags[settings.flag] then
        local sv = Library._config._flags[settings.flag]
        if type(sv) == "table" and sv.R then
            local c = Color3.fromRGB(sv.R, sv.G, sv.B)
            ColorpickerManager._color = c
            local h, s, v = Color3.toHSV(c)
            ColorpickerManager._h = h
            ColorpickerManager._s = s
            ColorpickerManager._v = v
        end
    end

    if self._size == 0 then self._size = 11 end
    self._size += 32

    if ModuleManager._state then
        Module.Size = UDim2.fromOffset(241, 93 + self._size)
    end
    Options.Size = UDim2.fromOffset(241, self._size)

    -- ── Row (label + swatch) ──────────────────────────────────────────────
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(0, 207, 0, 22)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = LayoutOrderModule
    Row.Parent = Options

    local Label = Instance.new("TextLabel")
    Label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextTransparency = 0.2
    Label.Text = settings.title or "Color"
    Label.Size = UDim2.new(1, -30, 1, 0)
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextSize = 11
    Label.Parent = Row

    local Swatch = Instance.new("TextButton")
    Swatch.Size = UDim2.new(0, 22, 0, 22)
    Swatch.Position = UDim2.new(1, -22, 0, 0)
    Swatch.BackgroundColor3 = ColorpickerManager._color
    Swatch.BorderSizePixel = 0
    Swatch.Text = ""
    Swatch.AutoButtonColor = false
    Swatch.Parent = Row
    Instance.new("UICorner", Swatch).CornerRadius = UDim.new(0, 5)
    local SwatchStroke = Instance.new("UIStroke", Swatch)
    SwatchStroke.Color = Color3.fromRGB(130, 70, 200)
    SwatchStroke.Transparency = 0.5

    -- ── Popup panel ───────────────────────────────────────────────────────
    local POPUP_H = 180
    local popupOpen = false

    local Popup = Instance.new("Frame")
    Popup.Size = UDim2.new(0, 207, 0, 0)
    Popup.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    Popup.BorderSizePixel = 0
    Popup.ClipsDescendants = true
    Popup.LayoutOrder = LayoutOrderModule
    Popup.Parent = Options
    Instance.new("UICorner", Popup).CornerRadius = UDim.new(0, 7)
    local PopupStroke = Instance.new("UIStroke", Popup)
    PopupStroke.Color = Color3.fromRGB(70, 70, 70)
    PopupStroke.Transparency = 0.4

    -- Inner wrapper so ClipsDescendants hides during close tween
    local Inner = Instance.new("Frame")
    Inner.Size = UDim2.new(1, 0, 0, POPUP_H)
    Inner.BackgroundTransparency = 1
    Inner.Parent = Popup

    -- ── SV square (left, 150×150) ─────────────────────────────────────────
    local SQ = 145
    local SvSquare = Instance.new("TextButton")
    SvSquare.Size = UDim2.new(0, SQ, 0, SQ)
    SvSquare.Position = UDim2.new(0, 8, 0, 10)
    SvSquare.BackgroundColor3 = Color3.fromHSV(ColorpickerManager._h, 1, 1)
    SvSquare.BorderSizePixel = 0
    SvSquare.Text = ""
    SvSquare.AutoButtonColor = false
    SvSquare.Parent = Inner
    Instance.new("UICorner", SvSquare).CornerRadius = UDim.new(0, 5)

    -- White→transparent (left to right: white gradient)
    local WhiteGrad = Instance.new("Frame")
    WhiteGrad.Size = UDim2.new(1, 0, 1, 0)
    WhiteGrad.BackgroundTransparency = 0
    WhiteGrad.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WhiteGrad.BorderSizePixel = 0
    WhiteGrad.Parent = SvSquare
    Instance.new("UICorner", WhiteGrad).CornerRadius = UDim.new(0, 5)
    local WG = Instance.new("UIGradient", WhiteGrad)
    WG.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
    }
    WG.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    WG.Rotation = 0

    -- Black→transparent (bottom to top: black gradient)
    local BlackGrad = Instance.new("Frame")
    BlackGrad.Size = UDim2.new(1, 0, 1, 0)
    BlackGrad.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BlackGrad.BackgroundTransparency = 0
    BlackGrad.BorderSizePixel = 0
    BlackGrad.Parent = SvSquare
    Instance.new("UICorner", BlackGrad).CornerRadius = UDim.new(0, 5)
    local BG = Instance.new("UIGradient", BlackGrad)
    BG.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
    }
    BG.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    }
    BG.Rotation = 90

    -- Picker circle on the SV square
    local Picker = Instance.new("Frame")
    Picker.Size = UDim2.new(0, 10, 0, 10)
    Picker.AnchorPoint = Vector2.new(0.5, 0.5)
    Picker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Picker.BorderSizePixel = 0
    Picker.ZIndex = 5
    Picker.Position = UDim2.new(
        ColorpickerManager._s,
        0,
        1 - ColorpickerManager._v,
        0
    )
    Picker.Parent = SvSquare
    Instance.new("UICorner", Picker).CornerRadius = UDim.new(1, 0)
    local PickerStroke = Instance.new("UIStroke", Picker)
    PickerStroke.Color = Color3.fromRGB(0, 0, 0)
    PickerStroke.Thickness = 1.5
    PickerStroke.Transparency = 0.3

    -- ── Hue strip (right of square) ───────────────────────────────────────
    local HueStrip = Instance.new("TextButton")
    HueStrip.Size = UDim2.new(0, 14, 0, SQ)
    HueStrip.Position = UDim2.new(0, 8 + SQ + 6, 0, 10)
    HueStrip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueStrip.BorderSizePixel = 0
    HueStrip.Text = ""
    HueStrip.AutoButtonColor = false
    HueStrip.Parent = Inner
    Instance.new("UICorner", HueStrip).CornerRadius = UDim.new(0, 4)

    -- Hue rainbow gradient (top=0°, bottom=360°)
    local HueGrad = Instance.new("UIGradient", HueStrip)
    HueGrad.Rotation = 90
    local hueKP = {}
    for i = 0, 6 do
        hueKP[i+1] = ColorSequenceKeypoint.new(i/6, Color3.fromHSV(i/6, 1, 1))
    end
    HueGrad.Color = ColorSequence.new(hueKP)

    -- Hue cursor line
    local HueCursor = Instance.new("Frame")
    HueCursor.Size = UDim2.new(1, 4, 0, 3)
    HueCursor.Position = UDim2.new(0, -2, ColorpickerManager._h, -1)
    HueCursor.AnchorPoint = Vector2.new(0, 0.5)
    HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueCursor.BorderSizePixel = 0
    HueCursor.ZIndex = 5
    HueCursor.Parent = HueStrip
    Instance.new("UICorner", HueCursor).CornerRadius = UDim.new(1, 0)
    local HueCursorStroke = Instance.new("UIStroke", HueCursor)
    HueCursorStroke.Color = Color3.fromRGB(0, 0, 0)
    HueCursorStroke.Thickness = 1
    HueCursorStroke.Transparency = 0.4

    -- ── Hex input + preview row at the bottom ─────────────────────────────
    local BottomRow = Instance.new("Frame")
    BottomRow.Size = UDim2.new(1, -16, 0, 22)
    BottomRow.Position = UDim2.new(0, 8, 0, 10 + SQ + 8)
    BottomRow.BackgroundTransparency = 1
    BottomRow.Parent = Inner

    local PreviewSwatch = Instance.new("Frame")
    PreviewSwatch.Size = UDim2.new(0, 22, 0, 22)
    PreviewSwatch.BackgroundColor3 = ColorpickerManager._color
    PreviewSwatch.BorderSizePixel = 0
    PreviewSwatch.Parent = BottomRow
    Instance.new("UICorner", PreviewSwatch).CornerRadius = UDim.new(0, 5)

    local HexLabel = Instance.new("TextLabel")
    HexLabel.Text = "#"
    HexLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    HexLabel.TextSize = 10
    HexLabel.TextColor3 = Color3.fromRGB(160, 90, 230)
    HexLabel.Size = UDim2.new(0, 12, 1, 0)
    HexLabel.Position = UDim2.new(0, 28, 0, 0)
    HexLabel.BackgroundTransparency = 1
    HexLabel.TextXAlignment = Enum.TextXAlignment.Center
    HexLabel.Parent = BottomRow

    local HexBox = Instance.new("TextBox")
    HexBox.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    HexBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    HexBox.PlaceholderText = "FF0000"
    HexBox.Text = ""
    HexBox.TextSize = 10
    HexBox.Size = UDim2.new(1, -46, 1, 0)
    HexBox.Position = UDim2.new(0, 42, 0, 0)
    HexBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    HexBox.BackgroundTransparency = 0.3
    HexBox.BorderSizePixel = 0
    HexBox.ClearTextOnFocus = false
    HexBox.Parent = BottomRow
    Instance.new("UICorner", HexBox).CornerRadius = UDim.new(0, 4)

    -- ── Helpers ───────────────────────────────────────────────────────────
    local function colorToHex(c)
        return string.format("%02X%02X%02X",
            math.round(c.R * 255),
            math.round(c.G * 255),
            math.round(c.B * 255))
    end

    local function hexToColor(hex)
        hex = hex:gsub("#","")
        if #hex ~= 6 then return nil end
        local r = tonumber(hex:sub(1,2), 16)
        local g = tonumber(hex:sub(3,4), 16)
        local b = tonumber(hex:sub(5,6), 16)
        if not (r and g and b) then return nil end
        return Color3.fromRGB(r, g, b)
    end

    local function applyColor(h, s, v, skipHex)
        ColorpickerManager._h = h
        ColorpickerManager._s = s
        ColorpickerManager._v = v
        local color = Color3.fromHSV(h, s, v)
        ColorpickerManager._color = color

        -- Update square background to pure hue
        SvSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

        -- Move picker dot: X = saturation, Y = (1-value)
        Picker.Position = UDim2.new(math.clamp(s, 0, 1), 0, math.clamp(1 - v, 0, 1), 0)

        -- Move hue cursor
        HueCursor.Position = UDim2.new(0, -2, math.clamp(h, 0, 0.9999), -1)

        -- Update swatches
        Swatch.BackgroundColor3 = color
        PreviewSwatch.BackgroundColor3 = color

        -- Update hex
        if not skipHex then
            HexBox.Text = colorToHex(color)
        end

        -- Save + callback
        Library._config._flags[settings.flag] = {
            R = math.round(color.R * 255),
            G = math.round(color.G * 255),
            B = math.round(color.B * 255)
        }
        Config:save(game.GameId, Library._config)
        if settings.callback then settings.callback(color) end
    end

    function ColorpickerManager:set_color(color)
        local h, s, v = Color3.toHSV(color)
        applyColor(h, s, v)
    end

    -- Initial sync
    applyColor(ColorpickerManager._h, ColorpickerManager._s, ColorpickerManager._v)

    -- ── SV square drag ────────────────────────────────────────────────────
    local svDragging = false

    local function updateSV()
        local rx = math.clamp((mouse.X - SvSquare.AbsolutePosition.X) / SvSquare.AbsoluteSize.X, 0, 1)
        local ry = math.clamp((mouse.Y - SvSquare.AbsolutePosition.Y) / SvSquare.AbsoluteSize.Y, 0, 1)
        applyColor(ColorpickerManager._h, rx, 1 - ry)
    end

    SvSquare.MouseButton1Down:Connect(function()
        if ModuleManager._locked then return end
        svDragging = true
        updateSV()
    end)

    Connections["sv_move_"..settings.flag] = UserInputService.InputChanged:Connect(function(inp)
        if svDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateSV()
        end
    end)

    Connections["sv_end_"..settings.flag] = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
        end
    end)

    -- ── Hue strip drag ────────────────────────────────────────────────────
    local hueDragging = false

    local function updateHue()
        local ry = math.clamp((mouse.Y - HueStrip.AbsolutePosition.Y) / HueStrip.AbsoluteSize.Y, 0, 0.9999)
        applyColor(ry, ColorpickerManager._s, ColorpickerManager._v)
    end

    HueStrip.MouseButton1Down:Connect(function()
        if ModuleManager._locked then return end
        hueDragging = true
        updateHue()
    end)

    Connections["hue_move_"..settings.flag] = UserInputService.InputChanged:Connect(function(inp)
        if hueDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateHue()
        end
    end)

    Connections["hue_end_"..settings.flag] = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)

    -- ── Hex input ─────────────────────────────────────────────────────────
    HexBox.FocusLost:Connect(function()
        if ModuleManager._locked then
            HexBox.Text = colorToHex(ColorpickerManager._color)
            return
        end
        local color = hexToColor(HexBox.Text)
        if color then
            local h, s, v = Color3.toHSV(color)
            applyColor(h, s, v, true)
        else
            HexBox.Text = colorToHex(ColorpickerManager._color)
        end
    end)

    -- ── Toggle popup ──────────────────────────────────────────────────────
    Swatch.MouseButton1Click:Connect(function()
        if ModuleManager._locked then return end
        popupOpen = not popupOpen

        if popupOpen then
            self._size += POPUP_H
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)

            TweenService:Create(Popup, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(207, POPUP_H)
            }):Play()
        else
            self._size -= POPUP_H
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)

            TweenService:Create(Popup, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(207, 0)
            }):Play()
        end
    end)

    return ColorpickerManager
end

            function ModuleManager:create_text(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextManager = {}
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 50 -- Adjust the default height for text elements
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                -- Container Frame
                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                TextFrame.BackgroundTransparency = 0.1
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize) -- Initial size, auto-resized later
                TextFrame.BorderSizePixel = 0
                TextFrame.Name = "Text"
                TextFrame.AutomaticSize = Enum.AutomaticSize.Y -- Support auto-resizing height
                TextFrame.Parent = Options
                TextFrame.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = TextFrame
            
                -- Body Text
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(180, 180, 180)
            
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi" -- Default text
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(200,200,200)'>ICEHUB</font> user" -- Default rich text
                end
            
                Body.Size = UDim2.new(1, -10, 1, 0)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 10
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = TextFrame
            
                -- Hover effect for TextFrame (optional)
                TextFrame.MouseEnter:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    }):Play()
                end)
            
                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    if not new_settings.rich then
                        Body.Text = new_settings.text or "Skibidi" -- Default text
                    else
                        Body.RichText = true
                        Body.Text = new_settings.richtext or "<font color='rgb(200,200,200)'>ICEHUB</font> user" -- Default rich text
                    end
                end;
            
                return TextManager
            end
            function ModuleManager:create_textbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextboxManager = {
                    _text = ""
                }
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 32
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.AnchorPoint = Vector2.new(0, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.BorderSizePixel = 0
                Label.Parent = Options
                Label.TextSize = 10;
                Label.LayoutOrder = LayoutOrderModule
            
                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
                Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Textbox.BackgroundTransparency = 0.9
                Textbox.ClearTextOnFocus = false
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Textbox
            
                function TextboxManager:update_text(text: string)
                    self._text = text
                    Library._config._flags[settings.flag] = self._text
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._text)
                end
            
                if Library:flag_type(settings.flag, 'string') then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end
            
                Textbox.FocusLost:Connect(function()
                    if ModuleManager._locked then return end
                    TextboxManager:update_text(Textbox.Text)
                end)
            
                return TextboxManager
            end   

            function ModuleManager:create_keybind(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local KeybindContainer = Instance.new("Frame")
                KeybindContainer.Name = "KeybindContainer"
                KeybindContainer.Size = UDim2.new(0, 207, 0, 16)
                KeybindContainer.BackgroundTransparency = 1
                KeybindContainer.Parent = Options
                KeybindContainer.LayoutOrder = LayoutOrderModule

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                TitleLabel.Size = UDim2.new(0, 150, 1, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Text = settings.title or "Keybind"
                TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                TitleLabel.TextTransparency = 0.2
                TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 13
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = KeybindContainer

                local KeyButton = Instance.new("TextButton")
                KeyButton.Name = "KeyButton"
                KeyButton.Size = UDim2.new(0, 50, 1, 0)
                KeyButton.Position = UDim2.new(1, -50, 0, 0)
                KeyButton.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
                KeyButton.BorderSizePixel = 0
                KeyButton.Text = settings.default or "None"
                KeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                KeyButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                KeyButton.TextSize = 12
                KeyButton.Parent = KeybindContainer

                local UICorner = Instance.new("UICorner")
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = KeyButton

                local waitingForBind = false

                KeyButton.MouseButton1Click:Connect(function()
                    if waitingForBind then return end
                    waitingForBind = true
                    KeyButton.Text = "..."
                end)

                game:GetService("UserInputService").InputBegan:Connect(function(input)
                    if waitingForBind and input.UserInputType == Enum.UserInputType.Keyboard then
                        waitingForBind = false
                        local keyName = input.KeyCode.Name
                        KeyButton.Text = keyName
                        if settings.callback then
                            task.spawn(settings.callback, keyName)
                        end
                    end
                end)
            end

            function ModuleManager:create_custom_button(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                if self._size == 0 then
                    self._size = 11
                end

                local hasDescription = type(settings.description) == "string" and settings.description ~= ""
                local rowHeight = hasDescription and 40 or 32
                self._size += rowHeight + 4
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local ButtonContainer = Instance.new("Frame")
                ButtonContainer.Name = "ButtonContainer"
                ButtonContainer.Size = UDim2.new(0, 207, 0, rowHeight)
                ButtonContainer.BackgroundTransparency = 1
                ButtonContainer.Parent = Options
                ButtonContainer.LayoutOrder = LayoutOrderModule

                local CustomButton = Instance.new("TextButton")
                CustomButton.Name = "CustomButton"
                CustomButton.Size = UDim2.new(1, 0, 1, 0)
                CustomButton.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
                CustomButton.BorderSizePixel = 0
                CustomButton.AutoButtonColor = false
                CustomButton.Text = ""
                CustomButton.ClipsDescendants = true
                CustomButton.Parent = ButtonContainer

                local UICorner = Instance.new("UICorner")
                UICorner.CornerRadius = UDim.new(0, 7)
                UICorner.Parent = CustomButton

                local UIStroke = Instance.new("UIStroke")
                UIStroke.Color = Color3.fromRGB(52, 57, 78)
                UIStroke.Thickness = 1
                UIStroke.Transparency = 0.4
                UIStroke.Parent = CustomButton

                local Title = Instance.new("TextLabel")
                Title.Name = "Title"
                Title.Position = UDim2.new(0, 12, 0, hasDescription and 6 or 0)
                Title.Size = UDim2.new(1, -24, 0, hasDescription and 15 or 16)
                Title.BackgroundTransparency = 1
                Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.Text = settings.title or "Button"
                Title.TextColor3 = Color3.fromRGB(236, 237, 245)
                Title.TextSize = 12
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextTruncate = Enum.TextTruncate.AtEnd
                Title.Parent = CustomButton

                if hasDescription then
                    local Description = Instance.new("TextLabel")
                    Description.Name = "Description"
                    Description.Position = UDim2.new(0, 12, 0, 21)
                    Description.Size = UDim2.new(1, -24, 0, 11)
                    Description.BackgroundTransparency = 1
                    Description.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                    Description.Text = settings.description
                    Description.TextColor3 = Color3.fromRGB(125, 128, 140)
                    Description.TextSize = 9
                    Description.TextXAlignment = Enum.TextXAlignment.Left
                    Description.TextTruncate = Enum.TextTruncate.AtEnd
                    Description.Parent = CustomButton
                else
                    Title.Position = UDim2.new(0, 12, 0.5, -8)
                    Title.Size = UDim2.new(1, -24, 0, 16)
                end

                local ButtonScale = Instance.new("UIScale")
                ButtonScale.Parent = CustomButton

                local buttonBusy = false
                local function setHovered(hovered)
                    local bg = hovered and Color3.fromRGB(26, 30, 42) or Color3.fromRGB(18, 20, 28)
                    TweenService:Create(CustomButton, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = bg}):Play()
                    TweenService:Create(UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Transparency = hovered and 0.1 or 0.4}):Play()
                    TweenService:Create(ButtonScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = hovered and 1.02 or 1.0}):Play()
                end

                local function setPressed()
                    TweenService:Create(CustomButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(35, 40, 55)}):Play()
                    TweenService:Create(UIStroke, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}):Play()
                    TweenService:Create(ButtonScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.96}):Play()
                end

                local function runButtonCallback()
                    if buttonBusy then return end
                    buttonBusy = true
                    setPressed()
                    if type(Utility) == "table" and type(Utility.Ripple) == "function" then Utility:Ripple(CustomButton) end
                    local ok, err = pcall(function()
                        if settings.callback then settings.callback() end
                    end)
                    if not ok then
                        warn("IceHub custom button failed:", err)
                    end
                    task.delay(0.15, function()
                        buttonBusy = false
                        setHovered(false)
                    end)
                end

                CustomButton.MouseEnter:Connect(function()
                    if not buttonBusy then setHovered(true) end
                end)
                CustomButton.MouseLeave:Connect(function()
                    if not buttonBusy then setHovered(false) end
                end)
                CustomButton.Activated:Connect(runButtonCallback)
                CustomButton.MouseButton1Click:Connect(runButtonCallback)
                CustomButton.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        runButtonCallback()
                    end
                end)
            end

            function ModuleManager:create_discord_panel(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 85
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Panel = Instance.new("Frame")
                Panel.Name = "DiscordPanel"
                Panel.Size = UDim2.new(0, 207, 0, 75)
                Panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                Panel.Parent = Options
                Panel.LayoutOrder = LayoutOrderModule

                local UICorner = Instance.new("UICorner")
                UICorner.CornerRadius = UDim.new(0, 8)
                UICorner.Parent = Panel

                local UIStroke = Instance.new("UIStroke")
                UIStroke.Color = Color3.fromRGB(40, 40, 45)
                UIStroke.Parent = Panel

                local Logo = Instance.new("ImageLabel")
                Logo.Size = UDim2.new(0, 32, 0, 32)
                Logo.Position = UDim2.new(0, 10, 0, 8)
                Logo.BackgroundTransparency = 1
                Logo.Image = getgenv().IceHubLogoAsset or "rbxassetid://135805711666993"
                Logo.Parent = Panel

                local ServerName = Instance.new("TextLabel")
                ServerName.Size = UDim2.new(0, 150, 0, 14)
                ServerName.Position = UDim2.new(0, 50, 0, 8)
                ServerName.BackgroundTransparency = 1
                ServerName.Text = settings.title or "ICEHUB | Premium S"
                ServerName.TextColor3 = Color3.fromRGB(255, 255, 255)
                ServerName.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                ServerName.TextSize = 12
                ServerName.TextXAlignment = Enum.TextXAlignment.Left
                ServerName.Parent = Panel

                local MemberCount = Instance.new("TextLabel")
                MemberCount.Size = UDim2.new(0, 150, 0, 12)
                MemberCount.Position = UDim2.new(0, 50, 0, 22)
                MemberCount.BackgroundTransparency = 1
                MemberCount.Text = "• Member Count : 407"
                MemberCount.TextColor3 = Color3.fromRGB(150, 150, 150)
                MemberCount.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                MemberCount.TextSize = 11
                MemberCount.TextXAlignment = Enum.TextXAlignment.Left
                MemberCount.Parent = Panel

                local OnlineCount = Instance.new("TextLabel")
                OnlineCount.Size = UDim2.new(0, 150, 0, 12)
                OnlineCount.Position = UDim2.new(0, 50, 0, 34)
                OnlineCount.BackgroundTransparency = 1
                OnlineCount.Text = "• Online Count : 44"
                OnlineCount.TextColor3 = Color3.fromRGB(150, 150, 150)
                OnlineCount.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                OnlineCount.TextSize = 11
                OnlineCount.TextXAlignment = Enum.TextXAlignment.Left
                OnlineCount.Parent = Panel

                local JoinButton = Instance.new("TextButton")
                JoinButton.Size = UDim2.new(0, 187, 0, 20)
                JoinButton.Position = UDim2.new(0, 10, 0, 50)
                JoinButton.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
                JoinButton.Text = "Join Discord"
                JoinButton.TextColor3 = Color3.fromRGB(10, 10, 10)
                JoinButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                JoinButton.TextSize = 12
                JoinButton.Parent = Panel

                local JoinCorner = Instance.new("UICorner")
                JoinCorner.CornerRadius = UDim.new(0, 4)
                JoinCorner.Parent = JoinButton

                JoinButton.MouseButton1Click:Connect(function()
                    if type(Utility) == "table" and type(Utility.Ripple) == "function" then
                        Utility:Ripple(JoinButton)
                    end
                    local cb = settings.Callback or settings.callback
                    if cb then
                        task.spawn(cb)
                    end
                end)
            end

            function ModuleManager:create_checkbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }
            
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Checkbox = Instance.new("TextButton")
                Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 15)
                Checkbox.BorderSizePixel = 0
                Checkbox.TextSize = 14
                Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule
            
                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                if SelectedLanguage == "th" then
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 13
                else
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 11
                end
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Skibidi"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = Checkbox

                local KeybindBox = Instance.new("Frame")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.Size = UDim2.fromOffset(14, 14)
                KeybindBox.Position = UDim2.new(1, -35, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindBox.BorderSizePixel = 0
                KeybindBox.Parent = Checkbox
            
                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 6)
                KeybindCorner.Parent = KeybindBox
            
                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Name = "KeybindLabel"
                KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                KeybindLabel.TextScaled = false
                KeybindLabel.TextSize = 10
                KeybindLabel.Font = Enum.Font.SourceSans
                KeybindLabel.Text = Library._config._keybinds[settings.flag] 
                    and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "") 
                    or "..."
                KeybindLabel.Parent = KeybindBox
            
                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Box.Parent = Checkbox
            
                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 6)
                BoxCorner.Parent = Box
            
                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0.5, 0.5)
                Fill.BackgroundTransparency = 0.2
                Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.Parent = Box
            
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
            
                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    if settings.flag ~= "Emotes" and settings.flag ~= "Unlock_All" then
                        Library._config._flags[settings.flag] = self._state
                        Config:save(game.GameId, Library._config)
                    end
                    settings.callback(self._state)
                end
            
                if settings.flag ~= "Emotes" and settings.flag ~= "Unlock_All" and Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end
            
                Checkbox.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)
            
                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                    if Library._choosing_keybind then return end
            
                    Library._choosing_keybind = true
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                        if ModuleManager._locked then return end
                        if processed then return end
                        if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        if keyInput.KeyCode == Enum.KeyCode.Unknown then return end
            
                        if keyInput.KeyCode == Enum.KeyCode.Backspace then
                            ModuleManager:scale_keybind(true)
                            Library._config._keybinds[settings.flag] = nil
                            Config:save(game.GameId, Library._config)
                            KeybindLabel.Text = "..."
                            if Connections[settings.flag .. "_keybind"] then
                                Connections[settings.flag .. "_keybind"]:Disconnect()
                                Connections[settings.flag .. "_keybind"] = nil
                            end
                            chooseConnection:Disconnect()
                            Library._choosing_keybind = false
                            return
                        end
            
                        chooseConnection:Disconnect()
                        Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                        Config:save(game.GameId, Library._config)
                        if Connections[settings.flag .. "_keybind"] then
                            Connections[settings.flag .. "_keybind"]:Disconnect()
                            Connections[settings.flag .. "_keybind"] = nil
                        end
                        ModuleManager:connect_keybind()
                        ModuleManager:scale_keybind()
                        Library._choosing_keybind = false
            
                        local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        KeybindLabel.Text = keybind_string
                    end)
                end)
            
                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if ModuleManager._locked then return end
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local storedKey = Library._config._keybinds[settings.flag]
                        if storedKey and tostring(input.KeyCode) == storedKey then
                            CheckboxManager:change_state(not CheckboxManager._state)
                        end
                    end
                end)
                Connections[settings.flag .. "_keypress"] = keyPressConnection
            
                return CheckboxManager
            end

            function ModuleManager:create_divider(settings: any)
                -- Layout order management
                LayoutOrderModule = LayoutOrderModule + 1;
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 27
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                local dividerHeight = 1
                local dividerWidth = 207 -- Adjust this to fit your UI width
            
                -- Create the outer frame to control spacing above and below
                local OuterFrame = Instance.new('Frame')
                OuterFrame.Size = UDim2.new(0, dividerWidth, 0, 20) -- Height here controls spacing above and below
                OuterFrame.BackgroundTransparency = 1 -- Fully invisible
                OuterFrame.Name = 'OuterFrame'
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.showtopic then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- 154, 182, 255
                    TextLabel.TextTransparency = 0
                    TextLabel.Text = settings.title
                    TextLabel.Size = UDim2.new(0, 153, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.BorderSizePixel = 0
                    TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
                    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    TextLabel.TextSize = 11
                    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.ZIndex = 3;
                    TextLabel.TextStrokeTransparency = 0;
                    TextLabel.Parent = OuterFrame
                end;
                
                if not settings or settings and not settings.disableline then
                    -- Create the inner divider frame that will be placed in the middle of the OuterFrame
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
                    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White color
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2;
                    Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2) -- Center the divider vertically in the OuterFrame
                
                    -- Add a UIGradient to the divider for left and right transparency
                    local Gradient = Instance.new('UIGradient')
                    Gradient.Parent = Divider
                    Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),  -- Start with white
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), -- Keep it white in the middle
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0))  -- Fade to transparent on the right side
                    })
                    Gradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),   
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    Gradient.Rotation = 0 -- Horizontal gradient (fade from left to right)
                
                    -- Optionally, you can add a corner radius for rounded ends
                    local UICorner = Instance.new('UICorner')
                    UICorner.CornerRadius = UDim.new(0, 2) -- Small corner radius for smooth edges
                    UICorner.Parent = Divider

                end;
            
                return true;
            end
            
            function ModuleManager:create_slider(settings: any)

                LayoutOrderModule = LayoutOrderModule + 1

                local SliderManager = {}

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 27

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal);
                Slider.TextSize = 14;
                Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule
                
                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05000000074505806, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Slider
                
                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.8999999761581421
                Drag.Position = UDim2.new(0.5, 0, 0.949999988079071, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Drag.Parent = Slider
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag
                
                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.Parent = Drag
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill
                
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 79, 79))
                }
                UIGradient.Parent = Fill
                
                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.Parent = Fill
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle
                
                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                Value.TextTransparency = 0.20000000298023224
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.BorderSizePixel = 0
                Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Value.TextSize = 10
                Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Value.Parent = Slider

                function SliderManager:set_percentage(percentage: number)
                    local rounded_number = 0

                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10
                    end

                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)
                    
                    local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)
    
                    Library._config._flags[settings.flag] = number_threshold
                    Value.Text = number_threshold
    
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()
    
                    settings.callback(number_threshold)
                end

                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()
    
                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)
                    
                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input: InputObject, process: boolean)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
    
                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)

                        if not settings.ignoresaved then
                            Config:save(game.GameId, Library._config);
                        end;
                    end)
                end


                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag]);
                    else
                        SliderManager:set_percentage(settings.value);
                    end;
                else
                    SliderManager:set_percentage(settings.value);
                end;
    
                Slider.MouseButton1Down:Connect(function()
                if ModuleManager._locked then return end
                    SliderManager:input()
                end)

                function SliderManager:SetVisible(state: boolean)
                    Slider.Visible = state
                end

                return SliderManager
            end

            function ModuleManager:create_dual_slider(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local SliderManager = { _min = settings.minimum_value, _max = settings.maximum_value }
                if Library._config._flags[settings.flag] then
                    local saved = Library._config._flags[settings.flag]
                    if type(saved) == "table" and #saved >= 2 then
                        SliderManager._min = saved[1]
                        SliderManager._max = saved[2]
                    end
                end

                if self._size == 0 then self._size = 11 end
                self._size += 27
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'DualSlider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule
                
                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.TextSize = 11
                TextLabel.Parent = Slider
                
                local Drag = Instance.new('Frame')
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.9
                Drag.Position = UDim2.new(0.5, 0, 0.95, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Drag.Parent = Slider
                
                local Fill = Instance.new('Frame')
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 0, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.Parent = Drag
                
                local MinCircle = Instance.new('Frame')
                MinCircle.AnchorPoint = Vector2.new(0.5, 0.5)
                MinCircle.Position = UDim2.new(0, 0, 0.5, 0)
                MinCircle.Size = UDim2.new(0, 6, 0, 6)
                MinCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                MinCircle.Parent = Drag
                Instance.new("UICorner", MinCircle).CornerRadius = UDim.new(1, 0)
                
                local MaxCircle = Instance.new('Frame')
                MaxCircle.AnchorPoint = Vector2.new(0.5, 0.5)
                MaxCircle.Position = UDim2.new(1, 0, 0.5, 0)
                MaxCircle.Size = UDim2.new(0, 6, 0, 6)
                MaxCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                MaxCircle.Parent = Drag
                Instance.new("UICorner", MaxCircle).CornerRadius = UDim.new(1, 0)
                
                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                Value.Text = '0 - 100'
                Value.Size = UDim2.new(0, 80, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.TextSize = 10
                Value.Parent = Slider

                function SliderManager:update_visuals()
                    local range = settings.maximum_value - settings.minimum_value
                    local minP = (self._min - settings.minimum_value) / range
                    local maxP = (self._max - settings.minimum_value) / range
                    
                    Fill.Position = UDim2.new(minP, 0, 0.5, 0)
                    Fill.Size = UDim2.new(maxP - minP, 0, 1, 0)
                    MinCircle.Position = UDim2.new(minP, 0, 0.5, 0)
                    MaxCircle.Position = UDim2.new(maxP, 0, 0.5, 0)
                    
                    local minV = settings.round_number and math.floor(self._min) or math.floor(self._min * 10) / 10
                    local maxV = settings.round_number and math.floor(self._max) or math.floor(self._max * 10) / 10
                    Value.Text = string.format("%s - %s%s", tostring(minV), tostring(maxV), settings.suffix or "")
                    
                    Library._config._flags[settings.flag] = {minV, maxV}
                    settings.callback({minV, maxV})
                end

                function SliderManager:input(isMin)
                    local connection
                    connection = mouse.Move:Connect(function()
                        local mouse_position = math.clamp((mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset, 0, 1)
                        local val = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position
                        
                        if isMin then
                            self._min = math.clamp(val, settings.minimum_value, self._max)
                        else
                            self._max = math.clamp(val, self._min, settings.maximum_value)
                        end
                        self:update_visuals()
                        -- Fire callback live during drag so script-side AccuracyMin/Max
                        -- update in real-time. Previously only update_visuals fired,
                        -- meaning the runtime values stayed at whatever was loaded -
                        -- effectively only the max ever mattered for the random roll.
                        if settings.callback then
                            pcall(settings.callback, {self._min, self._max})
                        end
                    end)
                    
                    Connections['dual_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                        connection:Disconnect()
                        Connections:disconnect('dual_input_'..settings.flag)
                        Config:save(game.GameId, Library._config)
                    end)
                end

                Slider.MouseButton1Down:Connect(function()
                if ModuleManager._locked then return end
                    local mouse_position = math.clamp((mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset, 0, 1)
                    local val = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position
                    local distMin = math.abs(val - SliderManager._min)
                    local distMax = math.abs(val - SliderManager._max)
                    SliderManager:input(distMin < distMax)
                end)

                if Library._config._flags[settings.flag] then
                    local saved = Library._config._flags[settings.flag]
                    if type(saved) == "table" then
                        SliderManager._min, SliderManager._max = (table.unpack or unpack)(saved)
                    else
                        SliderManager._min, SliderManager._max = settings.min_value, settings.max_value
                    end
                else
                    SliderManager._min, SliderManager._max = settings.min_value, settings.max_value
                end
                SliderManager:update_visuals()
                if settings.callback then
                    settings.callback({SliderManager._min, SliderManager._max})
                end

                function SliderManager:SetVisible(state: boolean)
                    Slider.Visible = state
                end

                return SliderManager
            end

            function ModuleManager:create_dropdown(settings: any)

                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1;
                end;

                local DropdownManager = {
                    _state = false,
                    _size = 0
                }

                if not settings.Order then
                    if self._size == 0 then
                        self._size = 11
                    end

                    self._size += 44
                end;

                if not settings.Order then
                    if ModuleManager._state then
                        Module.Size = UDim2.fromOffset(241, 93 + self._size)
                    end
                    Options.Size = UDim2.fromOffset(241, self._size)
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 207, 0, 39)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Parent = Options

                if not settings.Order then
                    Dropdown.LayoutOrder = LayoutOrderModule;
                else
                    Dropdown.LayoutOrder = settings.OrderValue;
                end;

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {};
                end;
                
                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Dropdown
                
                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.8999999761581421
                Box.Position = UDim2.new(0.5, 0, 1.2000000476837158, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Box.Parent = TextLabel
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 6)
                UICorner.Parent = Box
                
                local Header = Instance.new('Frame')
                Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 207, 0, 22)
                Header.BorderSizePixel = 0
                Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Header.Parent = Box
                
                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.TextTransparency = 0.20000000298023224
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.04999988153576851, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
                CurrentOption.TextSize = 10
                CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.Parent = Header
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.704, 0),
                    NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                    NumberSequenceKeypoint.new(1, 1)
                }
                UIGradient.Parent = CurrentOption
                
                local Arrow = Instance.new('ImageLabel')
                Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.9100000262260437, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Arrow.Parent = Header
                
                local Options = Instance.new('ScrollingFrame')
                Options.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
                Options.Active = true
                Options.ScrollBarImageTransparency = 1
                Options.AutomaticCanvasSize = Enum.AutomaticSize.XY
                Options.ScrollBarThickness = 0
                Options.Name = 'Options'
                Options.Size = UDim2.new(0, 207, 0, 0)
                Options.BackgroundTransparency = 1
                Options.Position = UDim2.new(0, 0, 1, 0)
                Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Options.BorderSizePixel = 0
                Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                Options.Parent = Box
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Options
                
                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, -1)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.Parent = Options
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Box

                function DropdownManager:update(option: string)
                    -- If multi-dropdown is enabled
                    if settings.multi_dropdown then
                        -- Split the CurrentOption.Text by commas into a table

                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {};
                        end;

                        local CurrentTargetValue = nil;
                        
                        if #Library._config._flags[settings.flag] > 0 then

                            CurrentTargetValue = convertTableToString(Library._config._flags[settings.flag]);

                        end;

                        local selected = {}

                        if CurrentTargetValue then
                            for value in string.gmatch(CurrentTargetValue, "([^,]+)") do
                                -- Trim spaces around the option using string.match
                                local trimmedValue = value:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
                                
                                -- Exclude any unwanted labels (e.g. "Label")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        else
                            for value in string.gmatch(CurrentOption.Text, "([^,]+)") do
                                -- Trim spaces around the option using string.match
                                local trimmedValue = value:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
                                
                                -- Exclude any unwanted labels (e.g. "Label")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        end;
                
                        local CurrentTextGet = convertStringToTable(CurrentOption.Text);

                        optionSkibidi = "nil";
                        if typeof(option) ~= 'string' then
                            optionSkibidi = option.Name;
                        else
                            optionSkibidi = option;
                        end;

                        local found = false
                        for i, v in pairs(CurrentTextGet) do
                            if v == optionSkibidi then
                                table.remove(CurrentTextGet, i);
                                break;
                            end
                        end

                        CurrentOption.Text = table.concat(selected, ", ")
                        local OptionsChild = {}
                        -- Update the transparent effect of each option
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                table.insert(OptionsChild, object.Text)
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end

                        CurrentTargetValue = convertStringToTable(CurrentOption.Text);

                        for _, v in CurrentTargetValue do
                            if not table.find(OptionsChild, v) and table.find(selected, v) then
                                table.remove(selected, _)
                            end;
                        end;

                        CurrentOption.Text = table.concat(selected, ", ");
                
                        Library._config._flags[settings.flag] = convertStringToTable(CurrentOption.Text);
                    else
                        -- For single dropdown, just set the CurrentOption.Text to the selected option
                        CurrentOption.Text = (typeof(option) == "string" and option) or option.Name
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                -- Only update transparency for actual option text buttons
                                if object.Text == CurrentOption.Text then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end
                
                    -- Save the configuration state
                    Config:save(game.GameId, Library._config)
                
                    -- Callback with the updated option(s)
                    settings.callback(option)
                end
                
                local CurrentDropSizeState = 0;

                function DropdownManager:unfold_settings()
                    self._state = not self._state

                    if self._state then
                        ModuleManager._multiplier += self._size

                        CurrentDropSizeState = self._size;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39 + self._size)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22 + self._size)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 180
                        }):Play()
                    else
                        ModuleManager._multiplier -= self._size

                        CurrentDropSizeState = 0;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0
                        }):Play()
                    end
                end

                if #settings.options > 0 then
                    DropdownManager._size = 3

                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.6000000238418579
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Parent = Options
                        
                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option

                        Option.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {};
                            end;

                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end

                            DropdownManager:update(value)
                        end)
    
                        if index > settings.maximum_options then
                            continue
                        end
    
                        DropdownManager._size += 16
                        Options.Size = UDim2.fromOffset(207, DropdownManager._size)
                    end
                end

                function DropdownManager:New(value)
                    Dropdown:Destroy(true);
                    value.OrderValue = Dropdown.LayoutOrder
                    ModuleManager._multiplier -= CurrentDropSizeState
                    return ModuleManager:create_dropdown(value)
                end;

                if Library:flag_type(settings.flag, 'string') then
                    DropdownManager:update(Library._config._flags[settings.flag])
                else
                    DropdownManager:update(settings.options[1])
                end
    
                Dropdown.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    DropdownManager:unfold_settings()
                end)

                return DropdownManager
            end

            function ModuleManager:create_feature(settings)

                local checked = false;
                
                LayoutOrderModule = LayoutOrderModule + 1
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size);
                end
            
                Options.Size = UDim2.fromOffset(241, self._size);
            
                local FeatureContainer = Instance.new("Frame")
                FeatureContainer.Size = UDim2.new(0, 207, 0, 16)
                FeatureContainer.BackgroundTransparency = 1
                FeatureContainer.Parent = Options
                FeatureContainer.LayoutOrder = LayoutOrderModule
            
                local UIListLayout = Instance.new("UIListLayout")
                UIListLayout.FillDirection = Enum.FillDirection.Horizontal
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = FeatureContainer
            
                local FeatureButton = Instance.new("TextButton")
                FeatureButton.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                FeatureButton.TextSize = 11;
                FeatureButton.Size = UDim2.new(1, -35, 0, 16)
                FeatureButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                FeatureButton.TextColor3 = Color3.fromRGB(210, 210, 210)
                FeatureButton.Text = "    " .. settings.title or "    " .. "Feature"
                FeatureButton.AutoButtonColor = false
                FeatureButton.TextXAlignment = Enum.TextXAlignment.Left
                FeatureButton.TextTransparency = 0.2
                FeatureButton.Parent = FeatureContainer
            
                local RightContainer = Instance.new("Frame")
                RightContainer.Size = UDim2.new(0, 45, 0, 16)
                RightContainer.BackgroundTransparency = 1
                RightContainer.Parent = FeatureContainer
            
                local RightLayout = Instance.new("UIListLayout")
                RightLayout.Padding = UDim.new(0.1, 0)
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightContainer
            
                local KeybindBox = Instance.new("TextLabel")
                KeybindBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                KeybindBox.Size = UDim2.new(0, 15, 0, 15)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                KeybindBox.TextSize = 11
                KeybindBox.BackgroundTransparency = 1
                KeybindBox.LayoutOrder = 2;
                KeybindBox.Parent = RightContainer
            
                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(1, 0, 1, 0)
                KeybindButton.BackgroundTransparency = 1
                KeybindButton.TextTransparency = 1
                KeybindButton.Parent = KeybindBox

                local CheckboxCorner = Instance.new("UICorner", KeybindBox)
                CheckboxCorner.CornerRadius = UDim.new(0, 3)

                local UIStroke = Instance.new("UIStroke", KeybindBox)
                UIStroke.Color = Color3.fromRGB(255, 255, 255)
                UIStroke.Thickness = 1
                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
                if not Library._config._flags then
                    Library._config._flags = {}
                end
            
                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {
                        checked = false,
                        BIND = settings.default or "Unknown"
                    }
                end
            
                checked = Library._config._flags[settings.flag].checked
                KeybindBox.Text = Library._config._flags[settings.flag].BIND

                if KeybindBox.Text == "Unknown" then
                    KeybindBox.Text = "...";
                end;

                local UseF_Var = nil;
            
                if not settings.disablecheck then
                    local Checkbox = Instance.new("TextButton")
                    Checkbox.Size = UDim2.new(0, 15, 0, 15)
                    Checkbox.BackgroundColor3 = checked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20)
                    Checkbox.Text = ""
                    Checkbox.Parent = RightContainer
                    Checkbox.LayoutOrder = 1;

                    local UIStroke = Instance.new("UIStroke", Checkbox)
                    UIStroke.Color = Color3.fromRGB(255, 255, 255)
                    UIStroke.Thickness = 1
                    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                
                    local CheckboxCorner = Instance.new("UICorner")
                    CheckboxCorner.CornerRadius = UDim.new(0, 3)
                    CheckboxCorner.Parent = Checkbox
            
                    local function toggleState()
                        checked = not checked
                        Checkbox.BackgroundColor3 = checked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20)
                        Library._config._flags[settings.flag].checked = checked
                        Config:save(game.GameId, Library._config)
                        if settings.callback then
                            settings.callback(checked)
                        end
                    end

                    UseF_Var = toggleState
                
                    Checkbox.MouseButton1Click:Connect(toggleState)

                else

                    UseF_Var = function()
                        settings.button_callback();
                    end;

                end;
            
                KeybindButton.MouseButton1Click:Connect(function()
                    KeybindBox.Text = "..."
                    local inputConnection
                    inputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode.Name
                            Library._config._flags[settings.flag].BIND = newKey
                            if newKey ~= "Unknown" then
                                KeybindBox.Text = newKey;
                            end;
                            Config:save(game.GameId, Library._config) -- Save new keybind
                            inputConnection:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                            Library._config._flags[settings.flag].BIND = "Unknown"
                            KeybindBox.Text = "..."
                            Config:save(game.GameId, Library._config)
                            inputConnection:Disconnect()
                        end
                    end)
                    Connections["keybind_input_" .. settings.flag] = inputConnection
                end)
            
                local keyPressConnection
                keyPressConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == Library._config._flags[settings.flag].BIND then
                            UseF_Var();
                        end
                    end
                end)
                Connections["keybind_press_" .. settings.flag] = keyPressConnection
            
                FeatureButton.MouseButton1Click:Connect(function()
                    if settings.button_callback then
                        settings.button_callback()
                    end
                end)

                if not settings.disablecheck then
                    settings.callback(checked);
                end;
            
                return FeatureContainer
            end                    

            return ModuleManager
        end

        return TabManager
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
        local toggleKey = Enum.KeyCode.Insert
        if getgenv().WindUI_ToggleKey then toggleKey = getgenv().WindUI_ToggleKey end
        if input.KeyCode ~= toggleKey then
            return
        end

        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)
    
    task.spawn(function()
        task.wait(0.5)
        self._ui_open = true
        self:change_visiblity(true)
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    return self
end


    local main = Library.new()
    local Window = { _main = main, _tabs = {} }
    
    function Window:Section(secArgs) end
    
    local IconMap = {} -- ICEHUB safety: remote icon-pack execution removed.

    function Window:Tab(tabArgs)
        local title = type(tabArgs) == "table" and tabArgs.Title or tostring(tabArgs)
        local rawIcon = type(tabArgs) == "table" and tabArgs.Icon or ""
        local mappedIcon = IconMap[rawIcon] or rawIcon
        
        local alionTab = main:create_tab(title, mappedIcon, true)
        local Tab = { _tab = alionTab, _current_module = nil, _left = true }
        
        function Tab:Section(secArgs)
            local secTitle = type(secArgs) == "table" and secArgs.Title or tostring(secArgs)
            local side = self._left and "left" or "right"
            self._left = not self._left
            
            self._current_module_settings = {
                title = secTitle,
                flag = secTitle:gsub(" ", "_"),
                description = secTitle,
                section = side,
                callback = function() end
            }
            self._current_secTitle = secTitle
            self._current_module = alionTab:create_module(self._current_module_settings)
        end
        
        function Tab:Toggle(tArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            
            local defVal = tArgs.Default
            if type(defVal) ~= "boolean" then defVal = tArgs.Value end
            if type(defVal) ~= "boolean" then defVal = false end

            if self._current_secTitle == tArgs.Title then
                self._current_module_settings.callback = function(val)
                    if tArgs.Callback then task.spawn(tArgs.Callback, val) end
                end
                
                if self._current_module and self._current_module._state then
                    if tArgs.Callback then task.spawn(tArgs.Callback, self._current_module._state) end
                elseif defVal and self._current_module.change_state then
                    self._current_module:change_state(true)
                elseif defVal and tArgs.Callback then
                    task.spawn(tArgs.Callback, true)
                end
                
                return tArgs
            end

            self._current_module:create_checkbox({
                title = tArgs.Title,
                flag = (tArgs.Flag or tArgs.Title):gsub(" ", "_"),
                description = tArgs.Desc or "",
                callback = tArgs.Callback or function() end
            })
            if defVal and tArgs.Callback then
                task.spawn(tArgs.Callback, true)
            end
            return tArgs
        end
        
        function Tab:Slider(sArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            local valueSettings = type(sArgs.Value) == "table" and sArgs.Value or {}
            local minVal = sArgs.Min or valueSettings.Min or 0
            local maxVal = sArgs.Max or valueSettings.Max or 100
            local defVal = sArgs.Default or valueSettings.Default
            if type(defVal) ~= "number" and type(sArgs.Value) == "number" then defVal = sArgs.Value end
            if type(defVal) ~= "number" then defVal = minVal end
            
            self._current_module:create_slider({
                title = sArgs.Title,
                flag = (sArgs.Flag or sArgs.Title):gsub(" ", "_"),
                minimum_value = minVal,
                maximum_value = maxVal,
                value = defVal,
                callback = sArgs.Callback or function() end
            })
            return sArgs
        end
        
        function Tab:DualSlider(sArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            local valueSettings = type(sArgs.Value) == "table" and sArgs.Value or {}
            
            local limitMin = sArgs.Min or valueSettings.Min or 0
            local limitMax = sArgs.Max or valueSettings.Max or 100
            local defMin = valueSettings.DefaultMin or limitMin
            local defMax = valueSettings.DefaultMax or limitMax
            
            self._current_module:create_dual_slider({
                title = sArgs.Title,
                flag = (sArgs.Flag or sArgs.Title):gsub(" ", "_"),
                minimum_value = limitMin,
                maximum_value = limitMax,
                min_value = defMin,
                max_value = defMax,
                callback = sArgs.Callback or function() end
            })
            return sArgs
        end
        
        function Tab:Button(bArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            self._current_module:create_custom_button({
                title = bArgs.Title,
                description = bArgs.Desc or bArgs.Description or "",
                button_text = bArgs.ButtonText or bArgs.Text or "Run",
                callback = function()
                    if bArgs.Callback then
                        local ok, err = pcall(bArgs.Callback)
                        if not ok then
                            warn("IceHub button callback failed:", err)
                        end
                    end
                end
            })
        end

        function Tab:DiscordPanel(dArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            self._current_module:create_discord_panel({
                title = dArgs.Title,
                callback = function()
                    if dArgs.Callback then
                        task.spawn(dArgs.Callback)
                    end
                end
            })
        end
        
        function Tab:Dropdown(dArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            self._current_module:create_dropdown({
                title = dArgs.Title,
                flag = (dArgs.Flag or dArgs.Title):gsub(" ", "_"),
                options = dArgs.Values or {},
                maximum_options = 5,
                multi_dropdown = false,
                callback = dArgs.Callback or function() end
            })
        end

        function Tab:Input(iArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            self._current_module:create_textbox({
                title = iArgs.Title,
                flag = (iArgs.Flag or iArgs.Title):gsub(" ", "_"),
                callback = iArgs.Callback or function() end
            })
        end
        
        function Tab:Label(lArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            self._current_module:create_text({
                title = type(lArgs) == "table" and (lArgs.Title or lArgs.Text) or tostring(lArgs),
                description = type(lArgs) == "table" and lArgs.Desc or "",
            })
        end
        
        function Tab:Select() end

        function Tab:Keybind(kArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            local defBind = kArgs.Value or kArgs.Default or "Unknown"
            if typeof(defBind) == "EnumItem" then
                defBind = defBind.Name
            end
            
            -- alion doesn't seem to have a create_keybind directly on ModuleManager,
            -- but we can use create_feature if needed, or simply a button as a fallback.
            -- Using create_feature as that's what was in the file, though we will fallback to a button just in case.
            if self._current_module.create_keybind then
                self._current_module:create_keybind({
                    title = kArgs.Title,
                    flag = (kArgs.Flag or kArgs.Title):gsub(" ", "_"),
                    default = defBind,
                    callback = kArgs.Callback or function() end
                })
            else
                self._current_module:create_checkbox({
                    title = "[KEY] " .. kArgs.Title,
                    flag = (kArgs.Flag or kArgs.Title):gsub(" ", "_"),
                    description = kArgs.Desc or "Key: " .. tostring(defBind),
                    callback = function(val)
                        if val and kArgs.Callback then task.spawn(kArgs.Callback, defBind) end
                    end
                })
            end
            return kArgs
        end
        
        function Tab:Colorpicker(cArgs)
            if not self._current_module then self:Section({Title = "General"}) end
            self._current_module:create_colorpicker({
                title = cArgs.Title,
                flag = (cArgs.Flag or cArgs.Title):gsub(" ", "_"),
                color = cArgs.Default or cArgs.Value or Color3.fromRGB(255, 255, 255),
                callback = cArgs.Callback or function() end
            })
            return cArgs
        end

        function Tab:BestSettingsCard(cArgs)
            local side = self._left and "left" or "right"
            self._left = not self._left
            local m = alionTab:create_module({
                title = cArgs.Title or "Best Settings",
                flag = (cArgs.Title or "Best Settings"):gsub(" ", "_"),
                description = cArgs.Subtitle or "",
                section = side,
                callback = function() end
            })
            if type(cArgs.Settings) == "table" then
                for _, s in ipairs(cArgs.Settings) do
                    m:create_text({
                        title = s.Label,
                        description = tostring(s.Value),
                    })
                end
            end
            if cArgs.ButtonText and cArgs.Callback then
                m:create_checkbox({
                    title = "[BUTTON] " .. cArgs.ButtonText,
                    flag = cArgs.ButtonText:gsub(" ", "_"),
                    description = "Execute",
                    callback = function(val)
                        if val then task.spawn(cArgs.Callback) end
                    end
                })
            end
        end

        return Tab
    end
    
    function Window:SelectTab(idx) end
    function Window:Destroy() end

    local WindUI = {}
    function WindUI:CreateWindow(args)
        getgenv().WindUI_ToggleKey = args.ToggleKey or Enum.KeyCode.Insert
        return Window
    end
    function WindUI:Notify(args)
        if Library and Library.SendNotification then
            Library.SendNotification({
                title = args.Title,
                text = args.Content,
                duration = args.Duration or 3
            })
        end
    end
    return WindUI
end


    local WindUI = createIceDarkLibrary()
    getgenv().WindUI = WindUI
    _G.WindUI = WindUI
    pcall(function()
        getfenv().WindUI = WindUI
    end)

    -- New Feature Backend Logic
    getgenv().playerFollowTarget = nil
    getgenv().playerFollowEnabled = false
    getgenv().updatePlayerFollow = function()
        if getgenv().playerFollowEnabled and getgenv().playerFollowTarget then
            if not getgenv().PlayerFollowConnection then
                getgenv().PlayerFollowConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    local targetPlayer = game:GetService("Players"):FindFirstChild(getgenv().playerFollowTarget)
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("PrimaryPart") then
                        local myChar = LocalPlayer.Character
                        if myChar then
                            local hum = myChar:FindFirstChild("Humanoid")
                            if hum then hum:MoveTo(targetPlayer.Character.PrimaryPart.Position) end
                        end
                    end
                end)
            end
        else
            if getgenv().PlayerFollowConnection then
                getgenv().PlayerFollowConnection:Disconnect()
                getgenv().PlayerFollowConnection = nil
            end
        end
    end

    getgenv().BallCameraMode = "None"
    getgenv().BallOrbitSpeed = 50
    getgenv().BallOrbitDistance = 20
    getgenv().BallOrbitAngle = 0
    getgenv().updateBallCamera = function()
        if getgenv().BallCameraMode ~= "None" then
            if not getgenv().BallCameraConnection then
                getgenv().BallCameraConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
                    if getgenv().BallCameraMode == "None" then return end
                    local ball = System.ball.get()
                    if not ball then return end
                    local char = LocalPlayer.Character
                    if not char then return end
                    
                    if getgenv().BallCameraMode == "Look at Ball" then
                        local bPos = ball.Position
                        local cam = workspace.CurrentCamera
                        local cPos = cam.CFrame.Position
                        cam.CFrame = CFrame.new(cPos, Vector3.new(bPos.X, cPos.Y, bPos.Z))
                    elseif getgenv().BallCameraMode == "Orbit Ball" then
                        getgenv().BallOrbitAngle = getgenv().BallOrbitAngle + getgenv().BallOrbitSpeed * dt
                        local bPos = ball.Position
                        local x = math.sin(getgenv().BallOrbitAngle) * getgenv().BallOrbitDistance
                        local z = math.cos(getgenv().BallOrbitAngle) * getgenv().BallOrbitDistance
                        local camPos = bPos + Vector3.new(x, 10, z)
                        workspace.CurrentCamera.CFrame = CFrame.new(camPos, bPos)
                    end
                end)
            end
        else
            if getgenv().BallCameraConnection then
                getgenv().BallCameraConnection:Disconnect()
                getgenv().BallCameraConnection = nil
            end
        end
    end

    getgenv().updateWorldFilters = function()
        local l = game:GetService("Lighting")
        if getgenv().WorldFilter_Atmosphere then
            if not l:FindFirstChild("CustomAtmosphere") then
                local a = Instance.new("Atmosphere")
                a.Name = "CustomAtmosphere"
                a.Parent = l
            end
            l.CustomAtmosphere.Density = getgenv().WorldFilter_Atmosphere_Density or 0.5
        else
            if l:FindFirstChild("CustomAtmosphere") then l.CustomAtmosphere:Destroy() end
        end
        if getgenv().WorldFilter_Fog then
            l.FogEnd = getgenv().WorldFilter_Fog_Distance or 1000
        else
            l.FogEnd = 100000
        end
        local cc = l:FindFirstChildOfClass("ColorCorrectionEffect")
        if not cc then cc = Instance.new("ColorCorrectionEffect", l) end
        cc.Saturation = getgenv().WorldFilter_Saturation and (getgenv().WorldFilter_Saturation_Level or 0) or 0
        cc.TintColor = getgenv().WorldFilter_Hue and Color3.fromHSV(getgenv().WorldFilter_Hue_Shift or 0, 1, 1) or Color3.new(1, 1, 1)
    end

    getgenv().updateCustomSky = function()
        local l = game:GetService("Lighting")
        local sky = l:FindFirstChildOfClass("Sky")
        if getgenv().CustomSkyEnabled then
            if not sky then sky = Instance.new("Sky", l) end
            local skies = {
                ["Default"] = {"591058823","591059876","591058104","591057861","591057625","591059642"},
                ["Vaporwave"] = {"1417494030","1417494145","1417494253","1417494402","1417494499","1417494643"},
                ["Redshift"] = {"8709420542","8709421295","8709422026","8709422681","8709423646","8709424424"},
            }
            local selected = skies[getgenv().CustomSkySelection] or skies["Default"]
            local props = {"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}
            for i, p in ipairs(props) do sky[p] = "rbxassetid://" .. selected[i] end
            l.GlobalShadows = true
        else
            if sky then sky:Destroy() end
        end
    end

    getgenv().updatePingSpoofer = function()
        if getgenv().PingSpooferEnabled then
            if not getgenv().PingSpooferConnection then
                getgenv().PingSpooferConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    local fakePing = tostring(math.floor(getgenv().PingSpoofedValue or 999)) .. " ms"
                    local robloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
                    if robloxGui then
                        local perfStats = robloxGui:FindFirstChild("PerformanceStats")
                        if perfStats then
                            for _, v in ipairs(perfStats:GetDescendants()) do
                                if v:IsA("TextLabel") and v.Text:match("%d+ ms") then v.Text = fakePing end
                            end
                        end
                    end
                end)
            end
        else
            if getgenv().PingSpooferConnection then
                getgenv().PingSpooferConnection:Disconnect()
                getgenv().PingSpooferConnection = nil
            end
        end
    end

    local Window = WindUI:CreateWindow({
        Title = "ICEHUB | PURPLE GLASS",
        ToggleKey = Enum.KeyCode.K,
    })

    -- ══ SECTIONS & TABS ═══════════════════════════════════════════════

    -- Auto Config
    local AutoConfig = {
        File = "IceHubX/auto_config.json",
        Data = {},
        SaveQueued = false,
    }
    getgenv()._lhxAutoConfig = AutoConfig

    pcall(function()
        if isfile and isfile(AutoConfig.File) then
            local decoded = HttpService:JSONDecode(readfile(AutoConfig.File))
            if type(decoded) == "table" then
                AutoConfig.Data = decoded
            end
        end
    end)

    function autoConfigSanitize(value)
        return tostring(value or "Option"):gsub("%s+", "_"):gsub("[^%w_%-]", "")
    end

    function autoConfigSave()
        pcall(function()
            if isfolder and makefolder and not isfolder("IceHubX") then
                makefolder("IceHubX")
            end
            if writefile then
                writefile(AutoConfig.File, HttpService:JSONEncode(AutoConfig.Data))
            end
        end)
    end

    function autoConfigQueueSave()
        if AutoConfig.SaveQueued then return end
        AutoConfig.SaveQueued = true
        task.delay(0.2, function()
            AutoConfig.SaveQueued = false
            autoConfigSave()
        end)
    end
    getgenv()._lhxAutoConfigQueueSave = autoConfigQueueSave

    function autoConfigKey(tabTitle, args)
        return autoConfigSanitize(tabTitle) .. "." .. autoConfigSanitize(args.Flag or args.Title)
    end

    function autoConfigNormalize(kind, value)
        if kind == "Keybind" and typeof(value) == "EnumItem" then
            return value.Name
        end
        return value
    end

    function autoConfigApplyValue(kind, args, value)
        if kind == "Slider" and type(args.Value) == "table" then
            args.Value.Default = value
        elseif kind == "Input" then
            args.Value = value
            args.Default = value
            args.Text = value
        else
            args.Value = value
        end
    end

    function autoConfigDropdownHasValue(args, value)
        if type(args.Values) ~= "table" then return true end
        for _, option in ipairs(args.Values) do
            if option == value then return true end
        end
        return false
    end

    function autoConfigPatchTab(tab, tabTitle)
        if type(tab) ~= "table" or tab.__lhxAutoConfigPatched then return tab end
        tab.__lhxAutoConfigPatched = true

        local function patchMethod(methodName, kind)
            local original = tab[methodName]
            if type(original) ~= "function" then return end

            tab[methodName] = function(self, args)
                if type(args) ~= "table" or not args.Title or tabTitle == "Bugs Reports" then
                    return original(self, args)
                end

                local key = autoConfigKey(tabTitle, args)
                if tabTitle == "Skin" and kind == "Dropdown" and args.Title == "Favorite List" then
                    if AutoConfig.Data[key] ~= nil then
                        AutoConfig.Data[key] = nil
                        autoConfigQueueSave()
                    end
                    return original(self, args)
                end

                if (tabTitle == "Unlock All" and args.Title == "Unlock All") or (tabTitle == "Visual" and args.Title == "Emotes") then
                    if AutoConfig.Data[key] ~= nil then
                        AutoConfig.Data[key] = nil
                        autoConfigQueueSave()
                    end
                    return original(self, args)
                end

                local saved = AutoConfig.Data[key]
                local hasSaved = saved ~= nil and (kind ~= "Dropdown" or autoConfigDropdownHasValue(args, saved))
                if hasSaved then
                    autoConfigApplyValue(kind, args, saved)
                end

                local callback = args.Callback
                args.Callback = function(value, ...)
                    AutoConfig.Data[key] = autoConfigNormalize(kind, value)
                    autoConfigQueueSave()
                    if callback then
                        return callback(value, ...)
                    end
                end

                local control = original(self, args)

                if hasSaved and callback then
                    task.defer(function()
                        pcall(callback, saved)
                    end)
                end

                return control
            end
        end

        patchMethod("Toggle", "Toggle")
        patchMethod("Dropdown", "Dropdown")
        patchMethod("Slider", "Slider")
        patchMethod("Keybind", "Keybind")
        patchMethod("Input", "Input")

        return tab
    end

    do
        local originalTab = Window.Tab
        if type(originalTab) == "function" then
            Window.Tab = function(self, args)
                local tab = originalTab(self, args)
                return autoConfigPatchTab(tab, args and args.Title or "Tab")
            end
        end
    end

    local BestSettingsControls = {}

    function applyBlatantBestSettings()
        local function setControl(name, value)
            local control = BestSettingsControls[name]
            if control and control.Set then
                control:Set(value)
            end
        end

        -- Configure timing first, then enable Auto Parry with the completed profile.
        setControl("ParryAccuracy", 1)
        setControl("RandomizedAccuracy", true)
        setControl("CurveDirection", "Random")
        setControl("CooldownProtection", false)
        setControl("ManualSpam", false)
        setControl("AutoSpamParry", true)
        setControl("AnimationFix", true)
        setControl("ParryMode", "Remote")
        setControl("AutoParry", true)

        WindUI:Notify({
            Title = "Best Settings",
            Content = "Recommended Blatant profile applied.",
            Duration = 3,
        })
    end



    Window:Section({ Title = "Main" })

    local MainTab = Window:Tab({ Title = "Main", Icon = "layout-dashboard" })

    -- ESP Section
    MainTab:Section({ Title = "ESP" })

    MainTab:Toggle({
        Title = "ESP Enabled", Desc = "Show players on screen",
        Value = false,
        Callback = function(v) getgenv().espEnabled = v; getgenv().updateESP() end,
    })

    MainTab:Toggle({
        Title = "ESP Boxes", Desc = "Show boxes around players",
        Value = false,
        Callback = function(v) getgenv().espBoxes = v; getgenv().updateESP() end,
    })
    MainTab:Toggle({
        Title = "Ability ESP", Desc = "Show active ability of each player above their head",
        Value = false,
        Callback = function(v) getgenv().espAbility = v; getgenv().updateESP() end,
    })

    MainTab:Section({ Title = "Ball Analytics" })

    MainTab:Toggle({
        Title = "Ball ESP", Desc = "Show ball target and speed",
        Value = false,
        Callback = function(v) getgenv().ballESP = v end,
    })
    MainTab:Toggle({
        Title = "Ball Tracer", Desc = "Show trajectory line from your character to the ball",
        Value = false,
        Callback = function(v) getgenv().ballTracer = v end,
    })

    -- Auto Section
    MainTab:Section({ Title = "Auto" })

    MainTab:Toggle({
        Title = "Auto Play", Desc = "Automatically plays the game for you",
        Value = false,
        Callback = function(v)
            getgenv().autoPlay = v
            if v then AutoPlayModule.runThread() else AutoPlayModule.finishThread() end
        end,
    })
    MainTab:Toggle({
        Title = "Auto Vote", Desc = "Automatically votes in lobby",
        Value = false,
        Callback = function(v) getgenv().autoVote = v end,
    })
    MainTab:Toggle({
        Title = "Auto Ability", Desc = "Automatically uses sword ability",
        Value = false,
        Callback = function(v) getgenv().autoAbility = v end,
    })

    -- ══ BLATANT TAB ═══════════════════════════════════════════════════

    local BlatantTab = Window:Tab({ Title = "Blatant", Icon = "swords" })

    BlatantTab:Section({ Title = "Auto Parry" })

    BestSettingsControls.AutoParry = BlatantTab:Toggle({
        Title = "Auto Parry",
        Desc = "Otomatik top parlay",
        Value = false,
        Callback = function(v)
            if v then startAutoParry() else stopAutoParry() end
        end,
    })

    BestSettingsControls.ParryMode = BlatantTab:Dropdown({
        Title = "Parry Mode",
        Desc = "Saldırı engelleme yöntemi",
        Values = {"Remote", "Keypress", "Hardware click"},
        Value = getgenv().SelectedParryMode or "Remote",
        Callback = function(v)
            getgenv().SelectedParryMode = v
        end,
    })

    BestSettingsControls.ParryAccuracy = BlatantTab:Slider({
        Title = "Parry Accuracy",
        Desc = "Otomatik parlay doğruluğu (Random kapalıysa geçerli)",
        Flag = "ParryAccuracyVal",
        Min = 1,
        Max = 100,
        Value = getgenv().parryAccuracy or 100,
        Callback = function(v)
            getgenv().parryAccuracy = v
            System.__properties.__accuracy = v
            update_divisor()
            
            if not HumanizerEnabled then
                AccuracyMin = v
                AccuracyMax = v
            end
        end,
    })
    BestSettingsControls.HumanizerToggle = BlatantTab:Toggle({
        Title = "Randomize Accuracy",
        Desc = "Her top değişiminde slider'daki aralıkta rastgele accuracy üretir.",
        Value = HumanizerEnabled,
        Callback = function(state)
            HumanizerEnabled = state
            System.__properties.__randomized_accuracy_enabled = state
            if not state then
                -- Eger kapatilirsa, o anki accuracy degeri sabit kalir (slider'in ortasi gibi)
                AccuracyMin = getgenv().parryAccuracy or 100
                AccuracyMax = getgenv().parryAccuracy or 100
            end
        end,
    })

    BestSettingsControls.RandomizedAccuracy = BlatantTab:DualSlider({
        Title = "Random Accuracy",
        Flag = "RandomAccuracyVals",
        Min = 1,
        Max = 100,
        Value = { DefaultMin = 25, DefaultMax = 85 },
        Callback = function(v)
            -- v is {min, max}
            local mn, mx = v[1], v[2]
            
            -- Sadece Humanizer aciksa min/max ayarla, kapaliysa arka plani guncelle ama anlik state'i degistirme
            if HumanizerEnabled then
                AccuracyMin = mn
                AccuracyMax = mx
            end
            
            -- Ortalamasini normal parryAccuracy olarak kaydet (hem fallback icin hem de Humanizer kapaliykenkullanilsin diye)
            getgenv().parryAccuracy = math.floor((mn + mx) / 2)
            System.__properties.__accuracy = getgenv().parryAccuracy
            
            if not HumanizerEnabled then
                AccuracyMin = getgenv().parryAccuracy
                AccuracyMax = getgenv().parryAccuracy
            end
            
            update_divisor()
        end,
    })

    BestSettingsControls.CurveDirection = BlatantTab:Dropdown({
        Title = "Auto Curve Direction",
        Desc = "Parlay eğri yönü",
        Values = System.__config.__curve_names,
        Value = "Camera",
        Callback = function(v)
            System.__properties.__curve_mode =
                table.find(System.__config.__curve_names, v) or 1
            Selected_Parry_Type = v
            getgenv().CurrentCurveMethod = v
        end,
    })

    BestSettingsControls.CooldownProtection = BlatantTab:Toggle({
        Title = "Cooldown Protection",
        Desc = "Blok cooldown düşükken beceriyi kullanır",
        Value = false,
        Callback = function(v) CooldownProtect = v end,
    })

    BlatantTab:Section({ Title = "Manuel Spam" })

    BestSettingsControls.ManualSpam = BlatantTab:Toggle({
        Title = "Manuel Spam",
        Desc = "Düğmeye dokun UI veya tuşa bas",
        Value = false,
        Callback = function(v)
            ManualSpamEnabled = v
            getgenv().ManualSpamEnabled = v
            if UserInputService.TouchEnabled then
                if getgenv().SpamGui then getgenv().SpamGui.Enabled = v end
            end
            if not v and getgenv().setSpam then getgenv().setSpam(false) end
        end,
    })

    BlatantTab:Keybind({
        Title = "Spam Key",
        Desc = "Spam toggle tuşu",
        Value = "E",
        Callback = function(v)
            if Enum.KeyCode[v] then
                getgenv().autoSpamKey = Enum.KeyCode[v]
            end
        end
    })

    BlatantTab:Toggle({
        Title = "Spam Notify",
        Desc = "Spam açılıp kapandığında bildirim göster",
        Value = false,
        Callback = function(state)
            getgenv().autoSpamNotify = state
        end
    })

    AnimFix = true
    System.__properties.__play_animation = true
    getgenv().AnimFix = true

    BestSettingsControls.AnimationFix = {
        Set = function() end
    }

    BlatantTab:Section({ Title = "Auto Spam Parry" })

    BestSettingsControls.AutoSpamParry = BlatantTab:Toggle({
        Title = "Auto Spam Parry",
        Desc = "Otomatik spam parlay",
        Value = false,
        Callback = function(v)
            autoSpamParryEnabled = v
            if v then startAutoSpamParry() else stopAutoSpamParry() end
        end,
    })

    BlatantTab:Section({ Title = "Lobby Auto Parry" })

    BestSettingsControls.LobbyAutoParry = BlatantTab:Toggle({
        Title = "Lobby Auto Parry",
        Desc = "Lobideki training topunu parlay",
        Value = false,
        Callback = function(v)
            if v then
                startLobbyAutoParry()
            else
                stopLobbyAutoParry()
            end
        end,
    })

    BestSettingsControls.LobbyParryAccuracy = BlatantTab:Slider({
        Flag = "LobbyParryAccuracyVal",
        Title = "Lobby Parry Accuracy",
        Desc = "Lobi parlay doğruluğu (1-100)",
        Step = 1,
        Value = { Min = 1, Max = 100, Default = 100 },
        Callback = function(v)
            getgenv().lobbyParryAccuracy = v
            getgenv().updateLobbyAutoParry()
        end,
    })

    BestSettingsControls.LobbyRandomAccuracy = BlatantTab:Toggle({
        Title = "Lobby Random Accuracy",
        Desc = "Lobi doğruluğunu rastgele ayarlar",
        Value = false,
        Callback = function(v)
            getgenv().lobbyRandomAccuracy = v
        end,
    })

    BestSettingsControls.LobbyParryKeypress = BlatantTab:Toggle({
        Title = "Lobby Parry Keypress",
        Desc = "Lobi parry akışını tuş benzeri zamanlar",
        Value = false,
        Callback = function(v)
            getgenv().lobbyParryKeypress = v
        end,
    })



    BlatantTab:Section({ Title = "Semi Immortal" })
    BlatantTab:Toggle({
        Title = "Semi Immortal",
        Desc = "Walkable semi immortal desync",
        Value = false,
        Callback = function(v)
            setSemiImmortalBeta(v)
        end,
    })

    -- ══ DETECTION TAB ═════════════════════════════════════════════════

    function _buildDetectionTab()
        local DetectionTab = Window:Tab({ Title = "Detection", Icon = "radar" })

    DetectionTab:Section({ Title = "Infinity Detection" })
    DetectionTab:Toggle({
        Title = "Infinity Detection", Desc = "Skips parry during Infinity",
        Value = false,
        Callback = function(v)
            detections.infinity = v
            System.__config.__detections.__infinity = v
        end,
    })

    DetectionTab:Section({ Title = "Death Slash Detection" })
    DetectionTab:Toggle({
        Title = "Death Slash Detection", Desc = "Skips parry during Death Slash",
        Value = false,
        Callback = function(v)
            detections.deathslash = v
            System.__config.__detections.__deathslash = v
        end,
    })

    DetectionTab:Section({ Title = "Time Hole Detection" })
    DetectionTab:Toggle({
        Title = "Time Hole Detection", Desc = "Skips parry during Time Hole",
        Value = false,
        Callback = function(v)
            detections.timehole = v
            System.__config.__detections.__timehole = v
        end,
    })

    DetectionTab:Section({ Title = "Pull Detection" })
    DetectionTab:Toggle({
        Title = "Pull Detection", Desc = "Skips parry during Pull",
        Value = false,
        Callback = function(v)
            detections.pull = v
            System.__config.__detections.__pull = v
        end,
    })

    DetectionTab:Section({ Title = "Anti-Phantom" })
    DetectionTab:Toggle({
        Title = "Anti-Phantom", Desc = "Protection against Phantom",
        Value = false,
        Callback = function(v)
            detections.phantom = v
            System.__config.__detections.__phantom = v
        end,
    })

    DetectionTab:Section({ Title = "Slashes of Fury" })
    DetectionTab:Toggle({
        Title = "Slashes of Fury", Desc = "Auto-parry during Slashes of Fury",
        Value = false,
        Callback = function(v)
            detections.slashesoffury = v
            System.__config.__detections.__slashesoffury = v
        end,
    })
    end
    _buildDetectionTab()

    -- ══ SKIN TAB ══════════════════════════════════════════════════════

    function _buildSkinTab()
    local isXeno = false
    pcall(function()
        local exec = (identifyexecutor or function() return "" end)()
        if type(exec) == "string" and exec:find("Xeno") then isXeno = true end
    end)

    if not isXeno then
        local SkinTab = Window:Tab({ Title = "Unlock All", Icon = "box" })

        if false then -- User requested to hide these but keep the code
            (function()
        -- Favorites system
        local FAV_FILE = "IceHubX/fav_swords.json"
        local favoriteSwords = {}
        local function saveFavs()
            pcall(function()
                if not isfolder("IceHubX") then makefolder("IceHubX") end
                writefile(FAV_FILE, HttpService:JSONEncode(favoriteSwords))
            end)
        end
        local function loadFavs()
            if isfile and isfile(FAV_FILE) then
                local ok, data = pcall(function() return HttpService:JSONDecode(readfile(FAV_FILE)) end)
                if ok and type(data) == "table" then favoriteSwords = data end
            end
        end
        loadFavs()
        local favOptions = {}
        local function refreshFavList()
            table.clear(favOptions)
            for _, s in ipairs(favoriteSwords) do table.insert(favOptions, s) end
            if #favOptions == 0 then table.insert(favOptions, "No Favorites") end
        end
        refreshFavList()

            local skinChangerToggle = SkinTab:Toggle({
                Title = "Skin Changer", Desc = "Changes your sword skin",
                Value = false,
                Callback = function(v)
                    getgenv().skinChanger = v
                    if v and getgenv().swordModel ~= "" then
                        if getgenv().updateSword then getgenv().updateSword() end
                    end
                end,
            })
            getgenv().setSkinChangerToggleUI = function(value)
                if skinChangerToggle and skinChangerToggle.Set then
                    skinChangerToggle:Set(value)
                end
            end

            local skinSwordInput = SkinTab:Input({
                Title = "Sword Name", Desc = "Enter the sword name",
                Placeholder = "Sword Name...",
                Callback = function(text)
                    getgenv().swordModel = text
                    getgenv().swordAnimations = text
                    getgenv().swordFX = text
                    if getgenv().skinChanger and text ~= "" then
                        if getgenv().updateSword then getgenv().updateSword() end
                    end
                end,
            })

            local favDropdown
            favDropdown = SkinTab:Dropdown({
                Title = "Favorite List", Desc = "Favorite Swords",
                Values = favOptions,
                Value = "No Favorites",
                Callback = function(value)
                    if value ~= "No Favorites" then
                        getgenv().swordModel = value
                        getgenv().swordAnimations = value
                        getgenv().swordFX = value
                        if skinSwordInput and skinSwordInput.Set then skinSwordInput:Set(value) end
                        if getgenv().skinChanger then
                            if getgenv().updateSword then getgenv().updateSword() end
                        end
                    end
                end,
            })

            SkinTab:Button({
                Title = "Remove Current from Favorites", Desc = "Removes current sword from favorites",
                ButtonText = "Remove",
                Callback = function()
                    local current = getgenv().swordModel
                    local removed = false
                    for i, s in ipairs(favoriteSwords) do
                        if s == current then
                            table.remove(favoriteSwords, i); saveFavs(); refreshFavList()
                            if favDropdown and favDropdown.SetOptions then pcall(function() favDropdown:SetOptions(favOptions) end) end
                            WindUI:Notify({ Title = "Favorites", Content = current .. " removed from favorites.", Duration = 3 })
                            removed = true
                            break
                        end
                    end
                    if not current or current == "" then
                        WindUI:Notify({ Title = "Favorites", Content = "Enter a sword name first.", Duration = 3 })
                    elseif not removed then
                        WindUI:Notify({ Title = "Favorites", Content = current .. " is not in favorites.", Duration = 3 })
                    end
                end,
            })
            end)()
        end

        getgenv().setExplosionChangerToggleUI = function() end
        getgenv().setExplosionInputUI = function() end
        getgenv().setExplosionApplyText = function() end
        getgenv().setIceHubShopButtonText = function(button, text)
            if not button then return end
            for _, textObject in ipairs(button:GetDescendants()) do
                if textObject:IsA("TextLabel")
                    or textObject:IsA("TextButton")
                    or textObject:IsA("TextBox") then
                    textObject.Text = text
                end
            end
            if button:IsA("TextButton") then
                button.Text = text
            end
        end
        getgenv().forceIceHubShopEquippedText = function(shop, button, kind, itemName)
            getgenv()._lhxShopForcedEquip = {
                Button = button,
                Kind = kind,
                Name = itemName,
                Until = os.clock() + 2.5,
            }

            local function applyOnce()
                local targetButton = button
                if (not targetButton or not targetButton.Parent) and shop and shop:FindFirstChild("Holder") then
                    local infoBG = shop.Holder:FindFirstChild("InfoBG")
                    targetButton = infoBG and (infoBG:FindFirstChild("BuyButton") or infoBG:FindFirstChild("EquipButton"))
                    if not targetButton and infoBG then
                        for _, child in ipairs(infoBG:GetChildren()) do
                            if (child:IsA("TextButton") or child:IsA("ImageButton")) and not child.Name:lower():find("close") then
                                targetButton = child
                                break
                            end
                        end
                    end
                end
                getgenv().setIceHubShopButtonText(targetButton, "Equipped")
            end

            applyOnce()
            task.spawn(function()
                while os.clock() < getgenv()._lhxShopForcedEquip.Until do
                    applyOnce()
                    task.wait(0.05)
                end
            end)
        end

        SkinTab:Section({ Title = "Unlock All" })
        SkinTab:Toggle({
            Title = "Unlock All",
            Desc = "Unlocks sword and explosion shop pages locally",
            Value = false,
            Callback = function(v)
                if not v then return end
                local player = game:GetService("Players").LocalPlayer
                local shop = player.PlayerGui:FindFirstChild("Shop")
                if not shop then
                    WindUI:Notify({ Title = "Error", Content = "Shop GUI not found!", Duration = 3 })
                    return
                end

                if not getgenv().unlockAllHooked then
                    getgenv().unlockAllHooked = true
                    getgenv().skinChanger = true
                    getgenv().explosionChanger = true
                    if getgenv().setSkinChangerToggleUI then getgenv().setSkinChangerToggleUI(true) end
                    if getgenv().setExplosionChangerToggleUI then getgenv().setExplosionChangerToggleUI(true) end

                    task.spawn(function()
                        while task.wait(0.15) do
                            local pages = shop.Holder and shop.Holder:FindFirstChild("Pages")
                            for _, pageName in ipairs({"Sword", "Explosion"}) do
                                local page = pages and pages:FindFirstChild(pageName)
                                if page then
                                    local unownedHeader = page:FindFirstChild("HeaderTitle")
                                    if unownedHeader then
                                        unownedHeader.Visible = false
                                    end

                                    for _, child in ipairs(page:GetDescendants()) do
                                        if child.Name == "Lock" and child:IsA("GuiObject") then
                                            child.Visible = false
                                            local itemCard = child.Parent
                                            if itemCard and itemCard:IsA("GuiObject") then
                                                itemCard.LayoutOrder = 0
                                                if itemCard.Parent and itemCard.Parent.Name == "Unowned" then
                                                    local ownedContainer = page:FindFirstChild("Owned", true)
                                                    if ownedContainer and ownedContainer:IsA("GuiObject") then
                                                        itemCard.Parent = ownedContainer
                                                    end
                                                end
                                                
                                                local favBtn = itemCard:FindFirstChild("Favorite", true) or itemCard:FindFirstChild("Star", true)
                                                local delBtn = itemCard:FindFirstChild("Delete", true) or itemCard:FindFirstChild("Trash", true)
                                                
                                                if favBtn and favBtn:IsA("GuiObject") then favBtn.Visible = true end
                                                if delBtn and delBtn:IsA("GuiObject") then delBtn.Visible = true end
                                                
                                                if not itemCard:FindFirstChild("IceHubHooked") then
                                                    local tag = Instance.new("BoolValue", itemCard)
                                                    tag.Name = "IceHubHooked"
                                                    
                                                    local itemName = itemCard.Name
                                                    local titleObj = itemCard:FindFirstChild("Title", true) or itemCard:FindFirstChild("ItemName", true) or itemCard:FindFirstChild("Name", true)
                                                    if titleObj and titleObj:IsA("TextLabel") then itemName = titleObj.Text end
                                                    
                                                    if favBtn and (favBtn:IsA("GuiButton") or favBtn:IsA("ImageButton") or favBtn:IsA("TextButton")) then
                                                        favBtn.MouseButton1Click:Connect(function()
                                                            local found = false
                                                            for _, s in ipairs(favoriteSwords) do if s == itemName then found = true; break end end
                                                            if not found then
                                                                table.insert(favoriteSwords, itemName)
                                                                pcall(function() saveFavs() end)
                                                                pcall(function() refreshFavList() end)
                                                                WindUI:Notify({ Title = "Favorites", Content = itemName .. " added to favorites.", Duration = 3 })
                                                            else
                                                                WindUI:Notify({ Title = "Favorites", Content = itemName .. " is already in favorites.", Duration = 3 })
                                                            end
                                                        end)
                                                    end
                                                    
                                                    if delBtn and (delBtn:IsA("GuiButton") or delBtn:IsA("ImageButton") or delBtn:IsA("TextButton")) then
                                                        delBtn.MouseButton1Click:Connect(function()
                                                            local removed = false
                                                            for i, s in ipairs(favoriteSwords) do
                                                                if s == itemName then
                                                                    table.remove(favoriteSwords, i)
                                                                    pcall(function() saveFavs() end)
                                                                    pcall(function() refreshFavList() end)
                                                                    WindUI:Notify({ Title = "Favorites", Content = itemName .. " removed from favorites.", Duration = 3 })
                                                                    removed = true
                                                                    break
                                                                end
                                                            end
                                                            if not removed then
                                                                WindUI:Notify({ Title = "Favorites", Content = itemName .. " is not in favorites.", Duration = 3 })
                                                            end
                                                        end)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            local infoBG = shop.Holder:FindFirstChild("InfoBG")
                            if infoBG then
                                local targetBtn = infoBG:FindFirstChild("BuyButton") or infoBG:FindFirstChild("EquipButton")

                                if not targetBtn then
                                    for _, child in ipairs(infoBG:GetChildren()) do
                                        if (child:IsA("TextButton") or child:IsA("ImageButton")) and not child.Name:lower():find("close") then
                                            targetBtn = child
                                            break
                                        end
                                    end
                                end

                                if targetBtn then
                                    local pages = shop.Holder and shop.Holder:FindFirstChild("Pages")
                                    local swordPage = pages and pages:FindFirstChild("Sword")
                                    local explosionPage = pages and pages:FindFirstChild("Explosion")
                                    local activeSkinPage = (swordPage and swordPage.Visible and swordPage)
                                        or (explosionPage and explosionPage.Visible and explosionPage)
                                    if not activeSkinPage then
                                        continue
                                    end
                                    targetBtn.Visible = true

                                    local forcedEquip = getgenv()._lhxShopForcedEquip
                                    local activeKindForButton = activeSkinPage == explosionPage and "Explosion" or "Sword"
                                    if forcedEquip
                                        and forcedEquip.Until
                                        and os.clock() < forcedEquip.Until
                                        and forcedEquip.Kind == activeKindForButton then
                                        getgenv().setIceHubShopButtonText(targetBtn, "Equipped")
                                    else
                                        local txt = targetBtn:FindFirstChildOfClass("TextLabel")
                                        if txt and txt.Text ~= "Equip" and txt.Text ~= "Equipped" then txt.Text = "Equip" end
                                        if targetBtn:IsA("TextButton") and targetBtn.Text ~= "Equip" and targetBtn.Text ~= "Equipped" then targetBtn.Text = "Equip" end
                                    end

                                    if not targetBtn:FindFirstChild("SkinChangerHooked") then
                                        local hookTag = Instance.new("BoolValue", targetBtn)
                                        hookTag.Name = "SkinChangerHooked"

                                        targetBtn.MouseButton1Click:Connect(function()
                                            local pages = shop.Holder and shop.Holder:FindFirstChild("Pages")
                                            local swordPage = pages and pages:FindFirstChild("Sword")
                                            local explosionPage = pages and pages:FindFirstChild("Explosion")
                                            local activePage = (swordPage and swordPage.Visible and swordPage)
                                                or (explosionPage and explosionPage.Visible and explosionPage)
                                            local activeKind = activePage == explosionPage and "Explosion" or "Sword"
                                            if not activePage then
                                                return
                                            end

                                            local infoBG = shop.Holder:FindFirstChild("InfoBG")
                                            if not infoBG then
                                                return
                                            end

                                            local itemName = ""
                                            local bestY = math.huge
                                            local bestX = math.huge

                                            local function scoreTextLabel(label)
                                                if not label or not label:IsA("TextLabel") and not label:IsA("TextButton") and not label:IsA("TextBox") then
                                                    return
                                                end
                                                if label.Visible == false then return end

                                                local text = tostring(label.Text or ""):gsub("<[^>]+>", "")
                                                text = text:gsub("^%s+", ""):gsub("%s+$", "")
                                                local cleanText = text:gsub(",", ""):gsub(" ", "")
                                                local lowered = text:lower()
                                                local isNumber = tonumber(cleanText) ~= nil

                                                if text == "" or text == "Title" or text == "Equip" or text == "Equipped" or text == "Buy" then return end
                                                if lowered == "sword" or lowered == "swords"
                                                    or lowered == "explosion" or lowered == "explosions"
                                                    or lowered == "skin" or lowered == "skins"
                                                    or lowered == "shop" or lowered == "owned (unlocked)" then return end
                                                if isNumber or lowered:find("coins", 1, true) or lowered:find("owned", 1, true) then return end
                                                if #text < 4 or #text > 40 then return end

                                                local pos = label.AbsolutePosition
                                                local yPos = pos and pos.Y or math.huge
                                                local xPos = pos and pos.X or math.huge
                                                if yPos < bestY or (yPos == bestY and xPos < bestX) then
                                                    bestY = yPos
                                                    bestX = xPos
                                                    itemName = text
                                                end
                                            end

                                            local function scan(parent)
                                                for _, child in ipairs(parent:GetChildren()) do
                                                    scoreTextLabel(child)
                                                    scan(child)
                                                end
                                            end

                                            local titleLabel = infoBG:FindFirstChild("Title", true)
                                                or infoBG:FindFirstChild("ItemName", true)
                                                or infoBG:FindFirstChild("Name", true)
                                                or infoBG:FindFirstChild("SwordName", true)
                                                or infoBG:FindFirstChild("ExplosionName", true)
                                                or infoBG:FindFirstChild("HeaderTitle", true)
                                            scoreTextLabel(titleLabel)
                                            scan(infoBG)
                                            if itemName == "" then
                                                scan(activePage)
                                            end

                                            if itemName ~= "" and itemName ~= "Title" then
                                                getgenv().forceIceHubShopEquippedText(shop, targetBtn, activeKind, itemName)

                                                if activeKind == "Explosion" then
                                                    getgenv().explosionFX = itemName
                                                    getgenv().explosionChanger = true
                                                    if getgenv().setExplosionChangerToggleUI then getgenv().setExplosionChangerToggleUI(true) end
                                                    if getgenv().setExplosionInputUI then getgenv().setExplosionInputUI(itemName) end
                                                    getgenv().setExplosionApplyText("Equipped")
                                                    if getgenv().updateExplosion then
                                                        task.spawn(function()
                                                            getgenv().updateExplosion()
                                                        end)
                                                    end
                                                else
                                                    getgenv().swordModel = itemName
                                                    getgenv().swordAnimations = itemName
                                                    getgenv().swordFX = itemName
                                                    getgenv().skinChanger = true

                                                    if getgenv().setSkinChangerToggleUI then getgenv().setSkinChangerToggleUI(true) end
                                                    --if skinSwordInput and skinSwordInput.Set then skinSwordInput:Set(itemName) end
                                                    if getgenv().updateSword then getgenv().updateSword() end
                                                end

                                                getgenv().forceIceHubShopEquippedText(shop, targetBtn, activeKind, itemName)
                                            end
                                        end)
                                    end
                                    
                                    local equipsContainer = infoBG:FindFirstChild("Equips")
                                    local finisherBtn = (equipsContainer and equipsContainer:FindFirstChild("Finisher")) or infoBG:FindFirstChild("Finisher")
                                    if finisherBtn and (finisherBtn:IsA("GuiButton") or finisherBtn:IsA("TextButton") or finisherBtn:IsA("ImageButton") or finisherBtn:IsA("GuiObject")) then
                                        finisherBtn.Visible = true
                                        local txt = finisherBtn:FindFirstChildOfClass("TextLabel")
                                        if txt and txt.Text ~= "Equip" and txt.Text ~= "Equipped" then txt.Text = "Equip" end
                                        
                                        if not finisherBtn:FindFirstChild("FinisherChangerHooked") then
                                            local hookTag = Instance.new("BoolValue", finisherBtn)
                                            hookTag.Name = "FinisherChangerHooked"
                                            
                                            finisherBtn.InputBegan:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    local pages = shop.Holder and shop.Holder:FindFirstChild("Pages")
                                                    local swordPage = pages and pages:FindFirstChild("Sword")
                                                    if not swordPage or not swordPage.Visible then return end
                                                    
                                                    local itemName = ""
                                                    local bestY = math.huge
                                                    local bestX = math.huge

                                                    local function scoreTextLabel(label)
                                                        if not label or not label:IsA("TextLabel") and not label:IsA("TextButton") and not label:IsA("TextBox") then return end
                                                        if label.Visible == false then return end
                                                        local text = tostring(label.Text or ""):gsub("<[^>]+>", "")
                                                        text = text:gsub("^%s+", ""):gsub("%s+$", "")
                                                        local cleanText = text:gsub(",", ""):gsub(" ", "")
                                                        local lowered = text:lower()
                                                        local isNumber = tonumber(cleanText) ~= nil

                                                        if text == "" or text == "Title" or text == "Equip" or text == "Equipped" or text == "Buy" then return end
                                                        if lowered == "sword" or lowered == "swords" or lowered == "explosion" or lowered == "explosions" or lowered == "skin" or lowered == "skins" or lowered == "shop" or lowered == "owned (unlocked)" then return end
                                                        if isNumber or lowered:find("coins", 1, true) or lowered:find("owned", 1, true) then return end
                                                        if #text < 4 or #text > 40 then return end

                                                        local pos = label.AbsolutePosition
                                                        local yPos = pos and pos.Y or math.huge
                                                        local xPos = pos and pos.X or math.huge
                                                        if yPos < bestY or (yPos == bestY and xPos < bestX) then
                                                            bestY = yPos
                                                            bestX = xPos
                                                            itemName = text
                                                        end
                                                    end

                                                    local function scan(parent)
                                                        for _, child in ipairs(parent:GetChildren()) do
                                                            scoreTextLabel(child)
                                                            scan(child)
                                                        end
                                                    end

                                                    local titleLabel = infoBG:FindFirstChild("Title", true) or infoBG:FindFirstChild("ItemName", true) or infoBG:FindFirstChild("Name", true) or infoBG:FindFirstChild("SwordName", true) or infoBG:FindFirstChild("HeaderTitle", true)
                                                    scoreTextLabel(titleLabel)
                                                    scan(infoBG)
                                                    if itemName == "" then scan(swordPage) end

                                                    if itemName ~= "" and itemName ~= "Title" then
                                                        getgenv().finisherModel = itemName
                                                        if getgenv().saveLastEquippedFinisher then getgenv().saveLastEquippedFinisher(itemName) end
                                                        if txt then txt.Text = "Equipped" end
                                                    end
                                                end
                                            end)
                                        end
                                    end

                                end
                            end
                        end
                    end)
                    WindUI:Notify({ Title = "Skin Changer", Content = "Unlocked swords and explosions locally!", Duration = 3 })
                else
                    WindUI:Notify({ Title = "Skin Changer", Content = "Already unlocked!", Duration = 3 })
                end
            end,
        })

        local finisherList = {"Default"}
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local finishers = rs:WaitForChild("Controllers", 5):WaitForChild("FinishersController", 5):WaitForChild("Finishers", 5)
            if finishers then
                for _, child in ipairs(finishers:GetChildren()) do
                    if child:IsA("ModuleScript") and child.Name ~= "Default" then
                        table.insert(finisherList, child.Name)
                    end
                end
            end
            table.sort(finisherList)
        end)

        SkinTab:Dropdown({
            Title = "Finisher Changer",
            Desc = "Select the finisher to equip",
            Values = finisherList,
            Value = "Default",
            Callback = function(value)
                if value == "Default" then value = "" end
                getgenv().finisherModel = value
                if getgenv().saveLastEquippedFinisher then
                    getgenv().saveLastEquippedFinisher(value)
                end
            end
        })




    end
    end
    _buildSkinTab()

    -- ══ VISUAL TAB ════════════════════════════════════════════════════

    local Visual = Window:Tab({ Title = "Visual", Icon = "eye" })

    -- ══ PLAYER TAB ════════════════════════════════════════════════════
    -- Ayrı function scope: kendi 200-local limiti var (Lua 5.1 register fix)
    function _buildPlayerTab()
        local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

        PlayerTab:Section({ Title = "Speed" })

        PlayerTab:Toggle({
            Title = "Speed", Desc = "Changes the player speed",
            Value = false,
            Callback = function(v)
                getgenv().playerSpeedEnabled = v
                getgenv().updatePlayerSpeed()
            end,
        })
        PlayerTab:Slider({
            Flag = "PlayerSpeedValue",
            Title = "Speed Value", Desc = "Speed value",
            Step = 1,
            Value = { Min = 16, Max = 200, Default = 36 },
            Callback = function(v)
                getgenv().playerSpeed = v
                if getgenv().playerSpeedEnabled then getgenv().updatePlayerSpeed() end
            end,
        })

        PlayerTab:Section({ Title = "Jump" })

        PlayerTab:Toggle({
            Title = "Jump", Desc = "Changes the player jump power",
            Value = false,
            Callback = function(v)
                getgenv().playerJumpEnabled = v
                if getgenv().updatePlayerJump then getgenv().updatePlayerJump() end
            end,
        })
        PlayerTab:Slider({
            Flag = "PlayerJumpValue",
            Title = "Jump Value", Desc = "Jump power value",
            Step = 1,
            Value = { Min = 50, Max = 200, Default = 75 },
            Callback = function(v)
                getgenv().playerJump = v
                if getgenv().playerJumpEnabled and getgenv().updatePlayerJump then getgenv().updatePlayerJump() end
            end,
        })
        PlayerTab:Section({ Title = "Field of View" })

        PlayerTab:Toggle({
            Title = "Field of View", Desc = "Changes the Field of View (FOV)",
            Value = false,
            Callback = function(v)
                getgenv().fovEnabled = v
                getgenv().updateFOV()
            end,
        })
        PlayerTab:Slider({
            Flag = "FOVValue",
            Title = "FOV Value", Desc = "FOV value",
            Step = 1,
            Value = { Min = 50, Max = 120, Default = 70 },
            Callback = function(v)
                getgenv().fov = v
                if getgenv().fovEnabled then getgenv().updateFOV() end
            end,
        })

        PlayerTab:Section({ Title = "Movement" })

        do  -- yeni scope: local sayacını sıfırlar (200 limit bypass)
            local function getPlayerNames()
                local names = {}
                for _, p in pairs(game.Players:GetPlayers()) do
                    if p ~= LocalPlayer then table.insert(names, p.Name) end
                end
                return names
            end

            local playerFollowDropdown
            PlayerTab:Toggle({
                Title = "Player Follow", Desc = "Follows the selected player",
                Value = false,
                Callback = function(v)
                    getgenv().playerFollowEnabled = v
                    getgenv().updatePlayerFollow()
                end,
            })
            playerFollowDropdown = PlayerTab:Dropdown({
                Title = "Follow Target", Desc = "Select player to follow",
                Values = getPlayerNames(),
                Value = "",
                Callback = function(v)
                    getgenv().playerFollowTarget = v
                    getgenv().updatePlayerFollow()
                end,
            })
            PlayerTab:Button({
                Title = "Refresh Players", Desc = "Refresh the player list",
                Callback = function()
                    if playerFollowDropdown and playerFollowDropdown.Refresh then
                        playerFollowDropdown:Refresh(getPlayerNames())
                    end
                end,
            })
        end  -- /movement do

        PlayerTab:Toggle({
            Title = "Fly", Desc = "Allows the player to fly",
            Value = false,
            Callback = function(v)
                System.player.set_fly(v, getgenv().FlySpeed or 50)
            end,
        })
        PlayerTab:Slider({
            Flag = "Fly_Speed",
            Title = "Fly Speed", Desc = "Speed of the fly",
            Step = 1,
            Value = { Min = 1, Max = 100, Default = 50 },
            Callback = function(v)
                getgenv().FlySpeed = v
                if System.__properties.fly_enabled then
                    System.player.set_fly(true, v)
                end
            end,
        })

        PlayerTab:Toggle({
            Title = "Spinbot", Desc = "Spins Player",
            Value = false,
            Callback = function(v)
                System.player.set_spinbot(v, getgenv().spinSpeed or 1)
            end,
        })
        PlayerTab:Slider({
            Flag = "Spinbot_Speed",
            Title = "Spinbot Speed", Desc = "Speed of the spinbot",
            Step = 1,
            Value = { Min = 1, Max = 100, Default = 1 },
            Callback = function(v)
                getgenv().spinSpeed = v
                if System.__properties.spinbot_enabled then
                    System.player.set_spinbot(true, v)
                end
            end,
        })

        PlayerTab:Section({ Title = "Cosmetics" })

        local function updateSelfEffect()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            if getgenv().self_effect_Enabled then
                if not root:FindFirstChild('nurysium_efx') then
                    pcall(function()
                        local effect = game:GetObjects("rbxassetid://17519530107")[1]
                        if effect then
                            effect.Name = 'nurysium_efx'
                            effect.Parent = root
                        end
                    end)
                end
            else
                local old = root:FindFirstChild('nurysium_efx')
                if old then old:Destroy() end
            end
        end

        PlayerTab:Toggle({
            Title = "Aura Effect", Desc = "Add an aura effect to the local player",
            Value = false,
            Callback = function(v)
                getgenv().self_effect_Enabled = v
                updateSelfEffect()
            end,
        })

        PlayerTab:Toggle({
            Title = "Player Cosmetics (Headless & Korblox)", Desc = "Applies Headless and Korblox",
            Value = false,
            Callback = function(v)
                getgenv().playerCosmeticsEnabled = v
                getgenv().updatePlayerCosmetics()
            end,
        })

        PlayerTab:Toggle({
            Title = "Avatar Changer", Desc = "Copies another player's appearance",
            Value = false,
            Callback = function(v)
                __av_flags["AvatarChanger"] = v
                if v then
                    local char = LocalPlayer.Character
                    if char and __av_flags["name"] and __av_flags["name"] ~= "" then
                        __av_set(__av_flags["name"], char)
                    end
                    if not __av_flags["loop"] then
                        __av_flags["loop"] = LocalPlayer.CharacterAdded:Connect(function(char)
                            task.wait(0.05)
                            if __av_flags["name"] then __av_set(__av_flags["name"], char) end
                        end)
                    end
                else
                    if __av_flags["loop"] then __av_flags["loop"]:Disconnect(); __av_flags["loop"] = nil end
                    __av_stop_all()
                    local char = LocalPlayer.Character
                    if char then
                        pcall(function()
                            LocalPlayer:ClearCharacterAppearance()
                            local ok, desc = pcall(function()
                                return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
                            end)
                            if ok and desc then
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                if hum then hum:ApplyDescriptionClientServer(desc) end
                            end
                        end)
                    end
                end
            end,
        })

        PlayerTab:Input({
            Title = "Username", Desc = "Enter player username",
            Placeholder = "Enter player username...",
            Callback = function(v)
                __av_flags["name"] = v
                if __av_flags["AvatarChanger"] and v ~= "" then
                    local char = LocalPlayer.Character
                    if char then __av_set(v, char) end
                end
            end,
        })

        Visual:Section({ Title = "Emotes" })
        Visual:Toggle({
            Title = "Emotes",
            Desc = "Unlock and refresh emotes (open wheel with [ E ])",
            Value = false,
            Callback = function(v)
                if getgenv().setBladeBallEmoteUnlock then
                    getgenv().setBladeBallEmoteUnlock(v)
                else
                    getgenv().emoteVFXEnabled = v
                end
                
                if v then
                    local names = getgenv().refreshBladeBallEmotes()
                    if getgenv().emoteVFXEnabled and getgenv().installBladeBallEmoteWheel then
                        getgenv().installBladeBallEmoteWheel()
                    end
                    WindUI:Notify({
                        Title = "Emotes Refreshed",
                        Content = tostring(#names) .. " Blade Ball emotes found.",
                        Duration = 3,
                    })
                end
            end,
        })



        PlayerTab:Section({ Title = "Sounds" })


        PlayerTab:Toggle({
            Title = "Hit Sounds", Desc = "Plays a sound on successful parry",
            Value = getgenv().hitSoundsEnabled or false,
            Callback = function(v)
                getgenv().hitSoundsEnabled = v
                getgenv().updateHitSounds()
            end,
        })
        PlayerTab:Slider({
            Flag = "HitSoundVolume",
            Title = "Hit Sound Volume", Desc = "Hit sound volume",
            Step = 1,
            Value = { Min = 1, Max = 10, Default = getgenv().hitSoundVolume or 5 },
            Callback = function(v)
                getgenv().hitSoundVolume = v
                getgenv().updateHitSounds()
            end,
        })
        PlayerTab:Dropdown({
            Title = "Hit Sound Type", Desc = "Hit sound type",
            Values = { "Medal", "Fatality", "Skeet", "Switches", "Rust Headshot", "Neverlose Sound", "Bubble", "Laser", "Steve", "Call of Duty", "Bat", "TF2 Critical", "Saber", "Bameware" },
            Value = getgenv().hitSoundType or "Medal",
            Callback = function(v)
                getgenv().hitSoundType = v
                getgenv().updateHitSounds()
            end,
        })
    end  -- /function _buildPlayerTab
    _buildPlayerTab()

    function _buildVisualTabCustomizations()
        Visual:Section({ Title = "Customization" })

    Visual:Toggle({
        Title = "Custom Winner Text", Desc = "Changes the game winner announcement text",
        Value = getgenv().customWinnerTextEnabled or false,
        Callback = function(v)
            getgenv().customWinnerTextEnabled = v
        end,
    })

    Visual:Input({
        Title = "Winner Text", Desc = "The text to show (e.g. ICEHUB Won!)",
        Placeholder = "Enter text...",
        Value = getgenv().customWinnerText or "ICEHUB Won!",
        Callback = function(v)
            getgenv().customWinnerText = v
        end,
    })

    Visual:Toggle({
        Title = "Custom Win Streak", Desc = "Changes the win streak above your head",
        Value = getgenv().customWinStreakEnabled or false,
        Callback = function(v)
            getgenv().customWinStreakEnabled = v
            if getgenv().updateFakeWinStreak then getgenv().updateFakeWinStreak() end
        end,
    })

    Visual:Input({
        Title = "Streak Text", Desc = "The streak text/number to show",
        Placeholder = "Enter streak (e.g. Streak: 999)",
        Value = getgenv().customWinStreak or "Streak: 999",
        Callback = function(v)
            getgenv().customWinStreak = v
            if getgenv().updateFakeWinStreak then getgenv().updateFakeWinStreak() end
        end,
    })

    getgenv().customShieldVfxColor = getgenv().customShieldVfxColor or getgenv().customVfxColor or Color3.fromRGB(255, 50, 50)
    getgenv().customSlashVfxColor = getgenv().customSlashVfxColor or getgenv().customVfxColor or Color3.fromRGB(255, 50, 50)
    if getgenv().customShieldVfxEnabled == nil then getgenv().customShieldVfxEnabled = getgenv().customVfxEnabled or false end
    if getgenv().customSlashVfxEnabled == nil then getgenv().customSlashVfxEnabled = getgenv().customVfxEnabled or false end
    local function refreshCustomVfxMasterToggle()
        getgenv().customVfxEnabled = getgenv().customShieldVfxEnabled or getgenv().customSlashVfxEnabled
    end
    refreshCustomVfxMasterToggle()

    Visual:Section({ Title = "FX Changer" })

    Visual:Toggle({
        Title = "Shield Changer", Desc = "Changes your parry shield FX color",
        Value = getgenv().customShieldVfxEnabled or false,
        Callback = function(v)
            getgenv().customShieldVfxEnabled = v
            refreshCustomVfxMasterToggle()
            if getgenv().reapplyCustomVfx then getgenv().reapplyCustomVfx() end
        end,
    })

    Visual:Colorpicker({
        Title = "Shield Color", Desc = "Select the shield FX color",
        Value = getgenv().customShieldVfxColor,
        Callback = function(v)
            getgenv().customShieldVfxColor = v
            if getgenv().customVfxColor == nil then getgenv().customVfxColor = v end
            if getgenv().reapplyCustomVfx then getgenv().reapplyCustomVfx() end
        end,
    })

    Visual:Toggle({
        Title = "Slash Changer", Desc = "Changes your sword hit FX color",
        Value = getgenv().customSlashVfxEnabled or false,
        Callback = function(v)
            getgenv().customSlashVfxEnabled = v
            refreshCustomVfxMasterToggle()
            if getgenv().reapplyCustomVfx then getgenv().reapplyCustomVfx() end
        end,
    })

    Visual:Colorpicker({
        Title = "Slash Color", Desc = "Select the slash FX color",
        Value = getgenv().customSlashVfxColor,
        Callback = function(v)
            getgenv().customSlashVfxColor = v
            getgenv().customVfxColor = v
            if getgenv().reapplyCustomVfx then getgenv().reapplyCustomVfx() end
        end,
    })

    -- Event-driven Winner Text Customizer
    local function checkWinnerLabel(v)
        if not v:IsA("TextLabel") then return end
        local function updateText()
            if getgenv().customWinnerTextEnabled and getgenv().customWinnerText then
                local lower = string.lower(v.Text or "")
                if (string.find(lower, " won") or string.find(lower, "winner") or string.find(lower, "match cancel")) and not string.find(lower, "wins") and string.len(v.Text) > 3 then
                    if v.Text ~= getgenv().customWinnerText then
                        v.Text = getgenv().customWinnerText
                    end
                end
            end
        end
        updateText()
        v:GetPropertyChangedSignal("Text"):Connect(updateText)
    end

    task.spawn(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
        if playerGui then
            for _, v in ipairs(playerGui:GetDescendants()) do
                task.spawn(checkWinnerLabel, v)
            end
            playerGui.DescendantAdded:Connect(checkWinnerLabel)
        end
    end)

    -- Event-driven Win Streak Customizer
    getgenv().updateFakeWinStreak = function()
        local char = LocalPlayer.Character
        if not char then return end
        
        if getgenv().customWinStreakEnabled and getgenv().customWinStreak then
            local head = char:FindFirstChild("Head")
            if head then
                local fakeStreak = char:FindFirstChild("FakeWinStreak")
                if not fakeStreak then
                    local template = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
                    if template then template = template:FindFirstChild("UI") end
                    if template then template = template:FindFirstChild("WinStreakDisplay") end
                    
                    if template then
                        fakeStreak = template:Clone()
                        fakeStreak.Name = "FakeWinStreak"
                        fakeStreak.Adornee = head
                        fakeStreak.Parent = char
                    end
                end
                
                if fakeStreak then
                    fakeStreak.Enabled = true
                    local main = fakeStreak:FindFirstChild("Main")
                    if main then
                        local valueLabel = main:FindFirstChild("Value")
                        if valueLabel then
                            local streakText = tostring(getgenv().customWinStreak or "")
                            local numStr = string.match(streakText, "%d+")
                            local num = tonumber(numStr)
                            local lowerStreakText = string.lower(streakText)
                            if num and string.find(streakText, "+", 1, true) then
                                num = math.max(num, 10000)
                            end
                            local shouldUseHighStreakColor = (num and num >= 10)
                                or string.find(lowerStreakText, "10+ win", 1, true) ~= nil

                            local function applyWinStreakColor(root, color)
                                local icon = root:FindFirstChild("Icon")
                                if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
                                    icon.ImageColor3 = color
                                end
                                valueLabel.TextColor3 = color
                                for _, item in ipairs(root:GetDescendants()) do
                                    if item:IsA("TextLabel") or item:IsA("TextButton") then
                                        item.TextColor3 = color
                                    elseif item:IsA("ImageLabel") or item:IsA("ImageButton") then
                                        item.ImageColor3 = color
                                    elseif item:IsA("UIStroke") then
                                        item.Color = color
                                    elseif item:IsA("UIGradient") then
                                        item.Color = ColorSequence.new(color)
                                    end
                                end
                            end

                            if shouldUseHighStreakColor then
                                applyWinStreakColor(main, Color3.fromRGB(0, 235, 255))
                            elseif num then
                                local template = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
                                if template then template = template:FindFirstChild("UI") end
                                if template then template = template:FindFirstChild("WinStreakDisplay") end
                                if template and template:FindFirstChild("Main") then
                                    local tMain = template.Main
                                    local icon = main:FindFirstChild("Icon")
                                    if icon and tMain:FindFirstChild("Icon") then icon.ImageColor3 = tMain.Icon.ImageColor3 end
                                    if tMain:FindFirstChild("Value") then valueLabel.TextColor3 = tMain.Value.TextColor3 end
                                end
                            end
                            
                            if valueLabel.Text ~= getgenv().customWinStreak then
                                valueLabel.Text = getgenv().customWinStreak
                            end
                        end
                    end
                end
                
                for _, v in pairs(char:GetChildren()) do
                    if v.Name == "WinStreakDisplay" and v:IsA("BillboardGui") then
                        v.Enabled = false
                    end
                end
            end
        else
            local fakeStreak = char:FindFirstChild("FakeWinStreak")
            if fakeStreak then
                fakeStreak:Destroy()
            end
            for _, v in pairs(char:GetChildren()) do
                if v.Name == "WinStreakDisplay" and v:IsA("BillboardGui") then
                    local main = v:FindFirstChild("Main")
                    local valLabel = main and main:FindFirstChild("Value")
                    local text = valLabel and valLabel.Text or ""
                    local num = tonumber(string.match(text, "%d+")) or 0
                    if num > 0 then
                        v.Enabled = true
                    else
                        v.Enabled = false
                    end
                end
            end
        end
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if getgenv().updateFakeWinStreak then getgenv().updateFakeWinStreak() end
    end)
    
        if LocalPlayer.Character then
            task.spawn(function()
                if getgenv().updateFakeWinStreak then getgenv().updateFakeWinStreak() end
            end)
        end
    end
    _buildVisualTabCustomizations()

    -- ══ OTHERS TAB ════════════════════════════════════════════════════
    function _buildRemainingTabs()
        World = Window:Tab({ Title = "World", Icon = "globe" })
        local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })

    ShopTab:Section({ Title = "Crates" })

    ShopTab:Toggle({
        Title = "Auto Sword Buy", Desc = "Continuously buys normal sword crates using coins",
        Value = getgenv().autoSwordBuy,
        Callback = function(v)
            getgenv().autoSwordBuy = v
            getgenv().updateAutoSwordBuy()
        end,
    })
    ShopTab:Button({
        Title = "Buy Sword Crate Once", Desc = "Buys one normal sword crate using coins",
        ButtonText = "Buy Sword",
        Callback = function() getgenv().openSwordBox() end,
    })
    ShopTab:Toggle({
        Title = "Auto Explosion Buy", Desc = "Continuously buys normal explosion crates when supported",
        Value = getgenv().autoExplosionBuy,
        Callback = function(v)
            getgenv().autoExplosionBuy = v
            getgenv().updateAutoExplosionBuy()
        end,
    })
    ShopTab:Button({
        Title = "Buy Explosion Crate Once", Desc = "Buys one normal explosion crate when supported",
        ButtonText = "Buy Explosion",
        Callback = function() getgenv().openExplosionBox() end,
    })
    ShopTab:Slider({
        Flag = "ShopBuyInterval",
        Title = "Auto Buy Interval", Desc = "Delay between automatic purchases",
        Step = 0.05,
        Value = { Min = 0.1, Max = 2, Default = getgenv().shopBuyInterval },
        Callback = function(v) getgenv().shopBuyInterval = v end,
    })

    ShopTab:Section({ Title = "Rewards" })

    ShopTab:Button({
        Title = "Claim Daily Rewards", Desc = "Claims the available daily reward when supported",
        ButtonText = "Claim",
        Callback = function()
            local ok,detail=getgenv().claimDailyRewards()
            WindUI:Notify({
                Title = ok and "Daily Rewards Claimed" or "Daily Rewards Unavailable",
                Content = ok and "Available daily rewards were claimed." or tostring(detail),
                Duration = 3,
            })
        end,
    })


    PFrame, VLog, PLog = nil, nil, nil

    World:Section({ Title = "Sky" })

    World:Toggle({
        Title = "Custom Sky", Desc = "Changes the skybox",
        Value = getgenv().customSky or false,
        Callback = function(v)
            getgenv().customSky = v
            getgenv().updateSky()
        end,
    })
    World:Dropdown({
        Title = "Select Sky", Desc = "Select the sky theme",
        Values = { "Default", "Vaporwave", "Redshift", "Desert", "DaBaby", "Minecraft", "SpongeBob", "Skibidi", "Blaze", "Pussy Cat", "Among Us", "Space Wave", "Space Wave2", "Turquoise Wave", "Dark Night", "Bright Pink", "White Galaxy", "Blue Galaxy" },
        Value = getgenv().selectedSky or "Default",
        Callback = function(v)
            getgenv().selectedSky = v
            if getgenv().customSky then getgenv().applySkybox(v) end
        end,
    })

    World:Section({ Title = "Filters" })

    World:Toggle({
        Title = "Enable Atmosphere", Desc = "Toggles atmosphere effect",
        Value = false,
        Callback = function(v)
            getgenv().WorldFilter_Atmosphere = v
            getgenv().updateWorldFilters()
        end,
    })
    World:Slider({
        Flag = "AtmosphereDensity",
        Title = "Atmosphere Density", Desc = "Density of the atmosphere",
        Step = 0.1,
        Value = { Min = 0, Max = 1, Default = 0.5 },
        Callback = function(v)
            getgenv().WorldFilter_Atmosphere_Density = v
            if getgenv().WorldFilter_Atmosphere then getgenv().updateWorldFilters() end
        end,
    })
    World:Toggle({
        Title = "Enable Fog", Desc = "Toggles fog effect",
        Value = false,
        Callback = function(v)
            getgenv().WorldFilter_Fog = v
            getgenv().updateWorldFilters()
        end,
    })
    World:Slider({
        Flag = "FogDistance",
        Title = "Fog Distance", Desc = "Distance of the fog",
        Step = 10,
        Value = { Min = 50, Max = 10000, Default = 1000 },
        Callback = function(v)
            getgenv().WorldFilter_Fog_Distance = v
            if getgenv().WorldFilter_Fog then getgenv().updateWorldFilters() end
        end,
    })
    World:Toggle({
        Title = "Enable Saturation", Desc = "Toggles saturation effect",
        Value = false,
        Callback = function(v)
            getgenv().WorldFilter_Saturation = v
            getgenv().updateWorldFilters()
        end,
    })
    World:Slider({
        Flag = "SaturationLevel",
        Title = "Saturation Level", Desc = "Level of saturation",
        Step = 0.1,
        Value = { Min = -1, Max = 1, Default = 0 },
        Callback = function(v)
            getgenv().WorldFilter_Saturation_Level = v
            if getgenv().WorldFilter_Saturation then getgenv().updateWorldFilters() end
        end,
    })
    World:Toggle({
        Title = "Enable Hue", Desc = "Toggles hue shift effect",
        Value = false,
        Callback = function(v)
            getgenv().WorldFilter_Hue = v
            getgenv().updateWorldFilters()
        end,
    })
    World:Slider({
        Flag = "HueShift",
        Title = "Hue Shift", Desc = "Hue shift color",
        Step = 0.05,
        Value = { Min = -1, Max = 1, Default = 0 },
        Callback = function(v)
            getgenv().WorldFilter_Hue_Shift = v
            if getgenv().WorldFilter_Hue then getgenv().updateWorldFilters() end
        end,
    })

    Visual:Section({ Title = "Ball Features" })

    Visual:Dropdown({
        Title = "Ball Camera Mode", Desc = "Change how the camera interacts with the ball",
        Values = {"None", "Look at Ball", "Orbit Ball"},
        Value = "None",
        Callback = function(v)
            getgenv().BallCameraMode = v
            getgenv().updateBallCamera()
        end,
    })
    Visual:Slider({
        Flag = "BallOrbitSpeed",
        Title = "Orbit Speed", Desc = "Speed of the camera orbit",
        Step = 1,
        Value = { Min = 1, Max = 200, Default = 50 },
        Callback = function(v)
            getgenv().BallOrbitSpeed = v
        end,
    })
    Visual:Slider({
        Flag = "BallOrbitDistance",
        Title = "Orbit Distance", Desc = "Distance of the camera from the ball",
        Step = 1,
        Value = { Min = 5, Max = 100, Default = 20 },
        Callback = function(v)
            getgenv().BallOrbitDistance = v
        end,
    })

    Visual:Toggle({
        Title = "Ball Stats", Desc = "Opens a panel showing ball velocity",
        Value = false,
        Callback = function(v)
            ShowPeak = v
            if PFrame then PFrame.Visible = v end
            if not v then
                peakVel = 0
                if VLog then VLog.Text = "0.0" end
                if PLog then PLog.Text = "0.0" end
            end
        end,
    })

    Visual:Toggle({
        Title = "Ball Trail", Desc = "Leaves a trail behind the ball",
        Value = false,
        Callback = function(v)
            PlasmaTrails.Enabled = v
            if not v and lastTrailBall then plasmaClean(lastTrailBall); lastTrailBall = nil end
        end,
    })
    Visual:Colorpicker({
        Flag = "BallTrailColor",
        Title = "Ball Trail Color", Desc = "Select ball trail color",
        Value = Color3.fromRGB(255, 0, 0),
        Callback = function(color)
            getgenv().ballTrailColor = color
            if not getgenv().ballTrailRainbow then
                PlasmaTrails.Color = color
            end
        end,
    })



    World:Section({ Title = "Particles" })
    World:Toggle({
        Title = "Particles",
        Desc = "Colored star particles fall from the sky",
        Value = getgenv().fallingParticlesEnabled or false,
        Callback = function(v)
            if getgenv().setFallingParticles then
                getgenv().setFallingParticles(v)
            end
        end,
    })

    World:Slider({
        Flag = "FallingParticleAmount",
        Title = "Particle Amount", Desc = "Amount of falling particles",
        Step = 1,
        Value = { Min = 1, Max = 10, Default = getgenv().fallingParticlesAmount or 5 },
        Callback = function(v)
            getgenv().fallingParticlesAmount = v
        end,
    })

    World:Slider({
        Flag = "FallingParticleSpeed",
        Title = "Particle Speed", Desc = "Falling speed",
        Step = 5,
        Value = { Min = 20, Max = 250, Default = getgenv().fallingParticlesSpeed or 90 },
        Callback = function(v)
            getgenv().fallingParticlesSpeed = v
        end,
    })

    World:Slider({
        Flag = "FallingParticleHue",
        Title = "Particle Color", Desc = "Particle color (HSV hue 0-360)",
        Step = 1,
        Value = { Min = 0, Max = 360, Default = getgenv().fallingParticlesHue or 180 },
        Callback = function(v)
            getgenv().fallingParticlesHue = v
            if getgenv().fallingParticlesEnabled and getgenv().setFallingParticles then
                getgenv().setFallingParticles(true)
            end
        end,
    })

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        updateSelfEffect()
    end)

    getgenv().spectateViewerEnabled = getgenv().spectateViewerEnabled or false
    getgenv()._lhxSpectateViewer = getgenv()._lhxSpectateViewer or { index = 1 }
    getgenv()._lhxSpectateViewer.isActiveTarget = function(player)
        if not player or player == LocalPlayer then return false end
        local aliveFolder = workspace:FindFirstChild("Alive")
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        return aliveFolder and character and character.Parent == aliveFolder and humanoid and root and humanoid.Health > 0
    end
    getgenv()._lhxSpectateViewer.getTargets = function()
        local targets = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if getgenv()._lhxSpectateViewer.isActiveTarget(player) then
                targets[#targets + 1] = player
            end
        end
        table.sort(targets, function(a, b) return a.Name < b.Name end)
        return targets
    end
    getgenv()._lhxSpectateViewer.restoreCamera = function()
        local state = getgenv()._lhxSpectateViewer
        state.paused = true
        state.target = nil
        if state.updatePanel then state.updatePanel() end
    end
    getgenv()._lhxSpectateViewer.setCameraToTarget = function()
        local state = getgenv()._lhxSpectateViewer
        local target = state.target
        if not state.isActiveTarget(target) then return false end
        return true
    end
    getgenv()._lhxSpectateViewer.clearViewport = function()
        local state = getgenv()._lhxSpectateViewer
        state.renderPlayer = nil
        state.renderClone = nil
        if state.worldModel then
            state.worldModel:ClearAllChildren()
        end
    end
    getgenv()._lhxSpectateViewer.updateViewport = function()
        local state = getgenv()._lhxSpectateViewer
        if not state.viewport or not state.worldModel then return end

        local target = state.target
        local character = target and target.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not state.isActiveTarget(target) or not character or not humanoid or not root then
            state.clearViewport()
            return
        end

        local now = tick()
        if state.renderPlayer == target and state.renderClone and (now - (state.lastRender or 0)) < 1 then
            return
        end
        state.lastRender = now
        state.renderPlayer = target
        state.worldModel:ClearAllChildren()

        local renderedParts = 0
        local maxSceneParts = 8
        local sceneRadius = 120

        local function prepClone(obj)
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("BaseScript") then
                    child:Destroy()
                elseif child:IsA("BasePart") then
                    child.Anchored = true
                    child.CanCollide = false
                    child.CastShadow = false
                end
            end
        end

        local function cloneCharacter(sourceCharacter)
            local sourceRoot = sourceCharacter and sourceCharacter:FindFirstChild("HumanoidRootPart")
            local sourceHumanoid = sourceCharacter and sourceCharacter:FindFirstChildOfClass("Humanoid")
            if not sourceRoot or not sourceHumanoid or sourceHumanoid.Health <= 0 then return nil end
            if (sourceRoot.Position - root.Position).Magnitude > sceneRadius then return nil end

            local oldArchivable = sourceCharacter.Archivable
            sourceCharacter.Archivable = true
            local ok, clone = pcall(function() return sourceCharacter:Clone() end)
            sourceCharacter.Archivable = oldArchivable
            if not ok or not clone then return nil end

            prepClone(clone)
            clone.Parent = state.worldModel
            pcall(function()
                clone:PivotTo(root.CFrame:ToObjectSpace(sourceRoot.CFrame))
            end)
            return clone
        end

        local function clonePart(part, transparency)
            if renderedParts >= maxSceneParts then return end
            if not part or not part:IsA("BasePart") then return end
            if (part.Position - root.Position).Magnitude > sceneRadius then return end

            local ok, clone = pcall(function() return part:Clone() end)
            if not ok or not clone then return end
            prepClone(clone)
            clone.CFrame = root.CFrame:ToObjectSpace(part.CFrame)
            clone.Anchored = true
            clone.CanCollide = false
            clone.CastShadow = false
            if transparency then clone.Transparency = math.max(clone.Transparency, transparency) end
            clone.Parent = state.worldModel
            renderedParts += 1
        end

        local mainClone = cloneCharacter(character)
        state.renderClone = mainClone

        for _, folderName in ipairs({"Balls", "TrainingBalls"}) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, part in ipairs(folder:GetChildren()) do
                    if part:IsA("BasePart") then
                        clonePart(part)
                    end
                end
            end
        end

        local floor = workspace:FindFirstChild("FLOOR")
        if floor and floor:IsA("BasePart") then
            clonePart(floor, 0.15)
        end

        if state.viewportCamera then
            state.viewportCamera.FieldOfView = 48
            state.viewportCamera.CFrame = CFrame.new(Vector3.new(0, 7, 16), Vector3.new(0, 2, 0))
        end
    end
    getgenv()._lhxSpectateViewer.updatePanel = function()
        local state = getgenv()._lhxSpectateViewer
        if not state or not state.gui then return end

        local target = state.target
        local character = target and target.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if not state.isActiveTarget(target) or not character or not humanoid or not root then
            if state.nameLabel then state.nameLabel.Text = "No target" end
            if state.infoLabel then state.infoLabel.Text = "Waiting for players..." end
            if state.clearViewport then state.clearViewport() end
            return
        end

        local distanceText = "--"
        pcall(function()
            distanceText = tostring(math.floor(LocalPlayer:DistanceFromCharacter(root.Position)))
        end)
        local ability = target:GetAttribute("EquippedAbility") or (character and (character:GetAttribute("CurrentAbility") or character:GetAttribute("ActiveAbility") or character:GetAttribute("Ability")))

        if state.nameLabel then
            state.nameLabel.Text = target.DisplayName .. " (@" .. target.Name .. ")"
        end
        if state.infoLabel then
            state.infoLabel.Text = "Dist " .. distanceText .. " | " .. tostring(ability or "No Ability")
        end
        if state.updateViewport then state.updateViewport() end
    end
    getgenv()._lhxSpectateViewer.select = function(step)
        local state = getgenv()._lhxSpectateViewer
        local targets = state.getTargets()
        if #targets == 0 then
            state.target = nil
            state.restoreCamera()
            state.updatePanel()
            return
        end

        state.index = ((state.index or 1) + (step or 0) - 1) % #targets + 1
        state.paused = false
        state.target = targets[state.index]
        state.setCameraToTarget()
        state.updatePanel()
    end
    getgenv()._lhxSpectateViewer.makeDraggable = function(frame, handle)
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPosition = nil

        handle.Active = true
        handle.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end)
        handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging or input ~= dragInput then return end
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end)
    end
    getgenv()._lhxSpectateViewer.createGui = function()
        local state = getgenv()._lhxSpectateViewer
        if state.gui and state.gui.Parent then return end

        local gui = Instance.new("ScreenGui")
        gui.Name = "IceHubPlayerViewer"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 1001
        gui.Parent = CoreGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 380, 0, 330)
        frame.Position = UDim2.new(1, -405, 0, 90)
        frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Parent = gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Color3.fromRGB(192, 132, 252)
        stroke.Thickness = 2
        stroke.Transparency = 0

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 34)
        header.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        header.BackgroundTransparency = 0.12
        header.BorderSizePixel = 0
        header.Parent = frame
        Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -42, 1, 0)
        title.Position = UDim2.new(0, 12, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "Game Window"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header

        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 28, 0, 24)
        close.Position = UDim2.new(1, -34, 0, 5)
        close.BackgroundColor3 = Color3.fromRGB(192, 132, 252)
        close.Text = "X"
        close.TextColor3 = Color3.fromRGB(20, 20, 20)
        close.Font = Enum.Font.GothamBold
        close.TextSize = 13
        close.Parent = header
        Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

        local viewport = Instance.new("ViewportFrame")
        viewport.Size = UDim2.new(1, -16, 1, -166)
        viewport.Position = UDim2.new(0, 8, 0, 42)
        viewport.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
        viewport.BackgroundTransparency = 0.25
        viewport.BorderSizePixel = 0
        viewport.Ambient = Color3.fromRGB(180, 180, 180)
        viewport.LightColor = Color3.fromRGB(255, 255, 255)
        viewport.LightDirection = Vector3.new(-1, -1, -1)
        viewport.Parent = frame
        Instance.new("UICorner", viewport).CornerRadius = UDim.new(0, 6)

        local viewportCamera = Instance.new("Camera")
        viewportCamera.FieldOfView = 48
        viewportCamera.CFrame = CFrame.new(Vector3.new(0, 7, 16), Vector3.new(0, 2, 0))
        viewportCamera.Parent = viewport
        viewport.CurrentCamera = viewportCamera

        local worldModel = Instance.new("WorldModel")
        worldModel.Parent = viewport

        local infoBar = Instance.new("Frame")
        infoBar.Size = UDim2.new(1, 0, 0, 112)
        infoBar.Position = UDim2.new(0, 0, 1, -112)
        infoBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        infoBar.BackgroundTransparency = 0.18
        infoBar.BorderSizePixel = 0
        infoBar.Parent = frame
        Instance.new("UICorner", infoBar).CornerRadius = UDim.new(0, 8)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -24, 0, 26)
        nameLabel.Position = UDim2.new(0, 12, 1, -104)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "No target"
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = frame

        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -24, 0, 34)
        infoLabel.Position = UDim2.new(0, 12, 1, -80)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = "Waiting for players..."
        infoLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 11
        infoLabel.TextWrapped = true
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = frame

        local prev = Instance.new("TextButton")
        prev.Size = UDim2.new(0, 78, 0, 30)
        prev.Position = UDim2.new(0, 12, 1, -40)
        prev.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        prev.Text = "Previous"
        prev.TextColor3 = Color3.fromRGB(235, 235, 235)
        prev.Font = Enum.Font.GothamBold
        prev.TextSize = 12
        prev.Parent = frame
        Instance.new("UICorner", prev).CornerRadius = UDim.new(0, 6)

        local next = Instance.new("TextButton")
        next.Size = UDim2.new(0, 78, 0, 30)
        next.Position = UDim2.new(0, 98, 1, -40)
        next.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        next.Text = "Next"
        next.TextColor3 = Color3.fromRGB(235, 235, 235)
        next.Font = Enum.Font.GothamBold
        next.TextSize = 12
        next.Parent = frame
        Instance.new("UICorner", next).CornerRadius = UDim.new(0, 6)

        local reset = Instance.new("TextButton")
        reset.Size = UDim2.new(0, 100, 0, 30)
        reset.Position = UDim2.new(1, -112, 1, -40)
        reset.BackgroundColor3 = Color3.fromRGB(192, 132, 252)
        reset.Text = "Clear"
        reset.TextColor3 = Color3.fromRGB(20, 20, 20)
        reset.Font = Enum.Font.GothamBold
        reset.TextSize = 12
        reset.Parent = frame
        Instance.new("UICorner", reset).CornerRadius = UDim.new(0, 6)

        state.gui = gui
        state.frame = frame
        state.viewport = viewport
        state.viewportCamera = viewportCamera
        state.worldModel = worldModel
        state.nameLabel = nameLabel
        state.infoLabel = infoLabel
        state.makeDraggable(frame, header)
        prev.MouseButton1Click:Connect(function() state.select(-1) end)
        next.MouseButton1Click:Connect(function() state.select(1) end)
        reset.MouseButton1Click:Connect(function() state.restoreCamera() end)
        close.MouseButton1Click:Connect(function()
            getgenv().spectateViewerEnabled = false
            if getgenv()._lhxSetSpectateViewerToggle then getgenv()._lhxSetSpectateViewerToggle(false) end
            getgenv()._lhxSpectateViewer.setEnabled(false)
        end)
    end
    getgenv()._lhxSpectateViewer.setEnabled = function(enabled)
        local state = getgenv()._lhxSpectateViewer
        state.enabled = enabled
        state.paused = not enabled
        getgenv().spectateViewerEnabled = enabled

        if state.connection then
            state.connection:Disconnect()
            state.connection = nil
        end

        if not enabled then
            state.target = nil
            if state.gui then
                state.gui:Destroy()
                state.gui = nil
            end
            state.restoreCamera()
            return
        end

        state.createGui()
        state.paused = false
        state.select(0)
        state.connection = RunService.Heartbeat:Connect(function()
            if not state.enabled then return end
            if not state.target then
                if not state.paused then state.select(0) end
                return
            end
            local target = state.target
            if not state.isActiveTarget(target) then
                state.select(1)
                return
            end
            if not state.setCameraToTarget() then
                state.select(1)
                return
            end
            local now = tick()
            if now - (state.lastPanelUpdate or 0) < 0.2 then return end
            state.lastPanelUpdate = now
            state.updatePanel()
        end)
    end

    World:Section({ Title = "Viewer" })

    SpectateViewerToggle = World:Toggle({
        Title = "Game Window", Desc = "Show Players Camera",
        Value = getgenv().spectateViewerEnabled,
        Callback = function(v)
            getgenv()._lhxSpectateViewer.setEnabled(v)
        end,
    })
    getgenv()._lhxSetSpectateViewerToggle = function(value)
        if SpectateViewerToggle and SpectateViewerToggle.Set then
            SpectateViewerToggle:Set(value)
        end
    end

    World:Toggle({
        Title = "No Render", Desc = "No Parry Sound/Effect To Avoid Lag",
        Value = false,
        Callback = function(v)
            setNoRender(v)
        end,
    })

    -- FPS / Ping Panel (Modern Visuals)
    ;(function()
    local PANEL_ACCENT = Color3.fromRGB(71,79,238)
    local PANEL_ACCENT_LIGHT = Color3.fromRGB(192,132,252)
    local PANEL_TEXT = Color3.fromRGB(231,231,237)
    local PANEL_MUTED = Color3.fromRGB(113,115,128)
    local StatsGui = Instance.new("ScreenGui", CoreGui)
    StatsGui.Name = "IceHubGui"; StatsGui.ResetOnSpawn = false; StatsGui.DisplayOrder = 999; StatsGui.IgnoreGuiInset = true

    local StatsContainer = Instance.new("Frame", StatsGui)
    StatsContainer.Size = UDim2.new(0, 180, 0, 100)
    StatsContainer.Position = UDim2.new(1, -200, 0, 16)
    StatsContainer.BackgroundTransparency = 1
    StatsContainer.Visible = false

    -- 1. Ping Panel
    local PingFrame = Instance.new("Frame", StatsContainer)
    PingFrame.Size = UDim2.new(1, 0, 0, 56)
    PingFrame.Position = UDim2.new(0, 0, 0, 0)
    PingFrame.BackgroundColor3 = Color3.fromRGB(12,14,22)
    PingFrame.BorderSizePixel = 0
    Instance.new("UICorner", PingFrame).CornerRadius = UDim.new(0, 6)
    local PStroke = Instance.new("UIStroke", PingFrame); PStroke.Color = Color3.fromRGB(76,83,238); PStroke.Thickness = 1; PStroke.Transparency = 0.5
    
    local PingLabel = Instance.new("TextLabel", PingFrame)
    PingLabel.Size = UDim2.new(1, -10, 0, 20)
    PingLabel.Position = UDim2.new(0, 0, 0, 4)
    PingLabel.BackgroundTransparency = 1
    PingLabel.Text = "-- ms"
    PingLabel.Font = Enum.Font.GothamBold
    PingLabel.TextSize = 13
    PingLabel.TextColor3 = PANEL_ACCENT_LIGHT
    PingLabel.TextXAlignment = Enum.TextXAlignment.Right

    local Divider = Instance.new("Frame", PingFrame)
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.Position = UDim2.new(0, 0, 0, 28)
    Divider.BackgroundColor3 = Color3.fromRGB(40,45,65)
    Divider.BorderSizePixel = 0
    Divider.BackgroundTransparency = 0.7

    local GraphContainer = Instance.new("Frame", PingFrame)
    GraphContainer.Size = UDim2.new(1, -16, 0, 24)
    GraphContainer.Position = UDim2.new(0, 8, 0, 30)
    GraphContainer.BackgroundTransparency = 1

    local numBars = 16
    local bars = {}
    local barWidth = (164 / numBars) - 1
    for i = 1, numBars do
        local bar = Instance.new("Frame", GraphContainer)
        bar.Size = UDim2.new(0, barWidth, 0, 2)
        bar.Position = UDim2.new(0, (i-1) * (barWidth + 1), 1, -2)
        bar.BackgroundColor3 = PANEL_ACCENT_LIGHT
        bar.BorderSizePixel = 0
        bar.BackgroundTransparency = 0.2
        local bGrad = Instance.new("UIGradient", bar)
        bGrad.Rotation = -90
        bGrad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0.1), NumberSequenceKeypoint.new(1,1)}
        bars[i] = bar
    end

    -- 2. FPS Pill
    local FpsFrame = Instance.new("Frame", StatsContainer)
    FpsFrame.Size = UDim2.new(0, 130, 0, 32)
    FpsFrame.Position = UDim2.new(0, 0, 0, 64)
    FpsFrame.BackgroundColor3 = Color3.fromRGB(16,10,25)
    FpsFrame.BorderSizePixel = 0
    Instance.new("UICorner", FpsFrame).CornerRadius = UDim.new(1, 0)
    local FStroke = Instance.new("UIStroke", FpsFrame); FStroke.Color = Color3.fromRGB(20,22,30); FStroke.Thickness = 1
    
    local Dot = Instance.new("Frame", FpsFrame)
    Dot.Size = UDim2.new(0, 6, 0, 6)
    Dot.Position = UDim2.new(0, 14, 0.5, -3)
    Dot.BackgroundColor3 = PANEL_TEXT
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    local FpsVal = Instance.new("TextLabel", FpsFrame)
    FpsVal.Size = UDim2.new(0, 30, 1, 0)
    FpsVal.Position = UDim2.new(0, 26, 0, 0)
    FpsVal.BackgroundTransparency = 1
    FpsVal.Text = "--"
    FpsVal.Font = Enum.Font.GothamBlack
    FpsVal.TextSize = 16
    FpsVal.TextColor3 = PANEL_TEXT
    FpsVal.TextXAlignment = Enum.TextXAlignment.Left

    local FpsLbl = Instance.new("TextLabel", FpsFrame)
    FpsLbl.Size = UDim2.new(0, 25, 1, 0)
    FpsLbl.Position = UDim2.new(0, 56, 0, 1)
    FpsLbl.BackgroundTransparency = 1
    FpsLbl.Text = "FPS"
    FpsLbl.Font = Enum.Font.GothamBold
    FpsLbl.TextSize = 9
    FpsLbl.TextColor3 = PANEL_MUTED
    FpsLbl.TextXAlignment = Enum.TextXAlignment.Left

    local StableLbl = Instance.new("TextLabel", FpsFrame)
    StableLbl.Size = UDim2.new(0, 40, 1, 0)
    StableLbl.Position = UDim2.new(1, -48, 0, 1)
    StableLbl.BackgroundTransparency = 1
    StableLbl.Text = "STABLE"
    StableLbl.Font = Enum.Font.GothamBold
    StableLbl.TextSize = 8
    StableLbl.TextColor3 = PANEL_MUTED
    StableLbl.TextXAlignment = Enum.TextXAlignment.Right

    -- Ball Stats panel
    PFrame = Instance.new("Frame", StatsGui)
    PFrame.Size = UDim2.new(0,204,0,126); PFrame.Position = UDim2.new(0,20,0.5,-63)
    PFrame.BackgroundColor3 = Color3.fromRGB(8,10,16); PFrame.BackgroundTransparency = 0; PFrame.BorderSizePixel = 0; PFrame.Visible = false
    Instance.new("UICorner", PFrame).CornerRadius = UDim.new(0,18)
    local PS_Stroke = Instance.new("UIStroke", PFrame); PS_Stroke.Color = PANEL_ACCENT; PS_Stroke.Thickness = 1; PS_Stroke.Transparency = 0.16
    local PGradient = Instance.new("UIGradient", PFrame); PGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(22,25,40)), ColorSequenceKeypoint.new(0.48, Color3.fromRGB(8,10,16)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12,19,34))}; PGradient.Rotation = 25
    local PTitleBand = Instance.new("Frame", PFrame)
    PTitleBand.Position = UDim2.fromOffset(10, 10)
    PTitleBand.Size = UDim2.new(1, -20, 0, 28)
    PTitleBand.BackgroundColor3 = Color3.fromRGB(20, 23, 35)
    PTitleBand.BackgroundTransparency = 0.05
    PTitleBand.BorderSizePixel = 0
    Instance.new("UICorner", PTitleBand).CornerRadius = UDim.new(0, 12)
    local PTitle2 = Instance.new("TextLabel", PTitleBand); PTitle2.Size = UDim2.new(1,-20,1,0); PTitle2.Position = UDim2.new(0,10,0,0); PTitle2.Text = "BALL VELOCITY"; PTitle2.TextColor3 = PANEL_ACCENT_LIGHT; PTitle2.BackgroundTransparency = 1; PTitle2.Font = Enum.Font.GothamBlack; PTitle2.TextSize = 11; PTitle2.TextXAlignment = Enum.TextXAlignment.Left

    local CurrentBox = Instance.new("Frame", PFrame)
    CurrentBox.Position = UDim2.fromOffset(10, 48)
    CurrentBox.Size = UDim2.new(1, -20, 0, 38)
    CurrentBox.BackgroundColor3 = Color3.fromRGB(17, 20, 31)
    CurrentBox.BackgroundTransparency = 0.02
    CurrentBox.BorderSizePixel = 0
    Instance.new("UICorner", CurrentBox).CornerRadius = UDim.new(0, 12)
    local CurrentAccent = Instance.new("Frame", CurrentBox)
    CurrentAccent.Size = UDim2.new(0, 4, 1, -12)
    CurrentAccent.Position = UDim2.new(0, 8, 0, 6)
    CurrentAccent.BackgroundColor3 = PANEL_ACCENT_LIGHT
    CurrentAccent.BorderSizePixel = 0
    Instance.new("UICorner", CurrentAccent).CornerRadius = UDim.new(1, 0)
    local VLabel = Instance.new("TextLabel", CurrentBox); VLabel.Position = UDim2.new(0,20,0,5); VLabel.Size = UDim2.new(0.5,0,0,12); VLabel.Text = "CURRENT"; VLabel.TextColor3 = PANEL_MUTED; VLabel.BackgroundTransparency = 1; VLabel.Font = Enum.Font.GothamBold; VLabel.TextSize = 8; VLabel.TextXAlignment = Enum.TextXAlignment.Left
    VLog = Instance.new("TextLabel", CurrentBox); VLog.Position = UDim2.new(0,20,0,16); VLog.Size = UDim2.new(1,-30,0,20); VLog.Text = "0.0"; VLog.TextColor3 = PANEL_TEXT; VLog.BackgroundTransparency = 1; VLog.Font = Enum.Font.GothamBlack; VLog.TextSize = 17; VLog.TextXAlignment = Enum.TextXAlignment.Left

    local PeakBox = Instance.new("Frame", PFrame)
    PeakBox.Position = UDim2.fromOffset(10, 91)
    PeakBox.Size = UDim2.new(1, -20, 0, 25)
    PeakBox.BackgroundColor3 = Color3.fromRGB(14, 16, 25)
    PeakBox.BackgroundTransparency = 0.04
    PeakBox.BorderSizePixel = 0
    Instance.new("UICorner", PeakBox).CornerRadius = UDim.new(0, 10)
    local PLabel = Instance.new("TextLabel", PeakBox); PLabel.Position = UDim2.new(0,12,0,0); PLabel.Size = UDim2.new(0.42,0,1,0); PLabel.Text = "PEAK"; PLabel.TextColor3 = PANEL_MUTED; PLabel.BackgroundTransparency = 1; PLabel.Font = Enum.Font.GothamBold; PLabel.TextSize = 8; PLabel.TextXAlignment = Enum.TextXAlignment.Left
    PLog = Instance.new("TextLabel", PeakBox); PLog.Position = UDim2.new(0.45,0,0,0); PLog.Size = UDim2.new(0.5,0,1,0); PLog.Text = "0.0"; PLog.TextColor3 = PANEL_ACCENT_LIGHT; PLog.BackgroundTransparency = 1; PLog.Font = Enum.Font.GothamBlack; PLog.TextSize = 12; PLog.TextXAlignment = Enum.TextXAlignment.Right

    local function makeDraggable(frame)
        frame.Active = true
        local dragging=false
        local dragInput=nil
        local dragStart=nil
        local startPosition=nil
        frame.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging=true
                dragStart=input.Position
                startPosition=frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState==Enum.UserInputState.End then dragging=false end
                end)
            end
        end)
        frame.InputChanged:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging or input~=dragInput then return end
            local delta=input.Position-dragStart
            frame.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+delta.X,startPosition.Y.Scale,startPosition.Y.Offset+delta.Y)
        end)
    end
    makeDraggable(StatsContainer)
    makeDraggable(PFrame)

    World:Toggle({
        Title = "FPS / Ping Panel", Desc = "Shows FPS/Ping panel in top right",
        Value = false,
        Callback = function(v) StatsContainer.Visible = v end,
    })
    task.defer(function()
        if StatsContainer and StatsContainer.Parent then
            StatsContainer.Visible = false
        end
    end)

    local pingHistory = {}
    for i=1, numBars do pingHistory[i] = 0 end

    local fpsC = 0; local fpsT = 0
    RunService.Heartbeat:Connect(function(dt)
        fpsC += 1; fpsT += dt
        if fpsT >= 1 then
            local currentFps = math.floor(fpsC / fpsT)
            FpsVal.Text = tostring(currentFps)
            if currentFps > 50 then
                StableLbl.Text = "STABLE"
                StableLbl.TextColor3 = PANEL_MUTED
                Dot.BackgroundColor3 = PANEL_TEXT
            elseif currentFps > 30 then
                StableLbl.Text = "UNSTABLE"
                StableLbl.TextColor3 = Color3.fromRGB(238,198,88)
                Dot.BackgroundColor3 = Color3.fromRGB(238,198,88)
            else
                StableLbl.Text = "LAGGING"
                StableLbl.TextColor3 = Color3.fromRGB(238,95,120)
                Dot.BackgroundColor3 = Color3.fromRGB(238,95,120)
            end
            fpsC = 0; fpsT = 0
            pcall(function()
                local ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
                PingLabel.Text = tostring(ping) .. " ms"
                if ping < 80 then PingLabel.TextColor3 = PANEL_ACCENT_LIGHT
                elseif ping < 150 then PingLabel.TextColor3 = Color3.fromRGB(238,198,88)
                else PingLabel.TextColor3 = Color3.fromRGB(238,95,120) end

                table.remove(pingHistory, 1)
                table.insert(pingHistory, ping)

                local maxPing = 100
                for i=1, numBars do if pingHistory[i] > maxPing then maxPing = pingHistory[i] end end
                for i=1, numBars do
                    local hPing = pingHistory[i]
                    local bar = bars[i]
                    if hPing == 0 then
                        bar.Size = UDim2.new(0, barWidth, 0, 2)
                        bar.Position = UDim2.new(0, (i-1) * (barWidth + 1), 1, -2)
                    else
                        local hFrac = math.clamp(hPing / maxPing, 0.1, 1)
                        local bHeight = math.max(2, math.floor(hFrac * 22))
                        bar.Size = UDim2.new(0, barWidth, 0, bHeight)
                        bar.Position = UDim2.new(0, (i-1) * (barWidth + 1), 1, -bHeight)
                        if hPing < 80 then bar.BackgroundColor3 = PANEL_ACCENT_LIGHT
                        elseif hPing < 150 then bar.BackgroundColor3 = Color3.fromRGB(238,198,88)
                        else bar.BackgroundColor3 = Color3.fromRGB(238,95,120) end
                    end
                end
            end)
        end
    end)
    end)()

    -- ══ BUG REPORT BACKEND ═════════════════════════════════════════
    do
    local DISCORD_WEBHOOK_URL = "" -- Removed: original webhook credential was exposed.
    local function sendBugReportToDiscord(bugType, bugMessage)
        -- ICEHUB safety: reports are not transmitted to any external server.
        return false
    end

    -- ══ SETTINGS TAB ══════════════════════════════════════════════════
    Window:Section({ Title = "Settings" })

    SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

    SettingsTab:Section({ Title = "Script" })
    SettingsTab:Button({
        Title = "Unload Script", Desc = "Closes the UI",
        ButtonText = "Unload",
        Callback = function()
            if getgenv().setFallingParticles then
                getgenv().setFallingParticles(false)
            end
            Window:Destroy()
        end,
    })

    SettingsTab:Section({ Title = "Network" })
    SettingsTab:Toggle({
        Title = "Ping Spoofer", Desc = "Spoofs your displayed ping",
        Value = false,
        Callback = function(v)
            getgenv().PingSpooferEnabled = v
            getgenv().updatePingSpoofer()
        end,
    })
    SettingsTab:Slider({
        Flag = "PingSpoofedValue",
        Title = "Spoofed Ping Value", Desc = "Fake ping to display",
        Step = 1,
        Value = { Min = 0, Max = 999, Default = 0 },
        Callback = function(v)
            getgenv().PingSpoofedValue = v
        end,
    })

    -- ══ BUGS REPORTS TAB ═════════════════════════════════════════
    BugReportTab = Window:Tab({ Title = "Bugs Reports", Icon = "bug" })

    getgenv()._lhxBugType = getgenv()._lhxBugType or "Other"
    getgenv()._lhxBugMessage = getgenv()._lhxBugMessage or ""

    BugReportTab:Section({ Title = "Report a Bug" })

    BugReportTab:Dropdown({
        Title = "Bug Type",
        Desc = "Select the type of bug",
        Values = { "Crash", "Feature Not Working", "UI Issue", "Performance Issue", "Other" },
        Value = "Other",
        Callback = function(value) getgenv()._lhxBugType = value end,
    })

    BugReportTab:Input({
        Title = "Bug Description",
        Desc = "Describe the bug...",
        Placeholder = "Type here...",
        Callback = function(value) getgenv()._lhxBugMessage = value end,
    })

    BugReportTab:Button({
        Title = "Send Bug Report",
        Desc = "External reporting is disabled for privacy",
        ButtonText = "Send Report",
        Callback = function()
            local bugMessage = getgenv()._lhxBugMessage or ""
            if bugMessage == "" then
                WindUI:Notify({ Title = "Error", Content = "Please enter a description.", Duration = 3 })
                return
            end
            local ok = sendBugReportToDiscord(getgenv()._lhxBugType or "Other", bugMessage)
            if ok then
                WindUI:Notify({ Title = "External Reporting Disabled", Content = "Your report was not sent anywhere.", Duration = 3 })
            else
                WindUI:Notify({ Title = "Failed", Content = "External bug reporting is disabled for privacy.", Duration = 3 })
            end
        end,
    })

    BugReportTab:Section({ Title = "Discord Server" })
    BugReportTab:DiscordPanel({
        Title = "ICEHUB | Premium S",
        Callback = function()
            if setclipboard then setclipboard(DISCORD_LINK) end
            WindUI:Notify({ Title = "Copied!", Content = "Discord link copied.", Duration = 3 })
        end
    })

    end -- /do (Bug Report Backend)
    -- ══ STARTUP ═══════════════════════════════════════════════════════
    end -- /function _buildRemainingTabs
    _buildRemainingTabs()

    Window:SelectTab(1)

    -- ICEHUB Purple Glass finish (only this script's own ScreenGuis).
    task.defer(function()
        local purple = Color3.fromRGB(168, 85, 247)
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local guiName = gui.Name:lower()
                if guiName:find("icehub", 1, true) or guiName:find("spamcenter", 1, true) then
                    for _, item in ipairs(gui:GetDescendants()) do
                        if item:IsA("Frame") then
                            local c = item.BackgroundColor3
                            local isDarkPanel = c.R < 0.25 and c.G < 0.25 and c.B < 0.35
                            if isDarkPanel then
                                item.BackgroundTransparency = math.max(item.BackgroundTransparency, 0.12)
                                if not item:FindFirstChildOfClass("UICorner") then
                                    local corner = Instance.new("UICorner")
                                    corner.CornerRadius = UDim.new(0, 10)
                                    corner.Parent = item
                                end
                                if not item:FindFirstChildOfClass("UIStroke") then
                                    local stroke = Instance.new("UIStroke")
                                    stroke.Color = purple
                                    stroke.Thickness = 1
                                    stroke.Transparency = 0.78
                                    stroke.Parent = item
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        WindUI:Notify({
            Title = "ICEHUB | PURPLE GLASS",
            Content = "ICEHUB loaded successfully.",
            Duration = 5,
        })
    end)



    -- ═══ MAIN HEARTBEAT ══════════════════════════════════════════════
    getgenv()._lhxMainHeartbeat = getgenv()._lhxMainHeartbeat or {
        lastBallCheck = 0,
        cachedBall = nil,
        lastHrpCache = 0,
        cachedHrp = nil,
        frameCount = 0,
    }
    RunService.Heartbeat:Connect(function()
        local hbState = getgenv()._lhxMainHeartbeat
        local now=tick(); hbState.frameCount=(hbState.frameCount or 0)+1
        if now-(hbState.lastHrpCache or 0)>0.15 then local ch=LocalPlayer.Character; hbState.cachedHrp=ch and ch:FindFirstChild("HumanoidRootPart"); hbState.lastHrpCache=now end
        local hrp=hbState.cachedHrp; if not hrp then return end
        if now-(hbState.lastBallCheck or 0)>0.08 then hbState.cachedBall=findBall(); hbState.lastBallCheck=now end
        local ball=hbState.cachedBall; local inGame=isInGame()
        if not inGame and spamActive then setSpam(false) end

        if ball and ball:IsA("BasePart") then
            if ShowPeak and hbState.frameCount%3==0 then local vel=getBallVelocity(ball).Magnitude; VLog.Text=string.format("%.1f",vel); if vel>peakVel then peakVel=vel; PLog.Text=string.format("%.1f",peakVel) end end
        else
            if ShowPeak and hbState.frameCount%3==0 then VLog.Text="0.0" end
        end
        if ManualSpamEnabled and spamActive and spamRemote and spamRaw and inGame then
            if now-lastSpamTime>=spamInterval then
                lastSpamTime=now
                Auto_Spam.Parry(true)
            end
        end
    end)

    -- Visuals & Hitbox Background Loop
    task.spawn(function()
        local CoreGui = game:GetService("CoreGui")
        local Workspace = game:GetService("Workspace")
        local ballEspFolder = Workspace:FindFirstChild("IceHubX_BallESP")
        if not ballEspFolder then
            ballEspFolder = Instance.new("Folder")
            ballEspFolder.Name = "IceHubX_BallESP"
            ballEspFolder.Parent = Workspace
        end


        local ballBeam = nil
        local ballAtt1 = nil
        local ballAtt2 = nil
        local ballBillboard = nil

        while task.wait(0.03) do
            pcall(function()
                local lpChar = LocalPlayer.Character
                local hrp = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
                
                -- Ball ESP & Tracer
                if getgenv().ballESP and hrp then
                    if not ballBeam then
                        ballAtt1 = Instance.new("Attachment", workspace.Terrain)
                        ballAtt2 = Instance.new("Attachment", workspace.Terrain)
                        ballBeam = Instance.new("Beam")
                        ballBeam.FaceCamera = true
                        ballBeam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
                        ballBeam.Width0 = 0.2
                        ballBeam.Width1 = 0.2
                        ballBeam.Attachment0 = ballAtt1
                        ballBeam.Attachment1 = ballAtt2
                        ballBeam.Parent = ballEspFolder
                        
                        ballBillboard = Instance.new("BillboardGui")
                        ballBillboard.Size = UDim2.new(0, 200, 0, 50)
                        ballBillboard.AlwaysOnTop = true
                        
                        local txt = Instance.new("TextLabel", ballBillboard)
                        txt.Name = "Info"
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.BackgroundTransparency = 1
                        txt.TextColor3 = Color3.fromRGB(255, 50, 50)
                        txt.TextStrokeTransparency = 0.5
                        txt.Font = Enum.Font.SourceSansBold
                        txt.TextSize = 16
                        ballBillboard.Parent = ballEspFolder
                    end
                    
                    local ballsFolder = workspace:FindFirstChild("Balls")
                    local realBall = nil
                    if ballsFolder then
                        for _, b in pairs(ballsFolder:GetChildren()) do
                            if b:GetAttribute("realBall") then realBall = b; break end
                        end
                    end
                    
                    if realBall then
                        if getgenv().ballTracer then
                            ballAtt1.Position = hrp.Position
                            ballAtt2.Position = realBall.Position
                            ballBeam.Enabled = true
                        else
                            ballBeam.Enabled = false
                        end
                        
                        ballBillboard.Adornee = realBall
                        ballBillboard.Enabled = true
                        
                        local speed = realBall.Velocity.Magnitude
                        local target = realBall:GetAttribute("target") or "None"
                        local txt = ballBillboard:FindFirstChild("Info")
                        if txt then
                            txt.Text = string.format("Speed: %.1f\nTarget: %s", speed, target)
                        end
                    else
                        ballBeam.Enabled = false
                        ballBillboard.Enabled = false
                    end
                else
                    if ballBeam then 
                        ballBeam:Destroy(); ballBeam = nil
                        ballAtt1:Destroy(); ballAtt1 = nil
                        ballAtt2:Destroy(); ballAtt2 = nil
                        ballBillboard:Destroy(); ballBillboard = nil
                    end
                end
            end)
        end
    end)

    -- Custom VFX Changer Background Logic
    task.spawn(function()
        getgenv().customVfxColor = getgenv().customVfxColor or Color3.fromRGB(255, 50, 50)
        getgenv().customShieldVfxColor = getgenv().customShieldVfxColor or getgenv().customVfxColor
        getgenv().customSlashVfxColor = getgenv().customSlashVfxColor or getgenv().customVfxColor
        if getgenv().customShieldVfxEnabled == nil then getgenv().customShieldVfxEnabled = getgenv().customVfxEnabled or false end
        if getgenv().customSlashVfxEnabled == nil then getgenv().customSlashVfxEnabled = getgenv().customVfxEnabled or false end
        getgenv().customVfxEnabled = getgenv().customShieldVfxEnabled or getgenv().customSlashVfxEnabled

        local VFX_CLASSES = {ParticleEmitter=true, Trail=true, Beam=true, Highlight=true, ImageLabel=true, ImageButton=true, Decal=true, Texture=true}
        local function isCustomVfxObject(obj)
            return VFX_CLASSES[obj.ClassName] == true
        end

        local function containsAny(text, keywords)
            for _, keyword in ipairs(keywords) do
                if string.find(text, keyword, 1, true) then return true end
            end
            return false
        end

        local shieldKeywords = {"shield", "parry", "block", "deflect", "guard"}
        local slashKeywords = {"slash", "sword", "blade", "hit", "trail", "impact", "swing", "weapon", "effect", "vfx"}

        local function getCustomColorFor(obj)
            if obj:IsDescendantOf(game:GetService("CoreGui")) then return nil end
            local shieldEnabled = getgenv().customShieldVfxEnabled == true
            local slashEnabled = getgenv().customSlashVfxEnabled == true
            if not shieldEnabled and not slashEnabled then return nil end

            local current = obj
            local names = ""
            local lpChar = LocalPlayer.Character
            for i = 1, 6 do
                if not current or current == workspace or current == game or (lpChar and current == lpChar.Parent) then
                    break
                end
                names = names .. " " .. string.lower(current.Name or "")
                current = current.Parent
            end

            if shieldEnabled and containsAny(names, shieldKeywords) then
                return getgenv().customShieldVfxColor or getgenv().customVfxColor
            end
            if slashEnabled and containsAny(names, slashKeywords) then
                return getgenv().customSlashVfxColor or getgenv().customVfxColor
            end
            if slashEnabled and shieldEnabled then
                return getgenv().customSlashVfxColor or getgenv().customVfxColor
            end
            if shieldEnabled then
                return getgenv().customShieldVfxColor or getgenv().customVfxColor
            end
            return getgenv().customSlashVfxColor or getgenv().customVfxColor
        end
        
        local function applyCustomColor(obj)
            local color = getCustomColorFor(obj)
            if not color then return end
            
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Color = ColorSequence.new(color)
                elseif obj:IsA("Highlight") then
                    obj.FillColor = color
                    obj.OutlineColor = color
                elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                    if obj.Parent and obj.Parent:IsA("BillboardGui") then
                        obj.ImageColor3 = color
                    end
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Color3 = color
                end
            end)
        end

        -- Event-driven character VFX setup
        local currentDescendantConnection = nil
        
        local function setupCharacterVfx(char)
            if currentDescendantConnection then
                currentDescendantConnection:Disconnect()
                currentDescendantConnection = nil
            end
            if not char then return end
            
            -- Apply custom colors to existing VFX
            for _, obj in ipairs(char:GetDescendants()) do
                if isCustomVfxObject(obj) then
                    applyCustomColor(obj)
                end
            end
            
            -- Listen to newly added descendants
            currentDescendantConnection = char.DescendantAdded:Connect(function(obj)
                if isCustomVfxObject(obj) then
                    applyCustomColor(obj)
                end
            end)
        end
        
        -- Master function to reapply all character VFX (called on UI changes)
        getgenv().reapplyCustomVfx = function()
            local char = LocalPlayer.Character
            if char then
                setupCharacterVfx(char)
            end
        end

        LocalPlayer.CharacterAdded:Connect(setupCharacterVfx)
        if LocalPlayer.Character then
            task.spawn(setupCharacterVfx, LocalPlayer.Character)
        end

        -- Hook for dynamically spawned parry shields and hit effects in workspace (close to player)
        game:GetService("Workspace").DescendantAdded:Connect(function(descendant)
            if not getgenv().customShieldVfxEnabled and not getgenv().customSlashVfxEnabled then return end
            if not isCustomVfxObject(descendant) then return end
            
            local lpChar = LocalPlayer.Character
            if not lpChar then return end
            
            -- If it's in character, setupCharacterVfx handles it via DescendantAdded
            if descendant:IsDescendantOf(lpChar) then
                applyCustomColor(descendant)
                return
            end
            
            local hrp = lpChar:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            task.defer(function()
                pcall(function()
                    local p = descendant.Parent
                    if not p then return end
                    
                    local pos = nil
                    if p:IsA("BasePart") then pos = p.Position
                    elseif p:IsA("Attachment") then pos = p.WorldPosition
                    elseif (descendant:IsA("ImageLabel") or descendant:IsA("ImageButton")) and p:IsA("BillboardGui") and p.Adornee and p.Adornee:IsA("BasePart") then
                        pos = p.Adornee.Position
                    end
                    
                    if pos and (pos - hrp.Position).Magnitude < 35 then
                        applyCustomColor(descendant)
                    end
                end)
            end)
        end)
    end)

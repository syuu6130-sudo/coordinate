local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 設定保存用のテーブル
local Settings = {
    CoordinateDisplay = false,
    CoordinateUpdate = true,
    AutoTP = false,
    AxisLines = false,
    UIScale = 1,
    PositionLocked = false,
    TPCooldown = false
}

-- 設定を保存する関数
local function saveSettings()
    pcall(function()
        writefile("CoordinateSystem_Settings.txt", game:GetService("HttpService"):JSONEncode(Settings))
    end)
end

-- 設定を読み込む関数
local function loadSettings()
    if pcall(function() return readfile("CoordinateSystem_Settings.txt") end) then
        local success, result = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile("CoordinateSystem_Settings.txt"))
        end)
        if success then
            for key, value in pairs(result) do
                Settings[key] = value
            end
        end
    end
end

-- 設定を読み込み
loadSettings()

-- Rayfieldウィンドウを作成
local Window = Rayfield:CreateWindow({
    Name = "座標表示システム",
    LoadingTitle = "座標表示システム",
    LoadingSubtitle = "by Rayfield",
})

-- メインタブを作成
local MainTab = Window:CreateTab("メイン", 4483362458)
local SettingsTab = Window:CreateTab("設定", 4483362458)

-- 座標表示用のフレーム
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoordinateDisplay"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- フレームサイズをスケーラブルに
local baseWidth = 200
local baseHeight = 80
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, baseWidth * Settings.UIScale, 0, baseHeight * Settings.UIScale)
frame.Position = UDim2.new(1, -210 * Settings.UIScale, 0, 10 * Settings.UIScale)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Visible = Settings.CoordinateDisplay
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- 座標表示ラベル
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.6, 0)
label.BackgroundTransparency = 1
label.Text = "X: 0, Y: 0, Z: 0"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.Gotham
label.Parent = frame

-- TP状態表示ラベル
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.2, 0)
statusLabel.Position = UDim2.new(0, 0, 0.6, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "TP: 準備完了"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = frame

-- 重力表示ラベル
local gravityLabel = Instance.new("TextLabel")
gravityLabel.Size = UDim2.new(1, 0, 0.2, 0)
gravityLabel.Position = UDim2.new(0, 0, 0.8, 0)
gravityLabel.BackgroundTransparency = 1
gravityLabel.Text = "状態: 通常"
gravityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gravityLabel.TextScaled = true
gravityLabel.Font = Enum.Font.Gotham
gravityLabel.Parent = frame

-- UIスケール更新関数
local function updateUIScale()
    frame.Size = UDim2.new(0, baseWidth * Settings.UIScale, 0, baseHeight * Settings.UIScale)
    frame.Position = UDim2.new(1, -210 * Settings.UIScale, 0, 10 * Settings.UIScale)
end

-- ドラッグ機能
local dragInput
local dragStart
local startPos

local function updateInput(input)
    if not Settings.PositionLocked then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end

frame.InputBegan:Connect(function(input)
    if not Settings.PositionLocked and input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragStart = nil
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if not Settings.PositionLocked and input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if not Settings.PositionLocked and input == dragInput and dragStart then
        updateInput(input)
    end
end)

-- 座標更新関数
local isUpdating = Settings.CoordinateUpdate
local function updateCoordinates()
    while isUpdating do
        if frame.Visible then
            local character = game.Players.LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local position = character.HumanoidRootPart.Position
                label.Text = string.format("X: %.2f, Y: %.2f, Z: %.2f", position.X, position.Y, position.Z)
            end
        end
        wait(0.1)
    end
end

-- 自動テレポートシステム
local autoTPEnabled = Settings.AutoTP
local originalGravity = workspace.Gravity
local reducedGravity = originalGravity * 0.5
local isReducedGravity = false
local lastTPTime = 0
local tpCooldown = 1 -- 1秒クールダウン

local function setupAutoTP()
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Y座標監視ループ
    while autoTPEnabled do
        local currentPos = humanoidRootPart.Position
        local currentY = currentPos.Y
        
        -- Y座標が-22.20より下回った場合
        if currentY < -22.20 and (tick() - lastTPTime) > tpCooldown then
            lastTPTime = tick()
            
            -- テレポート実行
            local newX = currentPos.X
            local newY = -7.35
            local newZ = currentPos.Z
            
            -- X座標が-782.71の場合、Xを-740に変更
            if math.abs(currentPos.X - (-782.71)) < 1 then
                newX = -740
            end
            
            humanoidRootPart.Position = Vector3.new(newX, newY, newZ)
            
            -- 重力を0.5倍に設定（浮遊効果）
            workspace.Gravity = reducedGravity
            isReducedGravity = true
            statusLabel.Text = "TP: 実行済み"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            -- 重力監視ループ開始
            spawn(function()
                while isReducedGravity and autoTPEnabled do
                    local newCharacter = game.Players.LocalPlayer.Character
                    if newCharacter and newCharacter:FindFirstChild("HumanoidRootPart") then
                        local newY = newCharacter.HumanoidRootPart.Position.Y
                        
                        -- Y座標が-7.35に達したら重力を元に戻す
                        if newY <= -7.35 then
                            workspace.Gravity = originalGravity
                            isReducedGravity = false
                            statusLabel.Text = "TP: 準備完了"
                            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            break
                        end
                    end
                    wait(0.01)
                end
            end)
            
            Rayfield:Notify({
                Title = "自動テレポート",
                Content = string.format("Y: %.2f → %.2f", currentY, newY),
                Duration = 3,
                Image = 4483362458,
            })
        end
        
        wait(0.01)
    end
end

-- 座標軸表示システム
local axisLinesEnabled = Settings.AxisLines
local axisLines = {}
local axisLength = 10

local function createAxisLine(color, name)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new(color)
    part.Size = Vector3.new(0.2, 0.2, axisLength)
    part.Parent = workspace
    return part
end

local function updateAxisLines()
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local root = character.HumanoidRootPart
    local position = root.Position
    local cframe = root.CFrame
    
    local lookVector = cframe.LookVector
    local rightVector = cframe.RightVector
    local upVector = cframe.UpVector
    
    -- X軸（赤） - プレイヤーの右方向
    if axisLines["X"] then
        local xEnd = position + rightVector * axisLength
        axisLines["X"].CFrame = CFrame.lookAt(position + rightVector * (axisLength/2), xEnd)
    end
    
    -- Y軸（青） - 上方向
    if axisLines["Y"] then
        local yEnd = position + upVector * axisLength
        axisLines["Y"].CFrame = CFrame.lookAt(position + upVector * (axisLength/2), yEnd)
    end
    
    -- Z軸（緑） - プレイヤーの正面方向
    if axisLines["Z"] then
        local zEnd = position + lookVector * axisLength
        axisLines["Z"].CFrame = CFrame.lookAt(position + lookVector * (axisLength/2), zEnd)
    end
end

-- 軸線更新ループ
local axisUpdateConnection
local function startAxisUpdateLoop()
    if axisUpdateConnection then
        axisUpdateConnection:Disconnect()
    end
    
    axisUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if axisLinesEnabled then
            updateAxisLines()
        end
    end)
end

local function toggleAxisLines()
    axisLinesEnabled = not axisLinesEnabled
    Settings.AxisLines = axisLinesEnabled
    saveSettings()
    
    if axisLinesEnabled then
        axisLines["X"] = createAxisLine("Bright red", "X_Axis")
        axisLines["Y"] = createAxisLine("Bright blue", "Y_Axis")
        axisLines["Z"] = createAxisLine("Bright green", "Z_Axis")
        startAxisUpdateLoop()
        gravityLabel.Text = "状態: 軸線表示中"
        gravityLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    else
        for _, line in pairs(axisLines) do
            if line then line:Destroy() end
        end
        axisLines = {}
        
        if axisUpdateConnection then
            axisUpdateConnection:Disconnect()
            axisUpdateConnection = nil
        end
        gravityLabel.Text = "状態: 通常"
        gravityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

-- キャラクターの死亡時やリスポーン時の処理
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if autoTPEnabled then
        wait(1)
        setupAutoTP()
    end
    
    if axisLinesEnabled then
        for _, line in pairs(axisLines) do
            if line then line:Destroy() end
        end
        axisLines = {}
        
        wait(1)
        axisLines["X"] = createAxisLine("Bright red", "X_Axis")
        axisLines["Y"] = createAxisLine("Bright blue", "Y_Axis")
        axisLines["Z"] = createAxisLine("Bright green", "Z_Axis")
        startAxisUpdateLoop()
    end
end)

-- メイン機能
MainTab:CreateButton({
    Name = "座標表示を表示/非表示",
    Callback = function()
        frame.Visible = not frame.Visible
        Settings.CoordinateDisplay = frame.Visible
        saveSettings()
        if frame.Visible and isUpdating then
            updateCoordinates()
        end
    end,
})

MainTab:CreateToggle({
    Name = "座標更新のオン/オフ",
    CurrentValue = isUpdating,
    Flag = "CoordinateUpdateToggle",
    Callback = function(value)
        isUpdating = value
        Settings.CoordinateUpdate = value
        saveSettings()
        if value and frame.Visible then
            updateCoordinates()
        end
    end,
})

MainTab:CreateToggle({
    Name = "自動テレポート機能のオン/オフ",
    CurrentValue = autoTPEnabled,
    Flag = "AutoTPToggle",
    Callback = function(value)
        autoTPEnabled = value
        Settings.AutoTP = value
        saveSettings()
        if value then
            local character = game.Players.LocalPlayer.Character
            if character then
                setupAutoTP()
            end
        else
            workspace.Gravity = originalGravity
            isReducedGravity = false
            statusLabel.Text = "TP: 無効"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end,
})

MainTab:CreateToggle({
    Name = "座標軸表示のオン/オフ",
    CurrentValue = axisLinesEnabled,
    Flag = "AxisLinesToggle",
    Callback = function(value)
        toggleAxisLines()
    end,
})

-- 設定機能
SettingsTab:CreateSlider({
    Name = "UIサイズ調整",
    Range = {0.5, 2.0},
    Increment = 0.1,
    Suffix = "倍",
    CurrentValue = Settings.UIScale,
    Flag = "UIScaleSlider",
    Callback = function(value)
        Settings.UIScale = value
        saveSettings()
        updateUIScale()
    end,
})

SettingsTab:CreateToggle({
    Name = "位置を固定する",
    CurrentValue = Settings.PositionLocked,
    Flag = "PositionLockToggle",
    Callback = function(value)
        Settings.PositionLocked = value
        saveSettings()
        if value then
            Rayfield:Notify({
                Title = "位置固定",
                Content = "座標表示の位置が固定されました",
                Duration = 2,
                Image = 4483362458,
            })
        end
    end,
})

SettingsTab:CreateButton({
    Name = "位置をリセット",
    Callback = function()
        frame.Position = UDim2.new(1, -210 * Settings.UIScale, 0, 10 * Settings.UIScale)
        Rayfield:Notify({
            Title = "位置リセット",
            Content = "座標表示の位置をリセットしました",
            Duration = 2,
            Image = 4483362458,
        })
    end,
})

SettingsTab:CreateToggle({
    Name = "TPクールダウン(1秒)のオン/オフ",
    CurrentValue = Settings.TPCooldown,
    Flag = "TPCooldownToggle",
    Callback = function(value)
        Settings.TPCooldown = value
        tpCooldown = value and 1 or 0
        saveSettings()
    end,
})

-- 重力状態監視
spawn(function()
    while true do
        if frame.Visible then
            if workspace.Gravity == reducedGravity then
                gravityLabel.Text = "状態: 浮遊中(0.5G)"
                gravityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            elseif axisLinesEnabled then
                gravityLabel.Text = "状態: 軸線表示中"
                gravityLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
            else
                gravityLabel.Text = "状態: 通常"
                gravityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        wait(0.1)
    end
end)

-- 初期設定の適用
if Settings.CoordinateDisplay then
    frame.Visible = true
end

if Settings.AutoTP then
    local character = game.Players.LocalPlayer.Character
    if character then
        setupAutoTP()
    end
end

if Settings.AxisLines then
    toggleAxisLines()
end

updateUIScale()

-- 初期化
spawn(updateCoordinates)

-- 初期状態設定
if autoTPEnabled then
    statusLabel.Text = "TP: 監視中"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
else
    statusLabel.Text = "TP: 無効"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
end

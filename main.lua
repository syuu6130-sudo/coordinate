local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 設定保存用のテーブル
local Settings = {
    CoordinateDisplay = false,
    CoordinateUpdate = true,
    AutoTP = false,
    AxisLines = false,
    TPCooldown = false
}

-- 設定を保存する関数
local function saveSettings()
    writefile("CoordinateSystem_Settings.txt", game:GetService("HttpService"):JSONEncode(Settings))
end

-- 設定を読み込む関数
local function loadSettings()
    if isfile("CoordinateSystem_Settings.txt") then
        local success, result = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile("CoordinateSystem_Settings.txt"))
        end)
        if success then
            Settings = result
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

-- 座標表示用のフレーム
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoordinateDisplay"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 80)
frame.Position = UDim2.new(1, -210, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Visible = Settings.CoordinateDisplay
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.6, 0)
label.BackgroundTransparency = 1
label.Text = "X: 0, Y: 0, Z: 0"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.Gotham
label.Parent = frame

-- TP回数表示用ラベル
local tpCountLabel = Instance.new("TextLabel")
tpCountLabel.Size = UDim2.new(1, 0, 0.2, 0)
tpCountLabel.Position = UDim2.new(0, 0, 0.6, 0)
tpCountLabel.BackgroundTransparency = 1
tpCountLabel.Text = "TP残り: 2回"
tpCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
tpCountLabel.TextScaled = true
tpCountLabel.Font = Enum.Font.Gotham
tpCountLabel.Parent = frame

-- ドラッグ機能
local dragInput
local dragStart
local startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragStart then
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

-- 自動テレポートと重力制御システム
local autoTPEnabled = Settings.AutoTP
local originalGravity = workspace.Gravity
local reducedGravity = originalGravity * 0.5
local isReducedGravity = false
local tpCount = 2
local maxTPCount = 2
local tpCooldown = Settings.TPCooldown
local lastTPTime = 0

local function updateTPCountDisplay()
    tpCountLabel.Text = "TP残り: " .. tpCount .. "回"
    if tpCount <= 0 then
        tpCountLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        tpCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

local function setupAutoTP()
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Y座標監視ループ
    while autoTPEnabled do
        local currentY = humanoidRootPart.Position.Y
        
        -- Y座標が-22.20より下回った場合かつTP回数が残っている場合
        if currentY < -22.20 and tpCount > 0 then
            -- クールダウン確認
            if tpCooldown and (tick() - lastTPTime) < 5 then
                wait(0.01)
                continue
            end
            
            -- TP回数を減らす
            tpCount = tpCount - 1
            updateTPCountDisplay()
            lastTPTime = tick()
            
            -- テレポート実行
            local currentPos = humanoidRootPart.Position
            humanoidRootPart.Position = Vector3.new(currentPos.X, 23.23, currentPos.Z)
            
            -- 重力を0.5倍に設定
            workspace.Gravity = reducedGravity
            isReducedGravity = true
            
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
                            break
                        end
                    end
                    wait(0.01)
                end
            end)
        end
        
        wait(0.01)
    end
end

-- 座標軸表示システム
local axisLinesEnabled = Settings.AxisLines
local axisLines = {}

local function createAxisLine(color, name)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new(color)
    part.Size = Vector3.new(0.2, 0.2, 10)
    part.Parent = workspace
    
    return part
end

local function updateAxisLines()
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local root = character.HumanoidRootPart
    local position = root.Position
    local lookVector = root.CFrame.LookVector
    local rightVector = root.CFrame.RightVector
    
    -- X軸（赤） - 左右方向
    if axisLines["X"] then
        axisLines["X"].Position = position + rightVector * 5
        axisLines["X"].CFrame = CFrame.lookAt(
            position + rightVector * 5,
            position + rightVector * 10
        )
    end
    
    -- Y軸（青） - 上下方向
    if axisLines["Y"] then
        axisLines["Y"].Position = position + Vector3.new(0, 5, 0)
        axisLines["Y"].CFrame = CFrame.lookAt(
            position + Vector3.new(0, 5, 0),
            position + Vector3.new(0, 10, 0)
        )
    end
    
    -- Z軸（緑） - 前後方向（キャラクターの向いている方向）
    if axisLines["Z"] then
        axisLines["Z"].Position = position + lookVector * 5
        axisLines["Z"].CFrame = CFrame.lookAt(
            position + lookVector * 5,
            position + lookVector * 10
        )
    end
end

local function toggleAxisLines()
    axisLinesEnabled = not axisLinesEnabled
    Settings.AxisLines = axisLinesEnabled
    saveSettings()
    
    if axisLinesEnabled then
        -- 軸線を作成
        axisLines["X"] = createAxisLine("Bright red", "X_Axis")    -- X軸（赤）- 左右
        axisLines["Y"] = createAxisLine("Bright blue", "Y_Axis")   -- Y軸（青）- 上下
        axisLines["Z"] = createAxisLine("Bright green", "Z_Axis")  -- Z軸（緑）- 前後（キャラクターの向き）
        
        -- 軸線更新ループ開始
        spawn(function()
            while axisLinesEnabled do
                updateAxisLines()
                wait(0.1)
            end
        end)
    else
        -- 軸線を削除
        for _, line in pairs(axisLines) do
            if line then
                line:Destroy()
            end
        end
        axisLines = {}
    end
end

-- キャラクターの死亡時やリスポーン時の処理
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if autoTPEnabled then
        wait(1)
        setupAutoTP()
    end
    
    -- 軸線が有効な場合は再設定
    if axisLinesEnabled then
        for _, line in pairs(axisLines) do
            if line then
                line:Destroy()
            end
        end
        axisLines = {}
        
        wait(1)
        axisLines["X"] = createAxisLine("Bright red", "X_Axis")
        axisLines["Y"] = createAxisLine("Bright blue", "Y_Axis")
        axisLines["Z"] = createAxisLine("Bright green", "Z_Axis")
    end
end)

-- 座標表示ボタン
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

-- 座標固定トグル
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

-- 自動テレポートトグル
MainTab:CreateToggle({
    Name = "自動テレポート機能のオン/オフ",
    CurrentValue = autoTPEnabled,
    Flag = "AutoTPToggle",
    Callback = function(value)
        autoTPEnabled = value
        Settings.AutoTP = value
        saveSettings()
        if value then
            tpCount = maxTPCount
            updateTPCountDisplay()
            local character = game.Players.LocalPlayer.Character
            if character then
                setupAutoTP()
            end
        else
            workspace.Gravity = originalGravity
            isReducedGravity = false
        end
    end,
})

-- 座標軸表示トグル
MainTab:CreateToggle({
    Name = "座標軸表示のオン/オフ",
    CurrentValue = axisLinesEnabled,
    Flag = "AxisLinesToggle",
    Callback = function(value)
        toggleAxisLines()
    end,
})

-- TPクールダウントグル
MainTab:CreateToggle({
    Name = "TPクールダウン(5秒)のオン/オフ",
    CurrentValue = tpCooldown,
    Flag = "TPCooldownToggle",
    Callback = function(value)
        tpCooldown = value
        Settings.TPCooldown = value
        saveSettings()
    end,
})

-- TP回数リセットボタン
MainTab:CreateButton({
    Name = "TP回数をリセット",
    Callback = function()
        tpCount = maxTPCount
        updateTPCountDisplay()
        Rayfield:Notify({
            Title = "TP回数リセット",
            Content = "TP回数が" .. maxTPCount .. "回にリセットされました",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-- 重力表示ラベル
local gravityLabel = Instance.new("TextLabel")
gravityLabel.Size = UDim2.new(1, 0, 0.2, 0)
gravityLabel.Position = UDim2.new(0, 0, 0.8, 0)
gravityLabel.BackgroundTransparency = 1
gravityLabel.Text = "重力: 通常"
gravityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gravityLabel.TextScaled = true
gravityLabel.Font = Enum.Font.Gotham
gravityLabel.Visible = false
gravityLabel.Parent = frame

-- 重力状態監視
spawn(function()
    while true do
        if frame.Visible then
            gravityLabel.Visible = true
            if workspace.Gravity == reducedGravity then
                gravityLabel.Text = "重力: 0.5倍（浮遊）"
                gravityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            else
                gravityLabel.Text = "重力: 通常"
                gravityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        else
            gravityLabel.Visible = false
        end
        wait(0.1)
    end
end)

-- 初期設定の適用
if axisLinesEnabled then
    toggleAxisLines()
end

-- 初期化
updateTPCountDisplay()
spawn(updateCoordinates)

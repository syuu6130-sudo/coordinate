local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 設定保存用のテーブル
local Settings = {
    CoordinateDisplay = false,
    CoordinateUpdate = true,
    AutoTP = false,
    UIScale = 1,
    PositionLocked = false
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

-- 設定タブを作成
local SettingsTab = Window:CreateTab("設定", 4483362458)

-- 座標表示用のフレーム
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoordinateDisplay"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- フレームサイズをスケーラブルに
local baseWidth = 200
local baseHeight = 60
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

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "X: 0, Y: 0, Z: 0"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.Gotham
label.Parent = frame

-- UIスケール更新関数
local function updateUIScale()
    frame.Size = UDim2.new(0, baseWidth * Settings.UIScale, 0, baseHeight * Settings.UIScale)
    frame.Position = UDim2.new(1, -210 * Settings.UIScale, 0, 10 * Settings.UIScale)
    label.TextSize = 14 * Settings.UIScale
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

-- キャラクターの死亡時やリスポーン時の処理
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if autoTPEnabled then
        wait(1)
        setupAutoTP()
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
        end
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
    end,
})

SettingsTab:CreateButton({
    Name = "位置をリセット",
    Callback = function()
        frame.Position = UDim2.new(1, -210 * Settings.UIScale, 0, 10 * Settings.UIScale)
        Rayfield:Notify({
            Title = "位置リセット",
            Content = "座標表示の位置をリセットしました",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

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

updateUIScale()

-- 初期化
spawn(updateCoordinates)

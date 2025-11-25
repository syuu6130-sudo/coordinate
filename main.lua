local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 60)
frame.Position = UDim2.new(1, -210, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Visible = false
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
local isUpdating = true
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
local autoTPEnabled = false
local originalGravity = workspace.Gravity
local reducedGravity = originalGravity * 0.3  -- 0.3倍（30%）に修正
local isReducedGravity = false

local function setupAutoTP()
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Y座標監視ループ
    while autoTPEnabled do
        local currentY = humanoidRootPart.Position.Y
        
        -- Y座標が-22.20より下回った場合
        if currentY < -22.20 then
            -- テレポート実行
            local currentPos = humanoidRootPart.Position
            humanoidRootPart.Position = Vector3.new(currentPos.X, 23.23, currentPos.Z)
            
            -- 重力を0.3倍に設定（浮遊効果）
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
        
        wait(0.01) -- 0.01秒ごとに監視
    end
end

-- キャラクターの死亡時やリスポーン時の処理
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if autoTPEnabled then
        wait(1) -- キャラクターのロードを待つ
        setupAutoTP()
    end
end)

-- 座標表示ボタン
MainTab:CreateButton({
    Name = "座標表示を表示/非表示",
    Callback = function()
        frame.Visible = not frame.Visible
        if frame.Visible and isUpdating then
            updateCoordinates()
        end
    end,
})

-- 座標固定トグル
MainTab:CreateToggle({
    Name = "座標更新のオン/オフ",
    CurrentValue = true,
    Flag = "CoordinateUpdateToggle",
    Callback = function(value)
        isUpdating = value
        if value and frame.Visible then
            updateCoordinates()
        end
    end,
})

-- 自動テレポートトグル
MainTab:CreateToggle({
    Name = "自動テレポート機能のオン/オフ",
    CurrentValue = false,
    Flag = "AutoTPToggle",
    Callback = function(value)
        autoTPEnabled = value
        if value then
            -- 自動テレポート機能を有効化
            local character = game.Players.LocalPlayer.Character
            if character then
                setupAutoTP()
            end
        else
            -- 自動テレポート機能を無効化、重力を元に戻す
            workspace.Gravity = originalGravity
            isReducedGravity = false
        end
    end,
})

-- 重力表示ラベル（オプション）
local gravityLabel = Instance.new("TextLabel")
gravityLabel.Size = UDim2.new(1, 0, 0, 20)
gravityLabel.Position = UDim2.new(0, 0, 1, 5)
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
                gravityLabel.Text = "重力: 0.3倍（浮遊）"
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

-- 初期化
spawn(updateCoordinates)

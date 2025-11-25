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

-- 初期化
spawn(updateCoordinates)

-- App
-- 11 Fevereiro, 2025
-- suporte mobile feito por MachineFox :)

local App = {}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local midiPlayer = script:FindFirstAncestor("MidiPlayer")

local FastDraggable = require(midiPlayer.FastDraggable)
local Controller = require(midiPlayer.Components.Controller)
local Sidebar = require(midiPlayer.Components.Sidebar)
local Preview = require(midiPlayer.Components.Preview)

local gui = midiPlayer.Assets.ScreenGui

-- Configurações de animação
local ANIMATION_TIME = 0.4
local EASING_STYLE = Enum.EasingStyle.Quart
local EASING_DIRECTION = Enum.EasingDirection.Out

function App:GetGUI()
    return gui
end

-- Função para criar animação
local function createTween(object, properties)
    local tweenInfo = TweenInfo.new(
        ANIMATION_TIME,
        EASING_STYLE,
        EASING_DIRECTION
    )
    return TweenService:Create(object, tweenInfo, properties)
end

function App:Init()
    FastDraggable(gui.Frame, gui.Frame.Handle)
    gui.Parent = CoreGui

    -- Criando o botão toggle circular
    local toggleButton = Instance.new("Frame")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 45, 0, 45)
    toggleButton.Position = UDim2.new(0, 20, 0.5, -22.5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = gui

    -- Tornando o botão circular
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = toggleButton

    -- Ícone do botão
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "+"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextSize = 30
    icon.Font = Enum.Font.GothamBold
    icon.Parent = toggleButton

    -- Configurando posição inicial do GUI centralizado
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local centerX = viewportSize.X/2 - gui.Frame.Size.X.Offset/2
    local centerY = viewportSize.Y/2 - gui.Frame.Size.Y.Offset/2
    local offScreenY = -gui.Frame.Size.Y.Offset - 50  -- 50 pixels extra para garantir que está fora da tela
    
    -- Estado do GUI
    local isOpen = false
    local animating = false
    
    local function toggleGUI()
        if animating then return end
        animating = true
        
        isOpen = not isOpen
        
        -- Animação do ícone
        local iconTween = createTween(icon, {
            Rotation = isOpen and 0 or 45
        })
        iconTween:Play()
        
        -- Posições do GUI (sempre mantendo X centralizado)
        local targetY = isOpen and centerY or offScreenY
        local frameTween = createTween(gui.Frame, {
            Position = UDim2.new(0.1, centerX, 0, targetY)
        })
        
        frameTween.Completed:Connect(function()
            animating = false
        end)
        
        frameTween:Play()
    end

    -- Sistema de clique simples
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            toggleGUI()
        end
    end)

    -- Inicializando componentes
    Controller:Init(gui.Frame)
    Sidebar:Init(gui.Frame)
    Preview:Init(gui.Frame)
    
    -- Posicionar GUI inicialmente fora da tela mas centralizado horizontalmente
    gui.Frame.Position = UDim2.new(0, centerX, 0, offScreenY)
end

return App

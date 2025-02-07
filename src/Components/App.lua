-- App
-- 7 Fevereiro, 2025
-- suporte mobile feito por MachineFox :)

local App = {}

local CoreGui = game:GetService("CoreGui")

local midiPlayer = script:FindFirstAncestor("MidiPlayer")

local FastDraggable = require(midiPlayer.FastDraggable)
local Controller = require(midiPlayer.Components.Controller)
local Sidebar = require(midiPlayer.Components.Sidebar)
local Preview = require(midiPlayer.Components.Preview)

local gui = midiPlayer.Assets.ScreenGui

function App:GetGUI()
    return gui
end

function App:Init()

    FastDraggable(gui.Frame, gui.Frame.Handle)
    gui.Parent = CoreGui

    -- Adicionando o botão para minimizar e maximizar com a nova aparência
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 100, 0, 50)
    toggleButton.Position = UDim2.new(0, 0, 0.5, -25)
    toggleButton.Text = "Toggle"
    toggleButton.Parent = gui

    -- Ajustando a aparência do botão
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 50)  -- Ajuste o tamanho conforme necessário
    toggleButton.Position = UDim2.new(0, 20, 0.5, -25)  -- Posição na esquerda, meio da tela
    toggleButton.AnchorPoint = Vector2.new(0, 0.5)
    toggleButton.BackgroundColor3 = Color3.new(0, 0, 0)  -- Cor preta
    toggleButton.BorderSizePixel = 0
    toggleButton.AutoButtonColor = false

    local plusSign = Instance.new("TextLabel")
    plusSign.Size = UDim2.new(1, 0, 1, 0)
    plusSign.BackgroundTransparency = 1
    plusSign.Text = "+"
    plusSign.TextColor3 = Color3.new(1, 1, 1)  -- Cor branca
    plusSign.Font = Enum.Font.SourceSans
    plusSign.TextSize = 36
    plusSign.Parent = toggleButton

    local function toggleGUI()
        if gui.Frame.Visible then
            gui.Frame.Visible = false
        else
            gui.Frame.Visible = true
        end
    end

    toggleButton.MouseButton1Click:Connect(toggleGUI)

    Controller:Init(gui.Frame)
    Sidebar:Init(gui.Frame)
    Preview:Init(gui.Frame)

end

return App
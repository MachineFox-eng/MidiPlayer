-- Sidebar
-- 7 Fevereiro, 2025
-- suporte mobile feito por MachineFox :)

local midiPlayer = script:FindFirstAncestor("MidiPlayer")
local Thread = require(midiPlayer.Util.Thread)
local Controller = require(midiPlayer.Components.Controller)
local FastTween = require(midiPlayer.FastTween)

local Sidebar = {}

local tweenInfo = { 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out }

local sidebar, template, isDragging, startDragPosition, startScrollPosition

-- Função para criar um elemento na barra lateral com base no arquivo MIDI
function Sidebar:CreateElement(filePath)
    local fullname = filePath:match("([^\\]+)$")
    local name = fullname:gsub("^midi/", ""):match("^([^%.]+)") or ""  -- Remove o prefixo "midi/"
    local extension = fullname:match("([^%.]+)$")

    if (extension ~= "mid") then
        return
    end

    local element = template:Clone()
    element.Name = filePath
    element.Title.Text = name

    if (Controller.CurrentFile == filePath) then
        element.Selection.Size = UDim2.fromOffset(3, 16)
    else
        element.Selection.Size = UDim2.fromOffset(3, 0)
    end

    local lastClickTime = 0

    element.InputBegan:Connect(function(input)
        if not isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            local currentTime = tick()
            if currentTime - lastClickTime < 0.5 then  -- Verifica se o clique é duplo
                FastTween(element, tweenInfo, { BackgroundTransparency = 0.5 })
                Controller:Select(filePath)
            end
            lastClickTime = currentTime
        end
    end)

    element.InputEnded:Connect(function(input)
        if not isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            FastTween(element, tweenInfo, { BackgroundTransparency = 0.75 })
        end
    end)

    element.MouseEnter:Connect(function()
        FastTween(element, tweenInfo, { BackgroundTransparency = 0.75 })
    end)

    element.MouseLeave:Connect(function()
        FastTween(element, tweenInfo, { BackgroundTransparency = 1 })
    end)

    element.Title.TextTruncate = Enum.TextTruncate.AtEnd  -- Ajuste para truncar o texto no final

    element.Parent = sidebar.Songs
    sidebar.Songs.CanvasSize = UDim2.new(0, 0, 0, #sidebar.Songs:GetChildren() * element.AbsoluteSize.Y)
end

-- Função para atualizar a barra lateral
function Sidebar:Update()
    local files = listfiles("midi")

    for _,element in ipairs(sidebar.Songs:GetChildren()) do
        if (element:IsA("Frame") and not table.find(files, element.Name)) then
            element:Destroy()
        end
    end

    for _,filePath in ipairs(files) do
        if (not sidebar.Songs:FindFirstChild(filePath)) then
            self:CreateElement(filePath)
        end
    end
end

-- Função para inicializar a barra lateral
function Sidebar:Init(frame)
    sidebar = frame.Sidebar

    template = sidebar.Songs.Song
    template.Parent = nil

    Controller.FileLoaded:Connect(function(song)
        for _,element in ipairs(sidebar.Songs:GetChildren()) do
            if (element:IsA("Frame")) then
                if (element.Name == song.Path) then
                    FastTween(element.Selection, tweenInfo, { Size = UDim2.fromOffset(3, 16) })
                else
                    FastTween(element.Selection, tweenInfo, { Size = UDim2.fromOffset(3, 0) })
                end
            end
        end
    end)

    sidebar.Songs.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            startDragPosition = input.Position
            startScrollPosition = sidebar.Songs.CanvasPosition
        end
    end)

    sidebar.Songs.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startDragPosition
            sidebar.Songs.CanvasPosition = Vector2.new(startScrollPosition.X, startScrollPosition.Y - delta.Y)
        end
    end)

    sidebar.Songs.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    Thread.DelayRepeat(1, self.Update, self)
    self:Update()
end

return Sidebar

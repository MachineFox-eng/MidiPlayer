-- Preview
-- Versão: 3.1
-- Data: 15 Fevereiro, 2025

local midiPlayer = script:FindFirstAncestor("MidiPlayer")
local Input = require(midiPlayer.Input)
local TweenService = game:GetService("TweenService")

local Preview = {}

local genv = getgenv()

-- Cores melhoradas com gradientes mais suaves
local colors = {
    Color3.fromRGB(254, 122, 122), -- Vermelho
    Color3.fromRGB(254, 122, 122), -- Amarelo
    Color3.fromRGB(254, 122, 122), -- Verde
    Color3.fromRGB(254, 122, 122),  -- Azul
}

-- Configurações visuais
local VISUAL_SETTINGS = {
    NOTE_TRANSPARENCY = 0.1,
    GLOW_TRANSPARENCY = 0.7,
    CORNER_RADIUS = UDim.new(0, 4),
    FADE_IN_TIME = 0.15,
    GRADIENT_TRANSPARENCY = 0.2,
    ANIMATION = {
        TIME = 0.3,
        EASING = Enum.EasingStyle.Quad,
        DIRECTION = Enum.EasingDirection.Out
    }
}

local c3White = Color3.new(1, 1, 1)
local preview, notes, noteTemplate
local lastSong -- Armazena a última música para redesenhar quando reativar

-- Função auxiliar para criar efeitos visuais
local function createVisualEffects(note)
    -- Adiciona cantos arredondados
    local corner = Instance.new("UICorner")
    corner.CornerRadius = VISUAL_SETTINGS.CORNER_RADIUS
    corner.Parent = note
    
    -- Adiciona efeito de brilho
    local glow = Instance.new("UIStroke")
    glow.Color = note.BackgroundColor3
    glow.Thickness = 2
    glow.Transparency = VISUAL_SETTINGS.GLOW_TRANSPARENCY
    glow.Parent = note
    
    -- Adiciona gradiente vertical
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, VISUAL_SETTINGS.GRADIENT_TRANSPARENCY),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, VISUAL_SETTINGS.GRADIENT_TRANSPARENCY)
    })
    gradient.Parent = note
    
    return {
        corner = corner,
        glow = glow,
        gradient = gradient
    }
end

-- Função para animar o aparecimento da nota
local function animateNoteAppearance(note, effects)
    note.BackgroundTransparency = 1
    effects.glow.Transparency = 1
    
    -- Animação de fade in
    local tweenInfo = TweenInfo.new(
        VISUAL_SETTINGS.FADE_IN_TIME,
        VISUAL_SETTINGS.ANIMATION.EASING,
        VISUAL_SETTINGS.ANIMATION.DIRECTION
    )
    
    local fadeInTween = TweenService:Create(note, tweenInfo, {
        BackgroundTransparency = VISUAL_SETTINGS.NOTE_TRANSPARENCY
    })
    
    local glowFadeInTween = TweenService:Create(effects.glow, tweenInfo, {
        Transparency = VISUAL_SETTINGS.GLOW_TRANSPARENCY
    })
    
    fadeInTween:Play()
    glowFadeInTween:Play()
end

function Preview:Draw(song)
    -- Se preview estiver desativada, apenas armazena a música e retorna
    if genv._hideSongPreview then
        lastSong = song
        return
    end

    notes:ClearAllChildren()

    for i, track in next, song._score, 1 do
        local color = colors[(i % #colors) + 1]

        for _, event in ipairs(track) do
            if (event[1] == "note") then
                local pitch = event[5]
                local note = noteTemplate:Clone()
                
                -- Define a cor base da nota
                if (Input.IsUpper(pitch)) then
                    note.BackgroundColor3 = color:Lerp(c3White, 0.25)
                else
                    note.BackgroundColor3 = color
                end
                
                -- Mantém as coordenadas originais
                note.Position = UDim2.new((pitch - 36) / 61, 0, 0, -event[2] / 2)
                note.Size = UDim2.new(0.016, 0, 0, math.max(event[3] / 2, 1))
                
                -- Adiciona efeitos visuais
                local effects = createVisualEffects(note)
                
                -- Anima o aparecimento
                note.Parent = notes
                animateNoteAppearance(note, effects)
            end
        end
    end

    notes.Parent = preview
end

function Preview:Clear()
    notes:ClearAllChildren()
    lastSong = nil
end

function Preview:Update(position)
    -- Se a preview estava desativada e foi reativada, redesenha
    if not genv._hideSongPreview and notes.Parent == nil and lastSong then
        self:Draw(lastSong)
    end
    
    -- Se a preview está desativada, remove as notas
    if genv._hideSongPreview then
        notes.Parent = nil
        return
    end
    
    -- Atualiza a posição se necessário
    if position then
        notes.Position = UDim2.new(0, 0, 1, position / 2)
    end
    
    -- Garante que as notas estão visíveis
    if notes.Parent == nil then
        notes.Parent = preview
    end
end

function Preview:Init(frame)
    preview = frame.Preview
    notes = preview.Notes
    noteTemplate = notes.Note
    noteTemplate.Parent = nil
end

return Preview

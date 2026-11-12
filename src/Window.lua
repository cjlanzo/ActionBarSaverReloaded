local _, ns = ...

-- The export and import windows. Only the windows live here; Actions decides
-- what to export and what an import does.
local Window = {}
ns.Window = Window

-- AceGUI's edit box has no method for its button's label
local function SetButtonText(box, text)
    box.button:SetText(text)
    box.button:SetWidth(box.button:GetFontString():GetStringWidth() + 24)
end

local function OpenFrame(title)
    local AceGUI = _G.LibStub("AceGUI-3.0")
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(title)
    frame:SetLayout("Fill")
    frame:SetWidth(500)
    frame:SetHeight(320)
    local box = AceGUI:Create("MultiLineEditBox")
    frame:SetCallback("OnClose", function(widget)
        -- AceGUI reuses widgets, and other addons expect the button to say Accept
        SetButtonText(box, ACCEPT)
        AceGUI:Release(widget)
    end)

    box:DisableButton(true)
    frame:AddChild(box)

    return frame, box
end

function Window.ShowExport(title, text)
    local frame, box = OpenFrame(title)
    box:SetLabel("Press Ctrl+C to copy, then use /abs import on the other account")
    box:SetText(text)
    box:SetFocus()
    box:HighlightText()
    frame:SetStatusText("")
end

-- onImport(text, replace) returns "done", "conflict" or "error", and a message.
-- A conflict turns the button into Replace, so a second click overwrites.
function Window.ShowImport(title, onImport)
    local frame, box = OpenFrame(title)
    local replace = false

    box:SetLabel("Paste an export with Ctrl+V")
    box:DisableButton(false)
    SetButtonText(box, "Import")
    box:SetFocus()

    box:SetCallback("OnTextChanged", function()
        replace = false
        SetButtonText(box, "Import")
        frame:SetStatusText("")
    end)

    box:SetCallback("OnEnterPressed", function(_, _, text)
        local result, message = onImport(text, replace)

        if result == "done" then
            frame:Hide()
            -- The box is released by now; keep AceGUI from touching its button
            return true
        elseif result == "conflict" then
            replace = true
            SetButtonText(box, "Replace")
            frame:SetStatusText(message .. " Click Replace to overwrite, or close to cancel.")
            -- Returning true keeps the button enabled for the second click
            return true
        else
            frame:SetStatusText(message)
        end
    end)
end

local _, ns = ...

-- The export and import windows. Only the windows live here; Actions decides
-- what to export and what an import does.
local Window = {}
ns.Window = Window

local function OpenFrame(title)
    local AceGUI = _G.LibStub("AceGUI-3.0")
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(title)
    frame:SetLayout("Fill")
    frame:SetWidth(500)
    frame:SetHeight(320)
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

    local box = AceGUI:Create("MultiLineEditBox")
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
    box:SetButtonText("Import")
    box:SetFocus()

    box:SetCallback("OnTextChanged", function()
        replace = false
        box:SetButtonText("Import")
        frame:SetStatusText("")
    end)

    box:SetCallback("OnEnterPressed", function(_, _, text)
        local result, message = onImport(text, replace)

        if result == "done" then
            frame:Hide()
        elseif result == "conflict" then
            replace = true
            box:SetButtonText("Replace")
            frame:SetStatusText(message .. " Click Replace to overwrite, or close to cancel.")
        else
            frame:SetStatusText(message)
        end
    end)
end

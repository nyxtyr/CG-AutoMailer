-- Initialize the addon namespace
local addonName, CGAutoMailer = ...

-- Default settings
local mailSubject = "Items from AutoMailer"

-- Create a frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("ADDON_LOADED")

-- Create the mail button
local mailButton = CreateFrame("Button", "MailAllButton", MailFrame, "UIPanelButtonTemplate")
mailButton:SetSize(102, 25)
mailButton:SetText("Mail All Items")
mailButton:SetPoint("BOTTOMRIGHT", MailFrame, "BOTTOMRIGHT", 0, -25)
mailButton:Hide()

-- Create the settings button
local settingsButton = CreateFrame("Button", "SettingsButton", MailFrame, "UIPanelButtonTemplate")
settingsButton:SetSize(25, 25)
settingsButton:SetPoint("RIGHT", mailButton, "LEFT", -5, 0)
settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton")
settingsButton:Hide()

-- Load the saved variables or set to defaults
local mailToCharacter = CGAutoMailerDB and CGAutoMailerDB.mailToCharacter or "Nyrk-Mal'Ganis"
local ignoredItems = CGAutoMailerDB and CGAutoMailerDB.ignoredItems or {}

-- Debug function
local function DebugPrint(...)
    -- Uncomment the next line to enable debug printing
    -- print(...)
end

-- Function to clean item names (remove link formatting and convert to lowercase)
local function CleanItemName(itemLink)
    if not itemLink then return "" end
    
    local cleanName = itemLink
    
    -- If it's an item link, extract the name
    if cleanName:match("|H") then
        -- Get the item name from the link using GetItemInfo
        local itemID = cleanName:match("|Hitem:(%d+)")
        if itemID then
            cleanName = select(1, GetItemInfo(itemID)) or cleanName
        else
            -- If we can't get the item ID, try to extract the name manually
            cleanName = cleanName:match("%[(.+)%]")
            if cleanName then
                -- Remove any remaining link formatting
                cleanName = cleanName:gsub("|c%x+", ""):gsub("|r", ""):gsub("|A:[^|]+|a", "")
            end
        end
    else
        -- If it's not an item link, just remove brackets and extra formatting
        cleanName = cleanName:gsub("%[", ""):gsub("%]", ""):gsub("|c%x+", ""):gsub("|r", ""):gsub("|A:[^|]+|a", "")
    end
    
    -- Trim whitespace and convert to lowercase
    cleanName = cleanName and cleanName:trim() or ""
    DebugPrint("Cleaned item name:", cleanName)
    return cleanName
end

-- Function to check if an item is in the ignore list
local function IsItemIgnored(itemLink)
    if not itemLink then return false end
    
    local itemName = CleanItemName(itemLink)
    local isIgnored = itemName ~= "" and ignoredItems[itemName:lower()]
    
    DebugPrint("Checking item:", itemName, "IsIgnored:", isIgnored)
    return isIgnored
end

-- Function to mail all items to the specified character
local function MailAllItems()
    -- Set the recipient and subject
    SendMailNameEditBox:SetText(mailToCharacter)
    SendMailSubjectEditBox:SetText(mailSubject)

    -- Loop through the bags to find items and place them in the mail slots
    for bag = 0, 5 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink then
                DebugPrint("Found item in bag:", itemLink)
                if not IsItemIgnored(itemLink) then
                    -- Add the item to the mail slot
                    C_Container.UseContainerItem(bag, slot)
                    DebugPrint("Mailing item:", itemLink)
                else
                    DebugPrint("Skipping ignored item:", itemLink)
                end
            end
        end
    end
end

-- Create the settings window with increased size for ignore list
local settingsFrame = CreateFrame("Frame", "MailerSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(300, 400)
settingsFrame:SetPoint("CENTER")
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
settingsFrame:Hide()

-- Title text
settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY")
settingsFrame.title:SetFontObject("GameFontHighlight")
settingsFrame.title:SetPoint("CENTER", settingsFrame.TitleBg, "CENTER", 0, 0)
settingsFrame.title:SetText("Mailer Settings")

-- Recipient name label
local nameLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
nameLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -30)
nameLabel:SetText("Recipient Name:")

-- Recipient name input box
local nameInput = CreateFrame("EditBox", nil, settingsFrame, "InputBoxTemplate")
nameInput:SetSize(180, 20)
nameInput:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
nameInput:SetAutoFocus(false)
nameInput:SetText(mailToCharacter)

-- Ignore list section
local ignoreLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ignoreLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -30)
ignoreLabel:SetText("Ignored Items:")

-- Create a ScrollFrame for the ignore list
local scrollFrame = CreateFrame("ScrollFrame", nil, settingsFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(260, 250)
scrollFrame:SetPoint("TOPLEFT", ignoreLabel, "BOTTOMLEFT", 0, -10)

local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetSize(260, 500)

-- Add item input box
local addItemInput = CreateFrame("EditBox", nil, settingsFrame, "InputBoxTemplate")
addItemInput:SetSize(180, 20)
addItemInput:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -10)
addItemInput:SetAutoFocus(false)
addItemInput:SetText("Enter item name...")

-- Add item button
local addItemButton = CreateFrame("Button", nil, settingsFrame, "GameMenuButtonTemplate")
addItemButton:SetSize(70, 20)
addItemButton:SetPoint("LEFT", addItemInput, "RIGHT", 5, 0)
addItemButton:SetText("Add")

-- Function to get a sorted list of ignored items
local function GetSortedIgnoredItems()
    local items = {}
    for item, _ in pairs(ignoredItems) do
        table.insert(items, item)
    end
    table.sort(items, function(a, b) 
        return a:lower() < b:lower()
    end)
    return items
end

-- Function to update the ignore list display
local function UpdateIgnoreList()
    -- Clear existing entries
    for _, child in pairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Add entries for each ignored item in alphabetical order
    local previousEntry
    local sortedItems = GetSortedIgnoredItems()
    
    for _, itemName in ipairs(sortedItems) do
        local entry = CreateFrame("Frame", nil, scrollChild)
        entry:SetSize(240, 20)
        
        if previousEntry then
            entry:SetPoint("TOPLEFT", previousEntry, "BOTTOMLEFT", 0, -2)
        else
            entry:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
        end

        local text = entry:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        text:SetPoint("LEFT", entry, "LEFT", 5, 0)
        -- Convert first letter of each word to uppercase for display
        local displayName = itemName:gsub("^%l", string.upper):gsub("%s%l", string.upper)
        text:SetText(displayName)

        local removeButton = CreateFrame("Button", nil, entry, "UIPanelCloseButton")
        removeButton:SetSize(20, 20)
        removeButton:SetPoint("RIGHT", entry, "RIGHT", 0, 0)
        removeButton:SetScript("OnClick", function()
            ignoredItems[itemName:lower()] = nil
            CGAutoMailerDB.ignoredItems = ignoredItems
            UpdateIgnoreList()
        end)

        previousEntry = entry
    end
end

-- Add item button click handler
addItemButton:SetScript("OnClick", function()
    local itemName = addItemInput:GetText()
    if itemName and itemName ~= "Enter item name..." and itemName ~= "" then
        -- Clean and standardize the item name
        local cleanName = CleanItemName(itemName)
        if cleanName ~= "" then
            ignoredItems[cleanName:lower()] = true
            CGAutoMailerDB.ignoredItems = ignoredItems
            addItemInput:SetText("Enter item name...")
            UpdateIgnoreList()
            DebugPrint("Added item to ignore list:", cleanName:lower())
        end
    end
end)

-- Save button
local saveButton = CreateFrame("Button", nil, settingsFrame, "GameMenuButtonTemplate")
saveButton:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -10, 10)
saveButton:SetSize(70, 20)
saveButton:SetText("Save")

-- Save button action
saveButton:SetScript("OnClick", function()
    mailToCharacter = nameInput:GetText()
    CGAutoMailerDB = CGAutoMailerDB or {}
    CGAutoMailerDB.mailToCharacter = mailToCharacter
    CGAutoMailerDB.ignoredItems = ignoredItems
    settingsFrame:Hide()
end)

-- Event handler
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "MAIL_SHOW" then
        mailButton:Show()
        settingsButton:Show()
    elseif event == "MAIL_CLOSED" then
        mailButton:Hide()
        settingsButton:Hide()
        settingsFrame:Hide()
    elseif event == "ADDON_LOADED" and arg1 == addonName then
        CGAutoMailerDB = CGAutoMailerDB or {}
        if CGAutoMailerDB.mailToCharacter then
            mailToCharacter = CGAutoMailerDB.mailToCharacter
            nameInput:SetText(mailToCharacter)
        end
        if CGAutoMailerDB.ignoredItems then
            ignoredItems = CGAutoMailerDB.ignoredItems
            UpdateIgnoreList()
        end
    end
end)

-- Set button click actions
mailButton:SetScript("OnClick", function()
    MailAllItems()
end)

settingsButton:SetScript("OnClick", function()
    settingsFrame:Show()
    UpdateIgnoreList()
end)

-- Add input box focus handlers
addItemInput:SetScript("OnEditFocusGained", function(self)
    if self:GetText() == "Enter item name..." then
        self:SetText("")
    end
end)

addItemInput:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then
        self:SetText("Enter item name...")
    end
end)

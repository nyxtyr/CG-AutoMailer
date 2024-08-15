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

-- Load the saved variables or set to default
local mailToCharacter = CGAutoMailerDB and CGAutoMailerDB.mailToCharacter or "Nyrk-Mal'Ganis"

-- Function to mail all items to the specified character
local function MailAllItems()
    -- Set the recipient and subject
    SendMailNameEditBox:SetText(mailToCharacter)
    SendMailSubjectEditBox:SetText(mailSubject)

    -- Loop through the bags to find items and place them in the mail slots
    for bag = 0, 5 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemLink(bag, slot)
            if item then
                -- Add the item to the mail slot
                C_Container.UseContainerItem(bag, slot)
            end
        end
    end
end

-- Create the settings window
local settingsFrame = CreateFrame("Frame", "MailerSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(300, 100)
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

-- Save button
local saveButton = CreateFrame("Button", nil, settingsFrame, "GameMenuButtonTemplate")
saveButton:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -10, 10)
saveButton:SetSize(70, 20)
saveButton:SetText("Save")

-- Save button action
saveButton:SetScript("OnClick", function()
    mailToCharacter = nameInput:GetText() -- Update the recipient name with user input
    CGAutoMailerDB.mailToCharacter = mailToCharacter -- Save to SavedVariables
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
        if CGAutoMailerDB and CGAutoMailerDB.mailToCharacter then
            mailToCharacter = CGAutoMailerDB.mailToCharacter -- Load the saved value
            nameInput:SetText(mailToCharacter) -- Update the input box with the loaded value
        end
    end
end)

-- Set button click actions
mailButton:SetScript("OnClick", function()
    MailAllItems()
end)

settingsButton:SetScript("OnClick", function()
    settingsFrame:Show()
end)

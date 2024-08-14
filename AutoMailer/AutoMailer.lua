local mailToCharacter = "Nyrk-Mal'Ganis" -- Default value
local mailSubject = "Items from AutoMailer"

-- Create a frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_SHOW")

-- Create the mail button
local mailButton = CreateFrame("Button", "MailAllButton", MailFrame, "UIPanelButtonTemplate")
mailButton:SetSize(102, 25)
mailButton:SetText("Mail All Items")
mailButton:SetPoint("BOTTOMRIGHT", MailFrame, "BOTTOMRIGHT", 0, -25) -- Position at the bottom right of the mail window

-- Create the settings button
local settingsButton = CreateFrame("Button", "SettingsButton", MailFrame, "UIPanelButtonTemplate")
settingsButton:SetSize(25, 25)
settingsButton:SetPoint("RIGHT", mailButton, "LEFT", 126, 0) -- Position to the right of the "Mail All Items" button
settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton")

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
nameInput:SetText(mailToCharacter) -- Set to current recipient name

-- Save button
local saveButton = CreateFrame("Button", nil, settingsFrame, "GameMenuButtonTemplate")
saveButton:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -10, 10)
saveButton:SetSize(70, 20)
saveButton:SetText("Save")

-- Save button action
saveButton:SetScript("OnClick", function()
    mailToCharacter = nameInput:GetText() -- Update the recipient name with user input
    settingsFrame:Hide()
end)

-- Show button when mailbox is opened
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_SHOW" then
        mailButton:Show()
        settingsButton:Show()
    end
end)

-- Set button click actions
mailButton:SetScript("OnClick", function()
    MailAllItems()
end)

settingsButton:SetScript("OnClick", function()
    settingsFrame:Show()
end)

-- Hide buttons when mailbox is closed
frame:RegisterEvent("MAIL_CLOSED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_CLOSED" then
        mailButton:Hide()
        settingsButton:Hide()
        settingsFrame:Hide()
    end
end)

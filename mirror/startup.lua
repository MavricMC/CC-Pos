--Pos Mirror version 0.2--

os.pullEvent = os.pullEventRaw

--Made by Mavric--
--Code on https://pastebin.com/u/MavricMC--

local modem = peripheral.wrap("bottom")
local mainC = 15
local playerC = 20

modem.open(playerC)
while true do
    local eventData = {os.pullEvent()}
    if eventData[1] == "modem_message" then
        if eventData[5][1] == "clear" then
            term.clear()
        elseif eventData[5][1] == "line" then
            term.clearLine(eventData[5][2])
        elseif eventData[5][1] == "background" then
            term.setBackgroundColor(eventData[5][2])
        elseif eventData[5][1] == "cursor" then
            term.setCursorPos(eventData[5][2], eventData[5][3])
        elseif eventData[5][1] == "text" then
            term.setTextColor(eventData[5][2])
        elseif eventData[5][1] == "write" then
            term.write(eventData[5][2])
        elseif eventData[5][1] == "blink" then
            term.setCursorBlink(eventData[5][2])
        elseif eventData[5][1] == "pic" then
            if eventData[5][2] == "logo" then
                local pic = paintutils.loadImage("MPNLogo.nfp")
                paintutils.drawImage(pic, eventData[5][3], eventData[5][4])
            end
        end
    elseif eventData[1] == "terminate" then
        if (redstone.getInput("bottom")) then
            error("You found the lever didnt you")
        else
            print("Did you think Im that stupid?")
        end
    else
        modem.transmit(mainC, playerC, eventData)
    end
end

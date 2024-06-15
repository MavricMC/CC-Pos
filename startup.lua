--Point os sales system--

local vers = "0.1T"

--Made by Mavric--
--How to setup is on my youtube channel--
--Code on https://github.com/MavricMC/CC-Pos--

--os.pullEvent = os.pullEventRaw --Prevent program termination
os.loadAPI("pos/items.lua") --Long list of products is stored seperate

--Settings--
local configButtons = {}
local mainButtons = {
    {"Exit", 2, 16, colors.gray, colors.white}, --Text, lop left x and y, background color, text color
    {"Loyalty", 9, 16, colors.lightBlue, colors.white},
    {"Clear", 19, 16, colors.red, colors.white},
    {"Pay", 46, 16, colors.green, colors.white}
}
local searchResultsLength = 10
local searchMaxLength = 18
local searchMaxExtra = 4 --Extra max length added to suggestions to suggestions
local backgroundColor = colors.black
local approvalPrice = 1000 --If total price is 0 or greater it requires manager approval
local approvalQuantity = 100 --If total quantity is greater it requires manager approval
local modemSide = "bottom"
local mainC = 15
local playerC = 20

--Program wide variables--
local searchText = ""
local searchY = 0
local searchLength = 0
local typedLen = 0
local searchResults = {} ----Indexs for items in main list
local order = {}
--Config type 0: click and type interger (value/default, indicatior, lable, min, max, editing)
--Config type 1: click on 5 point liner selector (selected/default 1-5, indicatior, lable, 5 options)
--Config type 2: toggle switch (text, boolean/default, lable)
--Config type 3: click buttons to increment interger (value/default, lable, step)
--Make their postion changable
local editing = {} --Index for item in main list and stored modified values
local mode = 0 --0 search, 1 modify item
local total = 0 --Total calculated price

--Create functions--
function lengthCheck(text, length, trimEnd)
    local textLength = string.len(text)
    if textLength > length then
        if trimEnd then
            return true, string.sub(text, 1, length), textLength - length--Trim end of the string
        else
            return true, string.sub(text, textLength - length + 1, textLength), textLength - length --Trim start of the string
        end
    end
    return false, text, 0
end

function clearScreen()
    term.setBackgroundColor(backgroundColor)
    term.setTextColor(colors.yellow)
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Point of sales OS ".. vers)
    term.setCursorPos(1, 19)
    term.setTextColor(colors.lightGray)
    term.write("Made By Mavric, Please Report Bugs")
end

function drawMainButtons()
    for _, v in pairs(mainButtons) do
        term.setBackgroundColor(v[4])
        term.setTextColor(v[4])
        term.setCursorPos(v[2], v[3])
        term.write("OO".. v[1])

        term.setCursorPos(v[2], v[3] + 1)
        term.write("O")
        term.setTextColor(v[5])
        term.write(v[1])
        term.setTextColor(v[4])
        term.write("O")

        term.setCursorPos(v[2], v[3] + 2)
        term.write("OO".. v[1])
    end
end

function drawOrderList()
    total = 0
    term.setTextColor(colors.white)
    for k, v in pairs(order) do
        term.setBackgroundColor(colors.blue)
        term.setCursorPos(28, 2 * k)
        term.write(utf8.char(7))

        term.setBackgroundColor(backgroundColor)
        local toLong, results = lengthCheck(items.itemList[v[1]][1], 20, true)
        term.write(results)
        if toLong then
            term.setTextColor(colors.red)
            term.write(utf8.char(16))
        end
        term.setTextColor(colors.yellow)
        term.setCursorPos(29, 2 * k + 1)
        term.write("#:")
        term.setTextColor(colors.white)
        term.write(v[2][1])

        local price = ""
        if v[2][1] == "" then
            price = string.format("$%.2f", 0)
        else
            price = string.format("$%.2f", items.itemList[v[1]][2] * v[2][1])
            total = items.itemList[v[1]][2] * v[2][1] + total
        end
        
        term.setTextColor(colors.yellow)
        term.setCursorPos(49 - string.len(price), 2 * k + 1)
        term.write(price)
        
        term.setTextColor(colors.white)
        term.setCursorPos(50, 2 * k)
        term.setBackgroundColor(colors.red)
        term.write("X")
    end
    local subtotal = string.format("$%.2f", total * 0.85)
    local tax = string.format("$%.2f", total * 0.15)
    local totalPrice = string.format("$%.2f", total)
    if string.len(subtotal) > 9 then
        subtotal = string.format("$%d", total * 0.85)
        tax = string.format("$%d", total * 0.15)
        totalPrice = string.format("$%d", total)
    end
    term.setBackgroundColor(backgroundColor)
    term.setTextColor(colors.yellow)
    term.setCursorPos(28, 16)
    term.write("Subtotal:")
    term.setTextColor(colors.white)
    term.write(subtotal)

    term.setTextColor(colors.yellow)
    term.setCursorPos(28, 17)
    term.write("Tax:")
    term.setTextColor(colors.white)
    term.write(tax)

    term.setTextColor(colors.yellow)
    term.setCursorPos(28, 18)
    term.write("Total:")
    term.setTextColor(colors.white)
    term.write(totalPrice)
end

function drawConfig()
    local toLong, results = lengthCheck(items.itemList[editing[1]][1], searchMaxLength, true)

    term.setBackgroundColor(backgroundColor)
    term.setTextColor(colors.yellow)    
    term.setCursorPos(2, 2)
    term.write("Item: ")
    term.setTextColor(colors.white)
    term.write(results)
    if toLong then
        term.setTextColor(colors.red)
        term.write(utf8.char(16))
    end

    term.setCursorPos(2, 3)
    term.setTextColor(colors.yellow)
    term.write("Price: ")
    term.setTextColor(colors.white)
    term.write(items.itemList[editing[1]][2])

    local totalPrice = ""
    if editing[2][1] == "" then
        totalPrice = string.format("$%.2f", 0)
    else
        totalPrice = string.format("$%.2f", items.itemList[editing[1]][2] * editing[2][1])
    end
    
    term.setTextColor(colors.yellow)
    term.setCursorPos(2, 14)
    term.write("Total:")
    term.setTextColor(colors.white)
    term.write(totalPrice)

    local endPosX = 0
    local endPosY = 0
    for i = 3, table.maxn(items.itemList[editing[1]]) do
        if items.itemList[editing[1]][i][1] == 0 then
            term.setBackgroundColor(backgroundColor)
            term.setTextColor(colors.yellow)
            term.setCursorPos(2, 3 * i - 4)
            term.write(items.itemList[editing[1]][i][4])

            term.setCursorPos(2, 3 * i - 3)
            term.write(items.itemList[editing[1]][i][3])

            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.white)
            if editing[i - 1][2] then
                endPosX = (string.len(items.itemList[editing[1]][i][3]) + string.len(editing[i - 1][1]) + 2)
                endPosY = (3 * i - 3)
            end
            term.write(editing[i - 1][1])
            term.setTextColor(colors.gray)
            term.write(string.sub(items.itemList[editing[1]][i][6], string.len(editing[i - 1][1]) + 1, string.len(items.itemList[editing[1]][i][6])))

            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.blue)
            term.write(utf8.char(7))
        elseif items.itemList[editing[1]][i][1] == 1 then
            term.setBackgroundColor(backgroundColor)
            term.setTextColor(colors.yellow)
            term.setCursorPos(2, 3 * i - 4)
            term.write(items.itemList[editing[1]][i][4])
            term.setTextColor(colors.white)
            term.write(items.itemList[editing[1]][i][editing[i - 1] + 4])

            term.setTextColor(colors.yellow)
            term.setCursorPos(2, 3 * i - 3)
            term.write(items.itemList[editing[1]][i][3])

            term.setBackgroundColor(colors.red)
            term.setTextColor(colors.white)
            term.write(string.sub(utf8.char(183), 2, 2))
            term.setBackgroundColor(backgroundColor)
            term.write(string.sub(utf8.char(183), 2, 2))
            term.setBackgroundColor(colors.gray)
            term.write(string.sub(utf8.char(183), 2, 2))
            term.setBackgroundColor(backgroundColor)
            term.write(string.sub(utf8.char(183), 2, 2))

            term.setBackgroundColor(colors.green)
            term.write(string.sub(utf8.char(183), 2, 2))
        elseif items.itemList[editing[1]][i][1] == 2 then
            term.setBackgroundColor(backgroundColor)
            term.setTextColor(colors.yellow)
            term.setCursorPos(2, 3 * i - 4)
            term.write(items.itemList[editing[1]][i][3])

            term.setCursorPos(4, 3 * i - 3)
            term.setTextColor(colors.white)
            if editing[i - 1] then
                term.setBackgroundColor(colors.gray)
                term.write("  ")
                term.setBackgroundColor(colors.green)
                term.write(utf8.char(7))
            else
                term.setBackgroundColor(colors.red)
                term.write("o")
                term.setBackgroundColor(colors.gray)
                term.write("  ")
            end
        elseif items.itemList[editing[1]][i][1] == 3 then
            term.setBackgroundColor(backgroundColor)
            term.setTextColor(colors.yellow)
            term.setCursorPos(2, 3 * i - 4)
            term.write(items.itemList[editing[1]][i][3])

            term.setCursorPos(2, 3 * i - 3)
            term.setBackgroundColor(colors.red)
            term.setTextColor(colors.white)
            term.write("-")

            term.setBackgroundColor(colors.gray)
            if editing[i - 1] >= 0 then
                term.write(" ")
            end

            term.write(editing[i - 1])

            term.setTextColor(colors.gray)
            term.write(string.sub(items.itemList[editing[1]][i][6], string.len(editing[i - 1]), string.len(items.itemList[editing[1]][i][6])))
            if editing[i - 1] < 0 then
                term.write(" ")
            end

            term.setBackgroundColor(colors.green)
            term.setTextColor(colors.white)
            term.write("+")
        end
    end

    if endPosX ~= 0 and endPosY ~= 0 then
        term.setCursorPos(endPosX, endPosY)
        term.setCursorBlink(true)
    else
        term.setCursorBlink(false)
    end
end

function clearRem()
    local msg = {"clear"}
    modem.transmit(playerC, mainC, msg)
end

function lineRem(y)
    local msg = {"line", y}
    modem.transmit(playerC, mainC, msg)
end

function backgroundRem(colour)
    local msg = {"background", colour}
    modem.transmit(playerC, mainC, msg)
end

function cursorRem(x, y)
    local msg = {"cursor", x, y}
    modem.transmit(playerC, mainC, msg)
end

function textRem(colour)
    local msg = {"text", colour}
    modem.transmit(playerC, mainC, msg)
end

function writeRem(text)
    local msg = {"write", text}
    modem.transmit(playerC, mainC, msg)
end

function picRem(picName, x, y)
    local msg = {"pic", picName, x, y}
    modem.transmit(playerC, mainC, msg)
end

function clearScreenRem(insert)
    backgroundRem(colours.green)
    clearRem()
    cursorRem(1, 1)
    textRem(colours.black)
    writeRem("Point of sales Mirror OS ".. vers)
    cursorRem(1, 2)
    textRem(colours.yellow)
    writeRem("Made By Mavric, Please Report Bugs")
    picRem("logo", 20, 4)
    if (insert) then
        backgroundRem(colours.green)
        cursorRem(17, 13)
        writeRem("Please insert card")
    end
end

function drawPinRem(number)
    clearScreenRem(false, false)
    picRem("logo", 20, 4)
    backgroundRem(colours.green)
    textRem(colours.lime)
    cursorRem(1, 3)
    writeRem("ID:")
    writeRem(number)
    cursorRem(20, 13)
    textRem(1)
    writeRem("PIN:")
    drawX()
end

function checkX(x, y)
    if x == 49 and y == 17 then
        return true
    else
        return false
    end
end

function drawX()
    textRem(colors.white)
    backgroundRem(colours.red)
    cursorRem(49, 17)
    writeRem("X")
end

function drawSearch(resChange)
    local toLong, results, hidden = lengthCheck(searchText, searchMaxLength, false)

    if resChange < 2 then
        typedLen = string.len(searchText)
    end
    if typedLen > 0 then
        if resChange == 0 then
            searchResults = {}
            for k, v in pairs(items.itemList) do
                if string.lower(string.sub(v[1], 1, typedLen)) ==  string.lower(searchText) then
                    table.insert(searchResults, k)
                end
            end
            searchLength = table.maxn(searchResults)
        elseif resChange == 1 then --check in old search results istead of whole list
            local recycle = searchResults
            searchResults = {}
            for _, v in pairs(recycle) do
                if string.lower(string.sub(items.itemList[v][1], 1, typedLen)) ==  string.lower(searchText) then
                    table.insert(searchResults, v)
                end
            end
            searchLength = table.maxn(searchResults)
        end

        term.setTextColor(colors.white)
        local overflowOffset = searchY - searchResultsLength
        local tempLength = searchResultsLength
        if overflowOffset < 0 then
            overflowOffset = 0
        end
        if searchLength < searchResultsLength then
            tempLength = searchLength
        end
        for k = 1 + overflowOffset, tempLength + overflowOffset, 1 do
            if k == searchY then
                term.setBackgroundColor(colors.gray)
            else
                term.setBackgroundColor(backgroundColor)
            end

            term.setCursorPos(4, 3 + (k - overflowOffset))
            local toLongAlt, resultsAlt = lengthCheck(items.itemList[searchResults[k]][1], searchMaxLength + searchMaxExtra, true)
            if toLongAlt and toLong then
                resultsAlt = string.sub(items.itemList[searchResults[k]][1], hidden + 1, string.len(items.itemList[searchResults[k]][1]))
                toLongAlt, resultsAlt = lengthCheck(resultsAlt, searchMaxLength + searchMaxExtra, true)
            end
            term.write(resultsAlt)
            if toLongAlt then
                term.setTextColor(colors.red)
                term.write(utf8.char(16))
                term.setTextColor(colors.white)
            end
        end

        if searchY < searchLength and searchLength > searchResultsLength then
            term.setBackgroundColor(backgroundColor)
            term.setTextColor(colors.red)
            term.setCursorPos(4, 4 + searchResultsLength)
            term.write(utf8.char(31))
        end
    else
        searchLength = 0
    end

    term.setBackgroundColor(backgroundColor)
    term.setTextColor(colors.yellow)
    term.setCursorPos(2, 2)
    term.write("Search and select an item")

    term.setCursorPos(2, 3)
    if toLong then
        term.write(">")
        term.setTextColor(colors.red)
        term.write(utf8.char(17))
    else
        term.write("> ")
    end

    term.setTextColor(colors.white)
    term.write(results)
end

function checkSearch(searched)
    for k, v in pairs(items.itemList) do
        if string.lower(v[1]) ==  string.lower(searched) then
            return true, k
        end
    end
    return false
end

--Start Program
--modem = peripheral.wrap(modemSide)
--modem.open(mainC)
--clearScreenRem(true)
term.setCursorBlink(true)
clearScreen()
drawMainButtons()
drawOrderList()
drawSearch(2)
--redstone.setOutput("front", false)
--redstone.setOutput("top", false)

while true do
    local event = {os.pullEvent()}
    --printError(items.itemList[1][5][2])
    --print(event[1])
    if event[1] == "terminate" then
        --redstone.setOutput("front", true)
        return
    elseif event[1] == "char" then
        if mode == 0 then
            searchY = 0
            searchText = searchText.. event[2]
            clearScreen()
            drawMainButtons()
            drawOrderList()
            if typedLen > 0 then
                drawSearch(1)--Adding letters cant widen scope
            else
                drawSearch(0)
            end
        elseif mode == 1 then
            --Make it modular with list
            if tonumber(event[2]) and editing[2][2] then
                if string.len(editing[2][1]) < string.len(items.itemList[editing[1]][3][6]) then
                    editing[2][1] = editing[2][1].. event[2]
                    if string.len(editing[2][1]) == string.len(items.itemList[editing[1]][3][6]) then
                        editing[2][2] = false
                    end
                end
                clearScreen()
                drawMainButtons()
                drawOrderList()
                drawConfig()
            end
        end
    elseif event[1] == "key" then
        if mode == 0 then
            --print(event[2])
            if event[2] == 259 then
                --print("backspace")
                searchText = string.sub(searchText, 1, string.len(searchText) - 1)
                searchY = 0
                clearScreen()
                drawMainButtons()
                drawOrderList()
                drawSearch(0)
            elseif event[2] == 257 or event[2] == 335 then
                if typedLen > 0 then
                    local success, searchIndex = checkSearch(searchText)
                    if success then
                        mode = 1
                        --editing = results
                        editing[1] = searchIndex
                        for i = 3, table.maxn(items.itemList[searchIndex]) do
                            if items.itemList[searchIndex][i][1] == 0 then
                                editing[i - 1] = {items.itemList[searchIndex][i][2], false}
                            elseif items.itemList[searchIndex][i][1] > 0 and items.itemList[searchIndex][i][1] < 4 then
                                editing[i - 1] = items.itemList[searchIndex][i][2]
                            end
                        end
                        term.setCursorBlink(false)
                        clearScreen()
                        drawMainButtons()
                        drawOrderList()
                        drawConfig()
                    end
                end
                --print("enter")
            elseif event[2] == 258 then
                if searchY > 0 then
                    searchText = items.itemList[searchResults[searchY]][1]
                    searchY = 0
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawSearch(1)--must be in searchResults
                end
                --print("tab")
            elseif event[2] == 265 then
                if searchY > 1 then
                    searchY = searchY - 1
                else
                    searchY = searchLength
                end
                clearScreen()
                drawMainButtons()
                drawOrderList()
                drawSearch(2)
                --print("up arrow")
            elseif event[2] == 264 then
                if searchY < searchLength then
                    searchY = searchY + 1
                else
                    searchY = 1
                end
                clearScreen()
                drawMainButtons()
                drawOrderList()
                drawSearch(2)
                --print("down arrow")
            end
        elseif mode == 1 then
            if event[2] == 259  then
                --print("backspace")
                if editing[2][2] then
                    editing[2][1] = string.sub(editing[2][1], 1, string.len(editing[2][1]) - 1)
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawConfig()
                else
                    editing = {}
                    mode = 0
                    term.setCursorBlink(true)
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawSearch(0)
                end
            elseif event[2] == 257 or event[2] == 335 then
                if editing[2][2] then
                    editing[2][2] = false
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawConfig()
                else
                    --Make bit more dynamic
                    if editing[2][1] ~= "" then --prevent nil error with tonumber
                        if tonumber(editing[2][1]) ~= 0 then --Cant input 0 quantity
                            table.insert(order, editing)
                            editing = {}
                            mode = 0
                            term.setCursorBlink(true)
                            searchText = ""
                            searchY = 0
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawSearch(0)
                        end
                    end
                end
            end
        end
    elseif event[1] == "mouse_click" then
        if event[3] == 1 and event[4] == 1 then
            --Robbery button
            --redstone.setOutput("top", true)
            --redstone.setOutput("front", true)
        end

        for k, v in pairs(order) do
            if event[4] == 2 * k then
                if event[3] == 28 then
                    mode = 1
                    editing = v
                    table.remove(order, k)
                    term.setCursorBlink(false)
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawConfig()
                    --printError("Edit: ".. v[1])
                elseif event[3] == 50 then
                    table.remove(order, k)
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawSearch(2)
                end
            end
        end

        for _, v in pairs(mainButtons) do
            if event[3] >= v[2] and event[3] < (v[2] + string.len(v[1]) + 2) and event[4] >= v[3] and event[4] < (v[3] + 3) then
                if v[1] == "Clear" and table.maxn(order) > 0 then
                    order = {}
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawSearch(2)
                elseif v[1] == "Pay" and table.maxn(order) > 0 then
                    --printError("Payed: ".. total)
                end
                --printError("Pressed: ".. v[1])
            end
        end

        if mode == 1 then
            for i = 3, table.maxn(items.itemList[editing[1]]) do
                --needs testing
                if items.itemList[editing[1]][i][1] == 0 then
                    if event[4] == (3 * i - 3) and event[3] == (string.len(items.itemList[editing[1]][i][3]) + string.len(items.itemList[editing[1]][i][6]) + 2) then
                        editing[i - 1][2] = true
                        editing[i - 1][1] = ""
                    else
                        editing[i - 1][2] = false
                    end
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawConfig()
                elseif items.itemList[editing[1]][i][1] == 1 and event[4] == (3 * i - 3) then
                    local length2 = string.len(items.itemList[editing[1]][i][3]) --Use in so many times
                    if event[3] > (length2 + 1) and event[3] < (length2 + 7) then 
                        editing[i - 1] = (event[3] + length2 - 5)
                        clearScreen()
                        drawMainButtons()
                        drawOrderList()
                        drawConfig()
                    end
                elseif items.itemList[editing[1]][i][1] == 2 and event[4] == (3 * i - 3) and event[3] > 3 and event[3] < 7 then
                    editing[i - 1] = not editing[i - 1]
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawConfig()
                elseif items.itemList[editing[1]][i][1] == 3 and event[4] == (3 * i - 3) then
                    if event[3] == 2 and editing[i - 1] > items.itemList[editing[1]][i][5] then
                        editing[i - 1] = editing[i - 1] - 1
                        clearScreen()
                        drawMainButtons()
                        drawOrderList()
                        drawConfig()
                    elseif event[3] == (string.len(items.itemList[editing[1]][i][6]) + 5) and editing[i - 1] < items.itemList[editing[1]][i][6] then
                        editing[i - 1] = editing[i - 1] + 1
                        clearScreen()
                        drawMainButtons()
                        drawOrderList()
                        drawConfig()
                    end
                end
            end
        end
    end
end

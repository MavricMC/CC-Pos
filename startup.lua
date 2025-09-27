--Point of sales system--

local vers = "0.1T"

--[[Todo
-Fix term.clearLine() there is no Y pos argument, it clears the current row selected with term.setCursorPos()
-Add price indicator when purchasing --Done
-Add timeout to transaction pending --Done, add to other bank software
-Add history page
-Add manager approval logic
-Make comments way better
-Make way for config to affect price
-Add negative support for config D
-Make config D max and min check better (Check value not just length)
-Size config using larger of minimum and maximum
-Record all login and log-out attempts
-Make items list a centralized server
-Make items live updatable
-Add current wharehouse stock information
-update utf8.char() with "\134" but correct numbers
-Make backspace when editing new exit when quantity is nil or zero as doesnt leave 0 quantity item in list (Because editing new)
]]

--Made by Mavric--
--How to setup is on my youtube channel--
--Code on https://github.com/MavricMC/CC-Pos--

--os.pullEvent = os.pullEventRaw --Prevent program termination
os.loadAPI("/pos/items.lua") --Long list of products is stored seperate
os.loadAPI("/pos/users.lua") --List of users is stored seperate
os.loadAPI("/pos/json.lua")

--Settings--
local atm = "pos_1"
local bankSide = "modem_0"
local drive = "drive_0"
local server = 0 --Server id
local modemSide = "bottom"
local mainC = 15
local playerC = 20
local backgroundColor = colors.black
local salesTax = 0.15 --0.15 = 15%
local addTax = false --false = removes sales tax from price of the item to calculate subtotal, true = adds the sales tax onto the price of the item to get total (USA)
local approvalPrice = 1000 --If the total price is greater it requires manager approval
local approvalQuantity = 100 --If the total quantity is greater it requires manager approval
local approvalFree = true --If manager approval is required when the total price is zero
local searchResultsLength = 10
local searchMaxLength = 18
local searchMaxExtra = 4 --Extra max length added to suggestions vs search
local mainButtons = {
    {"Exit", 2, 16, colors.gray, colors.white}, --Text, lop left x and y, background color, text color/
    {"History", 9, 16, colors.lightBlue, colors.white},
    {"Clear", 19, 16, colors.red, colors.white},
    {"Pay", 46, 16, colors.green, colors.white}
}
local configPos = { --Positions of each config
    {2, 5}, --x, y
    {15, 5},
    {2, 8},
    {15, 8},
    {2, 11},
    {15, 11}
}

--Program wide variables--
local searchText = ""
local searchY = 0
local searchLength = 0
local typedLen = 0
local searchResults = {} --Indexs for items in main list
local order = {}
local editing = {} --Index for the item in the main list and stored modified values
local mode = 0 --0, login, 1 search, 2 modify item, 3 order history, 4 payment
local lastMode = 1 --Stores whether the user was editing or searching when they clicked history or payment
local total = 0 --Total calculated price
local id = 0 --Id of card inserted
local pin = "" --Current entered pin
local isPin = false --In pin entering stage
local username = ""
local password = ""
local isPassword = false
local maxLength = 15 --Max length of both username and password
local currentUser = 0 --Index of current user. Lua indexes start at 1 so 0 is no user
local orderY = 1 --Which order item is displayed at the top

--Bank functions--
function balance(account, ATM, pin)
    local msg = {"bal", account, ATM, pin}
    rednet.send(server, msg, "banking")
    local send, mes, pro = rednet.receive("banking")
    if not send then
        return false, "timeout"
    else
        if mes[1] == "balR" then
            return mes[2], mes[3]
        end
    end
    return false, "oof"
end

function deposit(account, amount, ATM, pin)
    local msg = {"dep", account, amount, ATM, pin}
    rednet.send(server, msg, "banking")
    local send, mes, pro = rednet.receive("banking")
    if not send then
        return false, "timeout"
    else
        if mes[1] == "depR" then
            return mes[2], mes[3]
        end
    end
    return false, "oof"
end

function withdraw(account, amount, ATM, pin)
    local msg = {"wit", account, amount, ATM, pin}
    rednet.send(server, msg, "banking")
    local send, mes, pro = rednet.receive("banking", 5)
    if not send then
        return false, "timeout"
    else
        if mes[1] == "witR" then
            return mes[2], mes[3], amount
        end
    end
    return false, "oof"
end

function transfer(account, account2, amount, ATM, pin)
    local msg = {"tra", account, account2, amount, ATM, pin}
    rednet.send(server, msg, "banking")
    local send, mes, pro = rednet.receive("banking")
    if not send then
        return false, "timeout"
    else
        if mes[1] == "traR" then
            return mes[2], mes[3]
        end
    end
    return false, "oof"
end

--Other functions--
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

function writeCenter(text, y)
    term.setCursorPos(math.floor(26 - (string.len(text) / 2)), y)
    term.write(text)
end

function clearScreen()
    term.setBackgroundColor(backgroundColor)
    term.setTextColor(colors.yellow)
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Point Of Sales System ".. vers)
    term.setCursorPos(1, 19)
    term.setTextColor(colors.lightGray)
    term.write("Made By Mavric, Please Report Bugs")
    if currentUser ~= 0 then
        term.setTextColor(colors.white)
        term.setCursorPos(50 - string.len(users.userList[currentUser][1]), 1)
        term.write(users.userList[currentUser][1])
        term.setCursorPos(50, 1)
        term.setTextColor(colors.yellow)
        term.write(utf8.char(17).. utf8.char(2))
    end
end

function drawX()
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.setCursorPos(49, 17)
    term.write("X")
end

function drawPayment(x)
    clearScreen()
    local pic = paintutils.loadImage("/pos/MPNLogo.nfp")
    paintutils.drawImage(pic, 18, 3)
    if (x) then
        drawX()
    end
end

function drawLogin()
    clearScreen()
    local pic = paintutils.loadImage("/pos/MPNLogo.nfp")
    paintutils.drawImage(pic, 18, 3)
    term.setBackgroundColor(backgroundColor)
    term.setTextColor(colors.white)
    term.setCursorPos(22, 13)
    term.write("Username:")
    term.setCursorPos(22, 16)
    term.write("Password:")
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.setCursorPos(22, 14)
    term.write("         ")
    term.setCursorPos(22, 17)
    term.write("         ")
    drawX()
    term.setCursorBlink(true)
    term.setCursorPos(22, 14)
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
    for i = orderY, table.maxn(order) do
        local k = i - orderY + 1 --Used a lot
        local price = ""
        if items.itemList[order[i][1]][3] then --Quantity is editable so is first config
            if order[i][4][1] == "" then
                price = string.format("$%d", 0)
            else
                if addTax then
                    price = string.format("$%d", items.itemList[order[i][1]][2] * order[i][4][1] * (1 + salesTax))
                    total = items.itemList[order[i][1]][2] * order[i][4][1] * (1 + salesTax) + total
                else
                    price = string.format("$%d", items.itemList[order[i][1]][2] * order[i][4][1])
                    total = items.itemList[order[i][1]][2] * order[i][4][1] + total
                end
            end
        else --Quantity is not editable so is 1
            if addTax then
                price = string.format("$%d", items.itemList[order[i][1]][2] * (1 + salesTax))
                total = items.itemList[order[i][1]][2] * (1 + salesTax) + total
            else
                price = string.format("$%d", items.itemList[order[i][1]][2])
                total = items.itemList[order[i][1]][2] + total
            end
        end

        if k < 8 then
            term.setBackgroundColor(colors.blue)
            term.setCursorPos(28, 2 * k)
            term.write(utf8.char(7))

            term.setBackgroundColor(backgroundColor)
            local toLong, results = lengthCheck(items.itemList[order[i][1]][1], 20, true)
            term.write(results)
            if toLong then
                term.setTextColor(colors.red)
                term.write(utf8.char(16))
            end
            term.setTextColor(colors.yellow)
            term.setCursorPos(29, 2 * k + 1)
            term.write("#:")
            term.setTextColor(colors.white)
            if items.itemList[order[i][1]][3] then --Quantity is editable so is first config
                term.write(order[i][4][1])
            else --Quantity is not editable so is 1
                term.write(1)
            end
            
            term.setTextColor(colors.yellow)
            term.setCursorPos(49 - string.len(price), 2 * k + 1)
            term.write(price)
            
            term.setBackgroundColor(colors.red)
            term.setTextColor(colors.white)
            term.setCursorPos(50, 2 * k)
            term.write("X")
        end
    end

    local subtotal = string.format("$%d", total * (1 - salesTax))
    local tax = string.format("$%d", total * salesTax)
    local totalPrice = string.format("$%d", total)
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

    term.setTextColor(colors.yellow)
    term.setCursorPos(27, 14)
    term.write("-")
    term.setTextColor(colors.white)
    term.setCursorPos(27, 13)
    term.write(utf8.char(30))
    term.setCursorPos(27, 15)
    term.write(utf8.char(31))
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

    local price = ""
    if addTax then
        price = string.format("$%d", items.itemList[editing[1]][2] * (1 + salesTax))
    else
        price = string.format("$%d", (items.itemList[editing[1]][2]))
    end

    term.setTextColor(colors.yellow)
    term.setCursorPos(2, 3)
    term.write("Price:")
    term.setTextColor(colors.white)
    term.write(price)

    local totalPrice = ""
    if items.itemList[editing[1]][3] then --Quantity is editable so is first config
        if editing[4][1] == "" then
            totalPrice = string.format("$%d", 0)
        else
            if addTax then
                totalPrice = string.format("$%d", items.itemList[editing[1]][2] * editing[4][1] * (1 + salesTax))
            else
                totalPrice = string.format("$%d", items.itemList[editing[1]][2] * editing[4][1])
            end
        end
    else --Quantity is not editable so is 1
        if addTax then
            totalPrice = string.format("$%d", items.itemList[editing[1]][2] * (1 + salesTax))
        else
            totalPrice = string.format("$%d", items.itemList[editing[1]][2])
        end  
    end
    
    term.setTextColor(colors.yellow)
    term.setCursorPos(2, 14)
    term.write("Total:")
    term.setTextColor(colors.white)
    term.write(totalPrice)

    local endPosX = 0
    local endPosY = 0
    for i = 4, table.maxn(items.itemList[editing[1]]) do
        if items.itemList[editing[1]][i][1] == 0 then
            term.setBackgroundColor(backgroundColor)
            term.setTextColor(colors.yellow)
            term.setCursorPos(configPos[i - 3][1], configPos[i - 3][2])
            term.write(items.itemList[editing[1]][i][4])

            term.setCursorPos(configPos[i - 3][1], configPos[i - 3][2] + 1)
            term.write(items.itemList[editing[1]][i][3])

            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.white)
            if editing[i][2] then
                endPosX = (string.len(items.itemList[editing[1]][i][3]) + string.len(editing[i][1]) + configPos[i - 3][1])
                endPosY = (configPos[i - 3][2] + 1)
            end
            term.write(editing[i][1])
            term.setTextColor(colors.gray)
            term.write(string.sub(items.itemList[editing[1]][i][6], string.len(editing[i][1]) + 1, string.len(items.itemList[editing[1]][i][6])))

            term.setBackgroundColor(colors.blue)
            term.setTextColor(colors.white)
            term.write(utf8.char(7))
        elseif items.itemList[editing[1]][i][1] == 1 then
            term.setBackgroundColor(backgroundColor)
            term.setTextColor(colors.yellow)
            term.setCursorPos(configPos[i - 3][1], configPos[i - 3][2])
            term.write(items.itemList[editing[1]][i][4])
            term.setTextColor(colors.white)
            term.write(items.itemList[editing[1]][i][editing[i] + 4])

            term.setTextColor(colors.yellow)
            term.setCursorPos(configPos[i - 3][1], configPos[i - 3][2] + 1)
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
            term.setCursorPos(configPos[i - 3][1], configPos[i - 3][2])
            term.write(items.itemList[editing[1]][i][3])

            term.setCursorPos(configPos[i - 3][1], configPos[i - 3][2] + 1)
            term.setTextColor(colors.white)
            if editing[i] then
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
            term.setCursorPos(configPos[i - 3][1], configPos[i - 3][2])
            term.write(items.itemList[editing[1]][i][3])

            term.setBackgroundColor(colors.red)
            term.setTextColor(colors.white)
            term.setCursorPos(configPos[i - 3][1], configPos[i - 3][2] + 1)
            term.write("-")

            term.setBackgroundColor(colors.gray)
            if editing[i] >= 0 then
                term.write(" ")
            end

            term.write(editing[i])

            term.setTextColor(colors.gray)
            term.write(string.sub(items.itemList[editing[1]][i][6], string.len(editing[i]), string.len(items.itemList[editing[1]][i][6])))
            if editing[i] < 0 then
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

function backgroundRem(color)
    local msg = {"background", color}
    modem.transmit(playerC, mainC, msg)
end

function cursorRem(x, y)
    local msg = {"cursor", x, y}
    modem.transmit(playerC, mainC, msg)
end

function textRem(color)
    local msg = {"text", color}
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

function writeCenterRem(text, y)
    cursorRem(math.floor(26 - (string.len(text) / 2)), y)
    writeRem(text)
end

function drawXRem()
    backgroundRem(colors.red)
    textRem(colors.white)
    cursorRem(49, 17)
    writeRem("X")
end

function clearScreenRem(insert, x)
    backgroundRem(backgroundColor)
    textRem(colors.yellow)
    clearRem()
    cursorRem(1, 1)
    writeRem("MPN Payment Terminal")
    cursorRem(1, 19)
    textRem(colors.lightGray)
    writeRem("Made By Mavric, Please Report Bugs")
    picRem("logo", 18, 3)
    if (insert) then
        backgroundRem(backgroundColor)
        textRem(colors.white)
        writeCenterRem("Please insert card", 13) 
    end
    if (x) then
        drawXRem()
    end
end

function drawPinRem(ID)
    clearScreenRem(false, true)
    backgroundRem(backgroundColor)
    textRem(colors.white)
    cursorRem(1, 2)
    writeRem("ID:")
    writeRem(ID)
    cursorRem(1, 3)
    writeRem("$")
    writeRem(total)
    cursorRem(20, 13)
    textRem(1)
    writeRem("PIN:")
end

function checkX(x, y)
    if x == 49 and y == 17 then
        return true
    else
        return false
    end
end

function pinpad(key)
    if (key == ".") then
        return true, 10
    else
        if (tonumber(key)) then
            if tonumber(key) == 259 then
                return true, 10
            elseif (tonumber(key) == 257 or tonumber(key) == 335) then
                return true, 11
            elseif tonumber(key) >= 0 and tonumber(key) <= 9 then
                return true, tonumber(key)
            end
        end
    end
    return false
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

function checkLogin(name, pass)
    for k, v in pairs(users.userList) do
        if string.lower(v[1]) ==  string.lower(name) and v[2] == pass then --username is not case sensitive but password is
            return true, k
        end
    end
    return false
end

--Start Program
modem = peripheral.wrap(modemSide)
modem.open(mainC)
rednet.open(bankSide)
clearScreenRem(false, false)
drawLogin()
--redstone.setOutput("front", false)
--redstone.setOutput("top", false)

while true do
    local event = {os.pullEvent()}
    if event[1] == "terminate" then
        --redstone.setOutput("front", true)
        return
    elseif event[1] == "char" then
        if mode == 0 then
            if isPassword then
                if string.len(password) < (maxLength - 1) then
                    password = password.. event[2]
                    local toLong, results = lengthCheck(password, 8, false)
                    if toLong then
                        term.setBackgroundColor(backgroundColor)
                        term.clearLine(17)
                        drawX()
                        term.setBackgroundColor(backgroundColor)
                        term.setTextColor(colors.red)
                        term.setCursorPos(21, 17)
                        term.write(utf8.char(17))
                        term.setBackgroundColor(colors.gray)
                        term.setTextColor(colors.white)
                        term.write("******** ")
                        term.setCursorPos(30, 17)
                    else
                        term.setBackgroundColor(colors.gray)
                        term.setTextColor(colors.white)
                        term.setCursorPos(21 + string.len(password), 17)
                        term.write("*")
                    end
                elseif string.len(password) < maxLength then
                    password = password.. event[2]
                    local toLong = lengthCheck(password, 8, false)
                    term.setBackgroundColor(colors.gray)
                    term.setTextColor(colors.white)
                    if toLong then
                        term.setCursorPos(30, 17)
                    else
                        term.setCursorPos(21 + string.len(password), 17)
                    end  
                    term.write("*")
                    term.setCursorBlink(false)
                end
            else
                if string.len(username) < (maxLength - 1) then
                    username = username.. event[2]
                    local toLong, results = lengthCheck(username, 8, false)
                    if toLong then
                        term.setBackgroundColor(backgroundColor)
                        term.clearLine(14)
                        term.setTextColor(colors.red)
                        term.setCursorPos(21, 14)
                        term.write(utf8.char(17))
                        term.setBackgroundColor(colors.gray)
                        term.setTextColor(colors.white)
                        term.write(results.. " ")
                        term.setCursorPos(30, 14)
                    else
                        term.setBackgroundColor(colors.gray)
                        term.setTextColor(colors.white)
                        term.setCursorPos(21 + string.len(username), 14)
                        term.write(event[2])
                    end
                elseif string.len(username) < maxLength then
                    username = username.. event[2]
                    local toLong = lengthCheck(username, 8, false)
                    term.setBackgroundColor(colors.gray)
                    term.setTextColor(colors.white)
                    if toLong then
                        term.setCursorPos(30, 14)
                    else
                        term.setCursorPos(21 + string.len(username), 14)
                    end  
                    term.write(event[2])
                    term.setCursorBlink(false)
                end
            end
        elseif mode == 1 then
            searchY = 0
            searchText = searchText.. event[2]
            clearScreen()
            drawMainButtons()
            drawOrderList()
            if typedLen > 0 then
                drawSearch(1) --Adding letters cant widen the scope of the search
            else
                drawSearch(0)
            end
        elseif mode == 2 then
            if tonumber(event[2]) then
                for i = 4, table.maxn(items.itemList[editing[1]]) do
                    if items.itemList[editing[1]][i][1] == 0 then
                        if editing[i][2] then
                            if string.len(editing[i][1]) < string.len(items.itemList[editing[1]][i][6]) then
                                editing[i][1] = editing[i][1].. event[2]
                                if string.len(editing[i][1]) == string.len(items.itemList[editing[1]][i][6]) then
                                    editing[i][2] = false
                                end
                            end
                        end
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
            if event[2] == 259 then --backspace
                if isPassword then
                    if string.len(password) > 0 then
                        term.setCursorBlink(true)
                        password = string.sub(password, 1, string.len(password) - 1)
                        local toLong, results = lengthCheck(password, 8, false)
                        term.setBackgroundColor(backgroundColor)
                        term.clearLine(17)
                        drawX()
                        if toLong then
                            term.setBackgroundColor(backgroundColor)
                            term.setTextColor(colors.red)
                            term.setCursorPos(21, 17)
                            term.write(utf8.char(17))
                            term.setBackgroundColor(colors.gray)
                            term.setTextColor(colors.white)
                            term.write("******** ")
                            term.setCursorPos(30, 17)
                        else
                            term.setBackgroundColor(colors.gray)
                            term.setTextColor(colors.white)
                            term.setCursorPos(22, 17)
                            term.write(string.sub("********         ", 9 - string.len(password), 17 - string.len(password)))
                            term.setCursorPos(22 + string.len(password), 17)
                        end
                    end
                else
                    if string.len(username) > 0 then
                        term.setCursorBlink(true)
                        username = string.sub(username, 1, string.len(username) - 1)
                        local toLong, results = lengthCheck(username, 8, false)
                        term.setBackgroundColor(backgroundColor)
                        term.clearLine(14)
                        if toLong then
                            term.setTextColor(colors.red)
                            term.setCursorPos(21, 14)
                            term.write(utf8.char(17))
                            term.setBackgroundColor(colors.gray)
                            term.setTextColor(colors.white)
                            term.write(results.. " ")
                            term.setCursorPos(30, 14)
                        else
                            term.setBackgroundColor(colors.gray)
                            term.setTextColor(colors.white)
                            term.setCursorPos(22, 14)
                            term.write(username.. string.sub("         ", string.len(username) + 1, 9))
                            term.setCursorPos(22 + string.len(username), 14)
                        end
                    end
                end
            elseif event[2] == 257 or event[2] == 335 then --enter
                if isPassword then
                    if string.len(password) > 0 then
                        local valid, userId = checkLogin(username, password)
                        username = ""
                        password = ""
                        isPassword = false
                        if valid then
                            term.setCursorBlink(true)
                            currentUser = userId
                            mode = 1
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawSearch(2)
                        else
                            drawLogin()
                        end
                    end
                else
                    if string.len(username) > 0 then
                        isPassword = true
                        term.setCursorBlink(true)
                        term.setCursorPos(22, 17)
                    end
                end
            end
        elseif mode == 1 then
            if event[2] == 259 then --backspace
                searchText = string.sub(searchText, 1, string.len(searchText) - 1)
                searchY = 0
                clearScreen()
                drawMainButtons()
                drawOrderList()
                drawSearch(0)
            elseif event[2] == 257 or event[2] == 335 then --enter
                if typedLen > 0 then
                    local success, searchIndex = checkSearch(searchText)
                    if success then
                        mode = 2
                        editing[1] = searchIndex
                        editing[2] = true --Singify that user is editing item not yet in order
                        editing[3] = {} --Unused
                        for i = 4, table.maxn(items.itemList[searchIndex]) do
                            if items.itemList[searchIndex][i][1] == 0 then
                                editing[i] = {items.itemList[searchIndex][i][2], false}
                            elseif items.itemList[searchIndex][i][1] > 0 and items.itemList[searchIndex][i][1] < 4 then
                                editing[i] = items.itemList[searchIndex][i][2]
                            end
                        end
                        term.setCursorBlink(false)
                        clearScreen()
                        drawMainButtons()
                        drawOrderList()
                        drawConfig()
                    end
                end
            elseif event[2] == 258 then --tab
                if searchY > 0 then
                    searchText = items.itemList[searchResults[searchY]][1]
                    searchY = 0
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawSearch(1)--must be in search results
                end
            elseif event[2] == 265 then --up arrow
                if searchY > 1 then
                    searchY = searchY - 1
                else
                    searchY = searchLength
                end
                clearScreen()
                drawMainButtons()
                drawOrderList()
                drawSearch(2)
            elseif event[2] == 264 then --down arrow
                if searchY < searchLength then
                    searchY = searchY + 1
                else
                    searchY = 1
                end
                clearScreen()
                drawMainButtons()
                drawOrderList()
                drawSearch(2)
            end
        elseif mode == 2 then
            if event[2] == 259  then --backspace
                local anyEdits = false
                for i = 4, table.maxn(items.itemList[editing[1]]) do
                    if items.itemList[editing[1]][i][1] == 0 then
                        if editing[i][2] then
                            anyEdits = true
                            editing[i][1] = string.sub(editing[i][1], 1, string.len(editing[i][1]) - 1)
                        end
                    end
                end
                if anyEdits then
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawConfig()
                else
                    if items.itemList[editing[1]][3] then
                        if editing[4][1] ~= "" then --prevent nil error with tonumber
                            if tonumber(editing[4][1]) ~= 0 then --Cant input 0 quantity
                                editing = {}
                                mode = 1
                                term.setCursorBlink(true)
                                clearScreen()
                                drawMainButtons()
                                drawOrderList()
                                drawSearch(0)
                            end
                        end
                    else
                        editing = {}
                        mode = 1
                        term.setCursorBlink(true)
                        clearScreen()
                        drawMainButtons()
                        drawOrderList()
                        drawSearch(0)
                    end
                end
            elseif event[2] == 257 or event[2] == 335 then --enter
                local anyEdits = false
                for i = 4, table.maxn(items.itemList[editing[1]]) do
                    if items.itemList[editing[1]][i][1] == 0 then
                        if editing[i][2] then
                            anyEdits = true
                            editing[i][2] = false
                        end
                    end
                end
                if anyEdits then
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawConfig()
                else
                    if items.itemList[editing[1]][3] then
                        if editing[4][1] ~= "" then --prevent nil error with tonumber
                            if tonumber(editing[4][1]) ~= 0 then --Cant input 0 quantity
                                if editing[2] then --New input
                                    table.insert(order, editing)
                                end
                                editing = {}
                                mode = 1
                                term.setCursorBlink(true)
                                searchText = ""
                                searchY = 0
                                clearScreen()
                                drawMainButtons()
                                drawOrderList()
                                drawSearch(0)
                            end
                        end
                    else
                        if editing[2] then --New input
                            table.insert(order, editing)
                        end
                        editing = {}
                        mode = 1
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
    elseif event[1] == "mouse_click" then
        if event[3] == 1 and event[4] == 1 then
            --Robbery button
            --redstone.setOutput("top", true)
            --redstone.setOutput("front", true)
        end
        if mode == 0 then
            if (checkX(event[3], event[4])) then
                if string.len(username) > 0 or string.len(password) > 0 then
                    username = ""
                    password = ""
                    isPassword = false
                    drawLogin()
                end
            end
        elseif mode == 3 then
            if (checkX(event[3], event[4])) then
                clearScreenRem(false, false)
                drawPayment(false)
                local payText = string.format("Transaction cancelled: $%d", total)
                backgroundRem(backgroundColor)
                textRem(colors.white)
                writeCenterRem(payText, 13)
                term.setBackgroundColor(backgroundColor)
                term.setTextColor(colors.white)
                writeCenter(payText, 13)
                mode = lastMode
                sleep(3)
                clearScreenRem(false, false)
                term.setCursorBlink(true)
                if mode == 1 then
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawSearch(2)
                else
                    clearScreen()
                    drawMainButtons()
                    drawOrderList()
                    drawConfig()
                end
            end
        else
            if mode == 1 or mode == 2 then
                if event[3] == 27 and event[4] == 13 then --Order up
                    if orderY > 1 then
                        orderY = orderY - 1
                        if mode == 1 then
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawSearch(2)
                        elseif mode == 2 then
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawConfig()
                        end
                    end
                elseif event[3] == 27 and event[4] == 15 then --Order down
                    if (table.maxn(order) - orderY) > 6 then
                        orderY = orderY + 1
                        if mode == 1 then
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawSearch(2)
                        elseif mode == 2 then
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawConfig()
                        end
                    end
                end

                for k, v in pairs(order) do
                    if event[4] == 2 * k then
                        if event[3] == 28 then
                            mode = 2
                            editing = v
                            editing[2] = false --Signify that the user is editing an item already in order
                            term.setCursorBlink(false)
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawConfig()
                        elseif event[3] == 50 then
                            if table.maxn(order) > 7 then
                                if (orderY + 6) == table.maxn(order) then
                                    orderY = orderY - 1
                                end
                            end
                            if editing == order[k] then --User deleted item currently being edited
                                table.remove(order, k)
                                editing = {}
                                mode = 1
                                term.setCursorBlink(true)
                                clearScreen()
                                drawMainButtons()
                                drawOrderList()
                                drawSearch(0)
                            else
                                table.remove(order, k)
                                clearScreen()
                                drawMainButtons()
                                drawOrderList()
                                drawSearch(2)
                            end
                        end
                    end
                end
            end

            for _, v in pairs(mainButtons) do
                if event[3] >= v[2] and event[3] < (v[2] + string.len(v[1]) + 2) and event[4] >= v[3] and event[4] < (v[3] + 3) then
                    if v[1] == "Exit" then
                        if mode == 1 or mode == 2 then --logout
                            mode = 0
                            currentUser = 0
                            order = {}
                            orderY = 1
                            editing = {}
                            searchText = ""
                            searchY = 0
                            username = ""
                            password = ""
                            isPassword = false
                            drawLogin()
                        elseif mode == 3 then --exit history
                            --[[mode = lastMode
                            if mode == 1 then
                                clearScreen()
                                drawMainButtons()
                                drawOrderList()
                                drawSearch(2)
                            else
                                clearScreen()
                                drawMainButtons()
                                drawOrderList()
                                drawConfig()
                            end]]
                            printError("Exit history")
                        end
                    elseif v[1] == "History" then
                        if mode == 1 or mode == 2 then
                            --lastMode = mode
                            --mode = 3
                            printError("History not implemented")
                        end
                    elseif v[1] == "Clear" and table.maxn(order) > 0 then
                        if mode == 1 or mode == 2 then
                            order = {}
                            orderY = 1
                            editing = {}
                            searchText = ""
                            searchY = 0
                            mode = 1
                            term.setCursorBlink(true)
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawSearch(0)
                        elseif mode == 3 then
                            printError("Clear history not implemented")
                        end
                    elseif v[1] == "Pay" and table.maxn(order) > 0 then
                        if mode ==1 or mode == 2 then
                            local pay = true
                            if mode == 2 and not editing[2] and items.itemList[editing[1]][3] then --Currently editing item in list with editable quantity. Cant have 0 or nil quantity with set quantity and items not yet in list arent part of price
                                if editing[4][1] ~= "" then --prevent nil error with tonumber
                                    if tonumber(editing[4][1]) == 0 then --Cant pay while editing has 0 quantity
                                        pay = false
                                    end
                                else
                                    pay = false
                                end
                            end

                            if pay then
                                lastMode = mode
                                mode = 3
                                term.setCursorBlink(false)
                                drawPayment(true)
                                clearScreenRem(true, true)
                                local payText = string.format("Payment: $%d", total)
                                backgroundRem(backgroundColor)
                                textRem(colors.white)
                                writeCenterRem(payText, 15)
                                id = 0
                                pin = ""
                                isPin = false
                            end
                        end
                    end
                end
            end

            if mode == 2 then
                for i = 4, table.maxn(items.itemList[editing[1]]) do
                    if items.itemList[editing[1]][i][1] == 0 then
                        if event[4] == (configPos[i - 3][2] + 1) and event[3] == (string.len(items.itemList[editing[1]][i][3]) + string.len(items.itemList[editing[1]][i][6]) + configPos[i - 3][1]) then
                            editing[i][2] = true
                            editing[i][1] = ""
                        else
                            editing[i][2] = false
                        end
                        clearScreen()
                        drawMainButtons()
                        drawOrderList()
                        drawConfig()
                    elseif items.itemList[editing[1]][i][1] == 1 and event[4] == (configPos[i - 3][2] + 1) then
                        local length2 = string.len(items.itemList[editing[1]][i][3]) --Used so many times
                        if event[3] > (length2 + configPos[i - 3][1] - 1) and event[3] < (length2 + configPos[i - 3][1] + 5) then
                            editing[i] = (event[3] - length2 - configPos[i - 3][1] + 1)
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawConfig()
                        end
                    elseif items.itemList[editing[1]][i][1] == 2 and event[4] == (configPos[i - 3][2] + 1) and event[3] > (configPos[i - 3][1] - 1) and event[3] < (configPos[i - 3][1] + 3) then
                        editing[i] = not editing[i]
                        clearScreen()
                        drawMainButtons()
                        drawOrderList()
                        drawConfig()
                    elseif items.itemList[editing[1]][i][1] == 3 and event[4] == (configPos[i - 3][2] + 1) then
                        if event[3] == configPos[i - 3][1] and editing[i] > items.itemList[editing[1]][i][5] then
                            editing[i] = editing[i] - 1
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawConfig()
                        elseif event[3] == (string.len(items.itemList[editing[1]][i][6]) + configPos[i - 3][1] + 3) and editing[i] < items.itemList[editing[1]][i][6] then
                            editing[i] = editing[i] + 1
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawConfig()
                        end
                    end
                end
            end
        end
    elseif event[1] == "disk" then
        if mode == 3 then
            if not isPin then
                local tempId = disk.getID(drive)
                drawPayment(true)
                term.setBackgroundColor(backgroundColor)
                term.setTextColor(colors.white)
                if tempId ~= nil then
                    drawPinRem(id)
                    writeCenter("Disk id valid", 13)
                    id = tempId
                    isPin = true
                else
                    writeCenter("Disk id invalid", 13)
                end
            end
        end
        disk.eject(drive)
    elseif event[1] == "modem_message" then
        if mode == 3 then
            if event[5][1] == "mouse_click" then
                if (checkX(event[5][3], event[5][4])) then
                    if (isPin) then
                        clearScreenRem(true, true)
                        drawPayment(true)
                        local payText = string.format("Payment: $%d", total)
                        backgroundRem(backgroundColor)
                        textRem(colors.white)
                        writeCenterRem(payText, 15)
                        id = 0
                        pin = ""
                        isPin = false
                    else
                        clearScreenRem(false, false)
                        drawPayment(false)
                        local payText = string.format("Transaction cancelled: $%d", total)
                        backgroundRem(backgroundColor)
                        textRem(colors.white)
                        writeCenterRem(payText, 13)
                        term.setBackgroundColor(backgroundColor)
                        term.setTextColor(colors.white)
                        writeCenter(payText, 13)
                        mode = lastMode
                        sleep(3)
                        clearScreenRem(false, false)
                        term.setCursorBlink(true)
                        if mode == 1 then
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawSearch(2)
                        else
                            clearScreen()
                            drawMainButtons()
                            drawOrderList()
                            drawConfig()
                        end
                    end
                end
            elseif event[5][1] == "char" or event[5][1] == "key" then
                if (isPin) then
                    local isKey, keyNum = pinpad(event[5][2])
                    if (isKey) then
                        if keyNum == 10 then
                            if string.len(pin) > 0 then
                                pin = string.sub(pin, 1, string.len(pin) - 1)
                                backgroundRem(backgroundColor)
                                textRem(1)
                                lineRem(13)
                                cursorRem(20, 13)
                                writeRem("PIN: ".. string.sub("****", 1, string.len(pin)))
                            end
                        elseif keyNum == 11 then
                            if string.len(pin) == 5 then
                                clearScreenRem(false, false)
                                drawPayment(false)
                                local payText = string.format("Processing transaction: $%d", total)
                                backgroundRem(backgroundColor)
                                textRem(colors.white)
                                writeCenterRem(payText, 13)
                                term.setBackgroundColor(backgroundColor)
                                term.setTextColor(colors.white)
                                writeCenter(payText, 13)
                                local suc, res = withdraw(id, total, atm, pin)
                                clearScreenRem(false, false)
                                backgroundRem(backgroundColor)
                                if (suc) then
                                    drawPayment(false)
                                    payText = string.format("Transaction authorised: $%d", total)
                                    backgroundRem(backgroundColor)
                                    textRem(colors.white)
                                    writeCenterRem(payText, 13)
                                    term.setBackgroundColor(backgroundColor)
                                    term.setTextColor(colors.white)
                                    writeCenter(payText, 13)
                                    --[[local history = json.encode(order) -- Add more info like time, date, employee
                                    local hFile = fs.open(historyFile, "a")
                                    hFile.writeLine(history)
                                    hFile.close()]]
                                    mode = 1
                                    sleep(3)
                                    clearScreenRem(false, false)
                                    term.setCursorBlink(true)
                                    order = {}
                                    orderY = 1
                                    clearScreen()
                                    drawMainButtons()
                                    drawOrderList()
                                    drawSearch(2)
                                else
                                    drawPayment(false)
                                    backgroundRem(backgroundColor)
                                    textRem(colors.white)
                                    writeCenterRem("Transaction error: ".. res, 13)
                                    term.setBackgroundColor(backgroundColor)
                                    term.setTextColor(colors.white)
                                    writeCenter("Transaction error: ".. res, 13)
                                    id = 0
                                    pin = ""
                                    isPin = false
                                    sleep(3)
                                    clearScreenRem(true, true)
                                    payText = string.format("Payment: $%d", total)
                                    backgroundRem(backgroundColor)
                                    textRem(colors.white)
                                    writeCenterRem(payText, 15)
                                    drawPayment(true)
                                end
                            end
                        elseif keyNum >= 0 and keyNum <= 9 then
                            if string.len(pin) < 5 then
                                pin = pin.. keyNum
                                backgroundRem(backgroundColor)
                                textRem(1)
                                cursorRem(24 + string.len(pin), 13)
                                writeRem("*")
                            end
                        end
                    end
                end
            end
        end
    end
end

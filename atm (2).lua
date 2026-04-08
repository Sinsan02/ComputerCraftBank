-- KONFIGURASJON
local SERVER_ID = 1       -- Computer ID til bank_server
local TURTLE_ID = 2       -- Computer ID til turtle_bank
local DIAMOND_VALUE = 1000

rednet.open("back")

-- UI
local function button(x, y, w, h, text, bgColor, textColor)
    bgColor = bgColor or colors.gray
    textColor = textColor or colors.white
    paintutils.drawFilledBox(x, y, x + w, y + h, bgColor)
    term.setBackgroundColor(bgColor)
    term.setTextColor(textColor)
    term.setCursorPos(x + 2, y + 1)
    term.write(text)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

local function click()
    local _, _, x, y = os.pullEvent("mouse_click")
    return x, y
end

local function getCard()
    local drive = peripheral.find("drive")
    if not drive then return nil end
    if not drive.isDiskPresent() then return nil end
    return drive.getDiskID()
end

local function askPIN()
    term.clear()
    term.setCursorPos(1, 1)
    print("Skriv PIN:")
    return read("*")
end

-- CREATE CARD
local function createCard()
    local drive = peripheral.find("drive")
    if not drive then
        print("Ingen disk-stasjon funnet!")
        sleep(2)
        return
    end

    term.clear()
    term.setCursorPos(1, 1)
    print("Sett inn tom disk...")

    local timeout = 30
    local elapsed = 0
    while not drive.isDiskPresent() do
        sleep(0.5)
        elapsed = elapsed + 0.5
        if elapsed >= timeout then
            print("Tidsavbrudd.")
            sleep(2)
            return
        end
    end

    print("Velg PIN:")
    local pin = read("*")

    local id = drive.getDiskID()
    if not id then
        print("Kunne ikke lese disk-ID!")
        sleep(2)
        return
    end

    drive.setDiskLabel("Bankkort #" .. id)

    rednet.send(SERVER_ID, {type = "create", card = tostring(id), pin = pin})
    rednet.receive(5)

    print("Kort laget!")
    sleep(2)
end

-- DEPOSIT (kisten ved siden av ATM må inneholde diamonds)
local function deposit(card)
    local chest = peripheral.find("inventory")
    if not chest then
        print("Ingen kiste koblet til!")
        sleep(2)
        return
    end

    local diamonds = 0

    for slot, item in pairs(chest.list()) do
        if item.name == "minecraft:diamond" then
            diamonds = diamonds + item.count
        end
    end

    if diamonds == 0 then
        print("Ingen diamanter i kisten!")
        sleep(2)
        return
    end

    -- Fjern alle diamonds fra kisten
    for slot, item in pairs(chest.list()) do
        if item.name == "minecraft:diamond" then
            chest.pushItems(peripheral.getName(chest), slot, item.count)
        end
    end

    local money = diamonds * DIAMOND_VALUE

    rednet.send(SERVER_ID, {type = "deposit", card = tostring(card), amount = money})
    local _, ok = rednet.receive(5)

    if ok then
        print("Satt inn " .. money .. " kr (" .. diamonds .. " diamanter)")
    else
        print("Feil under innskudd!")
    end
    sleep(2)
end

-- WITHDRAW
local function withdraw(card)
    term.clear()
    term.setCursorPos(1, 1)
    print("Beloep (kr):")
    local amount = tonumber(read())

    if not amount or amount <= 0 then
        print("Ugyldig beloep!")
        sleep(2)
        return
    end

    if amount % DIAMOND_VALUE ~= 0 then
        print("Beloep maa vaere multiplum av " .. DIAMOND_VALUE)
        sleep(2)
        return
    end

    rednet.send(SERVER_ID, {type = "withdraw", card = tostring(card), amount = amount})
    local _, ok = rednet.receive(5)

    if ok then
        rednet.send(TURTLE_ID, {type = "give", amount = amount / DIAMOND_VALUE})
        print("Tok ut " .. amount .. " kr")
        sleep(2)
    else
        print("Ikke nok penger!")
        sleep(2)
    end
end

-- MENU
local function menu(balance)
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.yellow)
    print("=== BANK-AUTOMAT ===")
    term.setTextColor(colors.white)
    print("Saldo: " .. balance .. " kr")

    button(2, 5, 10, 2, "Sett inn", colors.green, colors.white)
    button(15, 5, 10, 2, "Ta ut", colors.red, colors.white)
    button(2, 10, 10, 2, "Lag kort", colors.blue, colors.white)
    button(15, 10, 10, 2, "Avslutt", colors.gray, colors.white)
end

-- MAIN
while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("Sett inn kort (disk)...")

    sleep(1)
    local card = getCard()

    if card then
        rednet.send(SERVER_ID, {type = "get", card = tostring(card)})
        local _, data = rednet.receive(5)

        if not data then
            -- Nytt kort uten konto -- registrer direkte
            term.clear()
            term.setCursorPos(1, 1)
            print("Nytt kort oppdaget!")
            print("Velg ein PIN-kode:")
            local pin1 = read("*")
            print("Skriv PIN ein gong til:")
            local pin2 = read("*")

            if pin1 ~= pin2 then
                print("PIN-kodene er ikkje like. Prøv igjen.")
                sleep(2)
            else
                rednet.send(SERVER_ID, {type = "create", card = tostring(card), pin = pin1})
                local _, ok = rednet.receive(5)
                if ok then
                    print("Konto oppretta!")
                    sleep(2)
                    data = {balance = 0, pin = pin1}
                    -- Fall gjennom til menyen
                    while true do
                        menu(data.balance)
                        local x, y = click()

                        if y >= 5 and y <= 7 and x >= 2 and x <= 12 then
                            deposit(card)
                        elseif y >= 5 and y <= 7 and x >= 15 and x <= 25 then
                            withdraw(card)
                        elseif y >= 10 and y <= 12 and x >= 2 and x <= 12 then
                            createCard()
                        elseif y >= 10 and y <= 12 and x >= 15 and x <= 25 then
                            break
                        end

                        rednet.send(SERVER_ID, {type = "get", card = tostring(card)})
                        _, data = rednet.receive(5)
                        if not data then break end
                    end
                else
                    print("Noko gjekk gale. Prøv igjen.")
                    sleep(2)
                end
            end
        else
            local pin = askPIN()

            if pin == data.pin then
                while true do
                    menu(data.balance)
                    local x, y = click()

                    if y >= 5 and y <= 7 and x >= 2 and x <= 12 then
                        deposit(card)

                    elseif y >= 5 and y <= 7 and x >= 15 and x <= 25 then
                        withdraw(card)

                    elseif y >= 10 and y <= 12 and x >= 2 and x <= 12 then
                        createCard()

                    elseif y >= 10 and y <= 12 and x >= 15 and x <= 25 then
                        break
                    end

                    -- Oppdater saldo
                    rednet.send(SERVER_ID, {type = "get", card = tostring(card)})
                    _, data = rednet.receive(5)
                    if not data then break end
                end
            else
                print("Feil PIN!")
                sleep(2)
            end
        end
    else
        sleep(0.5) -- unngaa CPU-spinn
    end
end

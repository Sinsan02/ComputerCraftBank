-- Blokker Ctrl+T slik at programmet ikke kan avsluttes
os.pullEvent = os.pullEventRaw

-- KONFIGURASJON
local SERVER_ID = 11      -- Computer ID til bank_server
local TURTLE_ID = 2       -- Computer ID til turtle_bank
local DIAMOND_VALUE = 1000

rednet.open("top")

-- Skjermstørrelse (standard CC: 51x19)
local W, H = term.getSize()

-- Farger
local COL_BG        = colors.black
local COL_BTN       = colors.orange
local COL_SHADOW    = colors.brown
local COL_BTN_TXT   = colors.black
local COL_TITLE_BG  = colors.orange
local COL_TITLE_TXT = colors.black
local COL_TEXT      = colors.white
local COL_BALANCE   = colors.yellow

-- Knapp-dimensjoner
local BTN_W = 22
local BTN_H = 2
local BTN_X = math.floor((W - BTN_W) / 2) + 1

-- Y-posisjoner: normalmeny (4 knapper)
local Y_DEPOSIT    = 6
local Y_WITHDRAW   = 9
local Y_CHANGEPIN  = 12
local Y_EXIT       = 15

-- Y-posisjoner: nytt-kort-meny (2 knapper)
local Y_CREATE     = 8
local Y_EXIT_NEW   = 13

-- ─── UI-HJELPERE ──────────────────────────────────────────────────────────────

local function clearScreen()
    term.setBackgroundColor(COL_BG)
    term.clear()
    term.setCursorPos(1, 1)
end

local function drawTitle()
    paintutils.drawFilledBox(1, 1, W, 3, COL_TITLE_BG)
    local title = "A  T  M"
    local tx = math.floor((W - #title) / 2) + 1
    term.setBackgroundColor(COL_TITLE_BG)
    term.setTextColor(COL_TITLE_TXT)
    term.setCursorPos(tx, 2)
    term.write(title)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
end

local function drawBalance(balance)
    local text = "[ Saldo:  " .. balance .. " kr ]"
    local tx = math.floor((W - #text) / 2) + 1
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_BALANCE)
    term.setCursorPos(tx, 4)
    term.write(text)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
end

local function drawButton(y, text)
    paintutils.drawFilledBox(BTN_X + 1, y + 1, BTN_X + BTN_W, y + BTN_H, COL_SHADOW)
    paintutils.drawFilledBox(BTN_X, y, BTN_X + BTN_W - 1, y + BTN_H - 1, COL_BTN)
    local tx = BTN_X + math.floor((BTN_W - #text) / 2)
    term.setBackgroundColor(COL_BTN)
    term.setTextColor(COL_BTN_TXT)
    term.setCursorPos(tx, y)
    term.write(text)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
end

local function inButton(cx, cy, btnY)
    return cy >= btnY and cy <= btnY + BTN_H - 1
       and cx >= BTN_X and cx <= BTN_X + BTN_W - 1
end

local function click()
    local _, _, x, y = os.pullEvent("mouse_click")
    return x, y
end

local function writeCentered(y, text, color)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(color or COL_TEXT)
    local tx = math.floor((W - #text) / 2) + 1
    term.setCursorPos(tx, y)
    term.write(text)
    term.setTextColor(COL_TEXT)
end

-- ─── NETTVERK ─────────────────────────────────────────────────────────────────

local function serverReceive()
    local deadline = os.clock() + 5
    while os.clock() < deadline do
        local sender, msg = rednet.receive(1)
        if sender == SERVER_ID then return msg end
    end
    return nil
end

local function turtleReceive()
    local deadline = os.clock() + 5
    while os.clock() < deadline do
        local sender, msg = rednet.receive(1)
        if sender == TURTLE_ID then return msg end
    end
    return nil
end

-- ─── KORT ─────────────────────────────────────────────────────────────────────

local function getDrive()
    return peripheral.find("drive")
end

local function getCard(drive)
    if not drive then return nil end
    if not drive.isDiskPresent() then return nil end
    return drive.getDiskID()
end

-- ─── SKJERMHJELPER ────────────────────────────────────────────────────────────

local function showMessage(lines, delay)
    clearScreen()
    drawTitle()
    local startY = math.floor((H - #lines) / 2) + 1
    for i, line in ipairs(lines) do
        writeCentered(startY + i - 1, line)
    end
    sleep(delay or 2)
end

local function askPIN(prompt)
    clearScreen()
    drawTitle()
    local p = prompt or "Skriv PIN-kode:"
    writeCentered(9, p)
    term.setCursorPos(math.floor(W / 2) - 1, 11)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_BALANCE)
    return read("*")
end

local function askText(prompt)
    clearScreen()
    drawTitle()
    writeCentered(9, prompt)
    term.setCursorPos(math.floor(W / 2) - 6, 11)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_BALANCE)
    return read()
end

local function askNumber(prompt)
    clearScreen()
    drawTitle()
    writeCentered(9, prompt)
    term.setCursorPos(math.floor(W / 2) - 1, 11)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_BALANCE)
    return tonumber(read())
end

-- ─── OPERASJONER ──────────────────────────────────────────────────────────────

local function deposit(card)
    clearScreen()
    drawTitle()
    writeCentered(10, "Teller diamanter i turtle...")

    rednet.send(TURTLE_ID, {type = "deposit"})
    local diamonds = turtleReceive()

    if not diamonds or type(diamonds) ~= "number" then
        showMessage({"Ingen respons fra turtle!"})
        return
    end
    if diamonds == 0 then
        showMessage({"Ingen diamanter i turtle!", "", "(Legg diamanter i slot 1)"})
        return
    end

    local money = diamonds * DIAMOND_VALUE
    rednet.send(SERVER_ID, {type = "deposit", card = tostring(card), amount = money})
    local ok = serverReceive()

    if ok then
        showMessage({"Innskudd vellykket!", "", diamonds .. " diamanter = " .. money .. " kr"})
    else
        showMessage({"Feil under innskudd!"})
    end
end

local function withdraw(card)
    local diamonds = askNumber("Antall diamanter å ta ut:")

    if not diamonds or diamonds <= 0 or math.floor(diamonds) ~= diamonds then
        showMessage({"Ugyldig antall!"})
        return
    end

    local amount = diamonds * DIAMOND_VALUE
    rednet.send(SERVER_ID, {type = "withdraw", card = tostring(card), amount = amount})
    local ok = serverReceive()

    if ok then
        rednet.send(TURTLE_ID, {type = "give", amount = diamonds})
        showMessage({"Uttak vellykket!", "", diamonds .. " diamanter utbetalt"})
    else
        showMessage({"Ikke nok penger!"})
    end
end

local function changePin(card, data)
    local old = askPIN("Skriv nåværende PIN:")
    if old ~= data.pin then
        showMessage({"Feil PIN-kode!"})
        return data
    end

    local new1 = askPIN("Velg ny PIN-kode:")
    local new2 = askPIN("Gjenta ny PIN-kode:")

    if new1 ~= new2 then
        showMessage({"PIN-kodene er ikke like."})
        return data
    end

    rednet.send(SERVER_ID, {type = "changepin", card = tostring(card), newpin = new1})
    local ok = serverReceive()

    if ok then
        showMessage({"PIN-kode endret!"})
        data.pin = new1
    else
        showMessage({"Noe gikk galt."})
    end
    return data
end

-- ─── MENYER ───────────────────────────────────────────────────────────────────

-- Normalmeny for eksisterende kort (4 knapper)
local function runMenu(card, data)
    while true do
        clearScreen()
        drawTitle()
        drawBalance(data.balance)
        drawButton(Y_DEPOSIT,   "Sett inn")
        drawButton(Y_WITHDRAW,  "Ta ut")
        drawButton(Y_CHANGEPIN, "Bytt PIN")
        drawButton(Y_EXIT,      "Avslutt")

        local x, y = click()

        if inButton(x, y, Y_DEPOSIT) then
            deposit(card)
        elseif inButton(x, y, Y_WITHDRAW) then
            withdraw(card)
        elseif inButton(x, y, Y_CHANGEPIN) then
            data = changePin(card, data)
        elseif inButton(x, y, Y_EXIT) then
            break
        end

        -- Oppdater saldo fra serveren
        rednet.send(SERVER_ID, {type = "get", card = tostring(card)})
        local fresh = serverReceive()
        if not fresh then break end
        data.balance = fresh.balance
    end
end

-- Nytt-kort-meny for ukjente kort (2 knapper)
local function runNewCardMenu(card, drive)
    while true do
        clearScreen()
        drawTitle()
        writeCentered(5, "Nytt kort oppdaget!", COL_BALANCE)
        drawButton(Y_CREATE,  "Lag kort")
        drawButton(Y_EXIT_NEW, "Avslutt")

        local x, y = click()

        if inButton(x, y, Y_CREATE) then
            -- Be om navn til disken
            local label = askText("Velg navn på kortet:")
            if label and #label > 0 then
                drive.setDiskLabel(label)
            end

            -- Be om PIN
            local pin1 = askPIN("Velg PIN-kode:")
            local pin2 = askPIN("Gjenta PIN-koden:")

            if pin1 ~= pin2 then
                showMessage({"PIN-kodene er ikke like.", "Prøv igjen."})
            else
                rednet.send(SERVER_ID, {type = "create", card = tostring(card), pin = pin1})
                local ok = serverReceive()
                if ok then
                    showMessage({"Konto opprettet!", "", "Velkommen!"}, 2)
                    runMenu(card, {balance = 0, pin = pin1})
                    return
                else
                    showMessage({"Noe gikk galt.", "Prøv igjen."})
                end
            end

        elseif inButton(x, y, Y_EXIT_NEW) then
            break
        end
    end
end

-- ─── HOVEDLOOP ────────────────────────────────────────────────────────────────

while true do
    clearScreen()
    drawTitle()
    writeCentered(10, "Sett inn bankkort (disk)...")

    sleep(1)
    local drive = getDrive()
    local card  = getCard(drive)

    if card then
        rednet.send(SERVER_ID, {type = "get", card = tostring(card)})
        local data = serverReceive()

        if not data then
            -- Ukjent kort → nytt-kort-meny
            runNewCardMenu(card, drive)
        else
            -- Kjent kort → PIN-sjekk → normalmeny
            local pin = askPIN()
            if pin == data.pin then
                runMenu(card, data)
            else
                showMessage({"Feil PIN-kode!"})
            end
        end
    else
        sleep(0.5) -- unngå CPU-spinn
    end
end

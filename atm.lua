-- Blokker Ctrl+T slik at programmet ikke kan avsluttes
os.pullEvent = os.pullEventRaw

-- KONFIGURASJON
local SERVER_ID = 11       -- Computer ID til bank_server
local TURTLE_ID = 2       -- Computer ID til turtle_bank
local DIAMOND_VALUE = 1000

rednet.open("top")

-- Skjermstorrelse (standard CC: 51x19)
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

-- Knapp Y-posisjoner
local Y_DEPOSIT  = 8
local Y_WITHDRAW = 12
local Y_EXIT     = 16

-- ─── UI-HJELPERE ──────────────────────────────────────────────────────────────

local function clearScreen()
    term.setBackgroundColor(COL_BG)
    term.clear()
    term.setCursorPos(1, 1)
end

local function drawTitle()
    -- Tre-rads orange banner
    paintutils.drawFilledBox(1, 1, W, 3, COL_TITLE_BG)
    -- "A T M" sentrert på rad 2
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
    term.setCursorPos(tx, 5)
    term.write(text)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
end

-- Tegner en knapp med skygge-effekt
local function drawButton(y, text)
    -- Skygge (brun, forskjøvet 1 til høyre og 1 ned)
    paintutils.drawFilledBox(BTN_X + 1, y + 1, BTN_X + BTN_W, y + BTN_H, COL_SHADOW)
    -- Hovedknapp (oransje)
    paintutils.drawFilledBox(BTN_X, y, BTN_X + BTN_W - 1, y + BTN_H - 1, COL_BTN)
    -- Tekst sentrert på øvre rad av knappen
    local tx = BTN_X + math.floor((BTN_W - #text) / 2)
    term.setBackgroundColor(COL_BTN)
    term.setTextColor(COL_BTN_TXT)
    term.setCursorPos(tx, y)
    term.write(text)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
end

-- Sjekk om klikk traff en knapp
local function inButton(cx, cy, btnY)
    return cy >= btnY and cy <= btnY + BTN_H - 1
       and cx >= BTN_X and cx <= BTN_X + BTN_W - 1
end

local function click()
    local _, _, x, y = os.pullEvent("mouse_click")
    return x, y
end

-- ─── NETTVERK ─────────────────────────────────────────────────────────────────

local function serverReceive()
    local deadline = os.clock() + 5
    while os.clock() < deadline do
        local sender, msg = rednet.receive(1)
        if sender == SERVER_ID then
            return msg
        end
    end
    return nil
end

local function turtleReceive()
    local deadline = os.clock() + 5
    while os.clock() < deadline do
        local sender, msg = rednet.receive(1)
        if sender == TURTLE_ID then
            return msg
        end
    end
    return nil
end

-- ─── KORT ─────────────────────────────────────────────────────────────────────

local function getCard()
    local drive = peripheral.find("drive")
    if not drive then return nil end
    if not drive.isDiskPresent() then return nil end
    return drive.getDiskID()
end

-- ─── SKJERMAR ─────────────────────────────────────────────────────────────────

local function showMessage(lines, delay)
    clearScreen()
    drawTitle()
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
    local startY = math.floor((H - #lines) / 2) + 1
    for i, line in ipairs(lines) do
        local tx = math.floor((W - #line) / 2) + 1
        term.setCursorPos(tx, startY + i - 1)
        term.write(line)
    end
    sleep(delay or 2)
end

local function askPIN()
    clearScreen()
    drawTitle()
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
    local prompt = "Skriv PIN-kode:"
    term.setCursorPos(math.floor((W - #prompt) / 2) + 1, 9)
    term.write(prompt)
    term.setCursorPos(math.floor(W / 2), 11)
    return read("*")
end

local function askNumber(prompt)
    clearScreen()
    drawTitle()
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
    term.setCursorPos(math.floor((W - #prompt) / 2) + 1, 9)
    term.write(prompt)
    term.setCursorPos(math.floor(W / 2), 11)
    return tonumber(read())
end

-- ─── OPERASJONAR ──────────────────────────────────────────────────────────────

local function deposit(card)
    -- Vis ventemelding mens turtle teller
    clearScreen()
    drawTitle()
    local wait = "Teller diamanter i turtle..."
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
    term.setCursorPos(math.floor((W - #wait) / 2) + 1, 10)
    term.write(wait)

    rednet.send(TURTLE_ID, {type = "deposit"})
    local diamonds = turtleReceive()

    if not diamonds or type(diamonds) ~= "number" then
        showMessage({"Ingen respons fra turtle!"})
        return
    end

    if diamonds == 0 then
        showMessage({"Ingen diamanter i turtle!"})
        return
    end

    local money = diamonds * DIAMOND_VALUE
    rednet.send(SERVER_ID, {type = "deposit", card = tostring(card), amount = money})
    local ok = serverReceive()

    if ok then
        showMessage({
            "Innskudd vellykket!",
            "",
            diamonds .. " diamanter = " .. money .. " kr"
        })
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
        rednet.send(TURTLE_ID, {type = "give", amount = amount / DIAMOND_VALUE})
        showMessage({
            "Uttak vellykket!",
            "",
            diamonds .. " diamanter utbetalt"
        })
    else
        showMessage({"Ikke nok penger!"})
    end
end

-- ─── MENY ─────────────────────────────────────────────────────────────────────

local function menu(balance)
    clearScreen()
    drawTitle()
    drawBalance(balance)
    drawButton(Y_DEPOSIT,  "Sett inn")
    drawButton(Y_WITHDRAW, "Ta ut")
    drawButton(Y_EXIT,     "Avslutt")
end

local function runMenu(card, data)
    while true do
        menu(data.balance)
        local x, y = click()

        if inButton(x, y, Y_DEPOSIT) then
            deposit(card)
        elseif inButton(x, y, Y_WITHDRAW) then
            withdraw(card)
        elseif inButton(x, y, Y_EXIT) then
            break
        end

        -- Oppdater saldo fra serveren
        rednet.send(SERVER_ID, {type = "get", card = tostring(card)})
        data = serverReceive()
        if not data then break end
    end
end

-- ─── HOVUDLOOP ────────────────────────────────────────────────────────────────

while true do
    clearScreen()
    drawTitle()
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
    local msg = "Sett inn bankkort (disk)..."
    term.setCursorPos(math.floor((W - #msg) / 2) + 1, 10)
    term.write(msg)

    sleep(1)
    local card = getCard()

    if card then
        rednet.send(SERVER_ID, {type = "get", card = tostring(card)})
        local data = serverReceive()

        if not data then
            -- Nytt kort – registrer
            clearScreen()
            drawTitle()
            term.setBackgroundColor(COL_BG)
            term.setTextColor(COL_TEXT)
            term.setCursorPos(math.floor(W / 2) - 9, 6)
            term.write("Nytt kort oppdaget!")

            term.setCursorPos(math.floor(W / 2) - 8, 8)
            term.write("Velg en PIN-kode:")
            term.setCursorPos(math.floor(W / 2) - 1, 9)
            local pin1 = read("*")

            term.setCursorPos(math.floor(W / 2) - 9, 11)
            term.write("Gjenta PIN-koden:")
            term.setCursorPos(math.floor(W / 2) - 1, 12)
            local pin2 = read("*")

            if pin1 ~= pin2 then
                showMessage({"PIN-kodene er ikke like.", "Prøv igjen."})
            else
                rednet.send(SERVER_ID, {type = "create", card = tostring(card), pin = pin1})
                local ok = serverReceive()
                if ok then
                    showMessage({"Konto opprettet!", "", "Velkommen!"}, 2)
                    data = {balance = 0, pin = pin1}
                    runMenu(card, data)
                else
                    showMessage({"Noe gikk galt.", "Prøv igjen."})
                end
            end
        else
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

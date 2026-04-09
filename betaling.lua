-- Blokker Ctrl+T
os.pullEvent = os.pullEventRaw

-- KONFIGURASJON
local SERVER_ID = 5
local DIAMOND_VALUE = 1000

rednet.open("back")

-- Skjermstorrelse
local W, H = term.getSize()

-- Farger
local COL_BG        = colors.black
local COL_TITLE_BG  = colors.orange
local COL_TITLE_TXT = colors.black
local COL_TEXT      = colors.white
local COL_DIM       = colors.gray
local COL_ACCENT    = colors.yellow
local COL_OK        = colors.lime
local COL_ERR       = colors.red

-- ─── UI-HJELPERE ──────────────────────────────────────────────────────────────

local function clearScreen()
    term.setBackgroundColor(COL_BG)
    term.clear()
    term.setCursorPos(1, 1)
end

local function drawTitle()
    paintutils.drawFilledBox(1, 1, W, 3, COL_TITLE_BG)
    local title = "K O R T B E T A L I N G"
    local tx = math.floor((W - #title) / 2) + 1
    term.setBackgroundColor(COL_TITLE_BG)
    term.setTextColor(COL_TITLE_TXT)
    term.setCursorPos(tx, 2)
    term.write(title)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_TEXT)
end

-- Skriv ei sentrert linje paa gjeven rad
local function writeCentered(y, text, color)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(color or COL_TEXT)
    local tx = math.floor((W - #text) / 2) + 1
    term.setCursorPos(tx, y)
    term.write(text)
    term.setTextColor(COL_TEXT)
end

-- Tegn ein horisontal skiljelinje
local function drawDivider(y)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_DIM)
    term.setCursorPos(2, y)
    term.write(string.rep("-", W - 2))
    term.setTextColor(COL_TEXT)
end

-- Vis ei melding med valfri farge, vent delay sekund
local function showMessage(lines, color, delay)
    clearScreen()
    drawTitle()
    local startY = math.floor((H - #lines) / 2) + 1
    for i, line in ipairs(lines) do
        writeCentered(startY + i - 1, line, color or COL_TEXT)
    end
    sleep(delay or 2)
end

-- Les input sentrert paa skjermen
local function readCentered(promptY, inputY)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_ACCENT)
    term.setCursorPos(math.floor(W / 2) - 4, inputY)
    return read()
end

local function readPIN(promptY, inputY)
    term.setBackgroundColor(COL_BG)
    term.setTextColor(COL_ACCENT)
    term.setCursorPos(math.floor(W / 2) - 4, inputY)
    return read("*")
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

-- ─── KORT ─────────────────────────────────────────────────────────────────────

local function getDrives()
    local left  = peripheral.isPresent("left")  and peripheral.getType("left")  == "drive" and peripheral.wrap("left")  or nil
    local right = peripheral.isPresent("right") and peripheral.getType("right") == "drive" and peripheral.wrap("right") or nil
    return left, right
end

local function getCardID(drive)
    if not drive then return nil end
    if not drive.isDiskPresent() then return nil end
    return drive.getDiskID()
end

-- ─── HOVUDLOOP ────────────────────────────────────────────────────────────────

while true do

    -- ── Velkomstskjerm ──────────────────────────────────────────────────────
    clearScreen()
    drawTitle()

    writeCentered(5,  "Sett inn begge korta:", COL_ACCENT)
    drawDivider(6)
    writeCentered(8,  "[ VENSTRE SIDE ]", COL_TEXT)
    writeCentered(9,  "Betalar sitt kort", COL_DIM)
    drawDivider(11)
    writeCentered(13, "[ HOGRE SIDE ]", COL_TEXT)
    writeCentered(14, "Mottakar sitt kort", COL_DIM)
    drawDivider(16)
    writeCentered(17, "Trykk Enter naa begge er sett inn...", COL_DIM)

    read()

    -- ── Valider kort ────────────────────────────────────────────────────────
    local leftDrive, rightDrive = getDrives()
    local fromCard = getCardID(leftDrive)
    local toCard   = getCardID(rightDrive)

    if not fromCard then
        showMessage({"Fann ikkje betalar sitt kort!", "", "(Venstre disk-stasjon)"}, COL_ERR)
    elseif not toCard then
        showMessage({"Fann ikkje mottakar sitt kort!", "", "(Hogre disk-stasjon)"}, COL_ERR)
    elseif tostring(fromCard) == tostring(toCard) then
        showMessage({"Kan ikkje betale til same kort!"}, COL_ERR)
    else

        -- ── Hent kontodata ───────────────────────────────────────────────────
        rednet.send(SERVER_ID, {type = "get", card = tostring(fromCard)})
        local fromData = serverReceive()

        rednet.send(SERVER_ID, {type = "get", card = tostring(toCard)})
        local toData = serverReceive()

        if not fromData then
            showMessage({"Betalar sitt kort er ikkje registrert!"}, COL_ERR)
        elseif not toData then
            showMessage({"Mottakar sitt kort er ikkje registrert!"}, COL_ERR)
        else

            -- ── PIN-skjerm ───────────────────────────────────────────────────
            clearScreen()
            drawTitle()

            writeCentered(5, "Betalar sin saldo:", COL_DIM)
            writeCentered(6, fromData.balance .. " kr", COL_ACCENT)
            drawDivider(8)
            writeCentered(10, "Skriv PIN-kode:", COL_TEXT)

            local pin = readPIN(10, 12)

            if pin ~= fromData.pin then
                showMessage({"Feil PIN-kode!"}, COL_ERR)
            else

                -- ── Belop-skjerm ─────────────────────────────────────────────
                clearScreen()
                drawTitle()

                writeCentered(5, "Betalar sin saldo:", COL_DIM)
                writeCentered(6, fromData.balance .. " kr", COL_ACCENT)
                drawDivider(8)
                writeCentered(10, "Antall diamanter aa betale:", COL_TEXT)

                local diamonds = tonumber(readCentered(10, 12))

                if not diamonds or diamonds <= 0 or math.floor(diamonds) ~= diamonds then
                    showMessage({"Ugyldig antal diamanter!"}, COL_ERR)
                else
                    local amount = diamonds * DIAMOND_VALUE

                    if amount > fromData.balance then
                        showMessage({
                            "Ikkje nok pengar!",
                            "",
                            "Saldo:    " .. fromData.balance .. " kr",
                            "Krevst:   " .. amount .. " kr"
                        }, COL_ERR, 3)
                    else

                        -- ── Utfor overfoering ────────────────────────────────
                        clearScreen()
                        drawTitle()
                        writeCentered(10, "Behandlar betaling...", COL_DIM)

                        rednet.send(SERVER_ID, {
                            type   = "transfer",
                            from   = tostring(fromCard),
                            to     = tostring(toCard),
                            amount = amount
                        })
                        local res = serverReceive()

                        -- ── Resultat-skjerm ──────────────────────────────────
                        if res and res.ok then
                            showMessage({
                                "Betaling gjennomfort!",
                                "",
                                diamonds .. " diamanter",
                                "(" .. amount .. " kr)",
                                "",
                                "er overfort til mottakar."
                            }, COL_OK, 3)
                        else
                            local reason = (res and res.reason) or "Ukjend feil"
                            showMessage({
                                "Betaling feila!",
                                "",
                                reason
                            }, COL_ERR, 3)
                        end

                    end
                end
            end
        end
    end
end

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

-- Vent på Enter-tasten, ignorer all annen input
local function ventPaaEnter()
    while true do
        local _, key = os.pullEvent("key")
        if key == keys.enter then break end
    end
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

    writeCentered(5,  "Sett inn begge kortene:", COL_ACCENT)
    drawDivider(6)
    writeCentered(8,  "[ VENSTRE SIDE ]", COL_TEXT)
    writeCentered(9,  "Betaler sitt kort", COL_DIM)
    drawDivider(11)
    writeCentered(13, "[ HØYRE SIDE ]", COL_TEXT)
    writeCentered(14, "Mottaker sitt kort", COL_DIM)
    drawDivider(16)
    writeCentered(17, "Trykk Enter når begge er satt inn...", COL_DIM)

    ventPaaEnter()

    -- ── Valider kort ────────────────────────────────────────────────────────
    local leftDrive, rightDrive = getDrives()
    local fromCard = getCardID(leftDrive)
    local toCard   = getCardID(rightDrive)

    if not fromCard then
        showMessage({"Fant ikke betaler sitt kort!", "", "(Venstre disk-stasjon)"}, COL_ERR)
    elseif not toCard then
        showMessage({"Fant ikke mottaker sitt kort!", "", "(Høyre disk-stasjon)"}, COL_ERR)
    elseif tostring(fromCard) == tostring(toCard) then
        showMessage({"Kan ikke betale til samme kort!"}, COL_ERR)
    else

        -- ── Hent kontodata ───────────────────────────────────────────────────
        rednet.send(SERVER_ID, {type = "get", card = tostring(fromCard)})
        local fromData = serverReceive()

        rednet.send(SERVER_ID, {type = "get", card = tostring(toCard)})
        local toData = serverReceive()

        if not fromData then
            showMessage({"Betaler sitt kort er ikke registrert!"}, COL_ERR)
        elseif not toData then
            showMessage({"Mottaker sitt kort er ikke registrert!"}, COL_ERR)
        else

            -- ── PIN-skjerm ───────────────────────────────────────────────────
            clearScreen()
            drawTitle()

            writeCentered(5, "Betaler sin saldo:", COL_DIM)
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

                writeCentered(5, "Betaler sin saldo:", COL_DIM)
                writeCentered(6, fromData.balance .. " kr", COL_ACCENT)
                drawDivider(8)
                writeCentered(10, "Antall diamanter å betale:", COL_TEXT)

                local diamonds = tonumber(readCentered(10, 12))

                if not diamonds or diamonds <= 0 or math.floor(diamonds) ~= diamonds then
                    showMessage({"Ugyldig antall diamanter!"}, COL_ERR)
                else
                    local amount = diamonds * DIAMOND_VALUE

                    if amount > fromData.balance then
                        showMessage({
                            "Ikke nok penger!",
                            "",
                            "Saldo:    " .. fromData.balance .. " kr",
                            "Kreves:   " .. amount .. " kr"
                        }, COL_ERR, 3)
                    else

                        -- ── Behandler overføring ─────────────────────────────
                        clearScreen()
                        drawTitle()
                        writeCentered(10, "Behandler betaling...", COL_DIM)

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
                                "Betaling gjennomført!",
                                "",
                                diamonds .. " diamanter",
                                "(" .. amount .. " kr)",
                                "",
                                "er overført til mottaker."
                            }, COL_OK, 3)
                        else
                            local reason = (res and res.reason) or "Ukjent feil"
                            showMessage({
                                "Betaling feilet!",
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

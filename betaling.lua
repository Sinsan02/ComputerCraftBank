-- KONFIGURASJON
local SERVER_ID = 5       -- Computer ID til bank_server
local DIAMOND_VALUE = 1000

rednet.open("back")

-- Motta svar KUN frå bank-serveren
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

-- Finn venstre og høgre disk drive
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

-- MAIN
while true do
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.yellow)
    print("=== KORTBETALING ===")
    term.setTextColor(colors.white)
    print("")
    print("Sett inn:")
    print("  Venstre side: BETALAR sitt kort")
    print("  Hogre side:   MOTTAKAR sitt kort")
    print("")
    print("Trykk Enter naa begge korta er sett inn...")
    read()

    local leftDrive, rightDrive = getDrives()

    local fromCard = getCardID(leftDrive)
    local toCard   = getCardID(rightDrive)

    if not fromCard then
        print("Fann ikkje betalar sitt kort (venstre)!")
        sleep(2)
    elseif not toCard then
        print("Fann ikkje mottakar sitt kort (hogre)!")
        sleep(2)
    elseif tostring(fromCard) == tostring(toCard) then
        print("Kan ikkje betale til same kort!")
        sleep(2)
    else
        -- Hent begge kontoar
        rednet.send(SERVER_ID, {type = "get", card = tostring(fromCard)})
        local fromData = serverReceive()

        rednet.send(SERVER_ID, {type = "get", card = tostring(toCard)})
        local toData = serverReceive()

        if not fromData then
            print("Betalar sitt kort er ikkje registrert!")
            sleep(2)
        elseif not toData then
            print("Mottakar sitt kort er ikkje registrert!")
            sleep(2)
        else
            -- Be om PIN
            term.clear()
            term.setCursorPos(1, 1)
            term.setTextColor(colors.yellow)
            print("=== KORTBETALING ===")
            term.setTextColor(colors.white)
            print("")
            print("Betalar sin saldo: " .. fromData.balance .. " kr")
            print("")
            print("Skriv PIN:")
            local pin = read("*")

            if pin ~= fromData.pin then
                print("")
                print("Feil PIN!")
                sleep(2)
            else
                -- Be om beløp
                term.clear()
                term.setCursorPos(1, 1)
                term.setTextColor(colors.yellow)
                print("=== KORTBETALING ===")
                term.setTextColor(colors.white)
                print("")
                print("Betalar sin saldo: " .. fromData.balance .. " kr")
                print("")
                print("Antall diamanter aa betale:")
                local diamonds = tonumber(read())

                if not diamonds or diamonds <= 0 or math.floor(diamonds) ~= diamonds then
                    print("Ugyldig antal!")
                    sleep(2)
                else
                    local amount = diamonds * DIAMOND_VALUE

                    if amount > fromData.balance then
                        print("")
                        print("Ikkje nok pengar!")
                        print("Saldo: " .. fromData.balance .. " kr")
                        sleep(3)
                    else
                        -- Utfør overføring
                        rednet.send(SERVER_ID, {
                            type   = "transfer",
                            from   = tostring(fromCard),
                            to     = tostring(toCard),
                            amount = amount
                        })
                        local res = serverReceive()

                        term.clear()
                        term.setCursorPos(1, 1)
                        term.setTextColor(colors.yellow)
                        print("=== KORTBETALING ===")
                        term.setTextColor(colors.white)
                        print("")

                        if res and res.ok then
                            term.setTextColor(colors.green)
                            print("Betaling gjennomfort!")
                            term.setTextColor(colors.white)
                            print("")
                            print(diamonds .. " diamanter (" .. amount .. " kr)")
                            print("er overfort til mottakar.")
                        else
                            term.setTextColor(colors.red)
                            print("Betaling feila!")
                            term.setTextColor(colors.white)
                            if res and res.reason then
                                print(res.reason)
                            end
                        end
                        sleep(3)
                    end
                end
            end
        end
    end
end

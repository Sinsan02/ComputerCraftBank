rednet.open("back")

local FILE = "bank.db"

-- LOAD
local function load()
    if not fs.exists(FILE) then return {} end
    local f = fs.open(FILE, "r")
    local data = textutils.unserialize(f.readAll())
    f.close()
    return data or {}
end

-- SAVE
local function save(db)
    local f = fs.open(FILE, "w")
    f.write(textutils.serialize(db))
    f.close()
end

local db = load()

print("Bank server startet (ID: " .. os.getComputerID() .. ")")

while true do
    local sender, msg = rednet.receive()

    if type(msg) ~= "table" or not msg.type then
        -- Ignorer ugyldige meldinger
    elseif msg.type == "get" then
        rednet.send(sender, db[msg.card])

    elseif msg.type == "create" then
        if db[msg.card] then
            -- Kort finnes allerede
            rednet.send(sender, false)
        else
            db[msg.card] = {balance = 0, pin = msg.pin}
            save(db)
            print("Nytt kort registrert: " .. msg.card)
            rednet.send(sender, true)
        end

    elseif msg.type == "deposit" then
        if not db[msg.card] then
            rednet.send(sender, false)
        else
            db[msg.card].balance = db[msg.card].balance + msg.amount
            save(db)
            print("Innskudd: " .. msg.card .. " +" .. msg.amount .. " kr")
            rednet.send(sender, true)
        end

    elseif msg.type == "withdraw" then
        if not db[msg.card] then
            rednet.send(sender, false)
        elseif db[msg.card].balance >= msg.amount then
            db[msg.card].balance = db[msg.card].balance - msg.amount
            save(db)
            print("Uttak: " .. msg.card .. " -" .. msg.amount .. " kr")
            rednet.send(sender, true)
        else
            print("Avvist uttak (ikke nok penger): " .. msg.card)
            rednet.send(sender, false)
        end
    elseif msg.type == "changepin" then
        if not db[msg.card] then
            rednet.send(sender, false)
        else
            db[msg.card].pin = msg.newpin
            save(db)
            print("PIN endret: " .. msg.card)
            rednet.send(sender, true)
        end

    elseif msg.type == "transfer" then
        if not db[msg.from] then
            rednet.send(sender, {ok=false, reason="Betalar sitt kort finst ikkje"})
        elseif not db[msg.to] then
            rednet.send(sender, {ok=false, reason="Mottakar sitt kort finst ikkje"})
        elseif db[msg.from].balance < msg.amount then
            rednet.send(sender, {ok=false, reason="Ikkje nok pengar"})
        else
            db[msg.from].balance = db[msg.from].balance - msg.amount
            db[msg.to].balance = db[msg.to].balance + msg.amount
            save(db)
            print("Overføring: " .. msg.from .. " -> " .. msg.to .. " " .. msg.amount .. " kr")
            rednet.send(sender, {ok=true})
        end
    end
end

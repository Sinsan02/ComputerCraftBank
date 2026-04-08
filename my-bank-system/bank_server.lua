rednet.open("back")

local FILE = "bank.db"

-- LOAD
local function load()
    if not fs.exists(FILE) then return {} end
    local f = fs.open(FILE,"r")
    local data = textutils.unserialize(f.readAll())
    f.close()
    return data or {}
end

-- SAVE
local function save(db)
    local f = fs.open(FILE,"w")
    f.write(textutils.serialize(db))
    f.close()
end

local db = load()

print("Bank server startet")

while true do
    local sender,msg = rednet.receive()

    if msg.type == "get" then
        rednet.send(sender, db[msg.card])

    elseif msg.type == "create" then
        db[msg.card] = {balance=0,pin=msg.pin}
        save(db)
        rednet.send(sender,true)

    elseif msg.type == "deposit" then
        db[msg.card].balance += msg.amount
        save(db)
        rednet.send(sender,true)

    elseif msg.type == "withdraw" then
        if db[msg.card].balance >= msg.amount then
            db[msg.card].balance -= msg.amount
            save(db)
            rednet.send(sender,true)
        else
            rednet.send(sender,false)
        end
    end
end
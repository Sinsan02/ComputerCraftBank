rednet.open("back")

print("Turtle-bank klar (ID: " .. os.getComputerID() .. ")")

while true do
    local sender, msg = rednet.receive()

    if type(msg) == "table" and msg.type == "deposit" then
        -- Kun slot 1 er innskudd-innboks, resten er uttaks-reserve
        local count = 0
        local item = turtle.getItemDetail(1)
        if item and item.name == "minecraft:diamond" then
            count = turtle.getItemCount(1)
            -- Flytt fra innboks (slot 1) til reserve (slot 2-16)
            for slot = 2, 16 do
                if turtle.getItemCount(slot) == 0 then
                    turtle.select(1)
                    turtle.transferTo(slot, count)
                    break
                end
            end
        end
        print("Mottok innskudd: " .. count .. " diamanter")
        rednet.send(sender, count)

    elseif type(msg) == "table" and msg.type == "give" then
        local amount = math.floor(msg.amount)
        print("Gir ut " .. amount .. " diamanter...")

        local given = 0
        for i = 1, amount do
            -- Bruk kun slot 2-16 for uttak (slot 1 er innboks)
            local dropped = false
            for slot = 2, 16 do
                if turtle.getItemCount(slot) > 0 then
                    turtle.select(slot)
                    if turtle.drop(1) then
                        given = given + 1
                        dropped = true
                        break
                    end
                end
            end

            if not dropped then
                print("Advarsel: Tom for diamanter! Ga ut " .. given .. " av " .. amount)
                break
            end
        end

        print("Ferdig. Ga ut " .. given .. " diamanter.")
    end
end

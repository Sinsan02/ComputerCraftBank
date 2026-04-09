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
            local remaining = count
            turtle.select(1)
            -- Fyll opp eksisterende stacks med < 64 først
            for slot = 2, 16 do
                if remaining <= 0 then break end
                local slotItem = turtle.getItemDetail(slot)
                if slotItem and slotItem.name == "minecraft:diamond" then
                    local space = 64 - turtle.getItemCount(slot)
                    if space > 0 then
                        local toMove = math.min(remaining, space)
                        turtle.transferTo(slot, toMove)
                        remaining = remaining - toMove
                    end
                end
            end
            -- Fyll tomme slots med det som er igjen
            for slot = 2, 16 do
                if remaining <= 0 then break end
                if turtle.getItemCount(slot) == 0 then
                    turtle.transferTo(slot, remaining)
                    remaining = 0
                end
            end
        end
        print("Mottok innskudd: " .. count .. " diamanter")
        rednet.send(sender, count)

    elseif type(msg) == "table" and msg.type == "give" then
        local amount = math.floor(msg.amount)
        print("Gir ut " .. amount .. " diamanter...")

        local given = 0
        -- Bruk kun slot 2-16 for uttak (slot 1 er innboks)
        for slot = 2, 16 do
            if given >= amount then break end
            local inSlot = turtle.getItemCount(slot)
            if inSlot > 0 then
                local toGive = math.min(inSlot, amount - given)
                turtle.select(slot)
                turtle.drop(toGive)
                given = given + toGive
            end
        end

        if given < amount then
            print("Advarsel: Tom for diamanter! Ga ut " .. given .. " av " .. amount)
        else
            print("Ferdig. Ga ut " .. given .. " diamanter.")
        end
    end
end

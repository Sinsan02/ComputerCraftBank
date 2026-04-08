rednet.open("back")

print("Turtle-bank klar (ID: " .. os.getComputerID() .. ")")

while true do
    local _, msg = rednet.receive()

    if type(msg) == "table" and msg.type == "give" then
        local amount = math.floor(msg.amount)
        print("Gir ut " .. amount .. " diamanter...")

        local given = 0
        for i = 1, amount do
            -- Finn en slot med diamanter
            local dropped = false
            for slot = 1, 16 do
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

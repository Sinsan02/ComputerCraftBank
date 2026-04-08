rednet.open("back")

while true do
    local _,msg = rednet.receive()

    if msg.type == "give" then
        local amount = math.floor(msg.amount)

        for i=1,amount do
            turtle.select(1)
            turtle.drop()
        end
    end
end
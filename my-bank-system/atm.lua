rednet.open("back")

local diamondValue = 1000

-- UI
local function button(x,y,w,h,text)
    paintutils.drawFilledBox(x,y,x+w,y+h,colors.gray)
    term.setCursorPos(x+2,y+1)
    term.write(text)
end

local function click()
    local _,_,x,y = os.pullEvent("mouse_click")
    return x,y
end

local function getCard()
    local drive = peripheral.find("drive")
    if not drive then return nil end
    return drive.getDiskID()
end

local function askPIN()
    term.clear()
    print("Skriv PIN:")
    return read("*")
end

-- CREATE CARD
local function createCard()
    local drive = peripheral.find("drive")

    term.clear()
    print("Sett inn tom disk...")

    while not drive.isDiskPresent() do sleep(0.5) end

    print("Velg PIN:")
    local pin = read("*")

    local id = drive.getDiskID()

    drive.setDiskLabel("Bankkort #"..id)

    rednet.send(1,{type="create",card=tostring(id),pin=pin})
    rednet.receive()

    print("Kort laget!")
    sleep(2)
end

-- DEPOSIT
local function deposit(card)
    local chest = peripheral.find("inventory")
    local diamonds = 0

    for slot,item in pairs(chest.list()) do
        if item.name == "minecraft:diamond" then
            diamonds += item.count
            chest.removeItem(slot,item.count)
        end
    end

    local money = diamonds * diamondValue

    rednet.send(1,{type="deposit",card=card,amount=money})
    rednet.receive()
end

-- WITHDRAW
local function withdraw(card)
    term.clear()
    print("Beløp:")
    local amount = tonumber(read())

    rednet.send(1,{type="withdraw",card=card,amount=amount})
    local _,ok = rednet.receive()

    if ok then
        rednet.send(2,{type="give",amount=amount/1000})
    else
        print("Ikke nok penger")
        sleep(2)
    end
end

-- MENU
local function menu(balance)
    term.clear()
    print("Saldo:",balance,"kr")

    button(2,5,10,3,"Deposit")
    button(15,5,10,3,"Withdraw")
    button(2,10,10,3,"Lag kort")
    button(15,10,10,3,"Exit")
end

-- MAIN
while true do
    term.clear()
    print("Sett inn kort...")

    local card = getCard()

    if card then
        rednet.send(1,{type="get",card=tostring(card)})
        local _,data = rednet.receive()

        if not data then data = {balance=0,pin="0000"} end

        local pin = askPIN()

        if pin == data.pin then
            while true do
                menu(data.balance)
                local x,y = click()

                if y>=5 and y<=8 and x<=12 then
                    deposit(card)

                elseif y>=5 and y<=8 and x>=15 then
                    withdraw(card)

                elseif y>=10 and y<=13 and x<=12 then
                    createCard()

                elseif y>=10 and y<=13 and x>=15 then
                    break
                end

                rednet.send(1,{type="get",card=tostring(card)})
                _,data = rednet.receive()
            end
        else
            print("Feil PIN!")
            sleep(2)
        end
    end
end
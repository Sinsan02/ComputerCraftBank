local base = "https://raw.githubusercontent.com/Sinsan02/ComputerCraftBank/main/"

local files = {
    "bank_server",
    "atm",
    "turtle_bank"
}

for _,file in pairs(files) do
    print("Laster ned "..file)

    local res = http.get(base..file..".lua")

    if res then
        local f = fs.open(file,"w")
        f.write(res.readAll())
        f.close()
        res.close()
    else
        print("Feil med "..file)
    end
end

print("Ferdig!")
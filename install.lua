local base = "https://raw.githubusercontent.com/Sinsan02/ComputerCraftBank/main/"

local files = {
    "bank_server",
    "atm",
    "turtle_bank",
    "betaling"
}

for _, file in pairs(files) do
    print("Laster ned " .. file .. "...")

    local ok, res = pcall(http.get, base .. file .. ".lua")

    if ok and res then
        local f = fs.open(file .. ".lua", "w")
        f.write(res.readAll())
        f.close()
        res.close()
        print("  OK: " .. file .. ".lua")
    else
        print("  FEIL: Kunne ikke laste ned " .. file)
    end
end

print("")
print("Ferdig! Huusk aa sette riktige Computer-IDer i atm.lua")

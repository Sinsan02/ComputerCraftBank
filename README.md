# ComputerCraft Banksystem

Et fullstendig banksystem for Minecraft med ComputerCraft. Bruker diamanter som valuta og diskstasjoner som bankkort.

**1 diamant = 1 000 kr**

---

## Komponenter

| Fil | Rolle | Kjøres på |
|---|---|---|
| `bank_server.lua` | Sentral server – lagrer kontoer og håndterer transaksjoner | Vanlig datamaskin |
| `atm.lua` | Minibank med grafisk grensesnitt | Avansert datamaskin med skjerm |
| `turtle_bank.lua` | Håndterer fysiske diamanter ved innskudd/uttak | Turtle |
| `betaling.lua` | Betalingsterminal for overføring mellom to kort | Avansert datamaskin |
| `install.lua` | Laster ned alle filene automatisk fra GitHub | Hvilken som helst datamaskin |

---

## Kom i gang

### 1. Installer filene

Kjør dette på hver datamaskin du vil sette opp:

```lua
pastebin run <install-kode>
```

Eller last ned manuelt fra GitHub-repoet.

### 2. Finn Computer-IDer

Skriv `id` i terminalen på hver datamaskin for å finne IDen.

### 3. Konfigurer IDer

Åpne `atm.lua` og `betaling.lua` og oppdater:

```lua
-- I atm.lua
local SERVER_ID = 11   -- ID til bank_server
local TURTLE_ID = 2    -- ID til turtle_bank

-- I betaling.lua
local SERVER_ID = 5    -- ID til bank_server
```

### 4. Start serverne

**Bank-server** – kjør på en dedikert datamaskin med modem i `back`-porten:
```
bank_server
```

**Turtle-bank** – kjør på turtlen med modem i `back`-porten:
```
turtle_bank
```

**Minibank (ATM)** – kjør på avansert datamaskin med modem i `top`-porten og en disk-stasjon koblet til:
```
atm
```

**Betalingsterminal** – kjør på avansert datamaskin med modem i `back`-porten og to disk-stasjoner (venstre og høyre):
```
betaling
```

---

## Bruk

### Bankkort

Bankkort er vanlige disketter (floppy disks). Disk-IDen brukes som kontonummer.

### Opprette konto (ATM)

1. Sett inn en ny disk i ATM-en
2. Velg **"Lag kort"**
3. Gi kortet et navn og velg PIN-kode
4. Kontoen er opprettet med 0 kr saldo

### Sette inn penger (ATM)

1. Legg diamanter i **slot 1** på turtlen
2. Sett inn bankkortet i ATM-en og logg inn
3. Velg **"Sett inn"** – turtlen teller og lagrer diamantene

### Ta ut penger (ATM)

1. Sett inn bankkortet og logg inn
2. Velg **"Ta ut"** og oppgi antall diamanter
3. Turtlen slipper ut diamantene foran seg

### Betaling mellom kort

1. Sett betalerens kort i **venstre** disk-stasjon
2. Sett mottakerens kort i **høyre** disk-stasjon
3. Trykk Enter, skriv PIN og oppgi antall diamanter

### Bytte PIN-kode (ATM)

Logg inn og velg **"Bytt PIN"**. Skriv inn gammel PIN, deretter ny PIN to ganger.

---

## Nettverksoppsett

Alle enheter kommuniserer via Rednet (trådløse modemer).

```
[bank_server] ←── rednet ──→ [atm]
                         ↕
                    [turtle_bank]

[bank_server] ←── rednet ──→ [betaling]
```

- `bank_server`: modem i **back**
- `atm`: modem i **top**
- `turtle_bank`: modem i **back**
- `betaling`: modem i **back**

---

## Filstruktur

```
bank.db        – Lagres automatisk på bank_server (kontodata)
bank_server.lua
atm.lua
turtle_bank.lua
betaling.lua
install.lua
```

Kontodatabasen (`bank.db`) lagres automatisk og leses inn ved oppstart av serveren.

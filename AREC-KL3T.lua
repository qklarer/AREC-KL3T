local Debug = true
local TCPPort = 5080
local Connected = false
local startInitiate = false
local commandCount = 0
local initiateCounter = 0

NamedControl.SetPosition("Connected", 0)

local Commands =
{
    powerOff = { Hex = "55F0050173505730", Response = "" },
    powerOn = "55F0050173505731",
    Record = { Hex = "55F00401735243", Response = "#ST3" },
    setRecordPause = { Hex = "55F00401735053", Response = "#ST4" },
    setRecordStop = { Hex = "55F00401735350", Response = "#ST5" },
    getRecordState = "55F00401675354",
    ntfyRecordState = { Hex = "55F005016E535431", Response = "" },
    setPlayback1 = { Hex = "55F0050173504201", Response = "", Value = nil },
    setPlayback2 = { Hex = "55F0050173504202", Response = "", Value = nil },
    setPlayback3 = { Hex = "55F0050173504203", Response = "", Value = nil },
    setPlayback4 = { Hex = "55F0050173504204", Response = "", Value = nil },
    getLayout = { Hex = "55F00401674C4F", Response = "" }, -- Returns 01-FF
    getBackGround = { Hex = "55F00401674247", Response = "" }, -- Returns 00-FF
    getOverLay = { Hex = "55F00401674F4C", Response = "" }, -- Returns 00-FF
    getDisplayLayout = { Hex = "55F00401674450", Response = "" }, -- Returns 01-05
    NtfyLayout = { Hex = "55F005016E4C4F01", Response = "" }, -- Returns 01-FF
    NtfyBackGround = { Hex = "55F005016E424700", Response = "" }, -- Returns 00-FF
    NtfyOverlay = { Hex = "55F005016E4F4C01", Response = "" },
    NtfyDisplayLayout = { Hex = "55F005016E445001", Response = "" },
    getAudioVolInput = { Hex = "55F006016741564931", Response = "" }, -- Audio volume(0~125)
    getAudioVolOutput = { Hex = "55F006016741564F31", Response = "" },
    getAudioMuteInput = { Hex = "55F0060167414D4931", Response = "" },
    getAudioMuteOutput = { Hex = "55F0060167414D4F31", Response = "" },
    setStreamSourceURL = "",
    setSnapShot = { Hex = "55F00401735353", Response = "" },
    exportToUSB = { Hex = "55F0050173425530", Response = "#UC1" }
}

local commandsWithVariables = {
    setLayOut = { Hex = "55F00501734C4F", Response = "", Value = NamedControl.GetValue("setLayOut") }, --Needs Variables 00-22 (0-34)
    setOverlay = { Hex = "55F00501734F4C", Response = "", Value = NamedControl.GetValue("setOverlay") }, --Needs Variables 00-FF (0-255)
    setDisplayLayout = { Hex = "55F00501734450", Response = "", Value = NamedControl.GetValue("setDisplayLayout") }, --Needs Variables 01-05 (0-5)
    setTheme = { Hex = "55F00501735445", Response = "", Value = NamedControl.GetValue("setTheme"), }, --Needs Variables 01-FF (0-255)
    setAudioVolInput1 = { Hex = "55F007017341564931", Response = "", Value = NamedControl.GetValue("setAudioVolInput1") }, -- Needs Variables 00-7D (00-125)
    setAudioVolInput2 = { Hex = "55F007017341564932", Response = "", Value = NamedControl.GetValue("setAudioVolInput2") }, -- Needs Variables 00-7D (00-125)
    setAudioVolInput3 = { Hex = "55F007017341564935", Response = "", Value = NamedControl.GetValue("setAudioVolInput3") }, -- Needs Variables 00-7D (00-125)
    setAudioVolInput4 = { Hex = "55F007017341564940", Response = "", Value = NamedControl.GetValue("setAudioVolInput4") }, -- Needs Variables 00-7D (00-125)
    setAudioVolOutput1 = { Hex = "55F007017341564F31", Response = "", Value = NamedControl.GetValue("setAudioVolOutput1"), }, -- Needs Variables 00-7D (00-125)
    setAudioVolOutput2 = { Hex = "55F007017341564F32", Response = "", Value = NamedControl.GetValue("setAudioVolOutput2"), }, -- Needs Variables 00-7D (00-125)
    setAudioVolOutput3 = { Hex = "55F007017341564F33", Response = "", Value = NamedControl.GetValue("setAudioVolOutput3"), }, -- Needs Variables 00-7D (00-125)
    setAudioVolOutput4 = { Hex = "55F007017341564F34", Response = "", Value = NamedControl.GetValue("setAudioVolOutput4"), }, -- Needs Variables 00-7D (00-125)
    setBackground = { Hex = "55F00501734247", Response = "", Value = NamedControl.GetValue("setBackground") },
    inputMute1 = { Hex = "55F0070173414D4931", Response = "", Value = NamedControl.GetValue("inputMute1") },
    inputMute2 = { Hex = "55F0070173414D4932", Response = "", Value = NamedControl.GetValue("inputMute2") },
    inputMute3 = { Hex = "55F0070173414D4935", Response = "", Value = NamedControl.GetValue("inputMute3") },
    inputMute4 = { Hex = "55F0070173414D4940", Response = "", Value = NamedControl.GetValue("inputMute4") },
    outputMute1 = { Hex = "55F0070173414D4F31", Response = "", Value = NamedControl.GetValue("outputMute1") },
    outputMute2 = { Hex = "55F0070173414D4F32", Response = "", Value = NamedControl.GetValue("outputMute2") },
    outputMute3 = { Hex = "55F0070173414D4F33", Response = "", Value = NamedControl.GetValue("outputMute3") },
    outputMute4 = { Hex = "55F0070173414D4F34", Response = "", Value = NamedControl.GetValue("outputMute4") },
    setGUI = { Hex = "55F00501734847", Response = "", Value = NamedControl.GetValue("setGUI") },
    setStream1 = { Hex = "55F0060173534331", Response = "", Value = NamedControl.GetValue("setStream1") },
    setStream2 = { Hex = "55F0060173534332", Response = "", Value = NamedControl.GetValue("setStream2") },
    recordAndStream = { Hex = "55F00501735253", Response = "", Value = NamedControl.GetValue("recordAndStream") }
}

-- Convert string to hex
function string.tohex(str)
    return (str:gsub('.', function(c)
        return string.format('%02X', string.byte(c))
    end))
end

--- Convert hex <-> string
function string.fromhex(str)
    return (str:gsub('..', function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

sock = TcpSocket.New()
sock.ReadTimeout = 0
sock.WriteTimeout = 0
sock.ReconnectTimeout = 0

sock.Connected = function(TcpSocket)

    --handle the new Connection
    print("socket connected\r")
    startInitiate = true
    NamedControl.SetText("saveUSB", "Connecting...")
end

sock.Reconnect = function(TcpSocket)

    --handle the Reconnection attempt
    print("socket reconnecting...\r")
end

sock.Data = function(TcpSocket, data)

    --handle the data
    rxLine = sock:ReadLine(1)
    if (nil ~= rxLine) then
        if Debug then print("Got:\r" .. rxLine) end
        if rxLine == "#UC1" then
            NamedControl.SetText("saveUSB", "")
        end
    end
end

sock.Closed = function(TcpSocket)

    --handle the socket closing
    print("socket closed by remote\r")
end

sock.Error = function(TcpSocket, error)

    --handle the error
    print(string.format("Error: '%s'\r", error))
end

sock.Timeout = function(TcpSocket, error)

    --handle the Timeout
    print("socket closed due to timeout\r")
end

function Send(Cmd, Variable, controlName)

    if Debug then print(Cmd, Variable, controlName) end
    if Variable == nil then
        sock:Write(string.fromhex(Cmd .. "0D"))
    end

    if controlName == "exportToUSB" then
        NamedControl.SetText("saveUSB", "Do Not Remove\n USB Drive")
    end

    if Variable ~= nil then

        if controlName == "setAudioVolInput" or controlName == "setAudioVolOutput" then
            Variable = math.floor(Variable) - 1
        end

        if controlName == "setLayOut" or controlName == "setTheme" or controlName == "setPlayback" then
            Variable = Variable + 1
        end

        for i = 1, 4 do
            if controlName == "inputMute" .. i or controlName == "outputMute" .. i then
                if Variable == 0 then
                    Variable = 48
                elseif Variable == 1 then
                    Variable = 49
                end
            end
        end

        if controlName == "setGUI" then
            if Variable == 0 then
                Variable = 50
            elseif Variable == 1 then
                Variable = 49
            end
        end

        if controlName == "setStream1" or controlName == "setStream2" or controlName == "recordAndStream" then
            if Variable == 0 then
                Variable = 01
            elseif Variable == 1 then
                Variable = 02
            end
        end

        Variable = string.format("%x", Variable)

        if string.len(tostring(Variable)) < 2 then
            Variable = "0" .. Variable
        end
        if Debug then print(Cmd .. Variable .. "0D") end
        sock:Write(string.fromhex(Cmd .. Variable .. "0D"))
    end
end

function Initiate()

    initiateCounter = initiateCounter + 1

    if initiateCounter == 1 then
        NamedControl.SetText("saveUSB", "Connecting...")
        Send(commandsWithVariables["setLayOut"].Hex, commandsWithVariables["setLayOut"].Value, "setLayOut")
    elseif initiateCounter == 2 then
        Send(commandsWithVariables["setOverlay"].Hex, commandsWithVariables["setOverlay"].Value, "setOverlay")
    elseif initiateCounter == 3 then
        Send(commandsWithVariables["setDisplayLayout"].Hex, commandsWithVariables["setDisplayLayout"].Value,
            "setDisplayLayout")
    elseif initiateCounter == 4 then
        Send(commandsWithVariables["setTheme"].Hex, commandsWithVariables["setTheme"].Value, "setTheme")
    elseif initiateCounter == 5 then
        Send(commandsWithVariables["setAudioVolInput1"].Hex, commandsWithVariables["setAudioVolInput1"].Value,
            "setAudioVolInput1")
    elseif initiateCounter == 6 then
        Send(commandsWithVariables["setAudioVolInput2"].Hex, commandsWithVariables["setAudioVolInput2"].Value,
            "setAudioVolInput2")
    elseif initiateCounter == 7 then
        Send(commandsWithVariables["setAudioVolInput3"].Hex, commandsWithVariables["setAudioVolInput3"].Value,
            "setAudioVolInput3")
    elseif initiateCounter == 8 then
        Send(commandsWithVariables["setAudioVolInput4"].Hex, commandsWithVariables["setAudioVolInput4"].Value,
            "setAudioVolInput4")
    elseif initiateCounter == 9 then
        Send(commandsWithVariables["setAudioVolOutput1"].Hex, commandsWithVariables["setAudioVolOutput1"].Value,
            "setAudioVolOutput1")
    elseif initiateCounter == 10 then
        Send(commandsWithVariables["setAudioVolOutput2"].Hex, commandsWithVariables["setAudioVolOutput2"].Value,
            "setAudioVolOutput2")
    elseif initiateCounter == 11 then
        Send(commandsWithVariables["setAudioVolOutput3"].Hex, commandsWithVariables["setAudioVolOutput3"].Value,
            "setAudioVolOutput3")
    elseif initiateCounter == 12 then
        Send(commandsWithVariables["setAudioVolOutput4"].Hex, commandsWithVariables["setAudioVolOutput4"].Value,
            "setAudioVolOutput4")
    elseif initiateCounter == 13 then
        Send(commandsWithVariables["setBackground"].Hex, commandsWithVariables["setBackground"].Value, "setBackground")
    elseif initiateCounter == 14 then
        Send(commandsWithVariables["inputMute1"].Hex, commandsWithVariables["inputMute1"].Value, "inputMute1")
    elseif initiateCounter == 15 then
        Send(commandsWithVariables["inputMute2"].Hex, commandsWithVariables["inputMute2"].Value, "inputMute2")
    elseif initiateCounter == 16 then
        Send(commandsWithVariables["inputMute3"].Hex, commandsWithVariables["inputMute3"].Value, "inputMute3")
    elseif initiateCounter == 17 then
        Send(commandsWithVariables["inputMute4"].Hex, commandsWithVariables["inputMute4"].Value, "inputMute4")
    elseif initiateCounter == 18 then
        Send(commandsWithVariables["outputMute1"].Hex, commandsWithVariables["outputMute1"].Value, "outputMute1")
    elseif initiateCounter == 19 then
        Send(commandsWithVariables["outputMute2"].Hex, commandsWithVariables["outputMute2"].Value, "outputMute2")
    elseif initiateCounter == 20 then
        Send(commandsWithVariables["outputMute3"].Hex, commandsWithVariables["outputMute3"].Value, "outputMute3")
    elseif initiateCounter == 21 then
        Send(commandsWithVariables["outputMute4"].Hex, commandsWithVariables["outputMute4"].Value, "outputMute4")
    elseif initiateCounter == 22 then
        Send(commandsWithVariables["setGUI"].Hex, commandsWithVariables["setGUI"].Value, "setGUI")
    elseif initiateCounter == 23 then
        Send(commandsWithVariables["setStream1"].Hex, commandsWithVariables["setStream1"].Value, "setStream1")
    elseif initiateCounter == 24 then
        Send(commandsWithVariables["setStream2"].Hex, commandsWithVariables["setStream2"].Value, "setStream2")
    elseif initiateCounter == 25 then
        Send(commandsWithVariables["recordAndStream"].Hex, commandsWithVariables["recordAndStream"].Value,
            "recordAndStream")
        startInitiate = false
        Connected = true
        NamedControl.SetText("saveUSB", "")
    end

    for k, v in pairs(commandsWithVariables) do
        if NamedControl.GetValue(k) ~= commandsWithVariables[k].Value then
            local newValue = NamedControl.GetValue(k)
            Send(v.Hex, newValue, k)
            commandsWithVariables[k].Value = newValue
            commandCount = commandCount + 1
        end
    end
end

function TimerClick()

    if NamedControl.GetPosition("Connect") == 1 then
        sock:Connect(NamedControl.GetText("IP"), TCPPort)
        NamedControl.SetPosition("Connect", 0)
    end

    if startInitiate then
        Initiate()

    end

    if Connected then

        for k, v in pairs(Commands) do
            if NamedControl.GetPosition(k) == 1 then
                Send(v.Hex, nil, k)
                activeCommand = k
                NamedControl.SetPosition(k, 0)
                commandCount = commandCount + 1
            end
        end

        for k, v in pairs(commandsWithVariables) do
            if NamedControl.GetValue(k) ~= commandsWithVariables[k].Value then
                local newValue = NamedControl.GetValue(k)
                Send(v.Hex, newValue, k)
                commandsWithVariables[k].Value = newValue
                commandCount = commandCount + 1
            end
        end

        if sock.IsConnected and startInitiate == false then
            NamedControl.SetPosition("Connected", 1)
        else NamedControl.SetPosition("Connected", 0)
        end
    end
end

MyTimer = Timer.New()
MyTimer.EventHandler = TimerClick
MyTimer:Start(.25)

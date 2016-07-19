require "class"
local socket = require "socket"
local binser = require "binser"
local udp = socket.udp()
local port = 52135

udp:settimeout(0)
udp:setsockname('*', port)

local state = {} -- the empty world-state
local data, msg_or_ip, port_or_nil

local running = true
local nextId = 1

NetworkEntity = class()
function NetworkEntity:init(state)
    self.state = state or {}
end
local networkEntities = {}

Client = class()
function Client:init(ip, port)
    self.ip = ip
    self.port = port
end
function Client:send(data)
    udp:sendto(data, self.ip, self.port)
    print("sending "..data.." to "..self.ip..":"..self.port)
end
local clients = {}

function print_r (t)
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    sub_print_r(t,"  ")
end

print "Beginning server loop."
while running do
    bindata, msg_or_ip, port_or_nil = udp:receivefrom()
    if bindata then
        local ip, port = msg_or_ip, port_or_nil
        local client = clients[ip]
        if not client or port ~= client.port then
            client = Client(ip, port)
            clients[ip] = client
        end
        local cmd, data = binser.deserializeN(bindata, 2)
        if cmd == "requestId" then
            print ("requestId from "..msg_or_ip)
            local response = {}
            client.id = nextId
            nextId = nextId + 1
            response.id = client.id
            client.entity = NetworkEntity({x = 5088, y = 4000})
            networkEntities[client.id] = client.entity
            response.state = client.entity.state
            client:send(binser.serialize("assignId", response))
            print_r(response)
        elseif cmd == "updateState" then
            networkEntities[data.id].state = data.state
        else
            print("unrecognised command:", cmd)
        end
    elseif msg_or_ip ~= "timeout" then
        error("Unknown network error: "..tostring(msg))
    end
 
    socket.sleep(0.01)
end

print "Thank you."
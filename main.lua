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
function Client:init(ip)
    self.ip = ip
end
function Client:send(data)
    udp:sendto(data, self.ip, port)
end
local clients = {}

print "Beginning server loop."
while running do
    bindata, msg_or_ip, port_or_nil = udp:receivefrom()
    if bindata then
        local ip = msg_or_ip
        local client = clients[ip]
        if not client then
            client = new Client(ip)
            clients[ip] = client
        end
        local cmd, data = binser.deserializeN(bindata, 2)
        if cmd == "requestId" then
            local response = {}
            client.id = nextId
            nextId = nextId + 1
            response.id = client.id
            client.entity = NetworkEntity({x = 5088, y = 4000})
            networkEntities[id] = client.entity
            response.state = client.entity.state
            client:send(binser.serialize(response))
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
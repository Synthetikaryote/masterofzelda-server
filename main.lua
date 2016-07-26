require "class"
require "vector"
local socket = require "socket"
local binser = require "binser"

-- this isn't working.  working around vector serialization on the client
binser.register(getmetatable(vector), "vector", function(vec) return vec.x, vec.y end, function(x, y) return vector(x, y) end)
local udp = socket.udp()
local port = 52135
local lastDisconnectCheck = os.time()

udp:settimeout(0)
udp:setsockname('*', port)

local state = {} -- the empty world-state
local data, msg_or_ip, port_or_nil

local running = true
local nextId = 1

NetworkEntity = class()
function NetworkEntity:init(id, state)
    self.nid = id
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

function checkDisconnects()
    for k, v in pairs(clients) do
        if os.time() - v.lastCommunication > 10 then
            print("disconnecting client "..k)
            -- tell all the clients to remove the disconnected player
            for i, j in pairs(clients) do
                    j:send(binser.serialize("removeEntity", {nid=v.entity.nid}))
            end
            networkEntities[v.entity.nid] = nil
            clients[k] = nil
        end
    end
end

function main()
    print "Beginning server loop."
    while running do
        bindata, msg_or_ip, port_or_nil = udp:receivefrom()
        if bindata then
            local ip, port = msg_or_ip, port_or_nil
            local clientId = ip..":"..port
            local client = clients[clientId]
            if not client or port ~= client.port then
                client = Client(ip, port)
                clients[clientId] = client
            end
            client.lastCommunication = os.time()
            local cmd, data = binser.deserializeN(bindata, 2)
            if cmd == "requestId" then
                client.entity = NetworkEntity(nextId, data.state)
                
                print ("new client "..clientId.." assigned id "..client.entity.nid)
                nextId = nextId + 1
                -- send the new client all the entities
                for k, v in pairs(networkEntities) do
                    client:send(binser.serialize("newEntity", {nid=v.nid, state=v.state}))
                end
                -- send all the other clients the new player
                for k, v in pairs(clients) do
                    if v ~= client then
                        v:send(binser.serialize("newEntity", {nid=client.entity.nid, state=client.entity.state}))
                    end
                end
                -- add the client's entity to the entities
                networkEntities[client.entity.nid] = client.entity
                client:send(binser.serialize("assignId", {nid=client.entity.nid}))
            elseif cmd == "updateEntity" then
                networkEntities[data.nid].state = data.state
                -- send all the other clients the update
                for k, v in pairs(clients) do
                    if v ~= client then
                        v:send(binser.serialize("updateEntity", {nid=data.nid, state=data.state}))
                    end
                end
            else
                print("unrecognised command:", cmd)
            end
        elseif msg_or_ip ~= "timeout" then
            error("Unknown network error: "..tostring(msg))
        end

        if os.time() - lastDisconnectCheck > 1 then
            checkDisconnects()
            lastDisconnectCheck = os.time()
        end
     
        socket.sleep(0.01)
    end
    print "Server stopped."
end
main()
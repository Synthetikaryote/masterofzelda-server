EntityMap = class()
function EntityMap:init()
    self.xyMap = {}
    self.mapCharacters = {}
    self.bucketSize = vector(50,50)
    self.mapCharacters = {}
end
function EntityMap:updateEntity(entity)
    -- convert to map coordinates, putting characters in big map buckets
    local x = math.floor(entity.state.p.x / self.bucketSize.x)
    local y = math.floor(entity.state.p.y / self.bucketSize.y)
    local p = self.mapCharacters[entity.nid]
    -- only update them if they moved map buckets
    if p == nil or (p ~= nil and (p.x ~= x or p.y ~= y)) then
        -- if there was an entry for this character before, remove them from the map first
        self:removeFromMap(entity)
        -- create the bucket if needed
        if self.xyMap[y] == nil then self.xyMap[y] = {} end
        if self.xyMap[y][x] == nil then self.xyMap[y][x] = {} end
        -- assign the entity to the map, both forward and backward lookup
        self.xyMap[y][x][entity.nid] = entity
        self.mapCharacters[entity.nid] = vector(x, y)

        --[[
        if p ~= nil then
            print("entity "..entity.nid.." moved from "..p.x..", "..p.y.." to "..x..", "..y)
        else
            print("entity "..entity.nid.." was placed on the map at "..x..", "..y)
        end
        ]]
    end
end

function EntityMap:removeFromMap(entity)
    local p = self.mapCharacters[entity.nid]
    if p ~= nil then
        if self.xyMap[p.y] ~= nil and self.xyMap[p.y][p.x] ~= nil and self.xyMap[p.y][p.x][entity.nid] ~= nil then
            self.xyMap[p.y][p.x][entity.nid] = nil
        end
    end
    self.mapCharacters[entity.nid] = nil
end

function EntityMap:visitEntitiesInRect(topLeft, bottomRight, f)
    -- convert into map coordinates
    topLeft = vector(math.floor(topLeft.x / self.bucketSize.x), math.floor(topLeft.y / self.bucketSize.y))
    bottomRight = vector(math.floor(bottomRight.x / self.bucketSize.x), math.floor(bottomRight.y / self.bucketSize.y))
    for y = topLeft.y, bottomRight.y do
        if xyMap[y] then
            for x = topLeft.x, bottomRight.x do
                if xyMap[y][x] then
                    for k, v in pairs(xyMap[y][x]) do
                        f(v)
                    end
                end
            end
        end
    end
end

function EntityMap:visitEntitiesInRadius(p, r, f)
    visitCharsInRect(vector(p.x - r, p.y - r), vector(p.x + r, p.y + r), function(c)
        if (c.state.p - p):lenSq() < r * r then
            f(c)
        end
    end)
end
require "class"

vector = class()
function vector:init(x, y)
    self.x = x
    self.y = y
end
function vector:__add(o)
    return vector(self.x + o.x, self.y + o.y)
end
function vector:__sub(o)
    return vector(self.x - o.x, self.y - o.y)
end
function vector:__mul(o)
    return vector(self.x * o, self.y * o)
end
function vector:__div(o)
    return vector(self.x / o, self.y / o)
end
function vector:__unm()
    return vector(-self.x, -self.y)
end
function vector:lenSq()
    return self.x * self.x + self.y * self.y
end
function vector:len()
    return math.sqrt(self:lenSq())
end
function vector:normalized()
    return self / self:len()
end

-- local mt = getmetatable(vector)
-- mt._serialize = function()
--     return self.x, self.y
-- end
-- mt._deserialize = function(x, y)
--     return vector(x, y)
-- end
-- setmetatable(vector, mt)
--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Franklin Ader
    adereinstein1@gmail.com

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety)
    -- board positions
    self.gridX = x
    self.gridY = y


    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety

    self.shinyTile = false
    
    if self.color >= 19 then
        self.shinyTile = true
    end

    -- These flags will tell us if a match in which this tile is contained is vertical or else horizontal. 
    -- This will help generate a more appreciable particle system
    self.inVerticalMatch = false
    self.inHorizontalMatch = false

end

function Tile:update(dt)

end

--[[
    Function to swap this tile with another tile, tweening the two's positions.
]]
function Tile:swap(tile)

end

function Tile:render(x, y)
    -- draw shadow
    love.graphics.setColor(34, 32, 52, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles2'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles2'][self.color][self.variety],
        self.x + x, self.y + y)
end

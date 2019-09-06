--[[
    GD50
    Match-3 Remake

    -- PlayState Class --

    Author: Franklin Ader
    adereinstein1@gmail.com

    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until they exceed the number of points needed to get to the next level
    or until the time runs out, at which point they are brought back to the
    main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 255

    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)

    self.Psystem = { love.graphics.newParticleSystem(gTextures['particle1'], 64),
                        love.graphics.newParticleSystem(gTextures['particle2'], 64)
                    }
    for k, psystem in pairs(self.Psystem) do
        psystem:setParticleLifetime(2, 5)
        psystem:setSpin(400)
    end

    self.emitRedParticles = false
    self.emitYellowParticles = false
    self.emitParticlesX = 0
    self.emitParticlesY = 0
    self.emitY = 0
    
end

function PlayState:enter(params)
    -- grab level # from the params we're passed
    self.level = params.level

    -- spawn a board and place it toward the right
    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16, self.level)

    -- grab score from params if it was passed
    self.score = params.score or 0

    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 1.25 * 1000
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- go back to start if time runs out
    if self.timer <= 0 then
        -- clear timers from prior PlayStates
        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then
        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
        -- will also clear!
        Timer.clear()

        gSounds['next-level']:play()

        -- change to begin game state with new level (incremented)
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    --[[Timer.every (3,
        function()
            if not (self:matchesAvailable()) then
                gSounds['board-reset']:play()
                self.board = Board(VIRTUAL_WIDTH - 272, 16, self.level)
            end
        end
        )
        ]]
    if self.canInput then
        -- move cursor around based on bounds of grid, playing sounds
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end

        -- if we've pressed enter, to select or deselect a tile...
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            -- if same tile as currently highlighted, deselect
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            
            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                -- swap grid positions of tiles
                local tempX = self.highlightedTile.gridX
                local tempY = self.highlightedTile.gridY

                local newTile = self.board.tiles[y][x]

                self.highlightedTile.gridX = newTile.gridX
                self.highlightedTile.gridY = newTile.gridY
                newTile.gridX = tempX
                newTile.gridY = tempY

                -- swap tiles in the tiles table
                self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                    self.highlightedTile

                self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                if not (self.board:calculateMatches()) then
                    gSounds['error']:play()
                    -- Revert grid arrangement if the swap didn't result produce any match
                    tempX = newTile.gridX
                    tempY = newTile.gridY

                    newTile.gridX = x  -- or highlightedTile.gridX 
                    newTile.gridY = y  -- or highlightedTile.gridY

                    self.highlightedTile.gridX = tempX
                    self.highlightedTile.gridY = tempY

                    -- swap tiles in the tiles table
                    self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] = self.highlightedTile
                    self.board.tiles[newTile.gridY][newTile.gridX] = newTile
                
                    -- Reset highlited tile cursor
                    self.highlightedTile = nil

                else
                 
                    -- tween coordinates between the two so they swap
                    Timer.tween(0.2, {
                        [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                        [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                    })
                    -- once the swap is finished, we can tween falling blocks as needed
                    :finish(function()
                        self:calculateMatches()
                        end)
                end
            end
        end
    end

    Timer.update(dt)

    for k, psystem in pairs(self.Psystem) do
        psystem:update(dt)
    end

    if self.emitYellowParticles then
        self.Psystem[2]:emit(200)
        Timer.after(2, 
                function()
                    self.emitYellowParticles = false
                end )  
    elseif self.emitRedParticles then
        self.Psystem[1]:emit(200)
        Timer.after(2, 
                function()
                    self.emitRedParticles = false
                end ) 
    end
end

--[[
    Calculates whether any matches were found on the board and tweens the needed
    tiles to their new destinations if so. Also removes tiles from the board that
    have matched and replaces them with new randomized tiles, deferring most of this
    to the Board class.
]]
function PlayState:calculateMatches()
    self.highlightedTile = nil

    -- if we have any matches, remove them and tween the falling blocks that result
    local matches = self.board:calculateMatches()
    
    if matches then
        gSounds['match']:stop()
        gSounds['match']:play()


        for k, match in pairs(matches) do
            for l, matchTile in pairs(match) do
                self.score = self.score + (matchTile.variety * 50)
                
                if matchTile.color == 19 or matchTile.color == 20 then
                    gSounds['chain-match']:stop()
                    gSounds['chain-match']:play()
                    local color = 5
                    for k, psystem in pairs(self.Psystem) do
                            psystem:setColors (
                            paletteColors[color].r,
                            paletteColors[color].b,
                            paletteColors[color].g,
                            250,
                            paletteColors[color].r,
                            paletteColors[color].b,
                            paletteColors[color].g,
                            0
                    )
                    end
                    
                    if matchTile.inHorizontalMatch then
                        for k, psystem in pairs(self.Psystem) do
                            psystem:setAreaSpread('normal', 20, 5)
                            psystem:setLinearAcceleration(-20, 5, 20, -5)
                        end
                        self.emitParticlesX = self.board.x + (32 * 4)
                        self.emitParticlesY = self.board.y + matchTile.y + 16
                    end
                    if matchTile.inVerticalMatch then
                        for k, psystem in pairs(self.Psystem) do
                            psystem:setLinearAcceleration(-5, 20, 5, -20)
                            psystem:setAreaSpread('normal', 5, 20)
                        end
                        self.emitParticlesX = self.board.x + matchTile.x + 16 
                        self.emitParticlesY = self.board.y + (32 * 4)
                    end
                    
                    if matchTile.color == 19 then
                        --self.Psystem[1]:emit(100)
                        self.emitRedParticles = true
                    elseif matches.color == 20 then
                        --self.Psystem[2]:emit(100)
                        self.emitYellowParticles = true
                    end
                end
            end

            -- add score for each match and increase a timer by a second for every tile in the the matches
            self.timer = self.timer + #match
        end

        -- remove any tiles that matched from the board, making empty spaces
        self.board:removeMatches()

        -- gets a table with tween values for tiles that should now fall
        local tilesToFall = self.board:getFallingTiles(self.level)

        -- first, tween the falling tiles over 0.25s
        Timer.tween(0.25, tilesToFall):finish(function()
            local newTiles = self.board:getNewTiles()
            
            -- then, tween new tiles that spawn from the ceiling over 0.25s to fill in
            -- the new upper gaps that exist
            Timer.tween(0.25, newTiles):finish(function()
                -- recursively call function in case new matches have been created
                -- as a result of falling blocks once new blocks have finished falling
                self:calculateMatches()
            end)
        end)
    -- if no matches, we can continue playing
    else
        self.canInput = true
    end
end

function PlayState:matchesAvailable()

    local currentTile = nil
    local nextTile = nil
    local testBoard = Board(32, 32, 1)
    
    testBoard.tiles = {}
    for y = 1, 8 do
        table.insert(testBoard.tiles, {})  
        for x = 1, 8 do
            table.insert(testBoard.tiles[y], self.board.tiles[y][x])
        end
    end

    for y = 1, 8 do
        for x = 1, 8 do
            currentTile = testBoard.tiles[y][x]
            nextTile = testBoard.tiles[y][x]

            local directions = {
                [1] = 'up',
                [2] = 'right',
                [3] = 'down',    
                [4] = 'left'
              }

            for  k, direction in pairs(directions) do
                if direction == 'up' then
                    nextTile.gridY = math.max(1, y - 1)
                elseif direction == 'right' then
                    nextTile.gridX = math.max(8, x + 1)
                elseif direction == 'down' then
                    nextTile.gridY = math.min(y + 1, 8) 
                else
                    nextTile.gridY = math.max(1, x - 1)
                end

                if currentTile.gridX == nextTile.gridX and currentTile.gridY == nextTile.gridY then
                    nextTile.gridX = x
                    nextTile.gridY = y

                else
                
                    local tempX = self.nextTile.gridX
                    local tempY = self.nextTile.gridY
                    
                    nextTile.gridX = currentTile.gridX
                    nextTile.gridY = currentTile.gridY

                    currentTile.gridX = tempX
                    currentTile.gridY = tempY
                    testBoard.tiles[currentTile.gridY][currentTile.gridX] = currentTile
                    testBoard.tiles[nextTile.gridY][nextTile.gridX] = nextTile

                    if testBoard:calculateMatches() then
                        return true
                    else
                        -- Revert tiles and proceed to next direction
                        tempX = currentTile.gridX
                        tempY = currentTile.gridY

                        currentTile.gridX = x
                        currentTile.gridY = y

                        nextTile.gridX = tempX
                        nextTile.gridY = tempY

                        -- swap back tiles in the tiles table
                        testBoard.tiles[currentTile.gridY][currentTile.gridX] = currentTile
                        testBoard.tiles[nextTile.gridY][nextTile.gridX] = nextTile
                    end
                end
            end

           
        end

        if y == 8 then -- If row(y) = 8 and we reach hear, no match was found
            return false
        end

    end 

end
function PlayState:render()
    -- render board of tiles
    self.board:render()

    -- render highlighted tile if it exists
    if self.highlightedTile then
        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(255, 255, 255, 96)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217, 87, 99, 255)
    else
        love.graphics.setColor(172, 50, 50, 255)
    end

    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56, 56, 56, 234)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99, 155, 255, 255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')


    if self.emitRedParticles then
        love.graphics.draw(self.Psystem[1], self.emitParticlesX, self.emitParticlesY)
    elseif self.emitYellowParticles then
        love.graphics.draw(self.Psystem[2], self.emitParticlesX, self.emitParticlesY)
    end
end
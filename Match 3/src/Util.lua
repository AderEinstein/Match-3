--[[
    GD50
    Match-3 Remake

    -- StartState Class --

    Author: Franklin Ader
    adereinstein1@gmail.com

    Helper functions for writing Match-3.
]]

--[[
    Given an "atlas" (a texture with multiple sprites), generate all of the
    quads for the different tiles therein, divided into tables for each set
    of tiles, since each color has 6 varieties.
]]
function GenerateTileQuads(atlas)
    local tiles = {}

    local x = 0
    local y = 0

    local counter = 1

    -- 9 rows of tiles
    for row = 1, 10 do
        -- two sets of 6 cols, different tile varietes
        for i = 1, 2 do
            tiles[counter] = {}
            
            for col = 1, 6 do
                table.insert(tiles[counter], love.graphics.newQuad(
                    x, y, 32, 32, atlas:getDimensions()
                ))
                x = x + 32
            end

            counter = counter + 1
        end
        y = y + 32
        x = 0
    end

    return tiles
end

--[[
    Util function to return us a specified section of our tile sheet
]]
function table.slice(tbl, first, last, step)
    local sliced = {}
  
    for i = first, last, step do
        for j = 0, 1 do
            local counter = i + j
            sliced[counter] = tbl[counter]
        end
    end
  
    return sliced
end


function CalculateMatches(tiles)
   
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = tiles[y][1].color
 
        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            -- if this is the same color as the one we're trying to match...
            if tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                -- set this as the new color we want to watch for
                colorToMatch = tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}
                    if tiles[y][x-1].shinyTile then -- include entire row into the match
                        
                        for x2 = 1, 8 do
                            tiles[y][x2].inHorizontalMatch = true     -- Activate inHorizontalMatch flag
                            table.insert(match, tiles[y][x2])
                        end
                    else
                        -- go backwards from here by matchNum
                        for x2 = x - 1, x - matchNum, -1 do
                            tiles[y][x2].inHorizontalMatch = true     -- Activate inHorizontalMatch flag
                            -- add each tile to the match that's in that match
                            table.insert(match, tiles[y][x2])
                        end
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end

                matchNum = 1
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            
            if tiles[y][8].shinyTile then -- include entire row into the match
                
                for x2 = 1, 8 do
                    tiles[y][x2].inHorizontalMatch = true     -- Activate inHorizontalMatch flag
                    table.insert(match, tiles[y][x2])
                end
            else
                -- go backwards from end of last row by matchNum
                for x2 = 8, 8 - matchNum + 1, -1 do
                    tiles[y][x2].inHorizontalMatch = true     -- Activate inHorizontalMatch flag
                   table.insert(match, tiles[y][x2])
                end
            end

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    if tiles[y-1][x].shinyTile then -- include entire row into the match
                        
                        for y2 = 1, 8 do
                            tiles[y2][x].inVerticalMatch = true     -- Activate inVerticalMatch flag
                            table.insert(match, tiles[y2][x])
                        end
                    else
                        for y2 = y - 1, y - matchNum, -1 do
                            tiles[y2][x].inVerticalMatch = true     -- Activate inVerticalMatch flag
                            table.insert(match, tiles[y2][x])
                        end
                    end
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            
            if tiles[8][x].shinyTile then -- include entire row into the match
                for y2 = 1, 8 do
                    tiles[y2][x].inVerticalMatch = true     -- Activate inVerticalMatch flag
                    table.insert(match, tiles[y2][x])
                end
            else
                -- go backwards from end of last row by matchNum
                for y2 = 8, 8 - matchNum, -1 do
                    tiles[y2][x].inVerticalMatch = true     -- Activate inVerticalMatch flag
                    table.insert(match, tiles[y2][x])
                end
            end

            table.insert(matches, match)
        end
    end

    -- return matches table if > 0, else just return false
    return matches > 0 and matches or false
end




--[[
    Recursive table printing function.
    https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/
]]
function print_r ( t )
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
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end
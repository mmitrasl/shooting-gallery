function love.load()
    Sprites = {
        target = love.graphics.newImage('assets/target.png'),
        targetData = love.image.newImageData('assets/target.png'),
        sky = love.graphics.newImage('assets/sky.png'),
        crosshairs = love.graphics.newImage('assets/crosshairs.png'),
        crosshairsData = love.image.newImageData('assets/crosshairs.png'),
        hit_target = love.graphics.newImage('assets/target_hit.png') 
    }
        
    Sprites_dimensions = {
        targetRadius = Sprites.targetData:getDimensions()/2,
        crosshairsRadius = Sprites.crosshairsData:getDimensions()/2,
    }

    HeaderHeight = 35 -- height of header
    HitSoundEffect = love.audio.newSource("assets/bullet_hit_short.mp3", "static")
    GameFont = love.graphics.newFont(20)
    MenuFont = love.graphics.newFont(50)
    Score = 0
    TargetChangeState = 0 -- boolean to determine when to show shot target
    GameTimer = 0 -- set to 20 after user clicks mouse
    GameState = "Menu"
    love.mouse.setVisible(false)

    -- start the target in a random area
    
    RealTarget = {
        x = love.math.random(Sprites_dimensions.targetRadius, (love.graphics.getWidth() - Sprites_dimensions.targetRadius)),
        y = love.math.random(Sprites_dimensions.targetRadius + HeaderHeight, (love.graphics.getHeight() - Sprites_dimensions.targetRadius)),
        radius = Sprites_dimensions.targetRadius,
    }
end

function love.update(dt)
    -- when target is hit, start timer to transition target state
    if TargetChangeState > 0 then
        TargetChangeState = TargetChangeState + dt
    end
    
    if TargetChangeState > 1.35 then
        love.audio.stop() -- if the user hits the next target before the sound file finishes playing, it won't play on the next hit
        RealTarget.x = love.math.random(Sprites_dimensions.targetRadius, (love.graphics.getWidth() - Sprites_dimensions.targetRadius))
        RealTarget.y = love.math.random(Sprites_dimensions.targetRadius + HeaderHeight, (love.graphics.getHeight() - Sprites_dimensions.targetRadius))
        TargetChangeState = 0
    end

    if GameTimer > 0 then
        GameTimer = GameTimer - dt
    end

    if GameTimer <= 0 and GameState == "Play" then
        GameTimer = 0
        GameState = "Over"
    end
end

function love.draw()
    love.graphics.draw(Sprites.sky, 0, 0)

    -- header
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), HeaderHeight)
    love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(GameFont)
    love.graphics.print("Score: " .. Score, 30, 6)
    love.graphics.print("Timer: " .. math.ceil(GameTimer), 200, 6)

    if GameState == "Menu" then
        love.graphics.setFont(MenuFont)
        love.graphics.setColor(245/255, 66/255, 212/255)
        love.graphics.printf("Click to Start!", 0, 200, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
    elseif GameState == "Over" then
        love.graphics.setFont(MenuFont)
        love.graphics.setColor(245/255, 66/255, 212/255)
        love.graphics.printf("Your score was: " .. Score, 0, 200, love.graphics.getWidth(), "center")
        love.graphics.setFont(GameFont)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Click to play again!", 0, 270, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
    elseif GameState == "Play" and TargetChangeState > 1 then
        love.graphics.draw(Sprites.hit_target, (RealTarget.x - Sprites_dimensions.targetRadius), (RealTarget.y - Sprites_dimensions.targetRadius))
    else
        love.graphics.draw(Sprites.target, (RealTarget.x - Sprites_dimensions.targetRadius), (RealTarget.y - Sprites_dimensions.targetRadius))
    end

    -- The whole crosshairs stays in the playable area
    
    local coordinateX
    if (love.mouse.getX() - Sprites_dimensions.crosshairsRadius) < 0 then
        coordinateX = 0
    elseif (love.mouse.getX() + Sprites_dimensions.crosshairsRadius) > love.graphics.getWidth() then
        coordinateX = love.graphics.getWidth() - Sprites_dimensions.crosshairsRadius*2
    elseif (love.mouse.getX() - Sprites_dimensions.crosshairsRadius) >= 0 and (love.mouse.getX() <= (love.graphics.getWidth() - Sprites_dimensions.crosshairsRadius)) then
        coordinateX = love.mouse.getX() - Sprites_dimensions.crosshairsRadius
    end

    local coordinateY
    if (love.mouse.getY() - Sprites_dimensions.crosshairsRadius) < HeaderHeight then
        coordinateY = HeaderHeight
    elseif (love.mouse.getY() + Sprites_dimensions.crosshairsRadius) > love.graphics.getHeight() then
        coordinateY = love.graphics.getHeight() - Sprites_dimensions.crosshairsRadius*2
    elseif love.mouse.getY() + Sprites_dimensions.crosshairsRadius <= love.graphics.getHeight() and (love.mouse.getY() - Sprites_dimensions.crosshairsRadius >= HeaderHeight) then
        coordinateY = love.mouse.getY() - Sprites_dimensions.crosshairsRadius
    end

    love.graphics.draw(Sprites.crosshairs, coordinateX, coordinateY)
end

function love.mousepressed( x, y, button, istouch, presses )
    if GameState == "Play" then
        local mouseClick = calculateDistance(x, y, RealTarget.x, RealTarget.y)
        if mouseClick <= RealTarget.radius then -- if target hit
            HitSoundEffect:play()
            Score = Score + button -- if right click, add 2 points
            GameTimer = GameTimer - (button - 1) -- if right click, take off a second
            TargetChangeState = TargetChangeState + 1
        elseif mouseClick > RealTarget.radius and Score > 0 then -- if target missed
            Score = Score - 1
        else -- if score already 0, keep at 0
            Score = 0
        end
    elseif GameState == "Menu" or GameState == "Over" then
        GameTimer = 20
        Score = 0
        GameState = "Play"    
    end
end

function calculateDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end
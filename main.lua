require "TEsound"

function love.load()
    math.randomseed(os.time()) -- Creates random seed for math.random based on users computer time

    sprites = {}
    sprites.background = love.graphics.newImage("assets/sprites/background.png")
    sprites.bullet = love.graphics.newImage("assets/sprites/bullet.png")
    sprites.player = love.graphics.newImage("assets/sprites/player.png")
    sprites.zombie = love.graphics.newImage("assets/sprites/zombie.png")

    sprites.background:setWrap("repeat", "repeat")
    bg_quad = love.graphics.newQuad(0, 0, love.graphics.getWidth(), love.graphics.getHeight(), sprites.background:getWidth(), sprites.background:getHeight())

    player = {}
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() / 2
    player.speed = 240
    player.injured = false
    player.injuredSpeed = 270

    gameFont = love.graphics.newFont(35)
    scoreFont = love.graphics.newFont(25)

    zombies = {}
    bullets = {}

    score = 0
    gameState = 1
    maxTime = 2
    timer = maxTime
    maxZombieDelay = 0.3

    maxBullets = 2

    -- Instantiating audio
    bgm = love.audio.newSource("assets/audio/tracks/bg-music.mp3", "stream")
    -- Audio options
    bgm:setVolume(0.8)
    bgm:setLooping(true)

    bgm:play()
end

function love.update(dt)
    TEsound.cleanup()

    if gameState == 2 then
        local moveSpeed = player.speed
        if player.injured then
            moveSpeed = player.injuredSpeed
        end
        if love.keyboard.isDown("w") and player.y > 15 then
            player.y = player.y - moveSpeed * dt
        end
        if love.keyboard.isDown("a") and player.x > 15 then
            player.x = player.x - moveSpeed * dt
        end
        if love.keyboard.isDown("s") and player.y < (love.graphics.getHeight() - 15) then
            player.y = player.y + moveSpeed * dt
        end
        if love.keyboard.isDown("d") and player.x < (love.graphics.getWidth() - 15) then
            player.x = player.x + moveSpeed * dt
        end
    end

    for i,z in ipairs(zombies) do
        z.x  = z.x + (math.cos(zombiePlayerAngle(z)) * z.speed * dt)
        z.y = z.y + (math.sin(zombiePlayerAngle(z)) * z.speed * dt)

        if distanceBetween(z.x, z.y, player.x, player.y) < sprites.player:getWidth() then
            if player.injured == false then
                player.injured = true
                z.dead = true
            else
                for i,z in ipairs(zombies) do
                    zombies[i] = nil;
                    gameState = 1
                    player.injured = false
                    player.x = love.graphics.getWidth() / 2
                    player.y = love.graphics.getHeight() / 2
                end
            end
        end
    end

    for i,b in ipairs(bullets) do
        b.x  = b.x + (math.cos(b.direction) * b.speed * dt)
        b.y  = b.y + (math.sin(b.direction) * b.speed * dt)
    end

    for i=#bullets, 1, -1 do
        local b = bullets[i]
        if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end

    for i,z in ipairs(zombies) do
        for j,b in ipairs(bullets) do
            if distanceBetween(z.x, z.y, b.x, b.y) < 20 then
                z.dead = true
                b.dead = true
                score = score + 1
            end
        end
    end

    for i=#zombies, 1, -1 do
        local z = zombies[i]
        if z.dead == true then
            table.remove(zombies, i)
        end
    end

    for i=#bullets, 1, -1 do
        local b = bullets[i]
        if b.dead == true then
            table.remove(bullets, i)
        end
    end

    if gameState == 2 then
        timer = timer - dt
        if timer <= 0 then
            spawnZombie()
            timer = maxTime
            if maxTime > maxZombieDelay then
                maxTime = 0.95 * maxTime
            elseif maxTime <= maxZombieDelay then
                maxBullets = 5
            end
        end
    end
end

function love.draw()
    love.graphics.draw(sprites.background, bg_quad, 0, 0)

    if gameState == 1 then
        love.graphics.setFont(gameFont)
        love.graphics.printf("Click anywhere to start the game!", 0, 50, love.graphics.getWidth(), "center")
    end

    if player.injured == true then
        love.graphics.setColor(1, 0, 0)
    end

        love.graphics.draw(sprites.player, player.x, player.y,  playerMouseAngle(), nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)

    love.graphics.setColor(1, 1, 1)

        love.graphics.setColor(255, 255, 255)

        for i,z in ipairs(zombies) do
            love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
        end

        for i,b in ipairs(bullets) do
            love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.5, nil, sprites.bullet:getWidth() / 2, sprites.bullet:getHeight() / 2)
        end

        love.graphics.setFont(scoreFont)
        love.graphics.printf("Score: " .. score, 5, love.graphics.getHeight() - 35, love.graphics.getWidth(), nil)

        print(player.injured)
    end

    function love.mousepressed(x, y, button)
        if button == 1 and gameState == 2 then
            if #bullets < maxBullets then
                spawnBullet()
            end
        elseif button == 1 and gameState == 1 then
            gameState = 2
            maxTime = 2
            timer = maxTime
            score = 0
            maxBullets = 2
        end
    end

    function playerMouseAngle()
        return math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX()) + math.pi
    end

    function zombiePlayerAngle(enemy)
        return math.atan2(player.y - enemy.y, player.x - enemy.x)
    end

    function spawnZombie()
        local zombie = {}
        zombie.x = 0
        zombie.y = 0
        zombie.speed = 150
        zombie.dead = false

        local side = math.random(1,4)

        if side == 1 then       -- Left side of screen
            zombie.x = -30
            zombie.y = math.random(0, love.graphics.getHeight())
        elseif side == 2 then       -- Right side of screen
            zombie.x = love.graphics.getWidth() + 30
            zombie.y = math.random(0, love.graphics.getHeight())
        elseif side == 3 then       -- Top side of screen
            zombie.x = math.random(0, love.graphics.getWidth())
            zombie.y = -30
        elseif side == 4 then       -- Bottom side of screen
            zombie.x = math.random(0, love.graphics.getWidth())
            zombie.y = love.graphics.getHeight() + 30
        end
        table.insert(zombies, zombie)
    end

    function spawnBullet()
        local bullet = {}
        bullet.x = player.x
        bullet.y = player.y
        bullet.speed = 500
        bullet.dead = false
        bullet.direction = playerMouseAngle()

        table.insert(bullets, bullet)
        --    TEsound.play("assets/audio/sfx/gunshot.mp3", "static")
        TEsound.play("assets/audio/sfx/gunshot2.mp3", "static", nil, 1)
    end

    function distanceBetween(x1, y1, x2, y2)
        return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
    end
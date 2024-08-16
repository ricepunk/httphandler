---@class Router
local router = require 'server.router'

local players = {}
for i = 1, 100 do
  players[i] = {
    id = i,
    name = 'Player ' .. i,
    money = math.random(1, 1000),
    coords = { x = math.random(1, 1000), y = math.random(1, 1000), z = math.random(1, 1000) }
  }
end

router.get('/player', function(req, res)
  res.json(players)
end)

router.get('/player/:id', function(req, res)
  local id = tonumber(req.params.id)

  if not players[id] then
    res.writeHead(404)
    res.send('Player with id ' .. id .. ' not found')
    return
  end

  res.json(players[id])
end)

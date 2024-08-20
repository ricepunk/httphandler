---@class Router
local router = require 'server.router'

local players = {}
for i = 1, 100 do
  players[i] = {
    id = i,
    name = 'Player ' .. i,
    money = math.random(1, 100000)
  }
end

router:setAuth(function(req, res)
  local ip = req.address:match("([^:]+)")
  return ip == '127.0.0.1' or req.headers.Authorization == 'Basic 123456789'
end)

router:get('/players', function(req, res)
  res.sendJson(players)
end)

router:get('/players/(%d+)', function(req, res)
  local player = players[tonumber(req.params[1])]
  if not player then
    res.writeHead(404)
    res.send('Player not found')
    return
  end

  res.sendJson(players[tonumber(req.params[1])])
end)

router:put('/players', function(req, res)
  local body = req.readBody()
  if not body then
    res.writeHead(400)
    res.send('Missing body')
    return
  end

  body = json.decode(body)

  local count = #players
  players[count + 1] = {
    id = count + 1,
    name = body.name or ('Player %s'):format(count + 1),
    money = math.random(1, 100000)
  }

  res.sendJson(players[count + 1])
end)

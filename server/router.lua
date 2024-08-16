if not IsDuplicityVersion() then
  lib.print.error('Cannot load router module in client environment')
  return {}
end

--- @alias HTTPMethods 'GET'|'POST'|'PUT'|'DELETE'|

---@class HTTPRequest
--- @field path string
--- @field method HTTPMethods
--- @field address string
--- @field headers table<string,string>
--- @field setDataHandler fun(handler:fun(body: string):nil):nil
--- @field setCancelHandler fun(handler:fun():nil):nil
--- @field params? { [string]: any }

---@class HTTPResponse
---@field writeHead fun(statusCode: number, headers?: { [string]: string })
---@field write fun(data: string)
---@field send fun(data?: string)
---@field json fun(data: table)

---@class Router : OxClass
local Router = lib.class('Router')
local config = require 'config'
local APIKEY = config.APIKEY
local HOST = config.HOST

---@param path string
---@param url string
---@return boolean
---@return table?
local function matchRoute(path, url)
  local paramNames = {}

  local pattern = '^' .. path:gsub('(:%w+)', function(param)
    local paramName = param:sub(2)
    table.insert(paramNames, paramName)
    return '([^/]+)'
  end) .. '$'

  local matches = { url:match(pattern) }

  local params = {}
  if #matches > 0 then
    for i, paramName in ipairs(paramNames) do
      params[paramName] = matches[i]
    end

    return true, params
  end

  return false
end


---@param res HTTPResponse
---@param status number
local function cancelResponse(res, status)
  res.writeHead(status or 400)
  res.send()
end

function Router:constructor()
  local routes = lib.array:new()

  ---@param req HTTPRequest
  ---@param res HTTPResponse
  ---@return nil
  SetHttpHandler(function(req, res)
    if HOST then
      if req.address:match('([^:]+)') ~= HOST then
        return cancelResponse(res, 403)
      end
    end

    if APIKEY then
      local apiKey = req.headers['x-api-key']
      if apiKey ~= APIKEY then
        return cancelResponse(res, 401)
      end
    end

    local route = routes:find(function(route)
      if route.method ~= req.method then return false end
      local isMatch, params = matchRoute(route.path, req.path)

      if isMatch then
        req.params = params
      end

      return isMatch
    end)

    if not route then
      res.writeHead(404)
      res.send()
      return
    end

    res.json = function(data)
      res.writeHead(200, { ['Content-Type'] = 'application/json' })
      res.send(json.encode(data))
    end

    local success, result = pcall(route.callback, req, res)
    if not success then
      res.writeHead(500)
      res.send(result)
    end
  end)

  ---@param path string
  ---@param callback fun(req: HTTPRequest, res: HTTPResponse)
  self.get = function(path, callback)
    routes:push({ method = 'GET', path = path, callback = callback })
  end

  ---@param path string
  ---@param callback fun(req: HTTPRequest, res: HTTPResponse)
  self.put = function(path, callback)
    routes:push({ method = 'PUT', path = path, callback = callback })
  end

  ---@param path string
  ---@param callback fun(req: HTTPRequest, res: HTTPResponse)
  self.post = function(path, callback)
    routes:push({ method = 'POST', path = path, callback = callback })
  end

  ---@param path string
  ---@param callback fun(req: HTTPRequest, res: HTTPResponse)
  self.delete = function(path, callback)
    routes:push({ method = 'DELETE', path = path, callback = callback })
  end
end

return Router:new()

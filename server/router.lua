---@class HTTPRequest
---@field address string the IP address of the request sender
---@field headers table<string, string> the headers of the request
---@field method 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' the request method.
---@field path string the path to where the request was sent
---@field params? table<string, string> the query parameters of the request
---@field setDataHandler fun(handler: fun(body: string)) sets the handler for when the request is finished
---@field setCancelHandler fun(handler: fun()) sets the handler for when the request is finished
---@field readBody fun(): string reads the body of the request

---@class HTTPResponse
---@field writeHead fun(code: number, headers?: table<string, string>) sets the status code & headers of the response. Can be only called once and won't work if called after running other response functions.
---@field write fun(data: string) writes to the response body without sending it. Can be called multiple times.
---@field send fun(data?: string) writes to the response body and then sends it along with the status code & headers, finishing the request
---@field sendJson fun(data: string | table, code?: number) sends a json response along with the status code & headers, finishing the request

---@class Router : OxClass
local Router = lib.class('Router')

---@param reqPath string
---@param routePath string
---@return boolean
---@return table?
local function matchPath(reqPath, routePath)
  -- Check for an exact match
  reqPath = reqPath:gsub('/$', '')
  if reqPath == routePath then
    return true
  end

  -- Check for a pattern match
  local pattern = '^' .. routePath .. '$'
  local params = { reqPath:match(pattern) }
  if #params > 0 then
    return true, params
  end

  return false
end

function Router:constructor()
  self.routes = lib.array:new()

  ---@param req HTTPRequest
  ---@param res HTTPResponse
  SetHttpHandler(function(req, res)
    if self.auth then
      local success = self.auth(req, res)
      if not success then
        res.writeHead(401)
        res.send('Unauthorized')
        return
      end
    end

    local route = self.routes:find(function(route)
      if req.method ~= route.method then return false end

      local matched, params = matchPath(req.path, route.path)
      if params then
        req.params = params
      end

      return matched
    end)

    if not route then
      res.writeHead(404)
      res.send()
      return
    end

    req.readBody = function()
      local p = promise.new()
      if req.headers['Content-Length'] == '0' then
        p:resolve()
      end

      req.setDataHandler(function(body)
        p:resolve(body)
      end)

      req.setCancelHandler(function()
        p:reject()
      end)

      return Citizen.Await(p)
    end

    res.sendJson = function(data, code)
      ---@cast data string
      data = type(data) == 'table' and json.encode(data) or data
      res.writeHead(code or 200, { ['Content-Type'] = 'application/json' })
      res.send(data)
    end

    local success, result = pcall(route.cb, req, res)
    if not success then
      res.writeHead(500)
      res.send(result or 'Internal Server Error')
    end
  end)
end

---@param cb fun(request: HTTPRequest, response: HTTPResponse): boolean
function Router:setAuth(cb)
  self.auth = cb
end

---@param path string
---@param cb fun(request: HTTPRequest, response: HTTPResponse)
function Router:get(path, cb)
  self.routes:push({ method = 'GET', path = path, cb = cb })
end

---@param path string
---@param cb fun(request: HTTPRequest, response: HTTPResponse)
function Router:put(path, cb)
  self.routes:push({ method = 'PUT', path = path, cb = cb })
end

return Router:new()

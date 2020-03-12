local jwt = require("resty.jwt")
local redis = require("resty.redis")
local cjson = require("cjson")
local red = redis:new()
local cip = client_ip
red:set_timeout(1000)
local ip = "127.0.0.1"
local port = 6379
local ok, err = red:connect(ip, port)

if not ok then
    ngx_log(ngx_ERR, "connect to redis error :", err)
    return
end

local headers = ngx.req.get_headers()
local token = headers['token']

if not token then 
    ngx.status = 400
    ngx.say("cannot get token")
    return 
end 

local jwt_obj = jwt:verify("lua-resty-jwt", token)

local payload = jwt_obj['payload']
local username = payload['name']
local str = payload['token']

local resp, err = red:get(username)
if not resp then
    ngx.say("invalid token")
    ngx.status = 400
    return
end

if resp == ngx.null then
    ngx.say("invalid token")
    ngx.status = 400
    return
end


if resp ~= str then
    ngx.say("invalid token3")
    ngx.status = 400
    return
end

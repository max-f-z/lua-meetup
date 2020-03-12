local jwt = require("resty.jwt")
local cjson = require("cjson")
local uuid = require("resty.uuid")
local redis = require("resty.redis")

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

if ngx.req.get_method() ~= 'POST' then
    ngx.status = 405
    ngx.log(ngx.ERR, "method not allowed")
    ngx.say("method not allowed")
    return
end

ngx.req.read_body()
local body_raw = ngx.req.get_body_data()
local body_json = cjson.decode(body_raw)
local username = body_json['username']
local password = body_json['password']

if not username or not password then
    ngx.log(ngx.ERR, "Empty username or password :", username, password)
    ngx.status = 400
    ngx.say("empty username or password")
    return
end

if username == "alex" and password == "superstrong" then
    local str = uuid.generate()
    local jwt_token = jwt:sign(
                    "lua-resty-jwt",
                    {
                        header={typ="JWT", alg="HS256"},
                        payload={token=str,name=username}
                    }
                )    
    ngx.status = 200
    ngx.say(jwt_token)
    red:set(username, str)
    red:expire(username, 120)
    return
end

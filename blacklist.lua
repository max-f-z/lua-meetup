local redis = require("resty.redis")
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_INFO = ngx.INFO
local ngx_exit = ngx.exit
local ngx_var = ngx.var

local function get_black_ip(red, client_ip)
    local resp, err = red:get(client_ip)
    if not resp then
        return false
    end
    if resp == ngx.null then
        return false
    end
    if tonumber(resp) > 4 then
        red:expire(client_ip, 60)
        return true
    else
        return false
    end
end

local function add_black_ip(red, ip)
    local resp, err = red:get(ip)
    if (not resp) or (resp == ngx.null) then
        red:set(ip, 1)
        red:expire(ip, 60)
    else
        red:set(ip, resp+1)
        red:expire(ip, 60)
    end
end

local red = redis:new()
local cip = client_ip
red:set_timeout(1000)
local ip = "127.0.0.1"
local port = 6379
local ok, err = red:connect(ip, port)
if not ok then
    ngx_log(ngx_ERR, "connect to redis error :", err)
    return
else
    local ccip = ngx_var.remote_addr
    if get_black_ip(red, ccip) then
        ngx_log(ngx_INFO, "block ip request: ", ccip)
        return ngx_exit(ngx.HTTP_FORBIDDEN)
    else
        add_black_ip(red, ccip)
    end
end
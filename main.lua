ds18b20 = require("ds18b20")

broker = "pihc"     -- IP or hostname of MQTT broker
mqttport = 1883          -- MQTT port (default 1883)
userID = ""              -- username for authentication if required
userPWD  = ""            -- user password if needed for security
clientID = "ESP8266_test"        -- Device ID
GPIO2 = 4                -- IO Index of GPIO2 which is connected to an LED
count = 0                -- Test number of mqtt_do cycles
mqtt_state = 0           -- State control

ds18b20.setup(GPIO2)
addrs=ds18b20.addrs()
print(table.getn(addrs))
temp=ds18b20.read(addrs[1], ds18b20.F)
print(temp)

function ds18b20_scan()
    ds18b20 = require("ds18b20")
    ds18b20.setup(GPIO2)
    addrs=ds18b20.addrs()
    print(table.getn(addrs))
    temp=ds18b20.read(addrs[1], ds18b20.F)
    print(temp)
    ds18b20 = nil
    package.loaded["ds18b20"]=nil
    return temp
end

function mqtt_do()
     count = count + 1  -- For testing number of interations before failure
     
     if mqtt_state < 5 then
          mqtt_state = wifi.sta.status() --State: Waiting for wifi

     elseif mqtt_state == 5 then
          m = mqtt.Client(clientID, 120, userID, userPWD)
          m:connect( broker , mqttport, 0,
          function(conn)
               print("Connected to MQTT:" .. broker .. ":" .. mqttport .." as " .. clientID )
               mqtt_state = 20 -- Go to publish state              
          end)

     elseif mqtt_state == 20 then
          mqtt_state = 25 -- Publishing...
          temp = ds18b20_scan()
          m:publish("/temperature/"..clientID,"Temperature: "..temp.." F", 0, 0,
          function(conn)
              -- Print confirmation of data published
              print(" Sent message #"..count.."\nTemp:"..temp.."\npublished!")
              mqtt_state = 20  -- Finished publishing - go back to publish state.
          end)
     else print("Publishing..."..mqtt_state)
          mqtt_state = mqtt_state - 1  -- takes us gradually back to publish state to retry
     end

end

-- release module
ds18b20 = nil
package.loaded["ds18b20"]=nil

tmr.alarm(0, 10000, 1, function() mqtt_do() end) -- convert 10000 to dynamic variable
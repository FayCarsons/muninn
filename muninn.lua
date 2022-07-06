--
--WORK IN PROGRESS !
--trigger pattern mutator
--input 1 = clock
--input 2 = mutate
--outputs 1-4 trigger or envelope outputs, to articulate musical events


--require lume.lua 
local lume = include("lib/lume")

--table of parameter options
boptions = {'trig','env'}

--initialize 2d table to store trigger patterns
tr = {{},{},{},{}}
count = 0

slice_weight = 5
map_weight = 5
rnd_weight = 5
xor_weight = 5
scramble_weight = 5

function init()
    --configure crow inputs and outputs
    crow.input[1].change('act',1,0.1,'rising')
    crow.input[2].change('mutate',1,0.1,'rising')
    
    --adding menu parameter to choose between outputting triggers and envelopes, 
    --and attaching a function to it
    params:add_option('outs','outs',boptions,1)

    --add params for envelope release times and amplitude
    for i = 1,4 do
      params:add_control('amp' .. i, 'amp' .. i,controlspec.new(3,8,'lin',0.01,5,'v'))
      
      params:add_control('dec' .. i, 'dec' .. i,controlspec.new(0.05,0.5,'lin',0.01,0.15,'s'))
    end  

    --populate trigger tables w/ booleans
    for i = 1,4 do
        for t = 1,16 do
            tr[i][t] = toss()
        end
    end  

  clock.run(act)  
end

function act()
  while true do
    count = (count+1)%16
    local out_state = params:string('outs')
    if (out_state == 'trig') then
      for i = 1,4 do
        if (tr[i][count+1]) then 
          crow.output[i].pulse(0.1,5,1) 
        end
      end
    elseif (out_state == 'env') then
      for i = 1,4 do
        if (tr[i][count+1]) then 
          crow.output[i].ar(0,decay(i),env_amp(i),'linear') 
        end
      end
    else
      
    end
    clock.sync(4)
    --print(out_state)
  end  
end
  
function toss() 
  if (math.random() > 0.5) then
    coin = not coin
  end
  return coin
end  

function decay(channel)
  return params:get('dec' .. channel)
end  

function env_amp(channel)
  return params:get('amp' .. channel)
end

function mutate()
  return 1 + 1
end  

--trigger pattern mutation functions

function randomize_trigs(channel)
  for i = 1,16 do
      tr[channel][i] = toss()
  end
end  

function slice(a,b)
  for i = 8,16 do
    tr[a][i],tr[b][i-8] = tr[b][i],tr[a][i-8]
  end
end    

function xor(a,b)
  for i = 1,16 do
    tr[a][i] = tr[a][i] ~ tr[b][i]
  end
end  

function scramble()
  for i = 1,8 do
    for c = 1,3 do
      tr[c][i] = tr[c+1][i+8]
    end
    tr[4][i] = tr[1][i+8]
  end
end   

function ftable()
  return lume.weightedchoice({
    slice = slice_weight,
    map = map_weight,
    randomize_trigs = rnd_weight,
    xor = xor_weight,
    scramble = scramble_weight})
  end    


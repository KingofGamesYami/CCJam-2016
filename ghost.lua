os.loadAPI( "commandsPlus" )

local tPlayers = commandsPlus.getNearbyPlayers( 10 )
if #tPlayers == 0 then
	error( "not in range", 0 )
elseif #tPlayers > 1 then
	error( "too many players in range", 0 )
end
local playerName = tPlayers[ 1 ]
commands.scoreboard( "objectives add __click trigger clicky" )
commands.scoreboard( "players add", playerName )
commands.scoreboard( "players enable", playerName, "__click" )

function selectArea()
  commands.scoreboard( "players reset", playerName, "__click" )
  commands.scoreboard( "players enable", playerName, "__click" )
  commands.gamerule( "commandBlockOutput false" )
  commands.tellraw( playerName, '["",{"text":"Select point #1","underlined":true,"clickEvent":{"action":"run_command","value":"/trigger __click set 1"}}]' )
  while true do
  	local ok, result = commands.scoreboard( "players test", playerName, "__click 1 1" )
  	if result[ 1 ]:match( "is in range" ) then
  		break
  	end
  	sleep( 0.1 )
  end
  commands.scoreboard( "players enable", playerName, "__click" )
  local x, y, z = commandsPlus.getObservedBlock( playerName )
  print( "X: " .. x )
  print( "Y: " .. y )
  print( "Z: " .. z )
  commands.tellraw( playerName, '["",{"text":"Select point #2","underlined":true,"clickEvent":{"action":"run_command","value":"/trigger __click set 2"}}]' )
  while true do
  	local ok, result = commands.scoreboard( "players test", playerName, "__click 2 2" )
  	if result[ 1 ]:match( "is in range" ) then
  		break
  	end
  	sleep( 0.1 )
  end
  local x2, y2, z2 = commandsPlus.getObservedBlock( playerName )
  print( "X2: " .. x2 )
  print( "Y2: " .. y2 )
  print( "Z2: " .. z2 )
  commands.gamerule( "commandBlockoutput true" )
  return x, y, z, x2, y2, z2
end


function merge(t1, t2) --http://stackoverflow.com/a/7470789
    for k, v in pairs(t2) do
        if (type(v) == "table") and (type(t1[k] or false) == "table") then
            merge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

function scanArea( x1, y1, z1, x2, y2, z2 )
	local minx, miny, minz = math.min( x1, x2 ), math.min( y1, y2 ), math.min( z1, z2 )
	local maxx, maxy, maxz = math.max( x1, x2 ), math.max( y1, y2 ), math.max( z1, z2 )
	local tAllInfo = {}
	parallel.waitForAll( function()
		for ix = minx, maxx, 16 do
			for iy = miny, maxy, 16 do
				for iz = minz, maxz, 16 do
					local t = commandsPlus.getFormattedBlockInfos( ix, iy, iz, math.min( ix + 15, maxx ), math.min( iy + 15, maxy ), math.min( iz + 15, maxz ) )
					tAllInfo = merge( tAllInfo, t )
				end
			end
		end
	end, function()
		for ix = minx, maxx do
			for iy = miny, maxy do
				for iz = minz, maxz do
					local ok, result = commands.blockdata( ix, iy, iz, {} )
          if result[ 1 ]:match( "did not change" ) then
            tAllInfo[ ix ][ iy ][ iz ].blockdata = result[ 1 ]:match( "change: (.+)" ):gsub( "[xyz]:%-?%d+,", "" )
          end
          commands.setblock( ix, iy, iz, "minecraft:air" )
				end
			end
		end
	end )
	return tAllInfo
end

local info = scanArea( selectArea() )
local file = fs.open( ".ghost", "w" )
file.write( textutils.serialize( info ) )
file.close()

sleep( 1 )

for ix, t in pairs( info ) do
  for iy, t2 in pairs( t ) do
    for iz, info in pairs( t2 ) do
      commands.setblock( ix, iy, iz, info.name, info.metadata, "replace", info.blockdata )
    end
  end
end

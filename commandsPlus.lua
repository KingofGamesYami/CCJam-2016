local ok, result = commands.testfor( "@e[type=ArmorStand,name=pData]" )
if not result[ 1 ] then
  commands.summon( "ArmorStand ~ ~ ~ {CustomName:pData,Invisible:1b,NoGravity:1b}" )
end

local lastPlayer, lastPlayerPosition, lastPlayerNBT = "", {}, {}, {}

function getPlayerPosition( playerName )
  if playerName == lastPlayer and lastPlayerPosition.time == os.time() then
    return unpack( lastPlayerPosition )
  end
  commands.tp( "@e[type=ArmorStand,name=pData] " .. playerName )
  local ok, result = commands.execute( playerName .. " ~ ~ ~ tp @e[type=ArmorStand,name=pData] ~ ~2 ~" )
  lastPlayer = playerName
  local x, y, z = result[1]:match( "to (%S+), (%S+), (%S+)" )
  lastPlayerPosition = { tonumber( x ), tonumber( y ) - 2, tonumber( z ), time = os.time()}
  return tonumber( x ), tonumber( y ) - 2, tonumber( z )
end

local function getPlayerNBT( playerName )
  if lastPlayer == playerName and lastPlayerNBT.time == os.time() then
    return unpack( lastPlayerNBT )
  end
  commands.tp( "@e[type=ArmorStand,name=pData] " .. playerName )
  commands.execAsync( "/execute " .. playerName .. " ~ ~ ~ tp @e[type=ArmorStand,name=pData] ~ ~2 ~" )
  local ok, result = commands.entitydata( "@e[type=ArmorStand,name=pData] {}" )
  lastPlayerNBT = {result[ 1 ], time = os.time()}
  return result[ 1 ]
end

function getPlayerRotation( playerName )
  local a, b = getPlayerNBT( playerName ):match( "Rotation:%[0:(%S-)f,1:(%S+)f,%]" )
  return tonumber( a ), tonumber( b )
end

function getNearbyPlayers( nLimit )
  local ok, result
  if nLimit then
    ok, result = commands.testfor( "@a[r=" .. tostring( nLimit ) .. "]" )
  else
    ok, result = commands.testfor( "@a" )
  end
  local tPlayers = {}
  for k, v in pairs( result ) do
    tPlayers[ k ] = v:match( "Found (.+)" )
  end
  return tPlayers
end

function getGameruleValue( gamerule )
  local ok, result = commands.gamerule( gamerule )
  local v = result[ 1 ]:match( "= (.+)" )
  if v == "true" then return true
  elseif v == "false" then return false
  else return tonumber( v ) or v end
end

function getDaysPassed()
  local ok, result = commands.time( "query day" )
  return tonumber( result[ 1 ]:match( "is (%S+)" ) )
end

function getGametime()
  local ok, result = commands.time( "query gametime" )
  return tonumber( result[ 1 ]:match( "is (%S+)" ) )
end

function getDaytime()
  local ok, result = commands.time( "query daytime" )
  return tonumber( result[ 1 ]:match( "is (%S+)" ) )
end

function getWorldborder()
  local ok, result = commands.worldborder( "get" )
  return tonumber( result[ 1 ]:match( "%d+" ) )
end

function getFormattedBlockInfos( x, y, z, x2, y2, z2 )
  --find the minimum and maximum verticies
  local minx, miny, minz = math.floor( math.min( x, x2 ) ), math.floor( math.min( y, y2 ) ), math.floor( math.min( z, z2 ) )
  local maxx, maxy, maxz = math.floor( math.max( x, x2 ) ), math.floor( math.max( y, y2 ) ), math.floor( math.max( z, z2 ) )

  local tBlockInfos = commands.getBlockInfos( minx, miny, minz, maxx, maxy, maxz )
  local tFormattedBlockInfos = {}
  local iTablePosition = 1

  for iy = miny, maxy do
    for iz = minz, maxz do
      for ix = minx, maxx do
        tFormattedBlockInfos[ ix ] = tFormattedBlockInfos[ ix ] or {}
        tFormattedBlockInfos[ ix ][ iy ] = tFormattedBlockInfos[ ix ][ iy ] or {}
        tFormattedBlockInfos[ ix ][ iy ][ iz ] = tBlockInfos[ iTablePosition ]
        iTablePosition = iTablePosition + 1
      end
    end
  end
  return tFormattedBlockInfos
end

local tIgnoredBlocks = {
  ["minecraft:air"] = true,
  ["minecraft:water"] = true,
  ["minecraft:flowing_water"] = true,
  ["minecraft:lava"] = true,
  ["minecraft:flowing_lava"] = true,
}

function getObservedBlock( playerName )
  --credit to moomoomoo3O9 (http://www.computercraft.info/forums2/index.php?/user/23178-moomoomoo3o9/) for the original function
  --which I have modified in order to restrict the results to the actual reach of the player, and utilize getBlockInfos
  local rotationx, rotationy = getPlayerRotation( playerName )
  local px, py, pz = getPlayerPosition( playerName )
  py = py + 1.62 --#The player's eyes are 1.62 blocks from the ground
  --Convert pitch/yaw into Vec3 from http://stackoverflow.com/questions/10569659/camera-pitch-yaw-to-direction-vector
  local xzLen=-math.cos(math.rad(rotationy))
  local x, y, z = xzLen * math.sin( -math.rad( rotationx+180 ) ), math.sin( math.rad( -rotationy ) ), xzLen * math.cos( math.rad( rotationx + 180 ) )

  local maxProjectedLength = 5

  local tBlockInfos = getFormattedBlockInfos( px, py, pz, (x * maxProjectedLength) + px, (y * maxProjectedLength) + py, (z * maxProjectedLength) + pz )

  local lastX, lastY, lastZ, skip
  for mult = 0, maxProjectedLength - 1, 0.05 do  --Extend the vector linearly
    local currX,currY,currZ= math.floor( (x*mult )+px ), math.floor( (y*mult)+py ), math.floor( (z*mult)+pz )
    skip = lastX and currX == lastX and currY== lastY and currZ == lastZ
    if not skip and not tIgnoredBlocks[ tBlockInfos[ currX ][ currY ][ currZ ].name ] then
      return currX, currY, currZ
    end
    lastX,lastY,lastZ=currX,currY,currZ
  end
end

function getForgeTPS()
  local ok, result = commands.forge( "tps" )
  local t = {}
  for k, v in pairs( result ) do
    local dim, time, tps = v:match( "D?i?m? ?(%S+).-time\\?: (%S+).-TPS\\?: (%S+)" )
    t[ tonumber( dim ) or dim ] = { time = tonumber( time ), tps = tonumber( tps ) }
  end
  return t
end

function listScoreboardTeams()
  local ok, result = commands.scoreboard( "teams list" )
  if not ok then return {} end
  local t = {}
  table.remove( result, 1 )
  for k, v in pairs( result ) do
    t[ v:match( "%- (%S+):" ) ] = v:match( "has (%d+)" )
  end
  return t
end

function listScoreboardObjectives()
  local ok, result = commands.scoreboard( "objectives list"  )
  local t = {}
  table.remove( result, 1 )
  for k, v in pairs( result ) do
    local name, displayname, objectivetype = v:match( "%- (%S+):.- '(.-)'.-type '(.-)'" )
    t[ name ] = {displayName = displayname, type = objectivetype}
  end
end

function listScoreboardPlayers()
  local ok, result = commands.scoreboard( "players list" )
  table.remove( result, 1 )
  return result
end

function listScoreboardTeamPlayers( teamName )
  local ok, result = commands.scoreboard( "teams list " .. teamName )
  table.remove( result, 1 )
  return result
end

os.loadAPI( "commandsPlus" )
commands.scoreboard( "objectives add __click trigger clicky" )
commands.scoreboard( "players add @p" )
commands.scoreboard( "players enable @p __click" )

function selectArea()
	commands.scoreboard( "players reset @p __click" )
  commands.scoreboard( "players enable @p __click" )
  commands.gamerule( "commandBlockOutput false" )
  commands.tellraw( '@p ["",{"text":"Select point #1","underlined":true,"clickEvent":{"action":"run_command","value":"/trigger __click set 1"}}]' )
  while true do
  	local ok, result = commands.scoreboard( "players test @p __click 1 1" )
  	if result[ 1 ]:match( "is in range" ) then
  		break
  	end
  	sleep( 0.1 )
  end
  commands.scoreboard( "players enable @p __click" )
  local x, y, z = commandsPlus.getObservedBlock( "@p" )
  commands.tellraw( '@p ["",{"text":"Select point #2","underlined":true,"clickEvent":{"action":"run_command","value":"/trigger __click set 2"}}]' )
  while true do
  	local ok, result = commands.scoreboard( "players test @p __click 2 2" )
  	if result[ 1 ]:match( "is in range" ) then
  		break
  	end
  	sleep( 0.1 )
  end
  local x2, y2, z2 = commandsPlus.getObservedBlock( "@p" )
  commands.gamerule( "commandBlockoutput true" )
  return x, y, z, x2, y2, z2
end

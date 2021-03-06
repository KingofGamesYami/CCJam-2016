local tCommandsToExecute = {}

function addCommand( str )
	tCommandsToExecute[ #tCommandsToExecute + 1 ] = str
end

local nRunningCommands = 0

local tRunningIds = {}

function run()
	while true do
		if nRunningCommands < 500 and #tCommandsToExecute > 0 then
			tRunningIds[ commands.execAsync( table.remove( tCommandsToExecute, 1 ) ) ] = true
		else
			local event = {os.pullEvent()}
			if event[ 1 ] == "task_complete" and tRunningIds[ event[ 2 ] ] then
				tRunningIds[ event[ 2 ] ] = false
				nRunningCommands = nRunningCommands - 1
			end
		end
	end
end

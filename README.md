# CCJam-2016
Repository for [CCJam 2016](http://www.computercraft.info/forums2/index.php?/topic/26906-get-ready-for-ccjam-2016/)

Usage: remove .lua from all file names and run ghost.  You will recieve a book with further instructions in game.

I would encourage you to select a small area, as large areas frequently fail, due to [this bug](http://www.computercraft.info/forums2/index.php?/topic/22068-17-task-complete-events-fail-to-fire/).

As far as I know, there is no fix, as BombBloke stated in the thread linked above:

>You'd think that even if every "task_complete" event failed to fire (low odds in itself), it would still resolve in a bit over half a minute (thanks to the timers) - but it still manages to stall *inside this loop* ... usually within a couple of minutes of constant "line writes"! The addition of a second timer only served to mitigate things somewhat. :( 

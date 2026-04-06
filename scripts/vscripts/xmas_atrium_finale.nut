PANIC <- 0
TANK <- 1
DELAY <- 2
ONSLAUGHT <- 3

NumButtons <- 8
ButtonsPressed <- 1
CurrentStage <- 0
CurrentType <- -1

DirectorOptions <-
{
	A_CustomFinale_StageCount = 11

	A_CustomFinale1 = PANIC
	A_CustomFinale2 = PANIC
	A_CustomFinale3 = TANK
	A_CustomFinale4 = PANIC
	A_CustomFinale5 = PANIC
	A_CustomFinale6 = PANIC
	A_CustomFinale7 = PANIC
	A_CustomFinale8 = TANK
	A_CustomFinale9 = PANIC
	A_CustomFinale10 = PANIC
	A_CustomFinale11 = PANIC

	CommonLimit = 25
	SpecialRespawnInterval = 35

	PanicForever = true
}
PanicOptions <-
{
	CommonLimit = 25
}

function OnBeginCustomFinaleStage(num, type)
{
	printl("Stage " + num + " Type " + type)
	CurrentStage = num
	CurrentType = type

	if(num == 1)
	{
		EntFire("Trigger_Finale", "BeginFinale")
		EntFire("info_director", "ForcePanicEvent")
	}

	if(type == TANK)
	{
		DirectorOptions.PanicForever <- false
	}
	else if(type == PANIC)
	{
		DirectorOptions.PanicForever <- true
	}
}

function FinaleStarted()
{
	printl("Finale started.")
	EntFire("info_director", "ForcePanicEvent")
}

function ButtonPressed()
{
	printl("Button pressed: " + ButtonsPressed)
	ButtonsPressed++
	EntFire("Trigger_Finale", "AdvanceFinaleState")
}

function Update()
{
	if(CurrentType == TANK)
	{
		DirectorOptions.PanicForever <- false
	}
	if(CurrentType == PANIC)
	{
		DirectorOptions.PanicForever <- true
	}
}

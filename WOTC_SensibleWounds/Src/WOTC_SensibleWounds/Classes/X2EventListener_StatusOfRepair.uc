//*******************************************************************************************
//  FILE:  SPARK REPAIR Add On                                 
//  
//	File created	14/07/21    05:00
//	LAST UPDATED    12/07/23	22:30
//
//  This listener uses a CHL event to set the status in the barracks correctly 
//	uses CHL issue #322 - version 1.19 or higher required
//	Or Detailed Soldier Lists
//
//*******************************************************************************************
class X2EventListener_StatusOfRepair extends X2EventListener config (Game);

var localized string m_strInRepair;

var config int eStatusELR_InRepairColor;

//setup the templates
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListenerTemplate_StatusOfRepair());
	Templates.AddItem(CreateListenerTemplate_StatusOfRepair_DSL());

	return Templates; 
}

//create the listener template
static function CHEventListenerTemplate CreateListenerTemplate_StatusOfRepair()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'StatusOfRepair');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	//run before other stuff, like CI, so if on infil CI overrides at priority 99 (lower number ovverrides)
	Template.AddCHEvent('OverridePersonnelStatus', OnStatusOfRepair, ELD_Immediate, 104); 

	return Template;
}

//create the listener template  - DSL function for non CHL
static function CHEventListenerTemplate CreateListenerTemplate_StatusOfRepair_DSL()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'StatusOfRepair_DSL');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	//run before other stuff, like CI, so if on infil CI overrides at priority 99 (lower number ovverrides)
	Template.AddCHEvent('CustomizeStatusStringsSeparate', OnStatusOfRepair_DSL, ELD_Immediate, 105);

	return Template;
}

/*
//FOR REF/INFO ONLY called in UiUtilities_Strategy from UIPersonnel_ListItem
static function TriggerOverridePersonnelStatus(XComGameState_Unit Unit,	out string Status, out EUIState eState,	out string TimeLabel, out string TimeValueOverride,	out int TimeNum, out int HideTime, out int DoTimeConversion)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverridePersonnelStatus';
	OverrideTuple.Data.Add(7);
	OverrideTuple.Data[0].s = Status;
	OverrideTuple.Data[1].s = TimeLabel;
	OverrideTuple.Data[2].s = TimeValueOverride;
	OverrideTuple.Data[3].i = TimeNum;
	OverrideTuple.Data[4].i = int(eState);
	OverrideTuple.Data[5].b = HideTime != 0;
	OverrideTuple.Data[6].b = DoTimeConversion != 0;

	`XEVENTMGR.TriggerEvent('OverridePersonnelStatus', OverrideTuple, Unit);
}
*/

//create the listener return
static function EventListenerReturn OnStatusOfRepair(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComLWTuple				Tuple;
    local XComGameState_Unit		UnitState;
	local XComGameState_StaffSlot	StaffSlot;
	
	local name StaffSlotName, TemplateName;
	local string Status;
	local int iTimeNum;
	local bool bIsRoboticClass;

    Tuple = XComLWTuple(EventData);
    UnitState = XComGameState_Unit(EventSource);

	if (Tuple == none)
	{
		return ELR_NoInterrupt;
	}

	if (UnitState != none)
	{
		TemplateName = UnitState.GetMyTemplateName();

		if (TemplateName == 'SparkSoldier' || TemplateName == 'LostTowersSpark' )
		{
			bIsRoboticClass = true;
		}
		else
		{
			bIsRoboticClass = false;
			return ELR_NoInterrupt;
		}

		StaffSlot = UnitState.GetStaffSlot();

		if (bIsRoboticClass && StaffSlot != none)
		{
			StaffSlotName = StaffSlot.GetMyTemplateName();

			// check if the unit is in a SPARK slot and override the wounded status string with "IN REPAIR"
			if (   StaffSlotName == 'SparkStaffSlot' 	|| StaffSlotName == 'SparkStaffSlot0' 
				|| StaffSlotName == 'SparkStaffSlot1' 	|| StaffSlotName == 'SparkStaffSlot2' 
				|| StaffSlotName == 'SparkStaffSlot3' 	|| StaffSlotName == 'SparkStaffSlot4' 
				|| InStr("SparkStaffSlot", StaffSlotName) != INDEX_NONE)
			{

				//so this should get all the correct information
				Status = UnitState.GetWoundStatus(iTimeNum);

				//override display string, but keep the time the same
				Tuple.Data[0].s = default.m_strInRepair;   			//"BEING REPAIRED"; //status string x
				Tuple.Data[1].s = "";                        		//time string y
				Tuple.Data[2].s = "";                               //time value override z??
				Tuple.Data[3].i = iTimeNum;                         //time number, days/hrs
				Tuple.Data[4].i = default.eStatusELR_InRepairColor;	//eUIState_Faded;                //colour from EUI State - see UI Utilities_Colours
				Tuple.Data[5].b = false;                            //Indicates whether you should display the time value and label or not. false means don't hide it || display it. true means hide.
				Tuple.Data[6].b = true;                             //convert time to hours
			}
		}
		else if (bIsRoboticClass && UnitState.IsOnCovertAction())
		{

			//so this should get all the correct information
			Status = UnitState.GetCovertActionStatus(iTimeNum);

			//swap order display of ON COVERT OPS and Wounded
			Tuple.Data[0].s = Status;			//"ON COVERT ACTION"; //status string x
			Tuple.Data[1].s = "";				//time string y
			Tuple.Data[2].s = "";				//time value override z??
			Tuple.Data[3].i = iTimeNum;			//time number, days/hrs
			Tuple.Data[4].i = eUIState_Warning;	//eUIState_Warning;                //colour from EUI State - see UI Utilities_Colours
			Tuple.Data[5].b = false;			//Indicates whether you should display the time value and label or not. false means don't hide it || display it. true means hide.
			Tuple.Data[6].b = true;				//convert time to hours
		}
		else if (bIsRoboticClass && (UnitState.IsInjured() || UnitState.IsDead()) )
		{

			//so this should get all the correct information
			Status = UnitState.GetWoundStatus(iTimeNum);

			//fallback if repair paused str is empty, grab the one for sparks.. 
			if (Status == "")
			{
				Status = class'X2SparkCharacterTemplate_DLC_3'.default.strCharacterHealingPaused;
			}

			//swap order display of ON COVERT OPS and Wounded
			Tuple.Data[0].s = Status;			//"WOUNDED // REPAIR REQUIRED"; //status string x
			Tuple.Data[1].s = "";				//time string y
			Tuple.Data[2].s = "";				//time value override z??
			Tuple.Data[3].i = iTimeNum;			//time number, days/hrs
			Tuple.Data[4].i = eUIState_Bad;		//eUIState_Bad;                //colour from EUI State - see UI Utilities_Colours
			Tuple.Data[5].b = false;			//Indicates whether you should display the time value and label or not. false means don't hide it || display it. true means hide.
			Tuple.Data[6].b = true;				//convert time to hours
		}

	} //end unit != none

	bIsRoboticClass = false;

	return ELR_NoInterrupt;
}

/*
//FOR REF/INFO ONLY called in UIPersonnel_SoldierListItemDetailed from Detailed Soldier Lists
{
	local LWTuple Tuple;

	Tuple = new class'LWTuple';
	Tuple.Id = 'CustomizeStatusStringsSeparate';
	Tuple.Data.Add(4);
	Tuple.Data[0].kind = LWTVBool;
	Tuple.Data[0].b = false;
	Tuple.Data[1].kind = LWTVString;
	Tuple.Data[1].s = Status;
	Tuple.Data[2].kind = LWTVString;
	Tuple.Data[2].s = TimeLabel;
	Tuple.Data[3].kind = LWTVInt;
	Tuple.Data[3].i = TimeValue;

	`XEVENTMGR.TriggerEvent('CustomizeStatusStringsSeparate', Tuple, Unit);
}
*/

//create the listener return for non CHL DSL
static function EventListenerReturn OnStatusOfRepair_DSL(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local LWTuple					Tuple;
    local XComGameState_Unit		UnitState;
	local XComGameState_StaffSlot	StaffSlot;
	
	local name StaffSlotName, TemplateName;
	local string Status;
	local int iTimeNum;
	local bool bIsRoboticClass;

    Tuple = LWTuple(EventData);
    UnitState = XComGameState_Unit(EventSource);

	if (Tuple == none)
	{
		return ELR_NoInterrupt;
	}

	if (UnitState != none)
	{
		TemplateName = UnitState.GetMyTemplateName();

		if (TemplateName == 'SparkSoldier' || TemplateName == 'LostTowersSpark')
		{
			bIsRoboticClass = true;
		}
		else
		{
			bIsRoboticClass = false;
			return ELR_NoInterrupt;
		}

		StaffSlot = UnitState.GetStaffSlot();

		if (bIsRoboticClass && StaffSlot != none)
		{
			StaffSlotName = StaffSlot.GetMyTemplateName();

			// check if the unit is in a SPARK slot and override the wounded status string with "IN REPAIR"
			if (   StaffSlotName == 'SparkStaffSlot' 	|| StaffSlotName == 'SparkStaffSlot0' 
				|| StaffSlotName == 'SparkStaffSlot1' 	|| StaffSlotName == 'SparkStaffSlot2' 
				|| StaffSlotName == 'SparkStaffSlot3' 	|| StaffSlotName == 'SparkStaffSlot4' 
				|| InStr("SparkStaffSlot", StaffSlot.GetMyTemplateName()) != INDEX_NONE)
			{

				//so this should get all the correct information
				Status = UnitState.GetWoundStatus(iTimeNum);

				//override display string, but keep the time the same
				Tuple.Data[0].b = true;								//override DSL display
				Tuple.Data[1].s = default.m_strInRepair;   			//"BEING REPAIRED"; //status string x
				Tuple.Data[2].s = "";                        		//time string y
				Tuple.Data[3].i = iTimeNum;                         //time number, days/hrs
			}
		}
		else if (bIsRoboticClass && UnitState.IsOnCovertAction())
		{

			//so this should get all the correct information
			Status = UnitState.GetCovertActionStatus(iTimeNum);

			//swap order display of ON COVERT OPS and Wounded
			Tuple.Data[0].b = true;				//override DSL display
			Tuple.Data[1].s = Status;			//"ON COVERT ACTION"; //status string x
			Tuple.Data[2].s = "";				//time string y
			Tuple.Data[3].i = iTimeNum;			//time number, days/hrs
		}
		else if (bIsRoboticClass && (UnitState.IsInjured() || UnitState.IsDead()) )
		{
			//so this should get all the correct information
			Status = UnitState.GetWoundStatus(iTimeNum);

			//fallback if repair paused str is empty, grab the one for sparks.. 
			if (Status == "")
			{
				Status = class'X2SparkCharacterTemplate_DLC_3'.default.strCharacterHealingPaused;
			}

			//swap order display of ON COVERT OPS and Wounded
			Tuple.Data[0].b = true;				//override DSL display
			Tuple.Data[1].s = Status;			//"WOUNDED // REPAIR REQUIRED"; //status string x
			Tuple.Data[2].s = "";				//time string y
			Tuple.Data[3].i = iTimeNum;			//time number, days/hrs
		}

	} //end unit != none

	bIsRoboticClass = false;

	return ELR_NoInterrupt;
}

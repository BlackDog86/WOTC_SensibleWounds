class X2EventListener_IgnoreHPHealingLogic extends X2EventListener config (Game);

var config bool IGNORE_LOWEST_HP;

`include(WOTC_SensibleWounds\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

//setup the templates
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListenerTemplate_IgnoreLowestHP());

	return Templates; 
}

//create the listener template
static function CHEventListenerTemplate CreateListenerTemplate_IgnoreLowestHP()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IgnoreLowestHPLogic');
	Template.AddCHEvent('UnitRemovedFromPlay', IgnoreLowestHPFn, ELD_OnStateSubmitted, 90);
	Template.AddCHEvent('TacticalGameEnd', MissionEndIgnoreLowestHPFn, ELD_OnStateSubmitted, 90);

	Template.RegisterInTactical = true;

	return Template;
}

static function EventListenerReturn IgnoreLowestHPFn(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData)
{
    local XComGameState_Unit		UnitState;
	local XComGameState				NewGameState;
	local bool						bIgnoreLowestHP;
  
	bIgnoreLowestHP = `GETMCMVAR(IGNORE_LOWEST_HP);

    if (bIgnoreLowestHP)
    {		
			UnitState = XComGameState_Unit(EventData);
			//we need to be not dead, on xcom team, a soldier, not removed from play already and not ignored from end mission health mod
			if (!UnitState.IsDead() && UnitState.GetTeam() == eTeam_XCom && UnitState.IsSoldier() && !UnitState.GetMyTemplate().bIgnoreEndTacticalHealthMod)
				{								
				//Ignore the fact that the unit might've had lower HP earlier on, just use the current value
				`Log("BeforeInd:" @ UnitState.GetFullName() @ "LowestHP:" @ UnitState.LowestHP @ "CurrentHP:" @ UnitState.GetCurrentStat(eStat_HP) @ "MaxHP:" @ UnitState.GetMaxStat(eStat_HP) @ "Armor:" @ UnitState.GetCurrentStat(eStat_ArmorMitigation),,'BDLOG');
				UnitState.LowestHP = UnitState.GetCurrentStat(eStat_HP);				
				`Log("AfterInd:" @ UnitState.GetFullName() @ "LowestHP:" @ UnitState.LowestHP @ "CurrentHP:" @ UnitState.GetCurrentStat(eStat_HP) @ "MaxHP:" @ UnitState.GetMaxStat(eStat_HP) @ "Armor:" @ UnitState.GetCurrentStat(eStat_ArmorMitigation),,'BDLOG');			
				}		    
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);		
	}
	return ELR_NoInterrupt;
}

static function EventListenerReturn MissionEndIgnoreLowestHPFn(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData)
{
    local XComGameState_Unit		UnitState;
	local XComGameState				NewGameState;
	local XComGameStateHistory		History;
	local bool						bIgnoreLowestHP;

	History = `XCOMHISTORY;
	bIgnoreLowestHP = `GETMCMVAR(IGNORE_LOWEST_HP);

    if (bIgnoreLowestHP)
    {		
		foreach History.IterateByClassType(class'XComGameState_Unit',UnitState)
		{
			//we need to be not dead, on xcom team, a soldier, not removed from play already and not ignored from end mission health mod
			if (!UnitState.IsDead() && UnitState.GetTeam() == eTeam_XCom && UnitState.IsSoldier() && !UnitState.bRemovedFromPlay && !UnitState.GetMyTemplate().bIgnoreEndTacticalHealthMod)
				{								
				//Ignore the fact that the unit might've had lower HP earlier on, just use the current value
				`Log("BeforeSquad:" @ UnitState.GetFullName() @ "LowestHP:" @ UnitState.LowestHP @ "CurrentHP:" @ UnitState.GetCurrentStat(eStat_HP) @ "MaxHP:" @ UnitState.GetMaxStat(eStat_HP) @ "Armor:" @ UnitState.GetCurrentStat(eStat_ArmorMitigation),,'BDLOG');
				UnitState.LowestHP = UnitState.GetCurrentStat(eStat_HP);				
				`Log("AfterSquad:" @ UnitState.GetFullName() @ "LowestHP:" @ UnitState.LowestHP @ "CurrentHP:" @ UnitState.GetCurrentStat(eStat_HP) @ "MaxHP:" @ UnitState.GetMaxStat(eStat_HP) @ "Armor:" @ UnitState.GetCurrentStat(eStat_ArmorMitigation),,'BDLOG');			
				}	
		}	    
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);		
	}
	return ELR_NoInterrupt;
}
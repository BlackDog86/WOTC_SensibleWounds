class X2EventListener_IgnoreHPHealingLogic extends X2EventListener config (Game);

var config bool IGNORE_LOWEST_HP;
var config int RESTORE_HP_PERCENTAGE;

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
	local bool						bIgnoreLowestHP, bSparksIncluded;
	local float						fRestorationFraction;
  
	bIgnoreLowestHP = `GETMCMVAR(IGNORE_LOWEST_HP);
	fRestorationFraction = `GETMCMVAR(RESTORE_HP_PERCENTAGE) / 100.0;
	bSparksIncluded = `GETMCMVAR(APPLY_TO_SPARKS);

    if (bIgnoreLowestHP)
    {		
		UnitState = XComGameState_Unit(EventData);
		// we need to be not dead, on xcom team, not removed from play, a soldier without a custom mission healing function or a SPARK, if the option is ON
		if (!UnitState.IsDead() && UnitState.GetTeam() == eTeam_XCom && ((UnitState.IsSoldier() && !UnitState.GetMyTemplate().bIgnoreEndTacticalHealthMod) || (UnitState.GetMyTemplateName() == 'SparkSoldier' && bSparksIncluded)))
		{
			if (NewGameState == none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tactical Wound Healing: Updating End of Mission HP");
			}
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			//Ignore the fact that the unit might've had lower HP earlier on, just use the current value
			`Log("SensibleWoundsUnitRemoved::HPBefore:" @ UnitState.GetFullName() @ "LowestHP:" @ UnitState.LowestHP @ "CurrentHP:" @ UnitState.GetCurrentStat(eStat_HP) @ "MaxHP:" @ UnitState.GetMaxStat(eStat_HP) @ "Armor:" @ UnitState.GetCurrentStat(eStat_ArmorMitigation),,'BDLOG');
			UnitState.LowestHP = Round(UnitState.LowestHP + ((UnitState.GetCurrentStat(eStat_HP) - UnitState.LowestHP) * fRestorationFraction));				
			// Guard against mod-added weirdness 
			if(UnitState.LowestHP > UnitState.HighestHP)
			{
				UnitState.LowestHP = UnitState.HighestHP;
			}
			`Log("SensibleWoundsUnitRemoved::HPAfter:" @ UnitState.GetFullName() @ "LowestHP:" @ UnitState.LowestHP @ "CurrentHP:" @ UnitState.GetCurrentStat(eStat_HP) @ "MaxHP:" @ UnitState.GetMaxStat(eStat_HP) @ "Armor:" @ UnitState.GetCurrentStat(eStat_ArmorMitigation),,'BDLOG');			
			 if (NewGameState != none)
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);		
		}
	}
	return ELR_NoInterrupt;
}

static function EventListenerReturn MissionEndIgnoreLowestHPFn(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData)
{
    local XComGameState_Unit		UnitState;
	local XComGameState				NewGameState;
	local XComGameStateHistory		History;
	local bool						bIgnoreLowestHP, bSparksIncluded;
	local float						fRestorationFraction;

	History = `XCOMHISTORY;
	bIgnoreLowestHP = `GETMCMVAR(IGNORE_LOWEST_HP);
	fRestorationFraction = `GETMCMVAR(RESTORE_HP_PERCENTAGE) / 100.0;
	bSparksIncluded = `GETMCMVAR(APPLY_TO_SPARKS);

    if (bIgnoreLowestHP)
    {		
		foreach History.IterateByClassType(class'XComGameState_Unit',UnitState)
		{
			// we need to be not dead, on xcom team, not removed from play, a soldier without a custom mission healing function or a SPARK, if the option is ON			
			if (!UnitState.IsDead() && UnitState.GetTeam() == eTeam_XCom && !UnitState.bRemovedFromPlay && ((UnitState.IsSoldier() && !UnitState.GetMyTemplate().bIgnoreEndTacticalHealthMod) || (UnitState.GetMyTemplateName() == 'SparkSoldier' && bSparksIncluded)))
			{		
				if(NewGameState == none)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tactical Wound Healing: Updating End of Mission HP");
				}
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				//Ignore the fact that the unit might've had lower HP earlier on, just use the current value
				`Log("SensibleWoundsMissionEnd::HPBefore:" @ UnitState.GetFullName() @ "LowestHP:" @ UnitState.LowestHP @ "CurrentHP:" @ UnitState.GetCurrentStat(eStat_HP) @ "MaxHP:" @ UnitState.GetMaxStat(eStat_HP) @ "Armor:" @ UnitState.GetCurrentStat(eStat_ArmorMitigation),,'BDLOG');
				UnitState.LowestHP = Round(UnitState.LowestHP + ((UnitState.GetCurrentStat(eStat_HP) - UnitState.LowestHP) * fRestorationFraction));
				
				// Guard against mod-added weirdness 
				if(UnitState.LowestHP > UnitState.HighestHP)
				{
					UnitState.LowestHP = UnitState.HighestHP;
				}
				`Log("SensibleWoundsMissionEnd::HPAfterAdjustment:" @ UnitState.GetFullName() @ "LowestHP:" @ UnitState.LowestHP @ "CurrentHP:" @ UnitState.GetCurrentStat(eStat_HP) @ "MaxHP:" @ UnitState.GetMaxStat(eStat_HP) @ "Armor:" @ UnitState.GetCurrentStat(eStat_ArmorMitigation),,'BDLOG');
			}
		}
		if (NewGameState != none)
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	return ELR_NoInterrupt;
}

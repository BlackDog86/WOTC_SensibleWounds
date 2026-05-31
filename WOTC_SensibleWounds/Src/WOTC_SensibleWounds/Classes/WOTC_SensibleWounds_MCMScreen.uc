class WOTC_SensibleWounds_MCMScreen extends Object config(XComWOTC_SensibleWounds);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;
var localized string exportButtonLabel;
var localized string exportButtonTooltip;
var localized string exportButtonText;
var localized string removeDupesButtonLabel;
var localized string removeDupesButtonTooltip;
var localized string removeDupesButtonText;

`include(WOTC_SensibleWounds\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoCheckBoxVars(IGNORE_LOWEST_HP);
`MCM_API_AutoSliderVars(RESTORE_HP_PERCENTAGE);
`MCM_API_AutoCheckBoxVars(APPLY_TO_SPARKS);

`include(WOTC_SensibleWounds\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoCheckBoxFns(IGNORE_LOWEST_HP, 1);
`MCM_API_AutoCheckBoxFns(APPLY_TO_SPARKS, 1);
`MCM_API_AutoSliderFns(RESTORE_HP_PERCENTAGE,, 1);

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

//Simple one group framework code
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;

	LoadSavedSettings();
	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	
	//Uncomment to enable reset
	//Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('Group', GroupHeader);

	`MCM_API_AutoAddCheckBox(Group, IGNORE_LOWEST_HP, CheckBoxChangeHandler);
	`MCM_API_AutoAddSlider(Group, RESTORE_HP_PERCENTAGE, 1, 100, 1);
	`MCM_API_AutoAddCheckBox(Group, APPLY_TO_SPARKS, CheckBoxChangeHandler);
	Group.AddLabel('desc_line0', "<p align='CENTER'> --- </p>","").SetEditable(True);
	Group.AddLabel('desc_line1', "<p align='LEFT'>HP Restoration - Example:</p>","").SetEditable(True);
	Group.AddLabel('desc_line2', "<p align='LEFT'>A soldier with 10HP is injured down to 2HP while on a mission.</p>","").SetEditable(True);
	Group.AddLabel('desc_line3', "<p align='LEFT'>They are then healed by 4HP up to 6HP total.</p>","").SetEditable(True);
	Group.AddLabel('desc_line4', "<p align='LEFT'>After the mission, they will have:</p>","").SetEditable(True);
	Group.AddLabel('desc_line5', "<p align='LEFT'>2/10HP: Healing Reduces Wounds Off (Base Game Behaviour)</p>","").SetEditable(True);
	Group.AddLabel('desc_line6', "<p align='LEFT'>4/10HP: Healing reduces wounds Slider at 50%</p>","").SetEditable(True);
	Group.AddLabel('desc_line7', "<p align='LEFT'>6/10HP: Healing reduces wounds Slider at 100%</p>","").SetEditable(True);
 
	Page.ShowSettings();
}

simulated function LoadSavedSettings()
{
	IGNORE_LOWEST_HP = `GETMCMVAR(IGNORE_LOWEST_HP);
	RESTORE_HP_PERCENTAGE = `GETMCMVAR(RESTORE_HP_PERCENTAGE);
	APPLY_TO_SPARKS = `GETMCMVAR(APPLY_TO_SPARKS);
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}

simulated function CheckBoxChangeHandler(MCM_API_Setting _Setting, bool _SettingValue)
{
	local name	SettingName;

	SettingName = _Setting.GetName();

	switch (SettingName)
	{
		case 'IGNORE_LOWEST_HP':
		IGNORE_LOWEST_HP = _SettingValue;
		RESTORE_HP_PERCENTAGE_MCMUI.SetEditable(IGNORE_LOWEST_HP);
		APPLY_TO_SPARKS_MCMUI.SetEditable(IGNORE_LOWEST_HP);
		break;
		default:
		break;
	}
}
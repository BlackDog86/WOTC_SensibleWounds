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

`include(WOTC_SensibleWounds\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoCheckBoxFns(IGNORE_LOWEST_HP, 1);

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

	`MCM_API_AutoAddCheckBox(Group, IGNORE_LOWEST_HP);	
	
	Page.ShowSettings();
}

simulated function LoadSavedSettings()
{
	IGNORE_LOWEST_HP = `GETMCMVAR(IGNORE_LOWEST_HP);	
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}


--------------------------------------------------------------------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local L = NS.localization;
--------------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------------------------------------------------------------------
NS.UI.cfg = {
	--
	mainFrame = {
		width		= 624,
		height		= 536,
		portrait	= true,
		frameStrata	= "MEDIUM",
		frameLevel	= "TOP",
		Init		= function( MainFrame )
			MainFrame:SetHeight( NS.UI.cfg.mainFrame.height + ( ( NS.db["monitorRows"] - 8 ) * 50 ) );
			SetPortraitToTexture( MainFrame.portrait, NS.currentCharacter.factionIcon );
		end,
		OnShow		= function( MainFrame )
			MainFrame:Reposition();
			PlaySound( 44298 ); -- UI_Garrison_GarrisonReport_Open
		end,
		OnHide		= function( MainFrame )
			StaticPopup_Hide( "WCC_CHARACTER_DELETE" );
			StaticPopup_Hide( "WCC_CHARACTER_ORDER" );
			StaticPopup_Hide( "WCC_MONITOR_COLUMN" );
			PlaySound( 44299 ); -- UI_Garrison_GarrisonReport_Close
			local point, relativeTo, relativePoint, xOffset, yOffset = MainFrame:GetPoint( 1 );
			NS.db["dragPosition"] = ( point and point == relativePoint and xOffset and yOffset ) and { point, xOffset, yOffset } or nil;
		end,
		Reposition = function( MainFrame )
			MainFrame:ClearAllPoints();
			local pos = ( NS.db["forgetDragPosition"] or not NS.db["dragPosition"] ) and { "TOPLEFT", 45, -120 } or NS.db["dragPosition"];
			MainFrame:SetPoint( unpack( pos ) );
		end,
	},
	--
	subFrameTabs = {
		{
			-- Monitor
			mainFrameTitle	= NS.title,
			tabText			= L["Monitor"],
			Init			= function( SubFrame )
				NS.Button( "NameColumnHeaderButton", SubFrame, NAME, {
					template = "WCCColumnHeaderButtonTemplate",
					size = { ( 162 + 2 + 8 ), 19 },
					setPoint = { "TOPLEFT", "$parent", "TOPLEFT", -2, 0 },
				} );
				NS.Button( "LvlColumnHeaderButton", SubFrame, "" .. L["Lvl"], {
					template = "WCCColumnHeaderButtonTemplate",
					size = { ( 40 + 2 + 8 ), 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "XPColumnHeaderButton", SubFrame, "" .. L["XP"], {
					template = "WCCColumnHeaderButtonTemplate",
					size = { ( 40 + 2 + 8 ), 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "HoAColumnHeaderButton", SubFrame, "" .. L["HoA"], {
					template = "WCCColumnHeaderButtonTemplate",
					size = { ( 40 + 2 + 8 ), 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "APColumnHeaderButton", SubFrame, "" .. L["AP"], {
					template = "WCCColumnHeaderButtonTemplate",
					size = { ( 40 + 2 + 8 ), 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "ButtonsColumnHeaderButton", SubFrame, "" .. L["Missions, Advancements, Followers"], {
					template = "WCCColumnHeaderButtonTemplate",
					size = { ( 216 + 2 + 0 ), 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "RefreshButton", SubFrame, nil, {
					template = false,
					size = { 32, 32 },
					setPoint = { "BOTTOMRIGHT", "$parent", "TOPRIGHT", 3, 5 },
					OnClick = function()
						SubFrame:Refresh();
						NS.Print( "Refreshed" );
					end,
					OnLoad = function( self )
						-- Mimic RefreshButton from https://www.townlong-yak.com/framexml/live/LFGList.xml
						local tx = self:CreateTexture( nil, "ARTWORK", nil, 5 );
						tx:SetTexture( "Interface\\Buttons\\UI-RefreshButton" ); -- This goes before the normal, pushed, highlight
						tx:SetPoint( "CENTER", -1, 0 );
						self:SetNormalTexture( "Interface\\Buttons\\UI-SquareButton-Up" );
						self:SetPushedTexture( "Interface\\Buttons\\UI-SquareButton-Down" );
						self:SetHighlightTexture( "Interface\\Buttons\\UI-Common-MouseHilight" );
						self:SetScript( "OnMouseDown", function() tx:SetPoint( "CENTER", self, "CENTER", -2, -1 ); end );
						self:SetScript( "OnMouseUp", function() tx:SetPoint( "CENTER", self, "CENTER", -1, 0 ); end );
					end,
				} );
				NS.TextFrame( "MessageShipmentConfirms", SubFrame, L["Initializing..."], {
					size = { 186, 16 },
					setPoint = { "TOPRIGHT", SubFrame:GetParent(), "TOPRIGHT", 0, -3 }, -- in title bar
					fontObject = "GameFontRedSmall",
					justifyH = "CENTER",
				} );
				NS.ScrollFrame( "ScrollFrame", SubFrame, {
					size = { 578, ( 50 * NS.db["monitorRows"] - 5 ) },
					setPoint = { "TOPLEFT", "$parentNameColumnHeaderButton", "BOTTOMLEFT", 1, -3 },
					buttonTemplate = "WCCMonitorTabScrollFrameButtonTemplate",
					update = {
						numToDisplay = NS.db["monitorRows"],
						buttonHeight = 50,
						alwaysShowScrollBar = true,
						UpdateFunction = function( sf )
							local monitorMax = 4; -- Number of monitor buttons in XML template
							local currentTime = time(); -- Time used in status calculation
							--------------------------------------------------------------------------------------------------------------------------------------------
							-- Add characters monitoring at least one into items for ScrollFrame
							--------------------------------------------------------------------------------------------------------------------------------------------
							local items = {};
							for _,char in ipairs( NS.db["characters"] ) do
								-- Monitoring?
								if NS.PairsFindKeyByValue( char["monitor"], true ) then
									if NS.db["currentCharacterFirst"] and char["name"] == NS.currentCharacter.name then
										-- Force current character to beginning of items
										local t = { char };
										for i = 1, #items do
											t[#t + 1] = items[i];
										end
										items = t;
									else
										items[#items + 1] = char;
									end
								end
							end
							--------------------------------------------------------------------------------------------------------------------------------------------
							local numItems = #items;
							local sfn = SubFrame:GetName();
							FauxScrollFrame_Update( sf, numItems, sf.numToDisplay, sf.buttonHeight, nil, nil, nil, nil, nil, nil, sf.alwaysShowScrollBar );
							local offset = FauxScrollFrame_GetOffset( sf );
							for num = 1, sf.numToDisplay do
								local bn = sf.buttonName .. num; -- button name
								local b = _G[bn]; -- button
								local k = offset + num; -- key
								b:UnlockHighlight();
								--
								if k <= numItems then
									-- Functions
									local MonitorButton_OnEnter = function( self, text, lines )
										NS.TooltipMonitorButton = self;
										GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
										GameTooltip:SetText( text );
										NS.AddLinesToTooltip( lines, false, GameTooltip );
										GameTooltip:Show();
										b:LockHighlight();
									end
									--
									local OnLeave = function( self )
										NS.TooltipMonitorButton = nil;
										WCCEventsFrame:UnregisterEvent( "MODIFIER_STATE_CHANGED" );
										GameTooltip_Hide();
										b:UnlockHighlight();
									end
									--
									local OnClick = function()
										NS.selectedCharacterKey = NS.FindKeyByField( NS.db["characters"], "name", items[k]["name"] ); -- Set clicked character to selected
										NS.UI.MainFrame:ShowTab( 2 ); -- Characters Tab
									end
									--
									b:SetScript( "OnClick", OnClick );
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Character
									--------------------------------------------------------------------------------------------------------------------------------------------
									_G[bn .. "CharacterText"]:SetText( "|c" .. RAID_CLASS_COLORS[items[k]["class"]].colorStr .. ( NS.db["showCharacterRealms"] and items[k]["name"] or strsplit( "-", items[k]["name"], 2 ) ) .. FONT_COLOR_CODE_CLOSE );
									_G[bn .. "Character"]:SetScript( "OnClick", OnClick );
									_G[bn .. "Character"]:SetScript( "OnEnter", function() b:LockHighlight(); end );
									_G[bn .. "Character"]:SetScript( "OnLeave", OnLeave );
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- War Resources, Seal of Wartorn Fate, and Heart of Azeroth Level
									--------------------------------------------------------------------------------------------------------------------------------------------
									_G[bn .. "CurrencyWarResourcesText"]:SetText( items[k]["warResources"] .. "|T" .. 2032600 .. ":16:16:3:0|t" );
									_G[bn .. "CurrencyWarResources"]:SetScript( "OnClick", OnClick );
									_G[bn .. "CurrencyWarResources"]:SetScript( "OnEnter", function() b:LockHighlight(); end );
									_G[bn .. "CurrencyWarResources"]:SetScript( "OnLeave", OnLeave );
									--------------------------------------------------------------------------------------------------------------------------------------------
									local seals = NS.allCharacters.seals[items[k]["name"]];
									if seals.sealOfWartornFate then
										_G[bn .. "CurrencySealOfWartornFateText"]:SetText( items[k]["sealOfWartornFate"] .. "|T" .. 1416740 .. ":16:16:3:0|t" );
										_G[bn .. "CurrencySealOfWartornFate"]:SetScript( "OnClick", OnClick );
										_G[bn .. "CurrencySealOfWartornFate"]:SetScript( "OnEnter", function( self ) MonitorButton_OnEnter( self, seals.sealOfWartornFate.text, seals.sealOfWartornFate.lines ); end );
										_G[bn .. "CurrencySealOfWartornFate"]:SetScript( "OnLeave", OnLeave );
										_G[bn .. "CurrencySealOfWartornFate"]:Show();
									else
										_G[bn .. "CurrencySealOfWartornFate"]:Hide();
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Lvl, XP, HoA, AP
									--------------------------------------------------------------------------------------------------------------------------------------------
									_G[bn .. "LvlText"]:SetText( items[k]["level"] );
									_G[bn .. "XPPctText"]:SetText( ( items[k]["level"] < 120 and ( items[k]["isRested"] and "|cff4D85E6" or "|cff80528C" ) or GRAY_FONT_COLOR_CODE ) .. items[k]["xpPercent"] .. "%|r" );
									--------------------------------------------------------------------------------------------------------------------------------------------
									local hoa = {
										text = ORDER_HALL_SHAMAN or L["Heart of Azeroth"],
										lines = HIGHLIGHT_FONT_COLOR_CODE .. string.format( AZERITE_POWER_TOOLTIP_TITLE, ( items[k]["hoaLevel"] or "??" ), ( items[k]["apMax"] and items[k]["apMax"] > 0 and ( items[k]["apMax"] - items[k]["ap"] ) or "??" ) ) .. FONT_COLOR_CODE_CLOSE,
									};
									_G[bn .. "HoALevel"]:SetScript( "OnClick", OnClick );
									_G[bn .. "HoALevel"]:SetScript( "OnEnter", function( self ) MonitorButton_OnEnter( self, hoa.text, hoa.lines ); end );
									_G[bn .. "HoALevel"]:SetScript( "OnLeave", OnLeave );
									_G[bn .. "HoALevelText"]:SetText( "|T" .. 1869493 .. ":16:16:-3:0:64:64:10:60:10:60|t" .. NORMAL_FONT_COLOR_CODE .. ( items[k]["hoaLevel"] or "??" ) .. FONT_COLOR_CODE_CLOSE );
									--------------------------------------------------------------------------------------------------------------------------------------------
									_G[bn .. "APPctText"]:SetText( ITEM_QUALITY_COLORS[6].hex .. ( items[k]["apPercent"] and items[k]["apPercent"] .. "%" or "??" ) .. "|r" );
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Init Monitor Buttons
									--------------------------------------------------------------------------------------------------------------------------------------------
									local monitorNum = 0;
									for monitorNum = ( monitorNum + 1 ), monitorMax do
										_G[bn .. "Monitor" .. monitorNum]:Hide(); -- Hide monitor buttons up to max
										_G[bn .. "Monitor" .. monitorNum .. "Indicator"]:Show(); -- Show indicator because it's hidden at Champions
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									local passedTime = currentTime - items[k]["updateTime"]; -- Time passed since character's last update
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Missions
									--------------------------------------------------------------------------------------------------------------------------------------------
									local missions = NS.allCharacters.missions[items[k]["name"]];
									if next( missions ) then
										monitorNum = NS.FindKeyByValue( NS.db["monitorColumn"], "missions" );
										_G[bn .. "Monitor" .. monitorNum]:SetNormalTexture( missions.texture );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnEnter", function( self ) MonitorButton_OnEnter( self, missions.text, missions.lines ); end );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnLeave", OnLeave );
										_G[bn .. "Monitor" .. monitorNum .. "TopRightText"]:SetText( "" );
										_G[bn .. "Monitor" .. monitorNum .. "CenterText"]:SetText( ( missions.color == "Gray" and "" ) or ( ( missions.total - missions.incomplete ) .. "/" .. missions.total ) );
										_G[bn .. "Monitor" .. monitorNum .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. missions.color );
										if missions.color == "Green" then
											_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
										else
											_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
										end
										_G[bn .. "Monitor" .. monitorNum]:Show();
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Advancement
									--------------------------------------------------------------------------------------------------------------------------------------------
									local advancement = NS.allCharacters.advancement[items[k]["name"]];
									if next( advancement ) then
										monitorNum = NS.FindKeyByValue( NS.db["monitorColumn"], "advancement" );
										_G[bn .. "Monitor" .. monitorNum]:SetNormalTexture( advancement.texture );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnEnter", function( self )
											WCCEventsFrame:RegisterEvent( "MODIFIER_STATE_CHANGED" );
											local shift = IsShiftKeyDown();
											MonitorButton_OnEnter( self, ( shift and advancement.shiftText or advancement.text ), ( shift and advancement.shiftLines or advancement.lines ) ); end );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnLeave", OnLeave );
										_G[bn .. "Monitor" .. monitorNum .. "TopRightText"]:SetText( "" );
										_G[bn .. "Monitor" .. monitorNum .. "CenterText"]:SetText( ( advancement.color == "Red" and SecondsToTime( advancement.seconds, false, false, 1 ) ) or "" );
										_G[bn .. "Monitor" .. monitorNum .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. advancement.color );
										if advancement.color == "Green" then
											_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
										else
											_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
										end
										_G[bn .. "Monitor" .. monitorNum]:Show();
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Champions
									--------------------------------------------------------------------------------------------------------------------------------------------
									local champions = NS.allCharacters.champions[items[k]["name"]];
									if next( champions ) then
										monitorNum = NS.FindKeyByValue( NS.db["monitorColumn"], "champions" );
										_G[bn .. "Monitor" .. monitorNum]:SetNormalTexture( champions.texture );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnEnter", function( self ) MonitorButton_OnEnter( self, champions.text, champions.lines ); end );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnLeave", OnLeave );
										_G[bn .. "Monitor" .. monitorNum .. "TopRightText"]:SetText( champions.count );
										_G[bn .. "Monitor" .. monitorNum .. "CenterText"]:SetText( "" );
										_G[bn .. "Monitor" .. monitorNum .. "Indicator"]:Hide();
										_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
										_G[bn .. "Monitor" .. monitorNum]:Show();
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Work Orders
									--------------------------------------------------------------------------------------------------------------------------------------------
									local orders = NS.allCharacters.orders[items[k]["name"]];
									for i = 1, #orders do
										monitorNum = NS.FindKeyByValue( NS.db["monitorColumn"], orders[i].monitorColumn );
										if not monitorNum then
											NS.Print( "Unexpected work order, please report to addon author on CurseForge: " .. orders[i].text .. " - " .. orders[i].texture );
										else
											_G[bn .. "Monitor" .. monitorNum]:SetNormalTexture( orders[i].texture );
											_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnEnter", function( self ) MonitorButton_OnEnter( self, orders[i].text, orders[i].lines ); end );
											_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnLeave", OnLeave );
											_G[bn .. "Monitor" .. monitorNum .. "TopRightText"]:SetText( orders[i].topRightText and orders[i].topRightText or "" );
											_G[bn .. "Monitor" .. monitorNum .. "CenterText"]:SetText( ( orders[i].color == "Gray" and "" ) or ( orders[i].readyForPickup .. "/" .. orders[i].total ) );
											_G[bn .. "Monitor" .. monitorNum .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. orders[i].color );
											if orders[i].color == "Green" then
												_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
											else
												_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
											end
											_G[bn .. "Monitor" .. monitorNum]:Show();
										end
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									b:Show();
								else
									b:Hide();
								end
							end
							-- Message When Empty
							if numItems == 0 then
								_G[SubFrame:GetName() .. "MessageWhenEmptyText"]:Show();
							else
								_G[SubFrame:GetName() .. "MessageWhenEmptyText"]:Hide();
							end
						end
					},
				} );
				NS.TextFrame( "MessageWhenEmpty", SubFrame, L["There are no War Campaigns being monitored.\n\nSelect the Characters tab to choose what you monitor."], {
					setPoint = {
						{ "TOPLEFT", "$parentScrollFrame", "TOPLEFT", 0, 0 },
						{ "BOTTOMRIGHT", "$parentScrollFrame", "BOTTOMRIGHT", 0, 100 },
					},
					justifyH = "CENTER",
					justifyV = "MIDDLE",
				} );
				local FooterFrame = NS.Frame( "Footer", SubFrame, {
					size = { 606, ( 32 + 8 + 8 ) },
					setPoint = { "BOTTOM", "$parent", "BOTTOM", 0, 0 },
					bg = { "Interface\\Garrison\\GarrisonMissionUIInfoBoxBackgroundTile", true, true },
					bgSetAllPoints = true,
				} );
				-- ( 606 - 32 ) = 574, 574 / 3 = ~191, , 191 * 3 = 573
				-- 574 - 573 = 1 leftover pixel(s) (spread over padding for 3 frames as 9's instead of 8's)
				local MissionsReportFrame = NS.Frame( "MissionsReport", FooterFrame, {
					size = { 191, 32 },
					setPoint = { "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
				} );
				local AdvancementsReportFrame = NS.Frame( "AdvancementsReport", FooterFrame, {
					size = { 191, 32 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 9, 0 },
				} );
				local WorkOrdersReportFrame = NS.Frame( "WorkOrdersReport", FooterFrame, {
					size = { 191, 32 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 8, 0 },
				} );
				--
				local MissionsReportButton = NS.Button( "Button", MissionsReportFrame, nil, {
					template = false,
					size = { 32, 32 },
					setPoint = { "LEFT", "$parent", "LEFT", 0, 0 },
					normalTexture = 1044517,
				} );
				local AdvancementsReportButton = NS.Button( "Button", AdvancementsReportFrame, nil, {
					template = false,
					size = { 32, 32 },
					setPoint = { "LEFT", "$parent", "LEFT", 0, 0 },
					normalTexture = 133743,
				} );
				local WorkOrdersReportButton = NS.Button( "Button", WorkOrdersReportFrame, nil, {
					template = false,
					size = { 32, 32 },
					setPoint = { "LEFT", "$parent", "LEFT", 0, 0 },
					normalTexture = NS.currentCharacter.factionIcon,
				} );
				--
				NS.TextFrame( "Center", MissionsReportButton, "", {
					layer = "OVERLAY",
					setAllPoints = true,
					justifyH = "CENTER",
					fontObject = "NumberFontNormal",
				} );
				NS.TextFrame( "Center", AdvancementsReportButton, "", {
					layer = "OVERLAY",
					setAllPoints = true,
					justifyH = "CENTER",
					fontObject = "NumberFontNormal",
				} );
				NS.TextFrame( "Center", WorkOrdersReportButton, "", {
					layer = "OVERLAY",
					setAllPoints = true,
					justifyH = "CENTER",
					fontObject = "NumberFontNormal",
				} );
				--
				local MissionsReportIndicator = MissionsReportButton:CreateTexture( "$parentIndicator", "OVERLAY" );
				MissionsReportIndicator:SetSize( 16, 16 );
				MissionsReportIndicator:SetPoint( "BOTTOMRIGHT", 4.5, -4.5 );
				local AdvancementsReportIndicator = AdvancementsReportButton:CreateTexture( "$parentIndicator", "OVERLAY" );
				AdvancementsReportIndicator:SetSize( 16, 16 );
				AdvancementsReportIndicator:SetPoint( "BOTTOMRIGHT", 4.5, -4.5 );
				local WorkOrdersReportIndicator = WorkOrdersReportButton:CreateTexture( "$parentIndicator", "OVERLAY" );
				WorkOrdersReportIndicator:SetSize( 16, 16 );
				WorkOrdersReportIndicator:SetPoint( "BOTTOMRIGHT", 4.5, -4.5 );
				--
				NS.TextFrame( "Right", MissionsReportFrame, "", {
					size = { ( 191 - 32 - 4 ), 32 },
					setPoint = { "LEFT", "$parent", "LEFT", ( 32 + 4 ), 0 },
					justifyH = "LEFT",
					fontObject = "GameFontNormalSmall",
				} );
				NS.TextFrame( "Right", AdvancementsReportFrame, "", {
					size = { ( 191 - 32 - 4 ), 32 },
					setPoint = { "LEFT", "$parent", "LEFT", ( 32 + 4 ), 0 },
					justifyH = "LEFT",
					fontObject = "GameFontNormalSmall",
				} );
				NS.TextFrame( "Right", WorkOrdersReportFrame, "", {
					size = { ( 191 - 32 - 4 ), 32 },
					setPoint = { "LEFT", "$parent", "LEFT", ( 32 + 4 ), 0 },
					justifyH = "LEFT",
					fontObject = "GameFontNormalSmall",
				} );
			end,
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				--
				_G[sfn .. "ScrollFrame"]:Reset();
				-- Missions
				local mbn = "FooterMissionsReportButton";
				local missionsCenterText,missionsRightText,missionsColor;
				if NS.allCharacters.missionsTotal == 0 then
					missionsCenterText = "";
					missionsColor = "Gray";
					missionsRightText = HIGHLIGHT_FONT_COLOR_CODE .. L["None in progress"] .. "\n" .. FONT_COLOR_CODE_CLOSE;
				elseif NS.allCharacters.missionsComplete == NS.allCharacters.missionsTotal then
					missionsCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.missionsComplete .. "/" .. NS.allCharacters.missionsTotal .. FONT_COLOR_CODE_CLOSE;
					missionsColor = "Green";
					missionsRightText = GREEN_FONT_COLOR_CODE .. COMPLETE .. "\n" .. FONT_COLOR_CODE_CLOSE;
				else
					missionsCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.missionsComplete .. "/" .. NS.allCharacters.missionsTotal .. FONT_COLOR_CODE_CLOSE;
					missionsColor = NS.allCharacters.missionsComplete > 0 and "Yellow" or "Red";
					missionsRightText = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( NS.allCharacters.nextMissionTimeRemaining ) )  .. FONT_COLOR_CODE_CLOSE .. "\n" .. NS.allCharacters.nextMissionCharName;
				end
				-- Advancement
				local abn = "FooterAdvancementsReportButton";
				local advancementsCenterText,advancementsRightText,advancementsColor;
				if NS.allCharacters.advancementsTotal == 0 then
					advancementsCenterText = "";
					advancementsColor = "Gray";
					advancementsRightText = HIGHLIGHT_FONT_COLOR_CODE .. L["None in progress"] .. "\n" .. FONT_COLOR_CODE_CLOSE;
				elseif NS.allCharacters.advancementsComplete == NS.allCharacters.advancementsTotal then
					advancementsCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.advancementsComplete .. "/" .. NS.allCharacters.advancementsTotal .. FONT_COLOR_CODE_CLOSE;
					advancementsColor = "Green";
					advancementsRightText = GREEN_FONT_COLOR_CODE .. COMPLETE .. "\n" .. FONT_COLOR_CODE_CLOSE;
				else
					advancementsCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.advancementsComplete .. "/" .. NS.allCharacters.advancementsTotal .. FONT_COLOR_CODE_CLOSE;
					advancementsColor = NS.allCharacters.advancementsComplete > 0 and "Yellow" or "Red";
					advancementsRightText = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( NS.allCharacters.nextAdvancementTimeRemaining ) )  .. FONT_COLOR_CODE_CLOSE .. "\n" .. NS.allCharacters.nextAdvancementCharName;
				end
				-- Work Orders
				local wbn = "FooterWorkOrdersReportButton";
				local workOrdersCenterText,workOrdersRightText,workOrdersColor;
				if NS.allCharacters.workOrdersTotal == 0 then
					workOrdersCenterText = "";
					workOrdersColor = "Gray";
					workOrdersRightText = HIGHLIGHT_FONT_COLOR_CODE .. L["None in progress"] .. "\n" .. FONT_COLOR_CODE_CLOSE;
				elseif NS.allCharacters.workOrdersReady == NS.allCharacters.workOrdersTotal then
					workOrdersCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.workOrdersReady .. "/" .. NS.allCharacters.workOrdersTotal .. FONT_COLOR_CODE_CLOSE;
					workOrdersColor = "Green";
					workOrdersRightText = GREEN_FONT_COLOR_CODE .. L["Ready for pickup"] .. "\n" .. FONT_COLOR_CODE_CLOSE;
				else
					workOrdersCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.workOrdersReady .. "/" .. NS.allCharacters.workOrdersTotal .. FONT_COLOR_CODE_CLOSE;
					workOrdersColor = NS.allCharacters.workOrdersReady > 0 and "Yellow" or "Red";
					workOrdersRightText = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( NS.allCharacters.nextWorkOrderTimeRemaining ) )  .. FONT_COLOR_CODE_CLOSE .. "\n" .. NS.allCharacters.nextWorkOrderCharName;
				end
				--
				_G[sfn .. mbn .. "CenterText"]:SetText( missionsCenterText );
				_G[sfn .. abn .. "CenterText"]:SetText( advancementsCenterText );
				_G[sfn .. wbn .. "CenterText"]:SetText( workOrdersCenterText );
				--
				_G[sfn .. mbn .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. missionsColor );
				_G[sfn .. abn .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. advancementsColor );
				_G[sfn .. wbn .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. workOrdersColor );
				--
				if missionsColor == "Green" then
					_G[sfn .. mbn]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
				else
					_G[sfn .. mbn]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
				end
				if advancementsColor == "Green" then
					_G[sfn .. abn]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
				else
					_G[sfn .. abn]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
				end
				if workOrdersColor == "Green" then
					_G[sfn .. wbn]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
				else
					_G[sfn .. wbn]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
				end
				--
				_G[sfn .. "FooterMissionsReportRightText"]:SetText( L["Missions"] .. "\n" .. missionsRightText );
				_G[sfn .. "FooterAdvancementsReportRightText"]:SetText( L["Advancements"] .. "\n" .. advancementsRightText );
				_G[sfn .. "FooterWorkOrdersReportRightText"]:SetText( L["Troops"] .. "\n" .. workOrdersRightText );
			end,
		},
		{
			-- Characters
			mainFrameTitle	= NS.title,
			tabText			= L["Characters"],
			Init			= function( SubFrame )
				local function CharactersTabNumMonitored()
					local numMonitored,numTotal = 0,0;
					for i = 1, #NS.charactersTabItems do
						if NS.db["characters"][NS.selectedCharacterKey]["monitor"][NS.charactersTabItems[i].key] then
							numMonitored = numMonitored + 1;
						end
						numTotal = numTotal + 1;
					end
					return numMonitored,numTotal;
				end
				--
				local function MonitorSetChecks( checked )
					for key in pairs( NS.db["characters"][NS.selectedCharacterKey]["monitor"] ) do
						NS.db["characters"][NS.selectedCharacterKey]["monitor"][key] = checked;
					end
					NS.UpdateAll( "forceUpdate" );
				end
				--
				NS.TextFrame( "CharacterLabel", SubFrame, L["Character:"], {
					size = { 67, 16 },
					setPoint = { "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
				} );
				NS.DropDownMenu( "CharacterDropDownMenu", SubFrame, {
					setPoint = { "LEFT", "#sibling", "RIGHT", -12, -1 },
					buttons = function()
						local t = {};
						local maxOrderPosition = #NS.db["characters"];
						for ck,c in ipairs( NS.db["characters"] ) do
							local cn = NS.db["showCharacterRealms"] and c["name"] or strsplit( "-", c["name"], 2 );
							tinsert( t, { ( ( c["order"] < 10 and maxOrderPosition > 9 ) and ( "0" .. c["order"] ) or c["order"] ) .. ". " .. cn, ck } );
						end
						return t;
					end,
					OnClick = function( info )
						NS.selectedCharacterKey = info.value;
						SubFrame:Refresh();
					end,
					width = 190,
				} );
				NS.ScrollFrame( "ScrollFrame", SubFrame, {
					size = { 578, ( 40 * 8 - 5 ) },
					setPoint = { "TOPLEFT", "$parent", "TOPLEFT", -1, -37 },
					buttonTemplate = "WCCCharactersTabScrollFrameButtonTemplate",
					update = {
						numToDisplay = 8,
						buttonHeight = 40,
						alwaysShowScrollBar = true,
						UpdateFunction = function( sf )
							local items = NS.charactersTabItems;
							local numItems = #items;
							FauxScrollFrame_Update( sf, numItems, sf.numToDisplay, sf.buttonHeight, nil, nil, nil, nil, nil, nil, sf.alwaysShowScrollBar );
							local offset = FauxScrollFrame_GetOffset( sf );
							local numMonitored = CharactersTabNumMonitored();
							for num = 1, sf.numToDisplay do
								local k = offset + num; -- key
								local bn = sf.buttonName .. num; -- button name
								local b = _G[bn]; -- button
								local c = _G[bn .. "_Check"]; -- check
								b:UnlockHighlight();
								if k <= numItems then
									b:SetScript( "OnClick", function() c:Click(); end );
									_G[bn .. "_IconTexture"]:SetNormalTexture( items[k].icon );
									_G[bn .. "_IconTexture"]:SetScript( "OnClick", function() c:Click(); end );
									_G[bn .. "_IconTexture"]:SetScript( "OnEnter", function() b:LockHighlight(); end );
									_G[bn .. "_IconTexture"]:SetScript( "OnLeave", function() b:UnlockHighlight(); end );
									_G[bn .. "_NameText"]:SetText( items[k].name );
									c:SetChecked( NS.db["characters"][NS.selectedCharacterKey]["monitor"][items[k].key] );
									c:SetScript( "OnClick", function()
										NS.db["characters"][NS.selectedCharacterKey]["monitor"][items[k].key] = c:GetChecked();
										_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
										NS.UpdateAll( "forceUpdate" );
									end );
									--
									b:Show();
								else
									b:Hide();
								end
							end
							-- Monitored: %d+/%d+
							_G[SubFrame:GetName() .. "MonitoredNumText"]:SetText( NORMAL_FONT_COLOR_CODE .. L["Monitored"] .. ": " .. FONT_COLOR_CODE_CLOSE .. numMonitored .. "/" .. numItems );
							-- Message When Empty
							if numItems == 0 then
								_G[SubFrame:GetName() .. "MessageWhenEmptyText"]:Show();
							else
								_G[SubFrame:GetName() .. "MessageWhenEmptyText"]:Hide();
							end
						end
					},
				} );
				NS.TextFrame( "MonitoredNum", SubFrame, "", {
					-- Text updated during scrollframe update
					size = { 200, 20 },
					setPoint = {
						{ "RIGHT", "$parentScrollFrame", "RIGHT", ( 31 - 8 ), 0 },
						{ "LEFT", "$parentCharacterDropDownMenu", "RIGHT", 0, 0 },
					},
					fontObject = "GameFontHighlight",
					justifyH = "RIGHT",
				} );
				NS.TextFrame( "MessageWhenEmpty", SubFrame, L["This character has no Missions, Advancements, or Troops.\n\nAs you progress they will be monitored automatically.\n\nYou can then uncheck any you don't want to monitor."], {
					setPoint = {
						{ "TOPLEFT", "$parentScrollFrame", "TOPLEFT", 0, 0 },
						{ "BOTTOMRIGHT", "$parentScrollFrame", "BOTTOMRIGHT", 0, 100 },
					},
					fontObject = "GameFontNormal",
					justifyH = "CENTER",
					justifyV = "MIDDLE",
				} );
				NS.CheckButton( "OrderAutomaticallyCheckButton", SubFrame, L["Order Automatically"], {
					setPoint = {
						{ "LEFT", "$parent", "LEFT", 8, 0 },
						{ "TOP", "$parentScrollFrame", "BOTTOM", 0, -8 },
					},
					tooltip = L["Order characters automatically by realm > name.\nUncheck to order characters manually by number."],
					OnClick = function( checked )
						NS.SortCharacters( "automatic" );
						NS.ResetCharactersOrderPositions();
						NS.UpdateAll( "forceUpdate" );
						SubFrame:Refresh();
						-- Prevent Automatic/Manual conflict
						StaticPopup_Hide( "WCC_CHARACTER_ORDER" );
					end,
					db = "orderCharactersAutomatically",
				} );
				NS.CheckButton( "CurrentCharacterFirstCheckButton", SubFrame, L["Current Character First"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Show current character first on the\nMonitor tab, regardless of order."],
					db = "currentCharacterFirst",
				} );
				NS.Button( "OrderButton", SubFrame, L["Order"], {
					size = { 110, 22 },
					setPoint = { "BOTTOMLEFT", "$parent", "BOTTOMLEFT", 8, 8 },
					OnClick = function()
						local cname = NS.db["characters"][NS.selectedCharacterKey]["name"];
						cname = NS.db["showCharacterRealms"] and cname or strsplit( "-", cname, 2 );
						StaticPopup_Show( "WCC_CHARACTER_ORDER", NS.selectedCharacterKey .. ". " .. cname, nil, { ["ck"] = NS.selectedCharacterKey, ["name"] = cname } );
					end,
				} );
				NS.Button( "DeleteCharacterButton", SubFrame, L["Delete"], {
					size = { 110, 22 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 10, 0 },
					OnClick = function()
						local cname = NS.db["characters"][NS.selectedCharacterKey]["name"];
						cname = NS.db["showCharacterRealms"] and cname or strsplit( "-", cname, 2 );
						StaticPopup_Show( "WCC_CHARACTER_DELETE", cname, nil, { ["ck"] = NS.selectedCharacterKey, ["name"] = cname } );
					end,
				} );
				NS.Button( "UncheckAllButton", SubFrame, L["Uncheck All"], {
					size = { 110, 22 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 10, 0 },
					OnClick = function()
						MonitorSetChecks( false );
						_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
					end,
				} );
				NS.Button( "CheckAllButton", SubFrame, L["Check All"], {
					size = { 110, 22 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 10, 0 },
					OnClick = function()
						MonitorSetChecks( true );
						_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
					end,
				} );
				StaticPopupDialogs["WCC_CHARACTER_ORDER"] = {
					text = L["\n%s\n\n|cffffd200Order|r\n|cff82c5ffNumber|r"],
					button1 = L["Change"],
					button2 = CANCEL,
					hasEditBox = 1,
					maxLetters = 2,
					OnAccept = function ( self, data )
						local order = self.editBox:GetNumber();
						if order > 0 then
							local char = NS.db["characters"][data["ck"]];
							local maxOrderPosition = #NS.db["characters"];
							order = order > maxOrderPosition and maxOrderPosition or order;
							if char and char["order"] ~= order then
								NS.SortCharacters( "manual", { ["ck"] = data["ck"], ["order"] = order } );
								NS.UpdateAll( "forceUpdate" );
								SubFrame:Refresh();
								NS.Print( string.format( L["Order changed: %d. %s"], order, data["name"] ) );
							end
						else
							NS.Print( RED_FONT_COLOR_CODE .. L["Order must be greater than zero."] .. FONT_COLOR_CODE_CLOSE );
						end
					end,
					OnCancel = function ( self ) end,
					OnShow = function ( self )
						self.editBox:SetNumeric( true );
						self.editBox:SetFocus();
					end,
					OnHide = function ( self )
						self.editBox:SetText( "" );
					end,
					EditBoxOnEnterPressed = function ( self )
						local parent = self:GetParent();
						local OnAccept = StaticPopupDialogs[parent.which].OnAccept;
						OnAccept( parent, parent.data );
						parent:Hide();
					end,
					EditBoxOnEscapePressed = function( self )
						self:GetParent():Hide();
					end,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
				StaticPopupDialogs["WCC_CHARACTER_DELETE"] = {
					text = L["Delete character? %s"];
					button1 = YES,
					button2 = NO,
					OnAccept = function ( self, data )
						if data["ck"] == NS.currentCharacter.key then return end
						-- Delete
						table.remove( NS.db["characters"], data["ck"] );
						NS.Print( RED_FONT_COLOR_CODE .. string.format( L["%s deleted"], data["name"] ) .. FONT_COLOR_CODE_CLOSE );
						-- Reset keys (Exactly like initialize)
						NS.currentCharacter.key = NS.FindKeyByField( NS.db["characters"], "name", NS.currentCharacter.name ); -- Must be reset when a character is deleted because the keys shift up one
						NS.selectedCharacterKey = NS.currentCharacter.key; -- Sets selected character to current character
						-- Reset Order Positions and Refresh
						NS.ResetCharactersOrderPositions();
						SubFrame:Refresh();
					end,
					OnCancel = function ( self ) end,
					OnShow = function ( self, data )
						if data["name"] == NS.currentCharacter.name then
							NS.Print( RED_FONT_COLOR_CODE .. L["You cannot delete the current character"] .. FONT_COLOR_CODE_CLOSE );
							self:Hide();
						end
					end,
					showAlert = 1,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
			end,
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				_G[sfn .. "CharacterDropDownMenu"]:Reset( NS.selectedCharacterKey );
				_G[sfn .. "OrderAutomaticallyCheckButton"]:SetChecked( NS.db["orderCharactersAutomatically"] );
				if NS.db["orderCharactersAutomatically"] then
					_G[sfn .. "OrderButton"]:Disable();
				else
					_G[sfn .. "OrderButton"]:Enable();
				end
				_G[sfn .. "CurrentCharacterFirstCheckButton"]:SetChecked( NS.db["currentCharacterFirst"] );
				-- Merge Missions, Advancements, Work Orders into items for ScrollFrame
				wipe( NS.charactersTabItems );
				local char = NS.db["characters"][NS.selectedCharacterKey];
				-- Missions
				if char["monitor"]["missions"] ~= nil then
					table.insert( NS.charactersTabItems, { key = "missions", name = L["Missions In Progress"], icon = 1044517 } );
				end
				-- Advancement
				if char["monitor"]["advancement"] ~= nil then
					table.insert( NS.charactersTabItems, { key = "advancement", name = L["Advancements"], icon = 133743 } );
				end
				-- Work Orders
				for i = 1, #char["orders"] do
					table.insert( NS.charactersTabItems, { key = char["orders"][i].texture, name = char["orders"][i].name, icon = char["orders"][i].texture } );
				end
				-- Champions (placed at bottom for UI order consistency)
				if char["monitor"]["champions"] ~= nil then
					table.insert( NS.charactersTabItems, { key = "champions", name = L["Champions"], icon = char["factionIcon"] == 2173920 --[[ Horde ]] and 2026471 or 2026469 --[[ Falstad Wildhammer or Arcanist Valtrois ]] } );
				end
				--
				_G[sfn .. "ScrollFrame"]:Reset();
			end,
		},
		{
			-- Misc
			mainFrameTitle	= NS.title,
			tabText			= L["Misc"],
			Init			= function( SubFrame )
				NS.TextFrame( "MinimapButtonHeader", SubFrame, L["Minimap Button"], {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.CheckButton( "ShowMinimapButtonCheckButton", SubFrame, L["Show Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 3, -5 },
					tooltip = L["Show or hide the\nbutton on the Minimap"],
					OnClick = function( checked )
						if not checked then
							WCCMinimapButton:Hide();
						else
							WCCMinimapButton:Show();
						end
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "showMinimapButton",
				} );
				NS.CheckButton( "ShowCharacterTooltipMinimapButtonCheckButton", SubFrame, L["Show Character Tooltip"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Show or hide the character\ntooltip when available\nfor the Minimap button"],
					db = "showCharacterTooltipMinimapButton",
				} );
				NS.CheckButton( "DockMinimapButtonCheckButton", SubFrame, L["Dock Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Docks Minimap button\nto drag around Minimap,\nundock to drag anywhere"],
					OnClick = function( checked )
						NS.db[WCCMinimapButton.db] = checked and NS.DefaultSavedVariables()["minimapButtonPosition"] or { "CENTER", 0, 150 };
						WCCMinimapButton.docked = checked;
						WCCMinimapButton:UpdatePos();
					end,
					db = "dockMinimapButton",
				} );
				NS.CheckButton( "LockMinimapButtonCheckButton", SubFrame, L["Lock Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Locks Minimap button\nto prevent dragging\n\nMiddle-clicking the Minimap\nbutton also toggles lock"],
					OnClick = function( checked )
						WCCMinimapButton.locked = checked;
					end,
					db = "lockMinimapButton",
				} );
				NS.CheckButton( "LargeMinimapButtonCheckButton", SubFrame, L["Large Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Enables larger Minimap button\nsimilar to Class Hall Report"],
					OnClick = function( checked )
						WCCMinimapButton:UpdateSize( NS.db["largeMinimapButton"] );
						WCCMinimapButton:UpdatePos();
					end,
					db = "largeMinimapButton",
				} );
				NS.CheckButton( "ShowOriginalMissionsReportMinimapButtonCheckButton", SubFrame, L["Show Original Missions Report Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Show or hide the\noriginal Missions Report\nbutton on the Minimap"],
					OnClick = function( checked )
						if not C_Garrison.HasGarrison( Enum.GarrisonType.Type_8_0 ) or not GarrisonLandingPageMinimapButton.title then return end
						GarrisonLandingPageMinimapButton:Hide();
						GarrisonLandingPageMinimapButton:Show();
					end,
					db = "showOriginalMissionsReportMinimapButton",
				} );
				NS.TextFrame( "MinimapButtonNotice", SubFrame, BATTLENET_FONT_COLOR_CODE .. L["Settings above apply to this addon's custom Minimap button.\nFor a standardized Minimap button see the LDB tab."] .. FONT_COLOR_CODE_CLOSE, {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -5 },
						{ "RIGHT", ( 0 - ( NS.UI.cfg.mainFrame.width / 2 ) ) },
					},
				} );
				NS.TextFrame( "OtherHeader", SubFrame, L["Other"], {
					setPoint = {
						{ "LEFT", "$parent", "LEFT", 8, 0 },
						{ "TOP", "#sibling", "BOTTOM", 0, -12 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.CheckButton( "ShowTroopDetailsInTooltipCheckButton", SubFrame, L["Show Troop Details In Tooltip"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 3, -5 },
					tooltip = L["Show or hide troop list in\ntooltip when available"],
					OnClick = function()
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "showTroopDetailsInTooltip",
				} );
				NS.CheckButton( "ShowCharacterRealmsCheckButton", SubFrame, L["Show Character Realms"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Show or hide\ncharacter realms"],
					db = "showCharacterRealms",
				} );
				NS.CheckButton( "ForgetDragPositionCheckButton", SubFrame, L["Forget Drag Position"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Forget drag position of\nthis frame when closed"],
					db = "forgetDragPosition",
					OnClick = function()
						SubFrame:Refresh();
					end,
				} );
				NS.Button( "CenterButton", SubFrame, L["Center"], {
					size = { 80, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 145, 0 },
					fontObject = "GameFontNormalSmall",
					OnClick = function()
						NS.UI.MainFrame:ClearAllPoints();
						NS.UI.MainFrame:SetPoint( "CENTER", 0, 0 );
					end,
				} );
				NS.DropDownMenu( "MonitorRowsDropDownMenu", SubFrame, {
					setPoint = { "TOPLEFT", "$parentForgetDragPositionCheckButton", "BOTTOMLEFT", -13, -1 },
					tooltip = L["The maximum number of\ncharacters visible at once."] .. "\n" .. RED_FONT_COLOR_CODE .. L["Requires Reload"] .. FONT_COLOR_CODE_CLOSE,
					buttons = {
						{ L["08 Monitor Rows"], 8 },
						{ L["09 Monitor Rows"], 9 },
						{ L["10 Monitor Rows"], 10 },
						{ L["11 Monitor Rows"], 11 },
						{ L["12 Monitor Rows"], 12 },
					},
					OnClick = function( info )
						NS.db["monitorRows"] = info.value;
						--
						local currentHeight = NS.UI.MainFrame:GetHeight();
						local newHeight = NS.UI.cfg.mainFrame.height + ( ( info.value - 8 ) * 50 );
						if currentHeight ~= newHeight then
							_G[SubFrame:GetName() .. "ReloadUIButton"]:Show();
						else
							_G[SubFrame:GetName() .. "ReloadUIButton"]:Hide();
						end
					end,
					width = 133,
				} );
				NS.Button( "ReloadUIButton", SubFrame, L["Reload UI"], {
					hidden = true,
					size = { 80, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 1, 0 },
					fontObject = "GameFontNormalSmall",
					OnClick = function()
						ReloadUI();
					end,
				} );
				local columnNames = {
					["missions"] = L["Missions"],
					["advancement"] = L["Advancement"],
					["troop1"] = L["Troops"],
					["champions"] = L["Champions"],
				};
				NS.DropDownMenu( "MonitorColumnsDropDownMenu", SubFrame, {
					setPoint = { "TOPLEFT", "$parentMonitorRowsDropDownMenu", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Column numbers for\nicons on the Monitor tab."],
					buttons = function()
						local t = {};
						for ck,cslug in ipairs( NS.db["monitorColumn"] ) do
							tinsert( t, { ( ck < 10 and ( "0" .. ck ) or ck ) .. ". " .. columnNames[cslug], ck } );
						end
						return t;
					end,
					width = 133,
				} );
				NS.Button( "ColumnButton", SubFrame, L["Column"], {
					size = { 80, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 1, 0 },
					fontObject = "GameFontNormalSmall",
					OnClick = function()
						local ck = UIDropDownMenu_GetSelectedValue( _G[SubFrame:GetName() .. "MonitorColumnsDropDownMenu"] );
						local cname = columnNames[NS.db["monitorColumn"][ck]];
						StaticPopup_Show( "WCC_MONITOR_COLUMN", ck .. ". " .. cname, nil, { ["ck"] = ck, ["name"] = cname } );
					end,
				} );
				NS.Button( "ResetButton", SubFrame, L["Reset"], {
					size = { 80, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 4, 0 },
					fontObject = "GameFontNormalSmall",
					OnClick = function()
						NS.db["monitorColumn"] = NS.DefaultSavedVariables()["monitorColumn"];
						SubFrame:Refresh();
						NS.Print( L["Monitor columns reset"] );
					end,
				} );
				StaticPopupDialogs["WCC_MONITOR_COLUMN"] = {
					text = L["\n%s\n\n|cffffd200Column|r\n|cff82c5ffNumber|r"],
					button1 = L["Change"],
					button2 = CANCEL,
					hasEditBox = 1,
					maxLetters = 2,
					OnAccept = function ( self, data )
						local column = self.editBox:GetNumber();
						if column > 0 then
							local mc = NS.db["monitorColumn"][data["ck"]];
							local maxColumn = #NS.db["monitorColumn"];
							column = column > maxColumn and maxColumn or column;
							if mc and mc ~= NS.FindKeyByValue( NS.db["monitorColumn"], mc ) then
								NS.ChangeColumns( data["ck"], column );
								SubFrame:Refresh();
								NS.Print( string.format( L["Column changed: %d. %s"], column, data["name"] ) );
							end
						else
							NS.Print( RED_FONT_COLOR_CODE .. L["Column must be greater than zero."] .. FONT_COLOR_CODE_CLOSE );
						end
					end,
					OnCancel = function ( self ) end,
					OnShow = function ( self )
						self.editBox:SetNumeric( true );
						self.editBox:SetFocus();
					end,
					OnHide = function ( self )
						self.editBox:SetText( "" );
					end,
					EditBoxOnEnterPressed = function ( self )
						local parent = self:GetParent();
						local OnAccept = StaticPopupDialogs[parent.which].OnAccept;
						OnAccept( parent, parent.data );
						parent:Hide();
					end,
					EditBoxOnEscapePressed = function( self )
						self:GetParent():Hide();
					end,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
			end,
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				_G[sfn .. "ShowMinimapButtonCheckButton"]:SetChecked( NS.db["showMinimapButton"] );
				_G[sfn .. "ShowCharacterTooltipMinimapButtonCheckButton"]:SetChecked( NS.db["showCharacterTooltipMinimapButton"] );
				_G[sfn .. "DockMinimapButtonCheckButton"]:SetChecked( NS.db["dockMinimapButton"] );
				_G[sfn .. "LockMinimapButtonCheckButton"]:SetChecked( NS.db["lockMinimapButton"] );
				_G[sfn .. "LargeMinimapButtonCheckButton"]:SetChecked( NS.db["largeMinimapButton"] );
				_G[sfn .. "ShowOriginalMissionsReportMinimapButtonCheckButton"]:SetChecked( NS.db["showOriginalMissionsReportMinimapButton"] );
				_G[sfn .. "ShowTroopDetailsInTooltipCheckButton"]:SetChecked( NS.db["showTroopDetailsInTooltip"] );
				_G[sfn .. "ShowCharacterRealmsCheckButton"]:SetChecked( NS.db["showCharacterRealms"] );
				_G[sfn .. "ForgetDragPositionCheckButton"]:SetChecked( NS.db["forgetDragPosition"] );
				if NS.db["forgetDragPosition"] then
					_G[sfn .. "CenterButton"]:Disable();
				else
					_G[sfn .. "CenterButton"]:Enable();
				end
				_G[sfn .. "MonitorRowsDropDownMenu"]:Reset( NS.db["monitorRows"] );
				_G[sfn .. "MonitorColumnsDropDownMenu"]:Reset( 1 );
			end,
		},
		{
			-- Alerts
			mainFrameTitle	= NS.title,
			tabText			= L["Alerts"],
			Init			= function( SubFrame )
				NS.TextFrame( "AlertHeader", SubFrame, L["Alert - Flashes Minimap button when an indicator is |TInterface\\COMMON\\Indicator-Green:0|t"], {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.DropDownMenu( "AlertDropDownMenu", SubFrame, {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", -12, -8 },
					buttons = {
						{ L["Current Character"], "current" },
						{ L["Any Character"], "any" },
						{ L["Disabled"], "disabled" },
					},
					OnClick = function( info )
						NS.db["alert"] = info.value;
						NS.UpdateAll( "forceUpdate" );
					end,
					width = 116,
				} );
				NS.CheckButton( "AlertMissionsCheckButton", SubFrame, L["Missions"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 15, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nMissions In Progress"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertMissions",
				} );
				NS.CheckButton( "AlertAdvancementsCheckButton", SubFrame, L["Advancements"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nAdvancement Research"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertAdvancements",
				} );
				NS.CheckButton( "AlertTroopsCheckButton", SubFrame, L["Troops"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nTroop Work Orders"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertTroops",
				} );
				NS.CheckButton( "AlertDisableInInstancesCheckButton", SubFrame, L["Disable in Instances"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffDisable Alert|r\nIn Arenas, Dungeons,\nBattlegrounds, Raids, etc."],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertDisableInInstances",
				} );
				NS.TextFrame( "AlertNotice", SubFrame, BATTLENET_FONT_COLOR_CODE .. L["Minimap button flash is only enabled for this addon's custom\nMinimap button. The optional standardized LibDBIcon\nMinimap button (see LDB tab) does not flash."] .. FONT_COLOR_CODE_CLOSE, {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -5 },
						{ "RIGHT", -8 },
					},
				} );
			end,
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				_G[sfn .. "AlertDropDownMenu"]:Reset( NS.db["alert"] );
				_G[sfn .. "AlertMissionsCheckButton"]:SetChecked( NS.db["alertMissions"] );
				_G[sfn .. "AlertAdvancementsCheckButton"]:SetChecked( NS.db["alertAdvancements"] );
				_G[sfn .. "AlertTroopsCheckButton"]:SetChecked( NS.db["alertTroops"] );
				_G[sfn .. "AlertDisableInInstancesCheckButton"]:SetChecked( NS.db["alertDisableInInstances"] );
			end,
		},
		{
			-- LDB
			mainFrameTitle	= NS.title,
			tabText			= L["LDB"],
			Init			= function( SubFrame )
				NS.TextFrame( "Description", SubFrame, string.format( L["The %s LDB data source can be used by LDB display addons such as Titan Panel, Chocolate Bar, and Bazooka.\n\n%sThe LDB data source reflects characters as configured and shown on the Monitor tab.|r"], HIGHLIGHT_FONT_COLOR_CODE .. NS.addon .. FONT_COLOR_CODE_CLOSE, RED_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					addHeight = 10,
					fontObject = "GameFontNormalSmall",
				} );
				NS.TextFrame( "SourceLabel", SubFrame, L["Source:"], {
					size = { 81, 16 },
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
					justifyH = "RIGHT",
				} );
				NS.DropDownMenu( "SourceDropDownMenu", SubFrame, {
					setPoint = { "LEFT", "#sibling", "RIGHT", -12, -1 },
					buttons = {
						{ L["Current Character"], "current" },
						{ L["All Characters"], "all" },
					},
					tooltip = L["Heart of Azeroth, Resources, and Seals shown\nare always for the current character only."],
					OnClick = function( info )
						NS.db["ldbSource"] = info.value;
						NS.UpdateAll( "forceUpdate" );
					end,
					width = 116,
				} );
				NS.TextFrame( "TextFormatLabel", SubFrame, L["Text Format:"], {
					size = { 81, 16 },
					setPoint = { "TOPLEFT", "$parentSourceLabel", "BOTTOMLEFT", 0, -18 },
					justifyH = "RIGHT",
				} );
				NS.CheckButton( "ShowMissionsCheckButton", SubFrame, string.format( L["%sMissions|r"], "|cff00ff96" ), {
					setPoint = { "LEFT", "#sibling", "RIGHT", 3, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowMissions",
				} );
				NS.CheckButton( "ShowNextMissionCheckButton", SubFrame, L["Show (Next: 1 Hr)"], {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 24, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowNextMission",
				} );
				NS.CheckButton( "ShowNextMissionCharacterCheckButton", SubFrame, L["Show Character Name"], {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "LEFT", "$parentShowNextMissionCheckButtonText", "RIGHT", 20, 0 },
					OnClick = function()
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowNextMissionCharacter",
				} );
				NS.CheckButton( "ShowAdvancementsCheckButton", SubFrame, string.format( L["%sAdvancements|r"], "|cff00ff96" ), {
					setPoint = { "TOPLEFT", "$parentShowNextMissionCheckButton", "BOTTOMLEFT", -24, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowAdvancements",
				} );
				NS.CheckButton( "ShowNextAdvancementCheckButton", SubFrame, L["Show (Next: 1 Hr)"], {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 24, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowNextAdvancement",
				} );
				NS.CheckButton( "ShowNextAdvancementCharacterCheckButton", SubFrame, L["Show Character Name"], {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "LEFT", "$parentShowNextAdvancementCheckButtonText", "RIGHT", 20, 0 },
					OnClick = function()
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowNextAdvancementCharacter",
				} );
				NS.CheckButton( "ShowOrdersCheckButton", SubFrame, string.format( L["%sOrders|r"], "|cff00ff96" ), {
					setPoint = { "TOPLEFT", "$parentShowNextAdvancementCheckButton", "BOTTOMLEFT", -24, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowOrders",
				} );
				NS.CheckButton( "ShowNextOrderCheckButton", SubFrame, L["Show (Next: 1 Hr)"], {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 24, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowNextOrder",
				} );
				NS.CheckButton( "ShowNextOrderCharacterCheckButton", SubFrame, L["Show Character Name"], {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "LEFT", "$parentShowNextOrderCheckButtonText", "RIGHT", 20, 0 },
					OnClick = function()
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowNextOrderCharacter",
				} );
				NS.CheckButton( "ShowHOACheckButton", SubFrame, string.format( L["%sHeart of Azeroth|r"], "|cff00ff96" ), {
					setPoint = { "TOPLEFT", "$parentShowNextOrderCheckButton", "BOTTOMLEFT", -24, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowHOA",
				} );
				NS.CheckButton( "ShowResourcesCheckButton", SubFrame, string.format( L["%sResources|r"], "|cff00ff96" ), {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowResources",
				} );
				NS.CheckButton( "ShowSealsCheckButton", SubFrame, string.format( L["%sSeals|r"], "|cff00ff96" ), {
					setPoint = { "LEFT", "$parentShowResourcesCheckButtonText", "RIGHT", 20, 0 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowSeals",
				} );
				NS.CheckButton( "ShowLabelsCheckButton", SubFrame, string.format( L["Show Labels (e.g. %sMissions|r)"], NORMAL_FONT_COLOR_CODE ), {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "TOPLEFT", "$parentShowResourcesCheckButton", "BOTTOMLEFT", 0, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowLabels",
				} );
				NS.CheckButton( "UseLetterLabelsCheckButton", SubFrame, string.format( L["Use Letter Labels (e.g. %sM|r)"], NORMAL_FONT_COLOR_CODE ), {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "LEFT", "$parentShowLabelsCheckButtonText", "RIGHT", 20, 0 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbUseLetterLabels",
				} );
				NS.CheckButton( "ShowWhenNoneCheckButton", SubFrame, string.format( L["Show when %sNone|r"], GRAY_FONT_COLOR_CODE ), {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "TOPLEFT", "$parentShowLabelsCheckButton", "BOTTOMLEFT", 0, -1 },
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbShowWhenNone",
				} );
				NS.CheckButton( "NumbersOnlyCheckButton", SubFrame, string.format( L["Numbers Only (e.g. %s1|r not %s1 Ready|r)"], GREEN_FONT_COLOR_CODE, GREEN_FONT_COLOR_CODE ), {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = {
						{ "BOTTOM", "#sibling", "BOTTOM", 0, 0 },
						{ "LEFT", "$parentUseLetterLabelsCheckButton", "LEFT", 0, 0 }
					},
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "ldbNumbersOnly",
				} );
				NS.TextFrame( "LibDBIconLabel", SubFrame, L["LibDBIcon:"], {
					size = { 81, 16 },
					setPoint = {
						{ "TOP", "#sibling", "BOTTOM", 0, -12 },
						{ "LEFT", "$parentSourceLabel", "LEFT", 0 },
					},
					justifyH = "RIGHT",
				} );
				NS.TextFrame( "LibDBIconDescription", SubFrame, L["Creates a standard addon Minimap button."], {
					setPoint = {
						{ "LEFT", "#sibling", "RIGHT", 5, 0 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.CheckButton( "HideLibDBIconMinimapButtonCheckButton", SubFrame, L["Hide LibDBIcon Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", ( -5 + ( 15 - 12 ) ), -5 },
					tooltip = L["Hide or show the\nbutton on the Minimap"],
					OnClick = function( checked )
						NS.db["ldbi"].hide = checked;
						NS.ldbi:Refresh( NS.addon );
					end,
				} );
				NS.CheckButton( "ShowCharacterTooltipLibDBIconMinimapButtonCheckButton", SubFrame, L["Show Character Tooltip"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Show or hide the character\ntooltip when available\nfor the Minimap button"],
					db = "ldbiShowCharacterTooltip",
				} );
			end,
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				_G[sfn .. "SourceDropDownMenu"]:Reset( NS.db["ldbSource"] );
				_G[sfn .. "ShowMissionsCheckButton"]:SetChecked( NS.db["ldbShowMissions"] );
				_G[sfn .. "ShowNextMissionCheckButton"]:SetChecked( NS.db["ldbShowNextMission"] );
				_G[sfn .. "ShowNextMissionCharacterCheckButton"]:SetChecked( NS.db["ldbShowNextMissionCharacter"] );
				_G[sfn .. "ShowAdvancementsCheckButton"]:SetChecked( NS.db["ldbShowAdvancements"] );
				_G[sfn .. "ShowNextAdvancementCheckButton"]:SetChecked( NS.db["ldbShowNextAdvancement"] );
				_G[sfn .. "ShowNextAdvancementCharacterCheckButton"]:SetChecked( NS.db["ldbShowNextAdvancementCharacter"] );
				_G[sfn .. "ShowOrdersCheckButton"]:SetChecked( NS.db["ldbShowOrders"] );
				_G[sfn .. "ShowNextOrderCheckButton"]:SetChecked( NS.db["ldbShowNextOrder"] );
				_G[sfn .. "ShowNextOrderCharacterCheckButton"]:SetChecked( NS.db["ldbShowNextOrderCharacter"] );
				_G[sfn .. "ShowHOACheckButton"]:SetChecked( NS.db["ldbShowHOA"] );
				_G[sfn .. "ShowResourcesCheckButton"]:SetChecked( NS.db["ldbShowResources"] );
				_G[sfn .. "ShowSealsCheckButton"]:SetChecked( NS.db["ldbShowSeals"] );
				_G[sfn .. "ShowLabelsCheckButton"]:SetChecked( NS.db["ldbShowLabels"] );
				_G[sfn .. "UseLetterLabelsCheckButton"]:SetChecked( NS.db["ldbUseLetterLabels"] );
				_G[sfn .. "ShowWhenNoneCheckButton"]:SetChecked( NS.db["ldbShowWhenNone"] );
				_G[sfn .. "NumbersOnlyCheckButton"]:SetChecked( NS.db["ldbNumbersOnly"] );
				_G[sfn .. "HideLibDBIconMinimapButtonCheckButton"]:SetChecked( NS.db["ldbi"].hide );
				_G[sfn .. "ShowCharacterTooltipLibDBIconMinimapButtonCheckButton"]:SetChecked( NS.db["ldbiShowCharacterTooltip"] );
			end,
		},
		{
			-- Help
			mainFrameTitle	= NS.title,
			tabText			= HELP_LABEL,
			Init			= function( SubFrame )
				NS.TextFrame( "Description", SubFrame, string.format( L["%s version %s for patch %s"], NS.title, NS.versionString, NS.releasePatch ), {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontRedSmall",
				} );
				NS.TextFrame( "SlashCommandsHeader", SubFrame, string.format( L["%sSlash Commands|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "SlashCommands", SubFrame, string.format( L["%s/wcc|r - Open and close this frame"], NORMAL_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "IndicatorsHeader", SubFrame, string.format( L["%sIndicators|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "IndicatorsGray", SubFrame, L["|TInterface\\COMMON\\Indicator-Gray:20:20|t None in progress"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "IndicatorsRed", SubFrame, L["|TInterface\\COMMON\\Indicator-Red:20:20|t All incomplete"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, 0 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "IndicatorsYellow", SubFrame,	L["|TInterface\\COMMON\\Indicator-Yellow:20:20|t Some complete"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, 0 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "IndicatorsGreen", SubFrame, L["|TInterface\\COMMON\\Indicator-Green:20:20|t All complete"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, 0 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "FontColorHeader", SubFrame, string.format( L["%sFont Color|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "FontColorOrange", SubFrame, string.format( L["%s0 1 2 3 4|r  Troops have recruits that are %s\"Ready to start\"|r"], ORANGE_FONT_COLOR_CODE, GREEN_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "FontColorXP", SubFrame, string.format( L["%s75|r %s25|r  XP colors reflect whether character is resting or has rested XP"], "|cff4D85E6", "|cff80528C" ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "FontColorAP", SubFrame, string.format( L["%s50|r AP color refers to Artifact Power %% to next level"], ITEM_QUALITY_COLORS[6].hex ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "GettingStartedHeader", SubFrame, string.format( L["%sGetting Started|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "GettingStarted", SubFrame, string.format(
						L["%s1.|r Log into a character you want to monitor.\n" ..
						"%s2.|r Select Characters tab and uncheck what you don't want to monitor.\n" ..
						"%s3.|r Repeat 1-2 for all characters you want included in this addon."],
						NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE
					), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "NeedMoreHelpHeader", SubFrame, string.format( L["%sNeed More Help?|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "NeedMoreHelp", SubFrame, string.format(
						L["%sQuestions, Comments, Bugs and Suggestions|r\n\n" ..
						"https://www.curseforge.com/wow/addons/war-campaigns-complete"],
						NORMAL_FONT_COLOR_CODE
					), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
			end,
			Refresh			= function( SubFrame ) return end,
		},
	},
};

--------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize Variables
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local L = NS.localization;
NS.releasePatch = "9.0.1";
NS.versionString = "1.08";
NS.version = tonumber( NS.versionString );
--
NS.initialized = false;
--
NS.lastTimeUpdateRequest = nil;
NS.lastTimeUpdateRequestSent = nil;
NS.lastTimeUpdateAll = nil;
NS.updateAllInterval = 10;
--
NS.shipmentConfirmsRequired = 3; -- Bypassed for players without an 8.0 Garrison
NS.shipmentConfirmsCount = 0;
NS.shipmentConfirmsFlaggedComplete = false;
NS.refresh = false;
--
NS.TooltipMonitorButton = nil; -- References the button origin of the tooltip
--
NS.minimapButtonFlash = nil;
NS.alertFlashing = false;
--
NS.selectedCharacterKey = nil;
NS.charactersTabItems = {};
--
NS.allCharacters = {}; -- See NS.UpdateCharacters()
NS.currentCharacter = { -- See NS.UpdateCharacter()
	name = UnitName( "player" ) .. "-" .. GetRealmName(),
	factionIcon = UnitFactionGroup( "player" ) == "Horde" and 2173920 or 2173919,	-- Permanent
	class = select( 2, UnitClass( "player" ) ),										-- Permanent
	classID = select( 3, UnitClass( "player" ) ),									-- Permanent
	key = nil,																		-- Set on NS.initialized and reset after character deletion
};
-- Seal of Wartorn Fate Quests
-- 52837 = Seal of Wartorn Fate: War Resources (1000)
-- 52840 = Seal of Wartorn Fate: Stashed War Resources (2000)
-- 52834 = Seal of Wartorn Fate: Gold (2000)
-- 52838 = Seal of Wartorn Fate: Piles of Gold (5000)
-- 52835 = Seal of Wartorn Fate: Marks of Honor (5)
-- 52839 = Seal of Wartorn Fate: Additional Marks of Honor (10)
NS.sealOfWartornFateQuests = { 52837, 52840, 52834, 52838, 52835, 52839 };
NS.sealOfWartornFateMax = 5;
NS.sealOfWartornFateWeeklyMax = 2;
NS.maxAdvancementTiers = 6;
NS.maxChampions = 6;
NS.maxLevelForPlayerExpansion = GetMaxLevelForPlayerExpansion();
--
NS.fullHeart = NS.GetAtlasInlineTexture( 'GarrisonTroops-Health' );
NS.emptyHeart = NS.GetAtlasInlineTexture( 'GarrisonTroops-Health-Consume' );
--
NS.ldbTooltip = {}; -- See NS.UpdateLDB()
--------------------------------------------------------------------------------------------------------------------------------------------
-- SavedVariables
--------------------------------------------------------------------------------------------------------------------------------------------
NS.DefaultSavedVariables = function()
	return {
		["version"] = NS.version,
		["characters"] = {},
		["orderCharactersAutomatically"] = true,
		["currentCharacterFirst"] = true,
		["showMinimapButton"] = true,
		["showCharacterTooltipMinimapButton"] = true,
		["dockMinimapButton"] = true,
		["lockMinimapButton"] = false,
		["largeMinimapButton"] = true,
		["minimapButtonPosition"] = 237.2,
		["showOriginalMissionsReportMinimapButton"] = true,
		["showTroopDetailsInTooltip"] = true,
		["showCharacterRealms"] = true,
		["forgetDragPosition"] = true,
		["dragPosition"] = nil,
		["monitorRows"] = 8,
		["monitorColumn"] = {
			"missions",
			"advancement",
			"troop1",
			"champions",
		},
		["alert"] = "current",
		["alertMissions"] = true,
		["alertAdvancements"] = true,
		["alertTroops"] = true,
		["alertDisableInInstances"] = true,
		["ldbSource"] = "current",
		["ldbShowMissions"] = true,
		["ldbShowNextMission"] = true,
		["ldbShowNextMissionCharacter"] = true,
		["ldbShowAdvancements"] = true,
		["ldbShowNextAdvancement"] = true,
		["ldbShowNextAdvancementCharacter"] = true,
		["ldbShowOrders"] = true,
		["ldbShowNextOrder"] = true,
		["ldbShowNextOrderCharacter"] = true,
		["ldbShowHOA"] = true,
		["ldbShowResources"] = false,
		["ldbShowSeals"] = false,
		["ldbShowLabels"] = true,
		["ldbUseLetterLabels"] = false,
		["ldbShowWhenNone"] = true,
		["ldbNumbersOnly"] = false,
		["ldbi"] = { hide = true },
		["ldbiShowCharacterTooltip"] = true,
	};
end
--
NS.Upgrade = function()
	local vars = NS.DefaultSavedVariables();
	local version = NS.db["version"];
	-- 1.01
	if version < 1.01 then
		-- Add/Change
		local textFormat = NS.Explode( "-", NS.db["ldbTextFormat"] );
		NS.db["ldbShowMissions"] = NS.FindKeyByValue( textFormat, "missions" ) and true or vars["ldbShowMissions"];
		NS.db["ldbShowAdvancements"] = NS.FindKeyByValue( textFormat, "advancements" ) and true or vars["ldbShowAdvancements"];
		NS.db["ldbShowOrders"] = NS.FindKeyByValue( textFormat, "orders" ) and true or vars["ldbShowOrders"];
		NS.db["ldbShowResources"] = vars["ldbShowResources"];
		NS.db["ldbShowSeals"] = vars["ldbShowSeals"];
		-- Remove
		NS.db["ldbTextFormat"] = nil;
	end
	-- 1.03
	if version < 1.03 then
		-- Add
		NS.db["ldbUseLetterLabels"] = vars["ldbUseLetterLabels"];
		NS.db["ldbNumbersOnly"] = vars["ldbNumbersOnly"];
		NS.db["ldbShowHOA"] = vars["ldbShowHOA"];
		-- Advancements
		for ck,c in ipairs( NS.db["characters"] ) do
			-- Add
			c["advancement"]["selectedTalents"] = {};
			-- Change talent being researched to tier (table to number)
			if c["advancement"]["talentBeingResearched"] then
				c["advancement"]["tierBeingResearched"] = c["advancement"]["talentBeingResearched"].tier;
			end
			-- Fill selected talents with empty tables unless talentBeingResearched matches, then transfer it
			if c["advancement"]["numTalents"] then
				for i = 1, c["advancement"]["numTalents"] do
					if i == c["advancement"]["tierBeingResearched"] then
						c["advancement"]["selectedTalents"][i] = CopyTable( c["advancement"]["talentBeingResearched"] );
					else
						c["advancement"]["selectedTalents"][i] = {};
					end
				end
			end
			-- Remove
			c["advancement"]["talentBeingResearched"] = nil;
			c["advancement"]["numTalents"] = nil;
		end
	end
	-- 1.06
	if version < 1.06 then
		-- Wipe characters
		NS.db["characters"] = {};
		NS.Print( L["Character data wiped due to significant game changes in patch 9.0.1. Please log back into your characters to repopulate their data."] );
	end
	--
	NS.db["version"] = NS.version;
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------------------------------------------------------------------
NS.SortCharacters = function( order, move )
	local selectedCharacterName = NS.selectedCharacterKey and NS.db["characters"][NS.selectedCharacterKey]["name"] or NS.currentCharacter.name;
	--
	if order == "automatic" then
		table.sort ( NS.db["characters"],
			function ( char1, char2 )
				if char1["realm"] == char2["realm"] then
					return char1["name"] < char2["name"];
				else
					return char1["realm"] < char2["realm"];
				end
			end
		);
	elseif order == "manual" then
		for i = 1, #NS.db["characters"] do
			if i == move["ck"] then
				-- Order
				NS.db["characters"][i]["order"] = move["order"];
			elseif move["ck"] > move["order"] then
				-- Moving Up, Reorder Downward
				if i == move["order"] or ( i < move["ck"] and i > move["order"] ) then
					NS.db["characters"][i]["order"] = i + 1;
				end
			elseif move["ck"] < move["order"] then
				-- Moving Down, Reorder Upward
				if i == move["order"] or ( i > move["ck"] and i < move["order"] ) then
					NS.db["characters"][i]["order"] = i - 1;
				end
			end
		end
		NS.Sort( NS.db["characters"], "order", "ASC" );
	end
	--
	NS.currentCharacter.key = NS.FindKeyByField( NS.db["characters"], "name", NS.currentCharacter.name );
	NS.selectedCharacterKey = NS.FindKeyByField( NS.db["characters"], "name", selectedCharacterName );
end
--
NS.ChangeColumns = function( old, new )
	-- Create temp table for column slugs that require change
	local t = {};
	-- Write column slugs to temp table that require change
	for i = 1, #NS.db["monitorColumn"] do
		if i == old then
			-- New
			t[new] = NS.db["monitorColumn"][i];
		elseif old > new then
			-- Moving Up, Reorder Downward
			if i == new or ( i < old and i > new ) then
				t[i + 1] = NS.db["monitorColumn"][i];
			end
		elseif old < new then
			-- Moving Down, Reorder Upward
			if i == new or ( i > old and i < new ) then
				t[i - 1] = NS.db["monitorColumn"][i];
			end
		end
	end
	-- Copy changed column slugs to primary table
	for k,v in pairs( t ) do
		NS.db["monitorColumn"][k] = v;
	end
end
--
NS.ResetCharactersOrderPositions = function()
	for i = 1, #NS.db["characters"] do
		NS.db["characters"][i]["order"] = i;
	end
end
--
NS.OrdersReadyForPickup = function( ready, total, duration, nextSeconds, passedTime )
	-- Calculate how many orders could have completed in the time passed, which could not be larger than the
	-- amount of orders in progress ( i.e. total - ready ), then we just add the orders that were already ready
	if not total then
		return 0;
	elseif duration == 0 then
		return total;
	else
		return math.min( math.floor( ( passedTime + ( duration - nextSeconds ) ) / duration ), ( total - ready ) ) + ready;
	end
end
--
NS.OrdersReadyToStart = function( capacity, total, troopCount )
	total = total and total or 0;
	troopCount = troopCount and troopCount or 0;
	return ( capacity - ( total + troopCount ) );
end
--
NS.OrdersAllSeconds = function( duration, total, ready, nextSeconds, passedTime )
	if not total or duration == 0 then
		return 0;
	else
		local seconds = duration * ( total - ready ) - ( duration - ( nextSeconds - passedTime ) );
		return math.max( seconds, 0 );
	end
end
--
NS.OrdersNextSeconds = function( allSeconds, duration )
	if allSeconds == 0 then
		return 0;
	elseif allSeconds == duration then
		return duration;
	else
		return allSeconds % duration;
	end
end
--
NS.OrdersOrigNextSeconds = function( duration, creationTime, currentTime )
	if not creationTime or duration == 0 or creationTime == 0 then
		return 0;
	else
		local passedTime = math.max( ( currentTime - creationTime ), 0 );
		return ( duration - passedTime );
	end
end
--
NS.ToggleAlert = function()
	if not NS.minimapButtonFlash then
		NS.minimapButtonFlash = WCCMinimapButton:CreateAnimationGroup();
		NS.minimapButtonFlash:SetLooping( "REPEAT" );
		local a1 = NS.minimapButtonFlash:CreateAnimation( "Alpha" );
		a1:SetDuration( 0.5 );
		a1:SetFromAlpha( 1 );
		a1:SetToAlpha( -1 );
		a1:SetOrder( 1 );
		local a2 = NS.minimapButtonFlash:CreateAnimation( "Alpha" );
		a2:SetDuration( 0.5 );
		a2:SetFromAlpha( -1 );
		a2:SetToAlpha( 1 );
		a2:SetOrder( 2 );
	end
	--
	if NS.db["showMinimapButton"] and ( not NS.db["alertDisableInInstances"] or not IsInInstance() ) and (
			( NS.db["alert"] == "current" and NS.allCharacters.alertCurrentCharacter ) or ( NS.db["alert"] == "any" and NS.allCharacters.alertAnyCharacter )
		) then
		if not NS.alertFlashing then
			NS.alertFlashing = true;
			NS.minimapButtonFlash:Play();
		end
	else
		if NS.alertFlashing then
			NS.alertFlashing = false;
			NS.minimapButtonFlash:Stop();
		end
	end
end
--
NS.ShipmentConfirmsComplete = function()
	NS.shipmentConfirmsFlaggedComplete = true;
	_G[NS.UI.SubFrames[1]:GetName() .. "MessageShipmentConfirmsText"]:SetText( "" );
	if NS.UI.SubFrames[1]:IsShown() then
		NS.refresh = true;
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Updates
--------------------------------------------------------------------------------------------------------------------------------------------
NS.UpdateCharacter = function()
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Find/Add Character
	--------------------------------------------------------------------------------------------------------------------------------------------
	local newCharacter = false;
	local k = NS.FindKeyByField( NS.db["characters"], "name", NS.currentCharacter.name ) or #NS.db["characters"] + 1;
	if not NS.db["characters"][k] then
		newCharacter = true; -- Flag for sort
		NS.db["characters"][k] = {
			["name"] = NS.currentCharacter.name,			-- Permanent
			["realm"] = GetRealmName(),						-- Permanent
			["class"] = NS.currentCharacter.class,			-- Permanent
			["level"] = 0,									-- Reset below every update
			["xp"] = 0,										-- ^
			["xpMax"] = 0,									-- ^
			["xpPercent"] = 0,								-- ^
			["isRested"] = nil,								-- ^
			["hoaLevel"] = 0,								-- ^
			["ap"] = 0,										-- ^
			["apMax"] = 0,									-- ^
			["apPercent"] = 0,								-- ^
			["factionIcon"] = nil,							-- ^ (Pandas may change)
			["warResources"] = 0,							-- ^
			["advancement"] = {},							-- ^
			["orders"] = {},								-- ^
			["troops"] = {},								-- ^
			["troopsUnlocked"] = false,						-- ^
			["champions"] = {},								-- ^
			["missions"] = {},								-- ^
			["seals"] = {},									-- ^
			["monitor"] = {},								-- Set below for each item when first added
		};
	end
	local char = NS.db["characters"][k];
	--------------------------------------------------------------------------------------------------------------------------------------------
	char["level"] = UnitLevel( "player" );
	char["xp"] = UnitXP( "player" );
	char["xpMax"] = UnitXPMax( "player" );
	char["xpPercent"] = char["level"] ~= NS.maxLevelForPlayerExpansion and math.floor( ( char["xp"] / char["xpMax"] * 100 ) ) or 0;
	char["isRested"] = char["level"] ~= NS.maxLevelForPlayerExpansion and ( IsResting() or GetXPExhaustion() ) or false;
	--
	local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem();
	if azeriteItemLocation then
		char["ap"], char["apMax"] = C_AzeriteItem.GetAzeriteItemXPInfo( azeriteItemLocation );
		char["hoaLevel"] = C_AzeriteItem.GetPowerLevel( azeriteItemLocation );
		char["apPercent"] = math.floor( ( char["ap"] / char["apMax"] * 100 ) );
	else
		char["ap"] = 0;
		char["apMax"] = 0;
		char["hoaLevel"] = 0;
		char["apPercent"] = 0;
	end
	--
	char["factionIcon"] = NS.currentCharacter.factionIcon;
	--
	char["warResources"] = C_CurrencyInfo.GetCurrencyInfo( 1560 )["quantity"];
	char["sealOfWartornFate"] = C_CurrencyInfo.GetCurrencyInfo( 1580 )["quantity"];
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- War Campaign Mission Table ?
	--------------------------------------------------------------------------------------------------------------------------------------------
	local hasWarCampaignMissionTable = C_Garrison.HasGarrison( Enum.GarrisonType.Type_8_0 );
	if hasWarCampaignMissionTable then
		--------------------------------------------------------------------------------------------------------------------------------------------
		-- Shipment Confirm: Avoids incomplete and inaccurate data being recorded following login, reloads, and pickups
		--------------------------------------------------------------------------------------------------------------------------------------------
		local shipmentsNum,shipmentsNumReady = 0,0;
		--
		local followerShipments = C_Garrison.GetFollowerShipments( Enum.GarrisonType.Type_8_0 );
		shipmentsNum = shipmentsNum + #followerShipments;
		for i = 1, #followerShipments do
			local name,texture,shipmentCapacity,shipmentsReady,shipmentsTotal,creationTime,duration,timeleftString = C_Garrison.GetLandingPageShipmentInfoByContainerID( followerShipments[i] );
			if name and texture and shipmentCapacity > 0 and shipmentsReady and shipmentsTotal > 0 then
				shipmentsNumReady = shipmentsNumReady + 1;
			end
		end
		--
		local shipmentConfirmed = false;
		if shipmentsNum == shipmentsNumReady then
			shipmentConfirmed = true;
			if not NS.shipmentConfirmsFlaggedComplete and NS.shipmentConfirmsCount < NS.shipmentConfirmsRequired then
				NS.shipmentConfirmsCount = NS.shipmentConfirmsCount + 1;
				if NS.shipmentConfirmsCount == NS.shipmentConfirmsRequired then
					NS.ShipmentConfirmsComplete();
				end
			end
		end
		--------------------------------------------------------------------------------------------------------------------------------------------
		-- Update War Campaign info the moment shipments are confirmed
		--------------------------------------------------------------------------------------------------------------------------------------------
		if NS.shipmentConfirmsFlaggedComplete and shipmentConfirmed then
			local monitorable = {};
			local currentTime = time();
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Advancement
			--------------------------------------------------------------------------------------------------------------------------------------------
			wipe( char["advancement"] ); -- Start fresh every update
			if char["monitor"]["advancement"] == nil then
				char["monitor"]["advancement"] = true;
			end
			monitorable["advancement"] = true;
			--
			local talentTiers = {}; -- Selected talents by tier
			--
			local talentTreeIDs = C_Garrison.GetTalentTreeIDsByClassID( Enum.GarrisonType.Type_8_0, NS.currentCharacter.classID );
			local completeTalentID = C_Garrison.GetCompleteTalent( Enum.GarrisonType.Type_8_0 );
			local talentTreeIDIndex = NS.currentCharacter.factionIcon == 2173920 --[[ Horde ]] and 1 or 2; -- 1=152 and 2=153
			if talentTreeIDs and talentTreeIDs[talentTreeIDIndex] then -- Talent trees and treeID available
				local talentTree = C_Garrison.GetTalentTreeInfo( talentTreeIDs[talentTreeIDIndex] )["talents"];
				for _,talent in ipairs( talentTree ) do
					talent.tier = talent.tier + 1; -- Fix tiers starting at 0
					talent.uiOrder = talent.uiOrder + 1; -- Fix order starting at 0
					if talent.selected or talent.isBeingResearched then
						-- selected applies only to completed talents whether they be completed now or previously
						-- isBeingResearched applies only to talents that are currently being researched and have timeRemaining > 0
						talentTiers[talent.tier] = talent;
						if talent.isBeingResearched or (talent.selected and talent.id == completeTalentID) then
							char["advancement"]["tierBeingResearched"] = talent.tier;
						end
					end
				end
				-- Talent Tier Available?
				if ( not char["advancement"]["tierBeingResearched"] and #talentTiers < NS.maxAdvancementTiers ) then
					char["advancement"]["newTalentTier"] = {};
					local newTier = #talentTiers + 1;
					for _,talent in ipairs( talentTree ) do
						if talent.tier == newTier then
							char["advancement"]["newTalentTier"][talent.uiOrder] = CopyTable( talent );
						end
					end
				end
				-- Advancements Locked? -- Not if player has talents or is on quest "Adapting Our Tactics"
				if #talentTiers > 0	or ( NS.currentCharacter.factionIcon == 2173920 --[[ Horde ]] and C_QuestLog.GetLogIndexForQuestID( 53602 ) ~= nil ) or ( NS.currentCharacter.factionIcon == 2173919 --[[ Alliance]] and C_QuestLog.GetLogIndexForQuestID( 53583 ) ~= nil ) then
					char["advancement"]["locked"] = false;
				else
					char["advancement"]["locked"] = true;
				end
			end
			--
			char["advancement"]["selectedTalents"] = CopyTable( talentTiers );
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Work Orders
			--------------------------------------------------------------------------------------------------------------------------------------------
			wipe( char["orders"] ); -- Start fresh every update
			-- Follower Shipments
			local followerShipments = C_Garrison.GetFollowerShipments( Enum.GarrisonType.Type_8_0 );
			for i = 1, #followerShipments do
				local name,texture,capacity,ready,total,creationTime,duration = C_Garrison.GetLandingPageShipmentInfoByContainerID( followerShipments[i] );
				table.insert( char["orders"], {
					["name"] = name,
					["texture"] = texture,
					["capacity"] = capacity,
					["ready"] = ready,
					["total"] = total,
					["duration"] = duration,
					["nextSeconds"] = NS.OrdersOrigNextSeconds( duration, creationTime, currentTime ),
				} );
				--NS.Print( texture .. ":" .. name ); -- DEBUG
			end
			-- Troops and Champions
			do
				-- Data
				local troops = {};
				local champions = {};
				local troopCapacity = 4 + ( talentTiers[2] and not talentTiers[2].isBeingResearched and talentTiers[2].id == 553 --[[ Upgraded Troop Barracks ]] and 2 or 0 ); -- 549
				local followers = C_Garrison.GetFollowers( Enum.GarrisonFollowerType.FollowerType_8_0 );
				char["troopsUnlocked"] = C_QuestLog.IsQuestFlaggedCompleted( 51771 ) --[[ Horde ]] or C_QuestLog.IsQuestFlaggedCompleted( 51715 ) --[[ Alliance ]] or false;
				if followers and #followers > 0 then
					for i = 1, #followers do
						if C_Garrison.GetFollowerIsTroop( followers[i].followerID ) then
						-- Troop
							troops[#troops + 1] = {
								portraitIconID = followers[i].portraitIconID,
								quality = followers[i].quality,
								name = followers[i].name,
								durability = followers[i].durability,
								maxDurability = followers[i].maxDurability,
								onMission = false, -- reset below in Missions
							};
						-- Champion
						elseif followers[i].isCollected then
							champions[#champions + 1] = {
								portraitIconID = followers[i].portraitIconID,
								quality = followers[i].quality,
								name = followers[i].name,
								xp = followers[i].xp,
								levelXP = followers[i].levelXP,
								onMission = false, -- reset below in Missions
							};
						end
					end
				end
				NS.Sort( troops, "quality", "DESC" ); -- Order by quality for a more consistent tooltip display
				NS.Sort( champions, "quality", "DESC" ); -- ^
				char["troops"] = CopyTable( troops );
				char["champions"] = CopyTable( champions );
				-- Troops - merge troop data into follower shipment (work order) or create a placeholder work order
				local texture = NS.currentCharacter.factionIcon;
				local name = FOLLOWERLIST_LABEL_TROOPS;
				if #followerShipments == 1 then -- SHOULD BE ONLY ONE AT THIS TIME
					-- Troop order FOUND
					local order = char["orders"][1]; -- ONE ^
					order["name"] = name;
					order["texture"] = texture;
					order["capacity"] = troopCapacity;
					order["troopCount"] = #troops;
				else
					-- Troop order NOT FOUND
					table.insert( char["orders"], {
						["name"] = name,
						["texture"] = texture,
						["capacity"] = troopCapacity,
						["troopCount"] = #troops,
					} );
				end
				if char["monitor"][texture] == nil then
					char["monitor"][texture] = true; -- Monitored by default
				end
				monitorable[texture] = true;
				-- Champions
				if char["monitor"]["champions"] == nil then
					char["monitor"]["champions"] = true; -- Monitored by default
				end
				monitorable["champions"] = true;
			end
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Missions
			--------------------------------------------------------------------------------------------------------------------------------------------
			wipe( char["missions"] );
			char["missions"] = C_Garrison.GetLandingPageItems( Enum.GarrisonType.Type_8_0 ); -- In Progress or Complete
			for i = 1, #char["missions"] do
				local mission = char["missions"][i];
				-- Success Chance
				mission.successChance = C_Garrison.GetMissionSuccessChance( mission.missionID );
				-- Rewards
				mission.rewardsList = {};
				for _,reward in pairs( mission.rewards ) do
					if reward.quality then
						mission.rewardsList[#mission.rewardsList + 1] = ITEM_QUALITY_COLORS[reward.quality + 1].hex .. reward.title .. FONT_COLOR_CODE_CLOSE;
					elseif reward.itemID then
						local itemName,_,itemRarity,_,_,_,_,_,_,itemTexture = GetItemInfo( reward.itemID );
						if not itemTexture then
							_,_,_,_,itemTexture = GetItemInfoInstant( reward.itemID );
						end
						if itemName then
							mission.rewardsList[#mission.rewardsList + 1] = "|T" .. itemTexture .. ":20:20:-2:0|t" .. ITEM_QUALITY_COLORS[itemRarity].hex .. itemName .. FONT_COLOR_CODE_CLOSE;
						else
							mission.rewardsList[#mission.rewardsList + 1] = "|T" .. itemTexture .. ":20:20:0:0|t";
						end
					elseif reward.followerXP then
						mission.rewardsList[#mission.rewardsList + 1] = HIGHLIGHT_FONT_COLOR_CODE .. reward.title .. FONT_COLOR_CODE_CLOSE;
					else
						mission.rewardsList[#mission.rewardsList + 1] = HIGHLIGHT_FONT_COLOR_CODE .. reward.title .. FONT_COLOR_CODE_CLOSE;
					end
				end
				-- Followers
				for x = 1, #mission.followers do
					mission.followers[x] = C_Garrison.GetFollowerName( mission.followers[x] ) or UNKNOWN;
					-- Insert mission times into Troops and Champions data
					if mission.timeLeftSeconds then
						local championKey = NS.FindKeyByField( char["champions"], "name", mission.followers[x] );
						if championKey then
							char["champions"][championKey]["timeLeftSeconds"] = mission.timeLeftSeconds;
						else
							local troopKey = NS.FindKeyByField( char["troops"], "name", mission.followers[x] );
							if troopKey then
								char["troops"][troopKey]["timeLeftSeconds"] = mission.timeLeftSeconds;
							end
						end
					end
				end
			end
			if char["monitor"]["missions"] == nil then
				char["monitor"]["missions"] = true; -- Monitored by default
			end
			monitorable["missions"] = true;
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Seals
			--------------------------------------------------------------------------------------------------------------------------------------------
			wipe( char["seals"] );
			if char["level"] >= 50 then
				-- Seal of Wartorn Fate Quests
				local sealOfWartornFateQuestsCompleted = 0;
				for i = 1, #NS.sealOfWartornFateQuests do
					if C_QuestLog.IsQuestFlaggedCompleted( NS.sealOfWartornFateQuests[i] ) then
						sealOfWartornFateQuestsCompleted = sealOfWartornFateQuestsCompleted + 1;
						if sealOfWartornFateQuestsCompleted == NS.sealOfWartornFateWeeklyMax then
							break; -- Stop early when possible
						end
					end
				end
				char["seals"]["sealOfWartornFateQuestsCompleted"] = sealOfWartornFateQuestsCompleted;
			end
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Update Time / Monitor Clean Up
			--------------------------------------------------------------------------------------------------------------------------------------------
			char["updateTime"] = currentTime;
			char["weeklyResetTime"] = NS.GetWeeklyQuestResetTime();
			if not newCharacter then
				-- Monitor Clean Up, only when NOT a new character
				for monitor in pairs( char["monitor"] ) do
					if not monitorable[monitor] then
						char["monitor"][monitor] = nil;
					end
				end
			end
		end
	elseif not NS.shipmentConfirmsFlaggedComplete then
		NS.ShipmentConfirmsComplete(); -- shipmentConfirms bypassed if no War Campaign Mission Table
	end
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Sort Characters by realm and name, only when a new character was added
	--------------------------------------------------------------------------------------------------------------------------------------------
	if newCharacter then
		if NS.db["orderCharactersAutomatically"] then
			NS.SortCharacters( "automatic" );
			NS.ResetCharactersOrderPositions();
		else
			char["order"] = k;
		end
	end
end
--
NS.UpdateCharacters = function()
	-- All Characters
	local seals = {};
	local missions = {};
	local advancement = {};
	local champions = {};
	local orders = {};
	local monitoredCharacters = {};
	--
	local missionsComplete = 0;
	local missionsTotal = 0;
	local nextMissionTimeRemaining = 0; -- Lowest time remaining for a mission to complete.
	local allMissionsTimeRemaining = 0; -- Highest Time remaining for a mission to complete.
	local nextMissionCharName = "";
	--
	local advancementsComplete = 0;
	local advancementsTotal = 0;
	local nextAdvancementTimeRemaining = 0; -- Lowest time remaining for an order advancement to complete.
	local allAdvancementsTimeRemaining = 0; -- Highest time remaining for an order advancement to complete.
	local nextAdvancementCharName = "";
	--
	local workOrdersReady = 0;
	local workOrdersTotal = 0;
	local nextWorkOrderTimeRemaining = 0; -- Lowest time remaining for a work order to complete.
	local allWorkOrdersTimeRemaining = 0; -- Highest time remaining for a work order to complete.
	local nextWorkOrderCharName = "";
	--
	local alertCurrentCharacter = false;
	local alertAnyCharacter = false;
	--
	-- Loop thru each character
	--
	local currentTime = time();
	for ck,char in ipairs( NS.db["characters"] ) do
		local passedTime = char["updateTime"] and ( currentTime > char["updateTime"] and ( currentTime - char["updateTime"] ) or 0 ) or nil; -- Characters without an 8.0 Garrison will not have an updateTime
		--
		-- Total War Resources & Seals -- (only from monitored characters)
		--
		if NS.PairsFindKeyByValue( char["monitor"], true ) then
			monitoredCharacters[char["name"]] = true;
		end
		--
		-- Seals
		--
		seals[char["name"]] = {};
		if char["seals"]["sealOfWartornFateQuestsCompleted"] --[[ number - initialized when char reaches level 50 ]] then
			local s = seals[char["name"]];
			s.sealOfWartornFate = {
				text = string.format( L["Seal of Wartorn Fate - %d/%d"], char["sealOfWartornFate"], NS.sealOfWartornFateMax ),
				lines = {},
				thisWeekQuests = 0,
				thisWeekWorkOrder = 0,
				thisWeek = 0,
			};
			--
			local sealsThisWeekQuests,sealsThisWeek = 0,0;
			if currentTime <= char["weeklyResetTime"] then
				s.sealOfWartornFate.thisWeekQuests = char["seals"]["sealOfWartornFateQuestsCompleted"];
				s.sealOfWartornFate.thisWeek = s.sealOfWartornFate.thisWeekWorkOrder + s.sealOfWartornFate.thisWeekQuests;
			end
			--
			s.sealOfWartornFate.lines[#s.sealOfWartornFate.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["%d/%d - This week's \"Seal of Wartorn Fate\" quests"], s.sealOfWartornFate.thisWeekQuests, NS.sealOfWartornFateWeeklyMax ) .. FONT_COLOR_CODE_CLOSE;
			s.sealOfWartornFate.lines[#s.sealOfWartornFate.lines + 1] = " ";
			s.sealOfWartornFate.lines[#s.sealOfWartornFate.lines + 1] = string.format( L["%sTotal Weekly:|r %s%d/%d|r"], NORMAL_FONT_COLOR_CODE, ( s.sealOfWartornFate.thisWeek == NS.sealOfWartornFateWeeklyMax and RED_FONT_COLOR_CODE or HIGHLIGHT_FONT_COLOR_CODE ), s.sealOfWartornFate.thisWeek, NS.sealOfWartornFateWeeklyMax );
		end
		--
		-- Missions
		--
		missions[char["name"]] = {};
		if char["monitor"]["missions"] then
			local mip = missions[char["name"]];
			mip.texture = 1044517;
			mip.text = string.format( L["Missions In Progress - %d"], #char["missions"] );
			mip.lines = {};
			mip.total = #char["missions"];
			mip.incomplete = mip.total;
			mip.nextMissionTimeRemaining = 0;
			missionsTotal = missionsTotal + mip.total; -- All characters
			for _,m in ipairs( char["missions"] ) do -- m is for mission
				if not m["typeInlineTexture"] then
					m["typeInlineTexture"] = NS.GetAtlasInlineTexture( m.typeAtlas, 24, 24 ); -- Update char missions for LDB tooltip use / Also prevents excessive use of GetAtlasInlineTexture()
				end
				mip.lines[#mip.lines + 1] = " ";
				mip.lines[#mip.lines + 1] = m.typeInlineTexture .. " " .. m.name;
				mip.lines[#mip.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. LEVEL .. " " .. m.level .. " (" .. m.iLevel .. ")" .. FONT_COLOR_CODE_CLOSE;
				mip.lines[#mip.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. ( m.successChance and string.format( GARRISON_MISSION_PERCENT_CHANCE, m.successChance ) or UNKNOWN ) .. FONT_COLOR_CODE_CLOSE;
				--
				mip.lines[#mip.lines + 1] = REWARDS;
				for i = 1, #m.rewardsList do
					mip.lines[#mip.lines + 1] = m.rewardsList[i];
				end
				--
				mip.lines[#mip.lines + 1] = L["Followers"];
				for i = 1, #m.followers do
					mip.lines[#mip.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. ( m.followers[i] or UNKNOWN ) .. FONT_COLOR_CODE_CLOSE;
				end
				--
				local timeLeftSeconds = ( m.timeLeftSeconds and m.timeLeftSeconds >= passedTime ) and ( m.timeLeftSeconds - passedTime ) or 0;
				m["lastKnownTimeLeftSeconds"] = timeLeftSeconds; -- Update char missions for LDB tooltip use
				if timeLeftSeconds == 0 then
					mip.lines[#mip.lines + 1] = GREEN_FONT_COLOR_CODE .. COMPLETE .. FONT_COLOR_CODE_CLOSE;
					mip.incomplete = mip.incomplete - 1;
					missionsComplete = missionsComplete + 1; -- All characters
				else
					mip.lines[#mip.lines + 1] = RED_FONT_COLOR_CODE .. SecondsToTime( timeLeftSeconds ) .. FONT_COLOR_CODE_CLOSE;
					mip.nextMissionTimeRemaining = mip.nextMissionTimeRemaining == 0 and timeLeftSeconds or math.min( mip.nextMissionTimeRemaining, timeLeftSeconds ); -- Character
					nextMissionTimeRemaining = nextMissionTimeRemaining == 0 and timeLeftSeconds or math.min( nextMissionTimeRemaining, timeLeftSeconds ); -- All characters
					allMissionsTimeRemaining = allMissionsTimeRemaining == 0 and timeLeftSeconds or math.max( allMissionsTimeRemaining, timeLeftSeconds ); -- All characters
					nextMissionCharName = nextMissionTimeRemaining == timeLeftSeconds and ( "|c" .. RAID_CLASS_COLORS[char["class"]].colorStr .. ( NS.db["showCharacterRealms"] and char["name"] or strsplit( "-", char["name"], 2 ) ) .. FONT_COLOR_CODE_CLOSE ) or nextMissionCharName;
				end
			end
			if #mip.lines == 0 then
				mip.lines[#mip.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. GARRISON_EMPTY_IN_PROGRESS_LIST .. FONT_COLOR_CODE_CLOSE;
			elseif mip.incomplete == 0 then
				if NS.db["alertMissions"] then
					alertCurrentCharacter = ( not alertCurrentCharacter and char["name"] == NS.currentCharacter.name ) and true or alertCurrentCharacter; -- All characters
					alertAnyCharacter = true; -- All characters
				end
			end
			mip.color = ( mip.total == 0 and "Gray" ) or ( mip.incomplete == mip.total and "Red" ) or ( mip.incomplete > 0 and "Yellow" ) or "Green";
		end
		--
		-- Advancements
		--
		advancement[char["name"]] = {};
		if char["monitor"]["advancement"] then
			local wea = advancement[char["name"]];
			--
			-- SHIFT
			--
			wea.shiftText = L["Advancements"];
			wea.shiftLines = {};
			--
			if #char["advancement"]["selectedTalents"] == 0 then
				-- No talents
				wea.shiftLines[#wea.shiftLines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. L["No advancements researched"] .. FONT_COLOR_CODE_CLOSE;
			else
				-- Selected talents
				for i = 1, #char["advancement"]["selectedTalents"] do
					local talent = char["advancement"]["selectedTalents"][i];
					--
					if not talent.tier then
						wea.shiftLines[#wea.shiftLines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. L["No data. Log into character once to fix."] .. FONT_COLOR_CODE_CLOSE;
						break; -- stop early, no data - OLD VERSION - character pre v1.03
					end
					--
					wea.shiftLines[#wea.shiftLines + 1] = " ";
					wea.shiftLines[#wea.shiftLines + 1] = "|T" .. talent.icon .. ":20|t " .. HIGHLIGHT_FONT_COLOR_CODE .. talent.name .. FONT_COLOR_CODE_CLOSE;
					wea.shiftLines[#wea.shiftLines + 1] = { talent.description, nil, nil, nil, true };
					wea.shiftLines[#wea.shiftLines + 1] = BATTLENET_FONT_COLOR_CODE .. string.format( L["Tier %d"], talent.tier ) .. FONT_COLOR_CODE_CLOSE;
				end
			end
			--
			-- NO-SHIFT
			--
			if char["advancement"]["tierBeingResearched"] then
				advancementsTotal = advancementsTotal + 1; -- All characters
				local talent = char["advancement"]["selectedTalents"][char["advancement"]["tierBeingResearched"]];
				wea.texture = talent.icon;
				wea.text = "|T" .. talent.icon .. ":20|t " .. HIGHLIGHT_FONT_COLOR_CODE .. talent.name .. FONT_COLOR_CODE_CLOSE;
				wea.seconds = talent.timeRemaining > passedTime and ( talent.timeRemaining - passedTime ) or 0;
				wea.lines = {};
				wea.lines[#wea.lines + 1] = { talent.description, nil, nil, nil, true };
				wea.lines[#wea.lines + 1] = " ";
				if wea.seconds > 0 then
					wea.lines[#wea.lines + 1] = string.format( L["Time Remaining: %s"], HIGHLIGHT_FONT_COLOR_CODE .. SecondsToTime( wea.seconds ) ) .. FONT_COLOR_CODE_CLOSE;
					nextAdvancementTimeRemaining = nextAdvancementTimeRemaining == 0 and wea.seconds or math.min( nextAdvancementTimeRemaining, wea.seconds ); -- All characters
					allAdvancementsTimeRemaining = allAdvancementsTimeRemaining == 0 and wea.seconds or math.max( allAdvancementsTimeRemaining, wea.seconds ); -- All characters
					nextAdvancementCharName = nextAdvancementTimeRemaining == wea.seconds and ( "|c" .. RAID_CLASS_COLORS[char["class"]].colorStr .. ( NS.db["showCharacterRealms"] and char["name"] or strsplit( "-", char["name"], 2 ) ) .. FONT_COLOR_CODE_CLOSE ) or nextAdvancementCharName;
				else
					advancementsComplete = advancementsComplete + 1; -- All characters
					wea.lines[#wea.lines + 1] = GREEN_FONT_COLOR_CODE .. COMPLETE .. FONT_COLOR_CODE_CLOSE;
					if NS.db["alertAdvancements"] then
						alertCurrentCharacter = ( not alertCurrentCharacter and char["name"] == NS.currentCharacter.name ) and true or alertCurrentCharacter; -- All characters
						alertAnyCharacter = true; -- All characters
					end
				end
				wea.status = "researching";
			elseif char["advancement"]["newTalentTier"] then
				wea.texture = char["advancement"]["newTalentTier"][1].icon;
				wea.text = string.format( L["Advancements - Tier %d"], char["advancement"]["newTalentTier"][1].tier );
				wea.lines = {};
				for i = 1, #char["advancement"]["newTalentTier"] do
					local talent = char["advancement"]["newTalentTier"][i];
					wea.lines[#wea.lines + 1] = " ";
					wea.lines[#wea.lines + 1] = "|T" .. talent.icon .. ":20|t " .. HIGHLIGHT_FONT_COLOR_CODE .. talent.name .. FONT_COLOR_CODE_CLOSE;
					wea.lines[#wea.lines + 1] = { talent.description, nil, nil, nil, true };
					wea.lines[#wea.lines + 1] = " ";
					wea.lines[#wea.lines + 1] = string.format( L["Research Time: %s"], HIGHLIGHT_FONT_COLOR_CODE .. SecondsToTime( talent.researchDuration ) ) .. FONT_COLOR_CODE_CLOSE;
					wea.lines[#wea.lines + 1] = string.format( L["Cost: %s"], HIGHLIGHT_FONT_COLOR_CODE .. BreakUpLargeNumbers( talent.researchCurrencyCosts[1].currencyQuantity ) .. FONT_COLOR_CODE_CLOSE .. "|T".. 2032600 ..":0:0:2:0|t" );
					-- Conditions
					if talent.tier == 1 then
						-- Level
						if char["level"] < 47 then
							wea.condition = RED_FONT_COLOR_CODE .. string.format( ITEM_MIN_LEVEL, 47 ) .. FONT_COLOR_CODE_CLOSE;
							wea.lines[#wea.lines + 1] = wea.condition;
						-- Locked
						elseif char["advancement"]["locked"] then
							wea.condition = RED_FONT_COLOR_CODE .. L["Requires quest \"Adapting Our Tactics\"."] .. FONT_COLOR_CODE_CLOSE;
							wea.lines[#wea.lines + 1] = wea.condition;
						end
					elseif talent.playerConditionReason then
						-- ???
						wea.condition = RED_FONT_COLOR_CODE .. talent.playerConditionReason .. FONT_COLOR_CODE_CLOSE;
						wea.lines[#wea.lines + 1] = RED_FONT_COLOR_CODE .. talent.playerConditionReason .. FONT_COLOR_CODE_CLOSE;
					end
				end
				wea.status = "available";
			elseif #char["advancement"]["selectedTalents"] == NS.maxAdvancementTiers then
				wea.texture = 133743;
				wea.text = string.format( L["Advancements - %d/%d"], NS.maxAdvancementTiers, NS.maxAdvancementTiers );
				wea.lines = {};
				wea.lines[#wea.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. L["No new tiers available."] .. FONT_COLOR_CODE_CLOSE;
				wea.status = "maxed";
			end
			-- [Shift] message
			if #char["advancement"]["selectedTalents"] > 0 then
				wea.lines[#wea.lines + 1] = " ";
				wea.lines[#wea.lines + 1] = BATTLENET_FONT_COLOR_CODE .. L["Hold [Shift] to view selected tiers"] .. FONT_COLOR_CODE_CLOSE;
			end
			--
			wea.color = ( ( wea.status == "available" or wea.status == "maxed" ) and "Gray" ) or ( wea.status == "researching" and ( wea.seconds > 0 and "Red" or "Green" ) ) or nil; -- nil if a character doesn't have their newTalentTier info, since v1.24 the info is recorded regardless of level requirement
		end
		--
		-- Champions
		--
		champions[char["name"]] = {};
		if char["monitor"]["champions"] then
			local ch = champions[char["name"]];
			ch.texture = char["factionIcon"] == 2173920 --[[ Horde ]] and 2026471 or 2026469; -- Falstad Wildhammer or Arcanist Valtrois
			ch.count = #char["champions"];
			ch.text = string.format( L["Champions - %d/%d"], #char["champions"], NS.maxChampions );
			ch.lines = {};
			if #char["champions"] == 0 then
				ch.lines[#ch.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. L["No champions collected"] .. FONT_COLOR_CODE_CLOSE;
			else
				ch.lines[#ch.lines + 1] = " "; -- spacer
				for i = 1, #char["champions"] do
					local c = char["champions"][i];
					local timeLeftSeconds = ( c.timeLeftSeconds and c.timeLeftSeconds >= passedTime ) and ( c.timeLeftSeconds - passedTime ) or 0;
					local timeLeft = c.timeLeftSeconds and ( "  " .. NS.SecondsToStrTime( timeLeftSeconds, BATTLENET_FONT_COLOR_CODE ) ) or "";
					c["lastKnownTimeLeftSeconds"] = timeLeftSeconds; -- Update champion missions for LDB tooltip use
					--
					ch.lines[#ch.lines + 1] = "|T" .. c.portraitIconID .. ":32:32|t  " .. ITEM_QUALITY_COLORS[c.quality].hex .. c.name .. FONT_COLOR_CODE_CLOSE .. timeLeft;
					if c.levelXP and c.levelXP > 0 and c.xp and c.quality < 5 then -- [[ Legendary quality is max upgrade ]]
						ch.lines[#ch.lines + 1] = "|T" .. 136449 --[[ see ArtTextureID.lua ]] .. ":1:32|t  " .. string.format( L["%s%d XP to|r %s"], HIGHLIGHT_FONT_COLOR_CODE, ( c.levelXP - c.xp ), ( ITEM_QUALITY_COLORS[c.quality + 1].hex .. _G["ITEM_QUALITY" .. ( c.quality + 1 ) .. "_DESC"] .. FONT_COLOR_CODE_CLOSE ) );
						ch.lines[#ch.lines + 1] = " "; -- spacer
					end
				end
			end
		end
		--
		-- Work Orders
		--
		orders[char["name"]] = {};
		local troopNum = 0; -- Used to increment multiple troop types for monitor order
		for _,o in ipairs( char["orders"] ) do -- o is for order
			if char["monitor"][o["texture"]] then -- Orders use texture as the monitorIndex
				orders[char["name"]][#orders[char["name"]] + 1] = {};
				local wo = orders[char["name"]][#orders[char["name"]]];
				wo.texture = o.texture;
				wo.text = o.name;
				wo.troopCount = o.troopCount;
				wo.capacity = o.capacity;
				wo.total = o.total or 0; -- o.total is nil if no orders
				wo.readyForPickup = NS.OrdersReadyForPickup( o.ready, o.total, o.duration, o.nextSeconds, passedTime );
				wo.readyToStart = NS.OrdersReadyToStart( wo.capacity, o.total, wo.troopCount );
				local allSeconds = NS.OrdersAllSeconds( o.duration, o.total, o.ready, o.nextSeconds, passedTime );
				wo.nextSeconds = NS.OrdersNextSeconds( allSeconds, o.duration );
				wo.topRightText = nil;
				--
				workOrdersReady = workOrdersReady + wo.readyForPickup; -- All characters
				workOrdersTotal = workOrdersTotal + wo.total; -- All characters
				if wo.nextSeconds > 0 then
					nextWorkOrderTimeRemaining = nextWorkOrderTimeRemaining == 0 and wo.nextSeconds or math.min( nextWorkOrderTimeRemaining, wo.nextSeconds ); -- All characters
					allWorkOrdersTimeRemaining = allWorkOrdersTimeRemaining == 0 and allSeconds or math.max( allWorkOrdersTimeRemaining, allSeconds ); -- All characters
					nextWorkOrderCharName = nextWorkOrderTimeRemaining == wo.nextSeconds and ( "|c" .. RAID_CLASS_COLORS[char["class"]].colorStr .. ( NS.db["showCharacterRealms"] and char["name"] or strsplit( "-", char["name"], 2 ) ) .. FONT_COLOR_CODE_CLOSE ) or nextWorkOrderCharName; -- All characters
				end
				--
				wo.lines = {};
				-- Troop count and details
				if wo.troopCount then
					wo.text = wo.text .. " - " .. wo.troopCount .. "/" .. wo.capacity;
					wo.topRightText = wo.readyToStart > 0 and char["troopsUnlocked"] and ( ORANGE_FONT_COLOR_CODE .. wo.troopCount .. FONT_COLOR_CODE_CLOSE ) or wo.troopCount;
					if NS.db["showTroopDetailsInTooltip"] and #char["troops"] > 0 then
						wo.lines[#wo.lines + 1] = " "; -- spacer
						local fullHeart, emptyHeart = NS.GetAtlasInlineTexture( 'GarrisonTroops-Health' ), NS.GetAtlasInlineTexture( 'GarrisonTroops-Health-Consume' );
						for i = 1, #char["troops"] do
							local t = char["troops"][i];
							local timeLeftSeconds = ( t.timeLeftSeconds and t.timeLeftSeconds >= passedTime ) and ( t.timeLeftSeconds - passedTime ) or 0;
							local timeLeft = t.timeLeftSeconds and ( "  " .. NS.SecondsToStrTime( timeLeftSeconds, BATTLENET_FONT_COLOR_CODE ) ) or "";
							t["lastKnownTimeLeftSeconds"] = timeLeftSeconds; -- Update troop missions for LDB tooltip use
							--
							local health = {};
							for x = 1, t.maxDurability do
								health[#health + 1] = x > t.durability and emptyHeart or fullHeart;
							end
							wo.lines[#wo.lines + 1] = "|T" .. t.portraitIconID .. ":32:32|t  " .. table.concat( health, " " ) .. "  " .. ITEM_QUALITY_COLORS[t.quality].hex .. t.name .. timeLeft;
						end
						wo.lines[#wo.lines + 1] = " "; -- spacer
					end
				end
				-- Ready to start
				if wo.readyToStart > 0 then
					if char["troopsUnlocked"] then
						wo.lines[#wo.lines + 1] = GREEN_FONT_COLOR_CODE .. string.format( L["%d Ready to start"], wo.readyToStart ) .. FONT_COLOR_CODE_CLOSE;
					else
						wo.lines[#wo.lines + 1] = RED_FONT_COLOR_CODE .. L["Locked"] .. FONT_COLOR_CODE_CLOSE;
					end
				end
				-- Ready for pickup
				if wo.total > 0 then
					if wo.readyForPickup == wo.total then
						wo.lines[#wo.lines + 1] = GREEN_FONT_COLOR_CODE .. string.format( L["%d Ready for pickup"], wo.readyForPickup ) .. FONT_COLOR_CODE_CLOSE;
						if wo.troopCount and NS.db["alertTroops"] then
							alertCurrentCharacter = ( not alertCurrentCharacter and char["name"] == NS.currentCharacter.name ) and true or alertCurrentCharacter; -- All characters
							alertAnyCharacter = true; -- All characters
						end
					else
						wo.lines[#wo.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["%d/%d Ready for pickup %s"], wo.readyForPickup, wo.total, string.format( L["(Next: %s)"], SecondsToTime( wo.nextSeconds ) ) ) .. FONT_COLOR_CODE_CLOSE;
					end
				end
				-- Troops full
				if wo.troopCount and wo.troopCount >= wo.capacity then
					wo.lines[#wo.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. L["0 recruits remaining"] .. FONT_COLOR_CODE_CLOSE;
				end
				-- Monitor column
				if wo.troopCount then
					troopNum = troopNum + 1;
					wo.monitorColumn = "troop" .. troopNum;
				end
				-- Indicator color
				wo.color = ( wo.total == 0 and "Gray" ) or ( wo.readyForPickup == 0 and "Red" ) or ( wo.readyForPickup < wo.total and "Yellow" ) or "Green";
			end
		end
	end
	-- Save to namespace for use on Monitor tab
	wipe( NS.allCharacters );
	--
	NS.allCharacters.seals = CopyTable( seals );
	NS.allCharacters.missions = CopyTable( missions );
	NS.allCharacters.advancement = CopyTable( advancement );
	NS.allCharacters.champions = CopyTable( champions );
	NS.allCharacters.orders = CopyTable( orders );
	NS.allCharacters.monitoredCharacters = CopyTable( monitoredCharacters );
	--
	NS.allCharacters.missionsComplete = missionsComplete;
	NS.allCharacters.missionsTotal = missionsTotal;
	NS.allCharacters.nextMissionTimeRemaining = nextMissionTimeRemaining;
	NS.allCharacters.allMissionsTimeRemaining = allMissionsTimeRemaining;
	NS.allCharacters.nextMissionCharName = nextMissionCharName;
	--
	NS.allCharacters.advancementsComplete = advancementsComplete;
	NS.allCharacters.advancementsTotal = advancementsTotal;
	NS.allCharacters.nextAdvancementTimeRemaining = nextAdvancementTimeRemaining;
	NS.allCharacters.allAdvancementsTimeRemaining = allAdvancementsTimeRemaining;
	NS.allCharacters.nextAdvancementCharName = nextAdvancementCharName;
	--
	NS.allCharacters.workOrdersReady = workOrdersReady;
	NS.allCharacters.workOrdersTotal = workOrdersTotal;
	NS.allCharacters.nextWorkOrderTimeRemaining = nextWorkOrderTimeRemaining;
	NS.allCharacters.allWorkOrdersTimeRemaining = allWorkOrdersTimeRemaining;
	NS.allCharacters.nextWorkOrderCharName = nextWorkOrderCharName;
	--
	NS.allCharacters.alertCurrentCharacter = alertCurrentCharacter;
	NS.allCharacters.alertAnyCharacter = alertAnyCharacter;
end
--
NS.UpdateLDB = function()
	local char = NS.db["characters"][NS.currentCharacter.key];
	--
	local headerTooltip = { lines = {} };
	local missionsTooltip = { label = L["Missions"], lines = {} };
	local advancementsTooltip = { label = L["Advancements"], lines = {} };
	local ordersTooltip = { label = L["Troops"], lines = {} };
	--
	local hoaLabel = NS.db["ldbShowLabels"] and ( NORMAL_FONT_COLOR_CODE .. ( NS.db["ldbUseLetterLabels"] and L["H"] or L["HoA"] ) .. ": " .. FONT_COLOR_CODE_CLOSE ) or "";
	local hoaText = char["hoaLevel"] > 0 and ( ITEM_QUALITY_COLORS[6].hex .. char["hoaLevel"] .. "(" .. char["apPercent"] .. "%)" .. FONT_COLOR_CODE_CLOSE ) or nil;
	--
	local resourcesLabel = NS.db["ldbShowLabels"] and ( NORMAL_FONT_COLOR_CODE .. ( NS.db["ldbUseLetterLabels"] and L["R"] or L["Resources"] ) .. ": " .. FONT_COLOR_CODE_CLOSE ) or "";
	local resourcesText = NS.allCharacters.monitoredCharacters[char["name"]] and ( HIGHLIGHT_FONT_COLOR_CODE .. char["warResources"] .. FONT_COLOR_CODE_CLOSE ) or nil;
	--
	local sealsLabel = NS.db["ldbShowLabels"] and ( NORMAL_FONT_COLOR_CODE .. ( NS.db["ldbUseLetterLabels"] and L["S"] or L["Seals"] ) .. ": " .. FONT_COLOR_CODE_CLOSE ) or "";
	local sealsText = NS.allCharacters.monitoredCharacters[char["name"]] and ( HIGHLIGHT_FONT_COLOR_CODE .. char["sealOfWartornFate"] .. FONT_COLOR_CODE_CLOSE ) or nil;
	----------------------------------------------------------------------------------------------------------------------------------------
	-- (Current) Character Tooltip
	----------------------------------------------------------------------------------------------------------------------------------------
	do
		-- Header
		headerTooltip.lines[#headerTooltip.lines + 1] = {
			--[[ Character Name ]]( "|c" .. RAID_CLASS_COLORS[NS.currentCharacter.class].colorStr .. ( NS.db["showCharacterRealms"] and NS.currentCharacter.name or strsplit( "-", NS.currentCharacter.name, 2 ) ) .. FONT_COLOR_CODE_CLOSE ),
			--[[ War Resources ]]( HIGHLIGHT_FONT_COLOR_CODE .. char["warResources"] .. FONT_COLOR_CODE_CLOSE .. "|T" .. 2032600 .. ":16:16:3:0|t" ) ..
			--[[ Seal of Wartorn Fate ]]( NS.allCharacters.seals[NS.currentCharacter.name].sealOfWartornFate and ( "   " .. HIGHLIGHT_FONT_COLOR_CODE .. char["sealOfWartornFate"] .. FONT_COLOR_CODE_CLOSE .. "|T" .. 1416740 .. ":16:16:3:0|t" ) or "" ) ..
			--[[ Heart of Azeroth Level ]]( "   " .. NORMAL_FONT_COLOR_CODE .. char["hoaLevel"] .. FONT_COLOR_CODE_CLOSE .. "|T" .. 1869493 .. ":16:16:3:0:64:64:10:60:10:60|t" ),
			"GameFontNormalLarge",
		};
		-- Missions
		-- mt = Missions Total
		-- mm = Missions Monitored
		local mt,mm = 0,false;
		local missions = NS.allCharacters.missions[NS.currentCharacter.name];
		if next( missions ) then
			mt = missions.total;
			mm = true;
		end
		if mt > 0 then
			-- List
			for _,m in ipairs( char["missions"] ) do -- Pulls mission details from char table, NOT allCharacters
				if m.lastKnownTimeLeftSeconds == 0 then
					missionsTooltip.lines[#missionsTooltip.lines + 1] = { ( m.typeInlineTexture .. " " .. m.name ), ( GREEN_FONT_COLOR_CODE .. L["Complete"] .. FONT_COLOR_CODE_CLOSE ), "GameFontNormalSmall" };
				else
					missionsTooltip.lines[#missionsTooltip.lines + 1] = { ( m.typeInlineTexture .. " " .. m.name ), ( RED_FONT_COLOR_CODE .. SecondsToTime( m.lastKnownTimeLeftSeconds, false, false, 2 ) .. FONT_COLOR_CODE_CLOSE ), "GameFontNormalSmall" };
				end
				for i = 1, #m.rewardsList do
					missionsTooltip.lines[#missionsTooltip.lines + 1] = { "          " .. m.rewardsList[i] , " ", "GameFontNormalSmall" };
				end
			end
		else
			-- None
			if mm then
				missionsTooltip.lines[#missionsTooltip.lines + 1] = { ( GRAY_FONT_COLOR_CODE .. L["None in progress"] .. FONT_COLOR_CODE_CLOSE ), " ", "GameFontNormalSmall" };
			end
		end
		-- Advancement
		-- ac = Advancements Complete
		-- at = Advancements Total
		-- natr = Next Advancement Time Remaining
		-- ari = Advancement Research Info [Researching, Available, Maxed] (Current)
		local ac,at,natr,ari = 0,0,0,nil;
		local advancement = NS.allCharacters.advancement[NS.currentCharacter.name];
		if next( advancement ) then
			ac = ( advancement.seconds and advancement.seconds == 0 and 1 ) or 0;
			at = advancement.seconds and 1 or 0;
			natr = advancement.seconds and advancement.seconds;
			ari = ( advancement.status == "researching" and char["advancement"]["tierBeingResearched"] and char["advancement"]["selectedTalents"][char["advancement"]["tierBeingResearched"]] ) or
			( advancement.status == "available" and { icon = char["advancement"]["newTalentTier"][1].icon, name = string.format( L["%sNew!|r Tier %d: %s"], GREEN_FONT_COLOR_CODE, char["advancement"]["newTalentTier"][1].tier, ( HIGHLIGHT_FONT_COLOR_CODE .. SecondsToTime( char["advancement"]["newTalentTier"][1].researchDuration ) .. " - " .. BreakUpLargeNumbers( char["advancement"]["newTalentTier"][1].researchCurrencyCosts[1].currencyQuantity ) .. FONT_COLOR_CODE_CLOSE .. "|T" .. 2032600 ..":0:0:2:0|t" ) ) } ) or
			( advancement.status == "maxed" and { icon = advancement.texture, name = ( GRAY_FONT_COLOR_CODE .. L["No new tiers available"] .. FONT_COLOR_CODE_CLOSE ) } );
		end
		if at == 0 then
			if ari then
				-- Available, Maxed
				advancementsTooltip.lines[#advancementsTooltip.lines + 1] = { ( "|T" .. ari.icon .. ":24:24|t " .. ari.name ), ( advancement.status == "available" and ( advancement.condition and advancement.condition or ( GREEN_FONT_COLOR_CODE .. L["Ready to start"] .. FONT_COLOR_CODE_CLOSE ) ) or " " ), "GameFontNormalSmall" };
			end
		elseif ac == at then
			-- Researching (Complete)
			advancementsTooltip.lines[#advancementsTooltip.lines + 1] = { ( "|T" .. ari.icon .. ":24:24|t " .. ari.name ), ( GREEN_FONT_COLOR_CODE .. L["Complete"] .. FONT_COLOR_CODE_CLOSE ), "GameFontNormalSmall" };
		else
			-- Researching (In Progress)
			advancementsTooltip.lines[#advancementsTooltip.lines + 1] = { ( "|T" .. ari.icon .. ":24:24|t " .. ari.name ), ( RED_FONT_COLOR_CODE .. SecondsToTime( natr, false, false, 2 ) .. FONT_COLOR_CODE_CLOSE ), "GameFontNormalSmall" };
		end
		-- Orders
		local orders = NS.allCharacters.orders[NS.currentCharacter.name];
		for i = 1, #orders do
			local complete = orders[i].readyForPickup;
			local total = orders[i].total;
			local readyToStart = orders[i].readyToStart;
			local icon = orders[i].texture;
			local leftText = orders[i].text;
			local rightText;
			if orders[i].troopCount then
				-- Troops
				if orders[i].troopCount >= orders[i].capacity then
					-- White, 0 recruits remaining
					rightText = HIGHLIGHT_FONT_COLOR_CODE .. L["0 recruits remaining"] .. FONT_COLOR_CODE_CLOSE;
				elseif total == 0 then
					if char["troopsUnlocked"] then
						-- Green, None in progress, Ready to start
						rightText = GREEN_FONT_COLOR_CODE .. string.format( L["%d Ready to start"], readyToStart ) .. FONT_COLOR_CODE_CLOSE;
					else
						rightText = RED_FONT_COLOR_CODE .. L["Locked"] .. FONT_COLOR_CODE_CLOSE;
					end
				elseif complete == total then
					-- Green, All complete
					rightText = GREEN_FONT_COLOR_CODE .. string.format( L["%d Ready"], total ) .. FONT_COLOR_CODE_CLOSE;
				else
					-- Yellow, Some complete
					-- Red, All incomplete
					rightText = ( complete > 0 and YELLOW_FONT_COLOR_CODE or RED_FONT_COLOR_CODE ) .. string.format( L["%d/%d Ready"], complete, total ) .. FONT_COLOR_CODE_CLOSE .. " " .. HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( orders[i].nextSeconds, false, false, 1 ) ) .. FONT_COLOR_CODE_CLOSE;
				end
			else
				-- Non-troops
				if total == 0 then
					-- Green, None in progress, Ready to start
					-- Gray, Not available
					rightText = orders[i].readyToStart > 0 and ( GREEN_FONT_COLOR_CODE .. string.format( L["%d Ready to start"], readyToStart ) .. FONT_COLOR_CODE_CLOSE ) or ( GRAY_FONT_COLOR_CODE .. L["Not available"] .. FONT_COLOR_CODE_CLOSE );
				elseif complete == total then
					-- Green, All complete
					rightText = GREEN_FONT_COLOR_CODE .. string.format( L["%d Ready"], total ) .. FONT_COLOR_CODE_CLOSE;
				else
					-- Yellow, Some complete
					-- Red, All incomplete
					rightText = ( complete > 0 and YELLOW_FONT_COLOR_CODE or RED_FONT_COLOR_CODE ) .. string.format( L["%d/%d Ready"], complete, total ) .. FONT_COLOR_CODE_CLOSE .. " " .. HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( orders[i].nextSeconds, false, false, 1 ) ) .. FONT_COLOR_CODE_CLOSE;
				end
			end
			ordersTooltip.lines[#ordersTooltip.lines + 1] = { ( "|T" .. icon .. ":24:24|t " .. leftText ), rightText, "GameFontNormalSmall" };
			--
			-- Show Troop Details
			--
			if NS.db["showTroopDetailsInTooltip"] and orders[i].troopCount and #char["troops"] > 0 then
				ordersTooltip.lines[#ordersTooltip.lines + 1] = { " ", " ", "GameFontNormalSmall" }; -- spacer
				for i = 1, #char["troops"] do
					local t = char["troops"][i];
					local timeLeft = t.timeLeftSeconds and ( BATTLENET_FONT_COLOR_CODE .. SecondsToTime( t.lastKnownTimeLeftSeconds ) .. FONT_COLOR_CODE_CLOSE ) or " ";
					--
					local health = {};
					for x = 1, t.maxDurability do
						health[#health + 1] = x > t.durability and NS.emptyHeart or NS.fullHeart;
					end
					ordersTooltip.lines[#ordersTooltip.lines + 1] = { "   |T" .. t.portraitIconID .. ":24:24:0:3|t  " .. table.concat( health, " " ) .. "  " .. ITEM_QUALITY_COLORS[t.quality].hex .. t.name, timeLeft, "GameFontNormalSmall" };
				end
			end
		end
	end
	----------------------------------------------------------------------------------------------------------------------------------------
	-- (All or Current) Character(s) Text
	----------------------------------------------------------------------------------------------------------------------------------------
	-- Missions
	-- mc = Missions Complete
	-- mt = Missions Total
	-- nmtr = Next Mission Time Remaining
	-- mm = Missions Monitored (Current)
	local mc,mt,nmtr,mm = 0,0,0,false;
	if NS.db["ldbSource"] == "current" then
		local missions = NS.allCharacters.missions[NS.currentCharacter.name];
		if next( missions ) then
			mc = missions.total - missions.incomplete;
			mt = missions.total;
			nmtr = missions.nextMissionTimeRemaining;
			mm = true;
		end
	else
		mc = NS.allCharacters.missionsComplete;
		mt = NS.allCharacters.missionsTotal;
		nmtr = NS.allCharacters.nextMissionTimeRemaining;
	end
	local missionsLabel = NS.db["ldbShowLabels"] and ( NORMAL_FONT_COLOR_CODE .. ( NS.db["ldbUseLetterLabels"] and L["M"] or L["Missions"] ) .. ": " .. FONT_COLOR_CODE_CLOSE ) or "";
	local missionsText;
	if mt == 0 then
		-- Text
		missionsText = ( NS.db["ldbShowWhenNone"] and ( mm or NS.db["ldbSource"] == "all" ) and ( GRAY_FONT_COLOR_CODE .. ( NS.db["ldbNumbersOnly"] and 0 or L["None"] ) .. FONT_COLOR_CODE_CLOSE ) ) or nil;
	elseif mc == mt then
		-- Text
		missionsText = GREEN_FONT_COLOR_CODE .. mt .. ( NS.db["ldbNumbersOnly"] and "" or " " .. L["Ready"] ) .. FONT_COLOR_CODE_CLOSE;
	else
		-- Text
		missionsText = HIGHLIGHT_FONT_COLOR_CODE .. mc .. "/" .. mt .. FONT_COLOR_CODE_CLOSE;
		if NS.db["ldbShowNextMission"] then
			missionsText = missionsText .. " " .. HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( nmtr, false, false, 1 ) ) .. FONT_COLOR_CODE_CLOSE;
			if NS.db["ldbShowNextMissionCharacter"] and NS.db["ldbSource"] == "all" then
				missionsText = missionsText .. " " .. NS.allCharacters.nextMissionCharName;
			end
		end
	end
	-- Advancement
	-- ac = Advancements Complete
	-- at = Advancements Total
	-- natr = Next Advancement Time Remaining
	-- am = Advancements Monitored (Current)
	local ac,at,natr,am = 0,0,0,false;
	if NS.db["ldbSource"] == "current" then
		local advancement = NS.allCharacters.advancement[NS.currentCharacter.name];
		if next( advancement ) then
			ac = ( advancement.seconds and advancement.seconds == 0 and 1 ) or 0;
			at = advancement.seconds and 1 or 0;
			natr = advancement.seconds and advancement.seconds;
			am = true;
		end
	else
		ac = NS.allCharacters.advancementsComplete;
		at = NS.allCharacters.advancementsTotal;
		natr = NS.allCharacters.nextAdvancementTimeRemaining;
	end
	local advancementsLabel = NS.db["ldbShowLabels"] and ( NORMAL_FONT_COLOR_CODE .. ( NS.db["ldbUseLetterLabels"] and L["A"] or L["Advancements"] ) .. ": " .. FONT_COLOR_CODE_CLOSE ) or "";
	local advancementsText;
	if at == 0 then
		-- Text
		advancementsText = NS.db["ldbShowWhenNone"] and ( am or NS.db["ldbSource"] == "all" ) and ( GRAY_FONT_COLOR_CODE .. ( NS.db["ldbNumbersOnly"] and 0 or L["None"] ) .. FONT_COLOR_CODE_CLOSE ) or nil;
	elseif ac == at then
		-- Text
		advancementsText = GREEN_FONT_COLOR_CODE .. ( NS.db["ldbSource"] == "current" and ( NS.db["ldbNumbersOnly"] and 1 or "" ) or ( at .. ( NS.db["ldbNumbersOnly"] and "" or " " ) ) ) .. ( NS.db["ldbNumbersOnly"] and "" or L["Ready"] ) .. FONT_COLOR_CODE_CLOSE;
	else
		-- Text
		advancementsText = HIGHLIGHT_FONT_COLOR_CODE .. ( NS.db["ldbSource"] == "current" and SecondsToTime( natr, false, false, 1 ) or ( ac .. "/" .. at ) ) .. FONT_COLOR_CODE_CLOSE;
		if NS.db["ldbShowNextAdvancement"] and NS.db["ldbSource"] == "all" then
			advancementsText = advancementsText .. " " .. HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( natr, false, false, 1 ) ) .. FONT_COLOR_CODE_CLOSE;
			if NS.db["ldbShowNextAdvancementCharacter"] then
				advancementsText = advancementsText .. " " .. NS.allCharacters.nextAdvancementCharName;
			end
		end
	end
	-- Orders
	-- oc = Orders Complete
	-- ot = Orders Total
	-- notr = Next Order Time Remaining
	-- om = Orders Monitored (Current)
	local oc,ot,notr,om = 0,0,0,false;
	if NS.db["ldbSource"] == "current" then
		local orders = NS.allCharacters.orders[NS.currentCharacter.name];
		for i = 1, #orders do
			oc = oc + orders[i].readyForPickup;
			ot = ot + orders[i].total;
			notr = ( orders[i].nextSeconds == 0 and notr ) or ( notr == 0 and orders[i].nextSeconds or math.min( notr, orders[i].nextSeconds ) );
			om = true;
		end
	else
		oc = NS.allCharacters.workOrdersReady;
		ot = NS.allCharacters.workOrdersTotal;
		notr = NS.allCharacters.nextWorkOrderTimeRemaining;
	end
	local ordersLabel = NS.db["ldbShowLabels"] and ( NORMAL_FONT_COLOR_CODE .. ( NS.db["ldbUseLetterLabels"] and L["O"] or L["Orders"] ) .. ": " .. FONT_COLOR_CODE_CLOSE ) or "";
	local ordersText;
	if ot == 0 then
		-- Text
		ordersText = NS.db["ldbShowWhenNone"] and ( om or NS.db["ldbSource"] == "all" ) and ( GRAY_FONT_COLOR_CODE .. ( NS.db["ldbNumbersOnly"] and 0 or L["None"] ) .. FONT_COLOR_CODE_CLOSE ) or nil;
	elseif oc == ot then
		-- Text
		ordersText = GREEN_FONT_COLOR_CODE .. ot .. ( NS.db["ldbNumbersOnly"] and "" or " " .. L["Ready"] ) .. FONT_COLOR_CODE_CLOSE;
	else
		-- Text
		ordersText = HIGHLIGHT_FONT_COLOR_CODE .. oc .. "/" .. ot .. FONT_COLOR_CODE_CLOSE;
		if NS.db["ldbShowNextOrder"] then
			ordersText = ordersText .. " " .. HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( notr, false, false, 1 ) ) .. FONT_COLOR_CODE_CLOSE;
			if NS.db["ldbShowNextOrderCharacter"] and NS.db["ldbSource"] == "all" then
				ordersText = ordersText .. " " .. NS.allCharacters.nextWorkOrderCharName;
			end
		end
	end
	----------------------------------------------------------------------------------------------------------------------------------------
	-- Icon, Text, and Tooltip
	----------------------------------------------------------------------------------------------------------------------------------------
	-- Icon
	NS.ldb.icon = NS.db["ldbSource"] == "current" and NS.currentCharacter.factionIcon or 2032600;
	-- Text Format
	local textFormat = { "missions", "advancements", "orders", "hoa", "resources", "seals" };
	local i = 1;
	while i <= #textFormat do
		if textFormat[i] == "missions" then
			textFormat[i] = missionsText and NS.db["ldbShowMissions"] and ( missionsLabel .. missionsText ) or "remove";
		elseif textFormat[i] == "advancements" then
			textFormat[i] = advancementsText and NS.db["ldbShowAdvancements"] and ( advancementsLabel .. advancementsText ) or "remove";
		elseif textFormat[i] == "orders" then
			textFormat[i] = ordersText and NS.db["ldbShowOrders"] and ( ordersLabel .. ordersText ) or "remove";
		elseif textFormat[i] == "hoa" then
			textFormat[i] = hoaText and NS.db["ldbShowHOA"] and ( hoaLabel .. hoaText ) or "remove";
		elseif textFormat[i] == "resources" then
			textFormat[i] = resourcesText and NS.db["ldbShowResources"] and ( resourcesLabel .. resourcesText ) or "remove";
		elseif textFormat[i] == "seals" then
			textFormat[i] = sealsText and NS.db["ldbShowSeals"] and ( sealsLabel .. sealsText ) or "remove";
		end
		--
		if textFormat[i] == "remove" then
			table.remove( textFormat, i );
		else
			i = i + 1;
		end
	end
	NS.ldb.text = #textFormat > 0 and table.concat( textFormat, " " ) or ( NORMAL_FONT_COLOR_CODE .. NS.addon .. FONT_COLOR_CODE_CLOSE );
	-- Tooltip
	NS.ldbTooltip.header = headerTooltip;
	NS.ldbTooltip.missions = missionsTooltip;
	NS.ldbTooltip.advancements = advancementsTooltip;
	NS.ldbTooltip.orders = ordersTooltip;
	NS.ldbTooltip.available = C_Garrison.HasGarrison( Enum.GarrisonType.Type_8_0 );
end
--
NS.UpdateAll = function( forceUpdate )
	-- Stop and delay attempted regular update if a forceUpdate has run recently
	if not forceUpdate then
		local lastSecondsUpdateAll = time() - NS.lastTimeUpdateAll;
		if lastSecondsUpdateAll < NS.updateAllInterval then
			C_Timer.After( ( NS.updateAllInterval - lastSecondsUpdateAll ), NS.UpdateAll );
			return; -- Stop function
		end
	end
	-- Character(s)
	NS.UpdateCharacter();
	NS.UpdateCharacters();
	-- Initialize Continued
	if not NS.initialized then
		-- More Variables
		NS.currentCharacter.key = NS.FindKeyByField( NS.db["characters"], "name", NS.currentCharacter.name ); -- Set key here after UpdateCharacter() because new characters will cause a characters sort
		NS.selectedCharacterKey = NS.currentCharacter.key; -- Sets selected character in Characters tab
		-- Events (continued from WCCEventsFrame > OnLoad)
		WCCEventsFrame:RegisterEvent( "CHAT_MSG_CURRENCY" ); -- Fires when War Resources are looted
		WCCEventsFrame:RegisterEvent( "BONUS_ROLL_RESULT" ); -- Fires when Bonus Rolls are used
		WCCEventsFrame:RegisterEvent( "GARRISON_MISSION_STARTED" ); -- Fires when player starts a mission
		WCCEventsFrame:RegisterEvent( "GARRISON_MISSION_BONUS_ROLL_COMPLETE" ); -- Fires when player ends a mission
		WCCEventsFrame:RegisterEvent( "PLAYER_LOGOUT" ); -- Fires when player logs out
		WCCEventsFrame:RegisterEvent( "GARRISON_FOLLOWER_ADDED" ); -- Troops
		WCCEventsFrame:RegisterEvent( "GARRISON_FOLLOWER_REMOVED" ); -- Troops
		WCCEventsFrame:RegisterEvent( "GARRISON_TALENT_COMPLETE" ); -- Troops and Advancement
		WCCEventsFrame:RegisterEvent( "GARRISON_TALENT_UPDATE" ); -- Troops and Advancement
		WCCEventsFrame:RegisterEvent( "GARRISON_SHOW_LANDING_PAGE" ); -- Troops
		WCCEventsFrame:RegisterEvent( "PLAYER_XP_UPDATE" ); -- Fires when player gains XP
		WCCEventsFrame:RegisterEvent( "AZERITE_ITEM_EXPERIENCE_CHANGED" ); -- Fires when player gains AP
		WCCEventsFrame:RegisterEvent( "PLAYER_LEVEL_UP" ); -- Fires when player levels up, duh
	end
	-- LDB
	NS.UpdateLDB();
	--
	NS.lastTimeUpdateAll = time();
	-- Schedule next regular update, repeats every 10 seconds
	if not forceUpdate or not NS.initialized then -- Initial call is forced, regular updates are not
		C_Timer.After( NS.updateAllInterval, NS.UpdateAll );
	end
	--
	NS.initialized = true;
	-- Alert
	NS.ToggleAlert(); -- Always attempt to turn on/off alerts after updating
	-- Refresh
	if NS.refresh then
		NS.UI.SubFrames[1]:Refresh();
		NS.refresh = false;
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Minimap Button
--------------------------------------------------------------------------------------------------------------------------------------------
NS.MinimapButton( "WCCMinimapButton", NS.currentCharacter.factionIcon == 2173920 --[[Horde]] and 2175464 or 2175463, { -- Uses round icons
	db = "minimapButtonPosition",
	tooltip = function()
		NS.ldb.OnTooltipShow( GameTooltip );
	end,
	OnLeftClick = function( self )
		NS.SlashCmdHandler();
	end,
	OnRightClick = function( self )
		if C_Garrison.HasGarrison( Enum.GarrisonType.Type_8_0 ) then
			GarrisonLandingPage_Toggle();
		end
	end,
	OnMiddleClick = function( self )
		NS.db["lockMinimapButton"] = ( not NS.db["lockMinimapButton"] and true ) or false;
		self.locked = NS.db["lockMinimapButton"];
	end,
} );
--------------------------------------------------------------------------------------------------------------------------------------------
-- LDB Data Object
--------------------------------------------------------------------------------------------------------------------------------------------
NS.ldb = LibStub:GetLibrary( "LibDataBroker-1.1" ):NewDataObject( NS.addon, {
	type = "data source",
	text = NORMAL_FONT_COLOR_CODE .. "..." .. FONT_COLOR_CODE_CLOSE,
	icon = NS.currentCharacter.factionIcon,
	OnClick = function( self, button )
		if button == "RightButton" and self:GetName() == NS.ldbiButtonName then -- Right-Click LibDBIcon Minimap button
			-- Open the original Missions report just as the custom Minimap button does
			if C_Garrison.HasGarrison( Enum.GarrisonType.Type_8_0 ) then
				GarrisonLandingPage_Toggle();
			end
		else
			NS.SlashCmdHandler( ( button == "RightButton" and "ldb" ) );
		end
	end,
	OnTooltipShow = function( self )
		local ownerName = self:GetOwner():GetName();
		-- Not initialized or not available and not known Minimap owner
		if not NS.initialized or ( not NS.ldbTooltip.available and ( ownerName ~= "WCCMinimapButton" and ownerName ~= NS.ldbiButtonName ) ) then return end
		-- Show default tooltip for known Minimap buttons when character tooltip is not available or disabled
		if ( not NS.ldbTooltip.available and ( ownerName == "WCCMinimapButton" or ownerName == NS.ldbiButtonName ) ) or ( not NS.db["showCharacterTooltipMinimapButton"] and ownerName == "WCCMinimapButton" ) or ( not NS.db["ldbiShowCharacterTooltip"] and ownerName == NS.ldbiButtonName ) then
			self:SetText( HIGHLIGHT_FONT_COLOR_CODE .. NS.title .. FONT_COLOR_CODE_CLOSE );
			self:AddLine( L["Left-Click to open and close"] );
			self:AddLine( L["Right-Click to show Missions report"] );
			self:AddLine( L["Drag to move this button"] );
			return;
		end
		-- Adjust anchor for known Minimap buttons when character tooltip will be shown
		if ownerName == "WCCMinimapButton" or ownerName == NS.ldbiButtonName then
			self:SetAnchorType( "ANCHOR_BOTTOMLEFT" );
		end
		-- Header
		NS.AddLinesToTooltip( NS.ldbTooltip.header.lines, "double", self );
		self:AddLine( " " );
		--
		local empty = true;
		-- Missions
		if #NS.ldbTooltip.missions.lines > 0 then
			self:AddLine( YELLOW_FONT_COLOR_CODE .. NS.ldbTooltip.missions.label .. FONT_COLOR_CODE_CLOSE );
			self:AddLine( " " );
			NS.AddLinesToTooltip( NS.ldbTooltip.missions.lines, "double", self );
			self:AddLine( " " );
			empty = nil;
		end
		-- War Effort Advancements
		if #NS.ldbTooltip.advancements.lines > 0 then
			self:AddLine( YELLOW_FONT_COLOR_CODE .. NS.ldbTooltip.advancements.label .. FONT_COLOR_CODE_CLOSE );
			self:AddLine( " " );
			NS.AddLinesToTooltip( NS.ldbTooltip.advancements.lines, "double", self );
			self:AddLine( " " );
			empty = nil;
		end
		-- Work Orders
		if #NS.ldbTooltip.orders.lines > 0 then
			self:AddLine( YELLOW_FONT_COLOR_CODE .. NS.ldbTooltip.orders.label .. FONT_COLOR_CODE_CLOSE );
			self:AddLine( " " );
			NS.AddLinesToTooltip( NS.ldbTooltip.orders.lines, "double", self );
			empty = nil;
		end
		-- Empty
		if empty then
			NS.AddLinesToTooltip( { { ( GRAY_FONT_COLOR_CODE .. L["Nothing is currently being monitored. Use the Characters tab to choose what you monitor."] .. FONT_COLOR_CODE_CLOSE ), nil, nil, nil, true, "GameFontNormal" } }, false, self );
			self:AddLine( " " );
		end
	end,
} );
--------------------------------------------------------------------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------------------------------------------------------------------
NS.SlashCmdHandler = function( cmd )
	if not NS.initialized then return end
	--
	if cmd == "hide" or ( ( not cmd or cmd == "" ) and NS.UI.MainFrame:IsShown() ) then
		NS.UI.MainFrame:Hide();
	elseif not cmd or cmd == "" or cmd == "monitor" then
		NS.UI.MainFrame:ShowTab( 1 );
	elseif cmd == "characters" then
		NS.UI.MainFrame:ShowTab( 2 );
	elseif cmd == "misc" then
		NS.UI.MainFrame:ShowTab( 3 );
	elseif cmd == "alerts" then
		NS.UI.MainFrame:ShowTab( 4 );
	elseif cmd == "ldb" then
		NS.UI.MainFrame:ShowTab( 5 );
	elseif cmd == "help" then
		NS.UI.MainFrame:ShowTab( 6 );
	else
		NS.UI.MainFrame:ShowTab( 6 );
		NS.Print( L["Unknown command, opening Help"] );
	end
end
--
SLASH_WARCAMPAIGNSCOMPLETE1 = "/warcampaignscomplete";
SLASH_WARCAMPAIGNSCOMPLETE2 = "/wcc";
SlashCmdList["WARCAMPAIGNSCOMPLETE"] = function( msg ) NS.SlashCmdHandler( msg ) end;
--------------------------------------------------------------------------------------------------------------------------------------------
-- Update Request Handler
--------------------------------------------------------------------------------------------------------------------------------------------
NS.UpdateRequestHandler = function( event )
	local currentTime = time();
	-- Ticker
	if not event then
		local hasWarCampaignMissionTable = C_Garrison.HasGarrison( Enum.GarrisonType.Type_8_0 );
		local playerMapID = C_Map.GetBestMapForUnit( "player" );
		local inBFACapitalCity = ( playerMapID == 1161 or playerMapID == 1165 ); -- Alliance-Boralus = 1161, Horde-Dazar'alor = 1165
		local inEventZoneOrPeriod = ( inBFACapitalCity or not NS.shipmentConfirmsFlaggedComplete );
		-- When INSIDE event zone or period, update requests are made automatically every 2 seconds
		-- When OUTSIDE event zone or period, update requests are only made 2 seconds after an event fires
		local updateRequestTimePast = NS.lastTimeUpdateRequest and ( currentTime - NS.lastTimeUpdateRequest ) or 0;
		local updateRequestSentTimePast = inEventZoneOrPeriod and NS.lastTimeUpdateRequestSent and ( currentTime - NS.lastTimeUpdateRequestSent ) or 0; -- Set to zero to ignore time past if OUTSIDE event zone or period
		--
		if math.max( updateRequestTimePast, updateRequestSentTimePast ) >= 2 then
			-- Send update request
			NS.lastTimeUpdateRequest = nil;
			NS.lastTimeUpdateRequestSent = currentTime;
			if hasWarCampaignMissionTable then
				-- Work Orders {REQUEST}
				WCCEventsFrame:RegisterEvent( "GARRISON_LANDINGPAGE_SHIPMENTS" );
				C_Garrison.RequestLandingPageShipmentInfo();
			else
				-- Bypass event, call update directly if player has no War Campaign Mission Table
				NS.UpdateAll( "forceUpdate" );
			end
		end
		--
		C_Timer.After( 0.5, NS.UpdateRequestHandler ); -- Emulate ticker, handling update requests every half-second
	-- Events
	else
		NS.lastTimeUpdateRequest = currentTime;
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- WCCEventsFrame
--------------------------------------------------------------------------------------------------------------------------------------------
NS.Frame( "WCCEventsFrame", UIParent, {
	topLevel = true,
	OnEvent = function ( self, event, ... )
		if event == "GARRISON_LANDINGPAGE_SHIPMENTS" then
			--------------------------------------------------------------------------------------------------------------------------------
			-- Work Orders {UPDATED}
			--------------------------------------------------------------------------------------------------------------------------------
			self:UnregisterEvent( event );
			NS.UpdateAll( "forceUpdate" );
			--------------------------------------------------------------------------------------------------------------------------------
		elseif event == "CHAT_MSG_CURRENCY" then
			--------------------------------------------------------------------------------------------------------------------------------
			-- War Resources {UPDATED}
			--------------------------------------------------------------------------------------------------------------------------------
			NS.db["characters"][NS.currentCharacter.key]["warResources"] = C_CurrencyInfo.GetCurrencyInfo( 1560 )["quantity"];
			--------------------------------------------------------------------------------------------------------------------------------
		elseif event == "BONUS_ROLL_RESULT" then
			--------------------------------------------------------------------------------------------------------------------------------
			-- Seal of Wartorn Fate {UPDATED}
			--------------------------------------------------------------------------------------------------------------------------------
			NS.db["characters"][NS.currentCharacter.key]["sealOfWartornFate"] = C_CurrencyInfo.GetCurrencyInfo( 1580 )["quantity"];
			--------------------------------------------------------------------------------------------------------------------------------
		elseif event == "GARRISON_MISSION_STARTED" or event == "GARRISON_MISSION_BONUS_ROLL_COMPLETE" then
			--------------------------------------------------------------------------------------------------------------------------------
			-- Missions started or ended at tables outside of BFA Capital City {UPDATED}
			--------------------------------------------------------------------------------------------------------------------------------
			local playerMapID = C_Map.GetBestMapForUnit( "player" ); -- Boralus = 1161, Dazar'alor = 1165
			if playerMapID ~= 1161 and playerMapID ~= 1165 then
				-- RequestLandingPageShipmentInfo() followed by NS.UpdateAll
				-- Only required and effective OUTSIDE event zone or period
				NS.UpdateRequestHandler( event );
			end
			--------------------------------------------------------------------------------------------------------------------------------
		elseif event == "ADDON_LOADED" then
			--------------------------------------------------------------------------------------------------------------------------------
			-- ADDON_LOADED
			--------------------------------------------------------------------------------------------------------------------------------
			if IsAddOnLoaded( NS.addon ) and not NS.db then
				self:UnregisterEvent( event );
				-- SavedVariables or "db"
				if not WARCAMPAIGNSCOMPLETE_SAVEDVARIABLES then
					WARCAMPAIGNSCOMPLETE_SAVEDVARIABLES = NS.DefaultSavedVariables();
				end
				NS.db = WARCAMPAIGNSCOMPLETE_SAVEDVARIABLES;
				-- Upgrade db
				if NS.db["version"] < NS.version then
					NS.Upgrade();
				end
			end
			--------------------------------------------------------------------------------------------------------------------------------
		elseif event == "PLAYER_LOGIN" then
			--------------------------------------------------------------------------------------------------------------------------------
			-- PLAYER_LOGIN
			--------------------------------------------------------------------------------------------------------------------------------
			self:UnregisterEvent( event );
			NS.UpdateRequestHandler( event ); -- Initial update request
			NS.UpdateRequestHandler(); -- Start handler/ticker
			-- WCC Minimap Button
			WCCMinimapButton.docked = NS.db["dockMinimapButton"];
			WCCMinimapButton.locked = NS.db["lockMinimapButton"];
			WCCMinimapButton:UpdateSize( NS.db["largeMinimapButton"] );
			WCCMinimapButton:UpdatePos(); -- Reset to last drag position
			if not NS.db["showMinimapButton"] then
				WCCMinimapButton:Hide(); -- Hide if unchecked in options
			end
			-- Original Missions Report Minimap Button
			GarrisonLandingPageMinimapButton:HookScript( "OnShow", function()
				if not NS.db["showOriginalMissionsReportMinimapButton"] and C_Garrison.HasGarrison( Enum.GarrisonType.Type_8_0 ) then
					GarrisonLandingPageMinimapButton:Hide();
				end
			end );
			-- LDB Icon
			NS.ldb.icon = NS.db["ldbSource"] == "current" and NS.currentCharacter.factionIcon or 2032600;
			-- LibDBIcon
			NS.ldbi = LibStub:GetLibrary( "LibDBIcon-1.0" );
			NS.ldbi:Register( NS.addon, NS.ldb, NS.db["ldbi"] );
			NS.ldbiButtonName = "LibDBIcon10_" .. NS.addon;
			--------------------------------------------------------------------------------------------------------------------------------
		elseif event == "MODIFIER_STATE_CHANGED" then
			--------------------------------------------------------------------------------------------------------------------------------
			-- MODIFIER_STATE_CHANGED
			--------------------------------------------------------------------------------------------------------------------------------
			if GetMouseFocus() == NS.TooltipMonitorButton then
				NS.TooltipMonitorButton:GetScript( "OnEnter" )( NS.TooltipMonitorButton ); -- Updates tooltip to help show all selected Advancements
			end
		else
			--------------------------------------------------------------------------------------------------------------------------------
			-- ??? {REQUEST} -- This catches all other events which should request an update. Including player level up, xp/ap, and troops.
			--------------------------------------------------------------------------------------------------------------------------------
			if C_Garrison.HasGarrison( Enum.GarrisonType.Type_8_0 ) then
				if NS.initialized then
					-- RequestLandingPageShipmentInfo() followed by NS.UpdateAll
					-- Only required and effective OUTSIDE event zone or period
					NS.UpdateRequestHandler( event );
				end
			end
			--------------------------------------------------------------------------------------------------------------------------------
		end
	end,
	OnLoad = function( self )
		-- Events (continues in NS.UpdateAll just before NS.initialized)
		self:RegisterEvent( "ADDON_LOADED" );
		self:RegisterEvent( "PLAYER_LOGIN" );
	end,
} );

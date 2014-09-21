FLIGHTTIMER_MSG_VERSION = GetAddOnMetadata("FlightTimer","Version");
FLIGHTTIMER_MSG_ADDONNAME = "Flight Timer";

-- Colours
COLOR_RED = "|cffff0000";
COLOR_GREEN = "|cff00ff00";
COLOR_BLUE = "|cff0000ff";
COLOR_PURPLE = "|cff700090";
COLOR_YELLOW = "|cffffff00";
COLOR_ORANGE = "|cffff6d00";
COLOR_GREY = "|cff808080";
COLOR_GOLD = "|cffcfb52b";
COLOR_NEON_BLUE = "|cff4d4dff";
COLOR_END = "|r";

-- options
FlightTimer_options = {
	["TaxiWarning"] = 20,
};

-- saved data
FlightTimer_flightTimes = {};

FlightTimer = {};
FlightTimer.lastUpdate = 0;
FlightTimer.landingWarningFile = "Sound\\Events\\Squire_horn_bb.Wav";

-- Support code
function FlightTimer.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_RED..FLIGHTTIMER_MSG_ADDONNAME.."> "..COLOR_END..msg;
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg );
end
function FlightTimer.Debug( msg )
	-- Print Debug Messages
	if FlightTimer.debug then
		msg = "debug-"..msg;
		FlightTimer.Print( msg );
	end
end
function FlightTimer.ParseCmd(msg)
	if msg then
		local a,b,c = strfind(msg, "(%S+)");  --contiguous string of non-space characters
		if a then
			return c, strsub(msg, b+2);
		else
			return "";
		end
	end
end

-- Command code
FlightTimer.commandList = {
	["debug"] = {
		["func"] = function() 
				FlightTimer.debug = (not FlightTimer.debug and true or nil)
				FlightTimer.Print( "Debug is now "..(FlightTimer.debug and "ON" or "OFF" ) );
			end,	
		["help"] = "Toggle debug",
	},
}
function FlightTimer.Command( msg )
	local cmd, param = FlightTimer.ParseCmd(msg);
	cmd = string.lower(cmd);
	local cmdFunc = FlightTimer.commandList[cmd];
	if cmdFunc then
		cmdFunc.func(param);
	-- else
		--InterfaceOptionsFrame_OpenToCategory("Random Fortune");
		--RF.Print("Use '/rf help' for a list of commands.");
	end
end

-- Event Handlers
function FlightTimer.OnLoad()
	FlightTimer_FlightTimeBarText:Hide();
	FlightTimer_FlightTimeBar:Hide();
	FlightTimerFrame:RegisterEvent("ADDON_LOADED");
	
	FlightTimerFrame:RegisterEvent("TAXIMAP_OPENED");
	hooksecurefunc("TakeTaxiNode", FlightTimer.TakeTaxiNode);
	
	FlightTimer.name = UnitName("player");
	FlightTimer.realm = GetRealmName();
	FlightTimer.faction = select(2, UnitFactionGroup("player"));  -- localized string

	--register slash commands
	SLASH_FT1 = "/ft";
	SlashCmdList["FT"] = function(msg) FlightTimer.Command(msg); end
end

function FlightTimer.ADDON_LOADED()
	FlightTimer.Print("FlightTimer loaded");
	hooksecurefunc("TakeTaxiNode", FlightTimer.TakeTaxiNode);
	FlightTimerFrame:UnregisterEvent("ADDON_LOADED");
end

function FlightTimer.TAXIMAP_OPENED()
	FlightTimer.Debug("I see "..NumTaxiNodes().." nodes.");
	for i = 1, NumTaxiNodes() do
		FlightTimer.Debug(TaxiNodeName(i)..":"..TaxiNodeGetType(i)..":"..GetNumRoutes(i));

		if (TaxiNodeGetType(i) == "CURRENT") then
			FlightTimer.startNode = TaxiNodeName(i);
			FlightTimer.Debug("I'm at: "..TaxiNodeName(i)..":"..
					TaxiNodeGetType(i)..":"..TaxiNodeCost(i)..":"..GetNumRoutes(i));
		end
	end
end

function FlightTimer.OnUpdate(arg1)
	if FlightTimer.flightStart and (time() >= FlightTimer.lastUpdate + 1) then
		-- Inflight, and update once per second
		FlightTimer.lastUpdate = time();
		if UnitOnTaxi("player") then
			if (FlightTimer.flightETA > time()) then
				FlightTimer.timeToGo = FlightTimer.flightETA - time();
				FlightTimer.timeStr = SecondsToTime( FlightTimer.timeToGo );
				if ((FlightTimer.playWarning) and (FlightTimer.playWarning == FlightTimer.timeToGo)) then
					PlaySoundFile(FlightTimer.landingWarningFile);
					FlightTimer.playWarning = nil;
				end
			else
				FlightTimer.timeStr = SecondsToTime( time() - FlightTimer.flightStart);
			end
			-- update bar
			FlightTimer.Debug(FlightTimer.startNode.." > "..FlightTimer.endNode);
			FlightTimer_FlightTimeBarText:SetText(FlightTimer.startNode.." > "..FlightTimer.endNode.." :: "..FlightTimer.timeStr);
			FlightTimer_FlightTimeBarText:Show();
			FlightTimer_FlightTimeBar:SetMinMaxValues(0, FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flightTime);
			FlightTimer_FlightTimeBar:SetValue(FlightTimer.flightETA - time());
			FlightTimer_FlightTimeBar:Show();

		elseif not UnitOnTaxi("player") and (time()-FlightTimer.flightStart > 2) then
			-- Getting off the Taxi, with a flight time of more than 2 seconds
			local ft = FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flightTime;
			if ft then
				FlightTimer.Print("Landed after "..SecondsToTime(time()-FlightTimer.flightStart)..". Expected flighttime: "..SecondsToTime(ft));
				PlaySoundFile(FlightTimer.landingWarningFile);
			end
			FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flightTime =
					max(ft, time()-FlightTimer.flightStart);
			-- Hide bar
			FlightTimer_FlightTimeBarText:Hide();
			FlightTimer_FlightTimeBar:Hide();
			FlightTimer.flightStart = nil;
		end
	end
end

function FlightTimer.TakeTaxiNode( index, ... )  -- hooked into when a Taxi is taken
	for i = 1, NumTaxiNodes() do
		if i==index then
			FlightTimer.Debug("Taxi from: "..FlightTimer.startNode.." -> "..TaxiNodeName(i));
			FlightTimer.endNode = TaxiNodeName(i);
		end
	end
	if not FlightTimer_flightTimes[FlightTimer.startNode] then
		FlightTimer_flightTimes[FlightTimer.startNode] = {};
		FlightTimer.Debug("Adding >"..FlightTimer.startNode.."< to startNodes.");
	end
	if not FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode] then
		FlightTimer.Debug("Adding >"..FlightTimer.endNode.."< to endNodes.");
		FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode] = {};
		FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flightTime = 0;
		FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flights = 0;
	end
	if FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flights then
		FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flights = 
				FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flights + 1;
	else
		FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flights = 1;
	end
	FlightTimer.flightStart = time();
	FlightTimer.flightETA = FlightTimer.flightStart + 
			FlightTimer_flightTimes[FlightTimer.startNode][FlightTimer.endNode].flightTime;
	if (FlightTimer_options.TaxiWarning) then
		FlightTimer.playWarning = FlightTimer_options.TaxiWarning;
	end
	FlightTimer.Debug("Flight start: "..FlightTimer.flightStart);
	FlightTimer.Debug("Flight ETA  : "..date( "%x %X", FlightTimer.flightETA ) )
	-- FlightTimer.debug = nil;
end
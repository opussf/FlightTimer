#!/usr/bin/env lua
-----------------------------------------
-- Author  :  $Author:$
-- Date    :  $Date:$
-- Revision:  $Revision:$
-----------------------------------------

addonData = {
	['version'] = "1.0",
}

require "wowTest"

test.outFileName = "testOut.xml"

-- from XML
FlightTimerFrame = Frame
FlightTimer_FlightTimeBarText = CreateFontString("FlightTimeBarText")
FlightTimer_FlightTimeBar = CreateStatusBar("FlightTimeBar")
--

package.path = "../src/?.lua;" .. package.path
require "FlightTimer"

function test.before()
	FlightTimer.OnLoad()
	FlightTimer.flightStart = nil
	FlightTimer.lastUpdate = time() - 5
	--print( "----> Before" )
end
function test.after()
	FlightTimer.debug = nil
	FlightTimer_flightTimes = {}  -- force reset
	--print( "after <----" )
end
function test.testDebug_ToggleOn()
	FlightTimer.Command("debug")
	assertTrue( FlightTimer.debug, "Should the toggled on" )
end
function test.testDebug_ToggleOff()
	FlightTimer.Command("debug")
	FlightTimer.Command("debug")
	assertFalse( FlightTimer.debug, "Should be false" )
	assertIsNil( FlightTimer.debug, "Should be nil" )
end
function test.testOnLoad_NameSet()
	assertEquals( "testPlayer", FlightTimer.name )
end
function test.testOnLoad_RealmSet()
	assertEquals( "testRealm", FlightTimer.realm )
end
function test.testOnLoad_FactionSet()
	assertEquals( "Alliance", FlightTimer.faction )
end
function test.testADDON_LOADED()
	FlightTimer.ADDON_LOADED()
end
function test.testTAXIMAP_OPENED_startNodeSet()
	FlightTimer.debug = true
	FlightTimer.TAXIMAP_OPENED()
	assertEquals( "Stormwind", FlightTimer.startNode )
end
function test.testTAXIMAP_OPENED_02()
	FlightTimer.TAXIMAP_OPENED()
	assertEquals( "Stormwind", FlightTimer.startNode )
end
function test.testTakeTaxiNode_endNodeSet()
	FlightTimer.TAXIMAP_OPENED()
	FlightTimer.debug = true
	FlightTimer.TakeTaxiNode(2)
	assertEquals( "Rebel Camp", FlightTimer.endNode )
end
function test.testTakeTaxiNode_dataStructureCreated_countIs1()
	FlightTimer.TAXIMAP_OPENED()
	FlightTimer.TakeTaxiNode(2)
	assertEquals( 1, FlightTimer_flightTimes["Stormwind"]["Rebel Camp"].flights )
end
function test.testTakeTaxiNode_dataStructureCreated_countIs2()
	FlightTimer_flightTimes["Stormwind"] = { ["Rebel Camp"] = { ["flights"] = 1, ["flightTime"] = 323 } }
	FlightTimer.TAXIMAP_OPENED()
	FlightTimer.TakeTaxiNode(2)
	assertEquals( 2, FlightTimer_flightTimes["Stormwind"]["Rebel Camp"].flights )
end
function test.testTakeTaxiNode_flightStart_Set()
	FlightTimer.TAXIMAP_OPENED()
	FlightTimer.TakeTaxiNode(2)
	assertTrue( FlightTimer.flightStart ) -- make sure it is set
end
function test.testTakeTaxiNode_flightTime_SetZero()
	FlightTimer.TAXIMAP_OPENED()
	FlightTimer.TakeTaxiNode(2)
	assertEquals( 0, FlightTimer_flightTimes["Stormwind"]["Rebel Camp"].flightTime ) -- make sure it is set
end

function test.testPruneFlightTimes_01()
	-- history
	FlightTimer.debug = true
	FlightTimer_flightTimes["Stormwind"] = {
			["Rebel Camp"] = {
				["flights"] = 120,
				["flightTime"] = 99,
				["flightTimes"] = { 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
									25, 26, 27, 28, 29, 30, 15, 16, 20, 5, 20, 20 }
			}
		}
	FlightTimer.TAXIMAP_OPENED()
	FlightTimer.TakeTaxiNode(2)
	FlightTimer.flightStart = time() - 22
	FlightTimer.OnUpdate()

	assertIsNil( FlightTimer_flightTimes["Stormwind"]["Rebel Camp"].flightTimes[20], "5 seconds should be removed" )
	assertIsNil( FlightTimer_flightTimes["Stormwind"]["Rebel Camp"].flightTimes[0], "Oldest should be removed for size" )
end
function test.testPruneFlightTimes_02()
	-- history
	FlightTimer.debug = true
	FlightTimer_flightTimes["Stormwind"] = {
			["Rebel Camp"] = {
				["flights"] = 120,
				["flightTime"] = 99,
				["flightTimes"] = { [1635631132] = 135,  [2] = 130,
									[1634779148] = 57,   [4] = 135,
									[1635210020] = 135,  [6] = 136,
									[1633843640] = 136,  [8] = 134,
									[1633493019] = 135,  [10] = 136,
									[1634786005] = 136,  [12] = 136,
									[1635306258] = 136,  [14] = 135,
									[1635038053] = 50,   [16] = 135,
									[1635226762] = 136,  [18] = 136,
									[1635210000] = 5,    [20] = 135,
				}
			}
		}
	FlightTimer.TAXIMAP_OPENED()
	FlightTimer.TakeTaxiNode(2)
	FlightTimer.flightStart = time() - 135
	FlightTimer.OnUpdate()

	assertIsNil( FlightTimer_flightTimes["Stormwind"]["Rebel Camp"].flightTimes[1635210000], "5 seconds should be removed" )
	assertIsNil( FlightTimer_flightTimes["Stormwind"]["Rebel Camp"].flightTimes[1635038053], "50 seconds should be removed" )
	--assertEquals( 130, FlightTimer_flightTimes["Stormwind"]["Rebel Camp"].flightTimes[2], "Oldest should not be deleted." )

end

test.run()

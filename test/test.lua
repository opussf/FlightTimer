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
function test.notestPruneFlightTimes_01()
	-- history
	FlightTimer.debug = true
	FlightTimer_flightTimes["Stormwind"] = {
			["Rebel Camp"] = {
				["flights"] = 120,
				["flightTime"] = 99,
				["flightTimes"] = { 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30 }
			}
		}
	FlightTimer.TAXIMAP_OPENED()
	FlightTimer.TakeTaxiNode(2)
	print( UnitOnTaxi( "player" ) )  -- ROFL..  I never actually got to testing this part!
	assertEquals( 10, #FlightTimer_flightTimes["Stormwind"]["Rebel Camp"].flightTimes )
end

test.run()

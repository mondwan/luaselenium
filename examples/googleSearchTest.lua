--[[
	Simple Google Search test.

	Purpose: to demonstrate the following Lua Selenium Diriver functionality:
	 * entering text into a text field
	 * clicking a button
	 * checking to see if a page contains text
]]

dofile("../lib/selenium.lua")
dofile("../lib/luaunit.lua")

TestGoogle = {} --Test class

function TestGoogle:setUp()
	 self.sele = selenium.new ('*chrome','http://www.google.com','127.0.0.1','4444','3000')
	 self.sele:start()
end

function TestGoogle:test_Search()
	 self.sele:open('/')
	 self.sele:waitForPageToLoad('3000')
	 self.sele:type('q','Lua Programming')
	 self.sele:click("btnG")
	 self.sele:waitForPageToLoad('3000')
	 res = self.sele:isTextPresent('The Programming Language Lua')
	 assertEquals(res,true)
end

function TestGoogle:tearDown()
	self.sele:stop()
end

-- will execute only one test
LuaUnit:run('TestGoogle:test_Search')

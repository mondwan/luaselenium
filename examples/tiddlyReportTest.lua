--Describe how to produce a tiddly report
dofile("../lib/selenium.lua")
dofile("../lib/luaunit.lua")
dofile("../lib/tiddlyReport .lua") --include report library

-- Set report name and path
Report:setName("Test Set")
Report:setPath("report/reports.html")

TestSet = {} --Test class

    function TestSet:setUp()
		--Open tiddly wiki reports
		tiddly.open()
		self.sele = selenium.new ('*googlechrome','http://www.w3schools.com/','127.0.0.1','4444','3000')
		self.sele:start()
    end

    function TestSet:test_CheckOptions()
		self.sele:open('/tags/tryit.asp?filename=tryhtml_option')
		self.sele:waitForPageToLoad('3000')
		options = self.sele:getSelectOptions("css=select")
		table.getn(options)
		assertEquals(table.getn(options),4)
    end


	function TestSet:tearDown()
		self.sele:stop()
	end


LuaUnit:run('TestSet') -- will execute only one class of test


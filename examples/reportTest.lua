-- Describe how to produce a simple report in txt format.
dofile("../lib/selenium.lua")
dofile("../lib/luaunit.lua")
dofile("../lib/txtReport.lua") --include report library

-- Set report name and path
Report:setName("Simple Test")
Report:setPath("TestReport.txt")

SimpleTest = {} --Test class

	function SimpleTest:setUp()
		 self.sele = selenium.new ('*googlechrome','http://www.w3schools.com/','127.0.0.1','4444','3000')
		 self.sele:start()
	end

	function SimpleTest:test_Link()
		 self.sele:open('html/tryit.asp?filename=tryhtml_basic_link')
		 self.sele:waitForPageToLoad('3000')
		 self.sele:click("link=This is a link")
		 self.sele:waitForPageToLoad('3000')
		 self.sele:selectFrame('view')
		 res = self.sele:isTextPresent('Learn to Create Websites')
		 assertEquals(res,true)
	end

	function SimpleTest:tearDown()
		self.sele:stop()
	end

-- will execute only one class of test
LuaUnit:run('SimpleTest')


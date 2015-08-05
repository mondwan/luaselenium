--[[
	Simple report library.
	Report objects can be registered with the Luaunit to retrieve notifications about events.
	We thus extend Luaunit with the option to add such a Report object.
]]

fileHandle = ''

function Report:setName(name)
		Report.name = name
end

function Report:setPath(path)
	Report.path = path
	open()
end

function open()
		fileHandle = assert(io.open(Report.path, "w+"),'Error opening the file'..Report.path)
end

function Report:displayClassName(currentClassName)
		fileHandle:write('Class Name: ' ..currentClassName..'\n\n')
end

function Report:displayTestName(currentTestName)
		fileHandle:write('===========================\n')
		fileHandle:write('Test Name: ' ..currentTestName..'\n')
end

function Report:displayFailure( errorMsg )
		fileHandle:write('Result:' ..errorMsg..'\n')
end

function Report:displaySuccess()
		fileHandle:write('Result: OK:\n')
end

function Report:displayOneFailedTest( failure )
		testName, errorMsg = unpack( failure )
		fileHandle:write(testName.." failed\n")
		fileHandle:write("Error:"..errorMsg.."\n")
end

function Report:displayFailedTests(errorList)
		if type(errorList) == 'table' then
			if table.getn(errorList ) == 0 then return end
			fileHandle:write(">>> Failed tests:\n")
			table.foreachi( errorList, Report:displayOneFailedTest( failure ))
		end
end

function Report:displayFinalResult(testCount,failureCount)
			Report:displayFailedTests()
			local failurePercent, successCount
			if testCount == 0 then
				failurePercent = 0
			else
				failurePercent = 100 * failureCount / testCount
			end
			successCount = testCount - failureCount
			fileHandle:write('===========================\n\n')
			fileHandle:write(string.format("Success : %d%% - %d / %d",
				100-math.ceil(failurePercent), successCount, testCount)..'\n\n')
			return failureCount
end

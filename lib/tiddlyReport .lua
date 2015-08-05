--[[
	TiddlyWiki repository report library.
	TiddlyWiki is written in HTML, CSS and JavaScript to run on any reasonably modern browser without needing any ServerSide logic.
	It allows to create a results repository, SelfContained hypertext documents that can be published to a WebServer, sent by email, stored in a DropBox or kept on a USB.
	TiddlyWiki versión: 2.6.5 - http://www.tiddlywiki.com/
]]

result = ''
tiddly={}

function tiddly.open()
	fileHandle = assert(io.open(Report.path, "r"),'Error opening the file'..Report.path)
	fileContent = fileHandle:read("*all")
	fileHandle:close()
end

function Report:setPath(path)
	Report.path = path
end

function tiddly.save()

	reportArea = '</pre>\n</div><div title="{NewReportName}" creator="Lua Selenium" modifier="Lua Selenium" created="{created}" tags="{tag}" changecount="1">\n<pre>{Result}</pre>\n</div>'

	--Replacement
	fileContent = string.gsub(fileContent , "{NewReportName}", Report.name)
	fileContent = string.gsub(fileContent , "{tag}", "Reports")
	fileContent = string.gsub(fileContent , "{created}", os.date("%Y%m%d%H%S"))

	fileContent = string.gsub(fileContent , "%{Result}</pre>\n</div>*", result..reportArea)

	--Save
	fileHandle = assert(io.open(Report.path, "w+"),'Error opening the file '..Report.path)
	fileHandle:write(fileContent)
	fileHandle:close()
end


function Report:setName(name)
		Report.name = name
end

function Report:displayClassName(currentClassName)
		result = "!Class Name - "..currentClassName..'\n\n'
end

function Report:displayTestName(currentTestName)
		result = result.."''Test Name:'' "..currentTestName..'\n'
end

function Report:displayFailure( errorMsg )
		result = result.."''Result: @@color(red):Failed@@''\n\n"
end

function Report:displaySuccess()
		result = result.."''Result: @@color(green):OK@@''\n\n"
end

function Report:displayOneFailedTest( failure )
		testName, errorMsg = unpack( failure )
		result = result..testName.."''@@color(red):Failed@@''\n"
		result = result..testName.."''Error:'' @@"..errorMsg.."@@\n\n"
end

function Report:displayFailedTests(errorList)
		if type(errorList) == 'table' then
			if table.getn(errorList ) == 0 then return end
			result = result.."''Failed tests:''\n"
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
			result = result..string.format("''Success : %d%% - %d / %d''",100-math.ceil(failurePercent), successCount, testCount)..'\n\n'
			tiddly.save()
			return failureCount
end

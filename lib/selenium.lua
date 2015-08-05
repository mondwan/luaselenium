require 'luarocks.require'

selenium = {}

function selenium.new (browser,baseurl,host,port,timeout)
   local self = {}

   self.http = require 'socket.http'
   self.sessionId = nil
   self.browser = browser
   self.baseurl =  baseurl
   self.host = host
   self.port = port
   self.timeout = '3000'
   self.lastStatusCode = nil
   self.strcut ='OK,'

	--[[
		Function: doCommand
		Build the HTTP request will be sent to the server

		Parameters:
			action - String Selenium command
			args - String or Array arguments

		Returns:
			String server response
	]]
   function self:doCommand(action, args)
		local result = nil
		local tempargs =''
		self.url = "http://" .. self.host .. ":" .. self.port .. "/selenium-server/driver/?cmd="

		if  self.sessionId == nil then
			self.url = self.url..action.."&1="..self.browser.."&2="..self.baseurl
		end

		if args == false then
			self.url = self.url .. action .. "&sessionId=" .. self.sessionId
		end

		if  type(args) == "table" then
			self.url = self.url .. action
			for ar in pairs(args)  do
				tempargs = tempargs.."&".. ar  .."="..args[ar]
			end
			self.url = self.url..tempargs.."&sessionId="..self.sessionId
		end

		print(self.url)
		result, self.lastStatusCode = self.http.request(self.url)
		return result
   end

   	--[[
		Function:  split
		splits a string on separator

		Parameters:
			str - String
			pat - String

		Returns:
			String
	]]
	function split(str, pat)
	   local t = {}
	   local fpat = "(.-)" .. pat
	   local last_end = 1
	   local s, e, cap = str:find(fpat, 1)

	   while s do
		  if s ~= 1 or cap ~= "" then
		 table.insert(t,cap)
		  end
		  last_end = e+1
		  s, e, cap = str:find(fpat, last_end)
	   end

	   if last_end <= #str then
		  cap = str:sub(last_end)
		  table.insert(t, cap)
	   end

	   return t[1]
	end

	--[[
		Function:  stringToTable
		splits a string on separator

		Parameters:
			str - String
			pat - String

		Returns:
			Table
	]]
	function stringToTable(str, pat)
	   local t = {}
	   local str = string.gsub(str , self.strcut,"")
	   local fpat = "(.-)" .. pat
	   local last_end = 1
	   local s, e, cap = str:find(fpat, 1)

	   while s do
		  if s ~= 1 or cap ~= "" then
		 table.insert(t,cap)
		  end
		  last_end = e+1
		  s, e, cap = str:find(fpat, last_end)
	   end

	   if last_end <= #str then
		  cap = str:sub(last_end)
		  table.insert(t, cap)
	   end
	   return t
	end

   	--[[
		Function: getSession
		Get a Selenium Session

		Parameters:
			action- String

		Returns:
			String
	]]
	function self:getSession(action)
		local str = self:doCommand(action,nil)
		return split(str,self.strcut)
	end

	--[[
		Function: getBoolean

		Parameters:
			action - String
			args - table

		Returns:
			Boolean
	]]
	function self:getBoolean(action,args)
		local str = self:doCommand(action,args)
		local temp = split(str,self.strcut)

		if temp == "true" then
			return true
		elseif temp == "false" then
			return false
		else
			return 0
		end
	end

	--[[
		Function: getNumber

		Parameters:
			action - String
			args - table

		Returns:
			Number
	]]
	function self:getNumber(action,args)
		local str = self:doCommand(action,args)
		return tonumber(split(str,self.strcut))
	end

	--[[
		Function: getString

		Parameters:
			action - String
			args - table

		Returns:
			String
	]]
	function self:getString(action,args)
		local str = self:doCommand(action,args)
		return tostring(split(str,self.strcut))
	end


	--[[
		Function: getStringArray

		Parameters:
			action - String
			args - table

		Returns:
			String
	]]
	function self:getStringArray(action,args)
		local str = self:doCommand(action,args)
		return stringToTable(str,",")
	end

	--[[
		Function: start
		Run the browser and set session id.

		Returns:
			String - Session Id
	]]
	function self:start()
		self.sessionId = self:getSession("getNewBrowserSession")
		return self.sessionId
	end

	--[[
		Function: start
		Opens an URL in the test frame. This accepts both relative and absolute URLs.
		The "open" command waits for the page to load before proceeding, ie. the "AndWait" suffix is implicit.
		*Note* : The URL must be on the same domain as the runner HTML
		due to security restrictions in the browser (Same Origin Policy). If you
		need to open an URL on another domain, use the Selenium Server to start a new browser session on that domain.

		Parameters:
			URL - String
	]]
	function self:open(url)
		local args={url}
		self:doCommand("open", args)
	end

	--[[
		Function: stop
		Close the browser and set session id null.
	]]
	function self:stop()
		self:doCommand("testComplete", false)
		self.sessionId = ""
	end

	--[[
		Function:getTitle
		Gets the title of the current page.

		Returns:
			String the title of the current page
	]]
	function self:getTitle()
		return self:getString("getTitle", false)
	end

	--[[
		Function: deleteAllVisibleCookies
		Calls deleteCookie with recurse=true on all cookies visible to the current page.
		As noted on the documentation for deleteCookie, recurse=true can be much slower
		than simply deleting the cookies using a known domain/path.
	]]
	function self:deleteAllVisibleCookies()
		self:doCommand("deleteAllVisibleCookies", false)
	end

	--[[
		Function:deleteCookie
		Delete a named cookie with specified path and domain.  Be careful-- to delete a cookie, you
		need to delete it using the exact same path and domain that were used to create the cookie.
		If the path is wrong, or the domain is wrong, the cookie simply won't be deleted.  Also
		note that specifying a domain that isn't a subset of the current domain will usually fail.
		Since there's no way to discover at runtime the original path and domain of a given cookie,
		we've added an option called 'recurse' to try all sub-domains of the current domain with
		all paths that are a subset of the current path.  Beware-- this option can be slow.  In
		big-O notation, it operates in O(n--m) time, where n is the number of dots in the domain
		name and m is the number of slashes in the path.

		Parameters:
			name - String
			optionString - String
	]]
	function self:deleteCookie(name, optionsString)
		local args={name,optionsString}
		self:doCommand("deleteCookie", args)
	end

	--[[
		Function: createCookie
		Create a new cookie whose path and domain are same with those of current page
		under test, unless you specified a path for this cookie explicitly.

		Parameters:
			nameValuePair - String
			optionString - String
	]]
	function self:createCookie(nameValuePair, optionsString)
		local args={nameValuePair,optionsString}
		self:doCommand("createCookie", args)
	end   --==>_createCookie

	--[[
		Function: isCookiePresent

		Parameters:
			name - String

		Returns:
			true if a cookie with the specified name is present, or false otherwise.
	]]
	function self:isCookiePresent(name)
		local args={name}
		return self:getBoolean("isCookiePresent", args)
	end

	--[[
		Function: getCookieByName

		Parameters:
			name - String

		Returns:
			String - the value of the cookie with the specified name, or throws an error if the cookie is not present.
	]]
	function self:getCookieByName(name)
		local args={name}
		return  self:getString("getCookieByName", args)
	end

	--[[
		Function: getCookie

		Returns:
			String - all cookies of the current page under test.
	]]
	function self:getCookie()
		return self:getString("getCookie", false)
	end

	--[[
		Function: attachFile
			Sets a file input (upload) field to the file listed in fileLocator

		Parameters:
			fieldLocator - String
			fileLocator - String
	]]
	function self:attachFile(fieldLocator, fileLocator)
		local args={fieldLocator,fileLocator}
		self:doCommand("attachFile", args)
	end

	--[[
		Function: captureScreenshot
		Captures a PNG screenshot to the specified file.

		Parameters:
		filename - the absolute path to the file to be written, e.g. "c:\blah\screenshot.png"
	]]
	function self:captureScreenshot(filename)
		local args={filename}
		self:doCommand("captureScreenshot", args)
	end   --==>_captureScreenshot

	--[[
		Function: captureScreenshotToString
		Capture a PNG screenshot.  It then returns the file as a base 64 encoded string.

		Returns:
			String - The base 64 encoded string of the screen shot (PNG file)
	]]
	function self:captureScreenshotToString()
		return self:getString("captureScreenshotToString", false)
	end

	--[[
		Function: getSelectOptions
		Gets all option labels in the specified select drop-down.

		Parameters:
		selectLocator -  string an element locator identifying a drop-down menu

		Returns:
		array an array of all option labels in the specified select drop-down
	]]
	function self:getSelectOptions(selectLocator)
		local args={selectLocator}
		return self:getStringArray("getSelectOptions", args)
	end

	--[[
		Function:click
		Clicks on a link, button, checkbox or radio button. If the click action
		causes a new page to load (like a link usually does), call waitForPageToLoad.

		Parameters:
			locator - string an element locator
	]]
	function self:click(locator)
		local args={locator}
		self:doCommand("click", args)
	end

	--[[
		Function: getText
		Gets the text of an element. This works for any element that contains
		text. This command uses either the textContent (Mozilla-like browsers) or
		the innerText (IE-like browsers) of the element, which is the rendered
		text shown to the user.

		Parameters:
			locator - String an element locator

		Returns:
			locator - String the text of the element
	]]
	function self:getText(locator)
		local args={locator}
		return self:getString("getText", args)
	end

	--[[
		Function:doubleClick()
		Doubleclicks on a link, button, checkbox or radio button. If the action
		causes a new page to load (like a link usually does), call waitForPageToLoad.

		Parameters:
			locator - String an element locator
	]]
	function self:doubleClick(locator)
		local args={locator}
		self:doCommand("doubleClick", args)
	end

	--[[
		Function:contextMenu
		Simulates opening the context menu for the specified element (as might happen if the user "right-clicked" on the element).

		Parameters:
			locator - String an element locator
	]]
	function self:contextMenu(locator)
		local args={locator}
		self:doCommand("contextMenu", args)
	end

	--[[
		Function: clickAt
		Clicks on a link, button, checkbox or radio button. If the click action
		causes a new page to load (like a link usually does), call waitForPageToLoad.

		Parameters:
			locator - String an element locator
			coordString - String specifies the x,y position (i.e. - 10,20) of the mouse event relative to the element returned by the locator.
	]]
	function self:clickAt(locator, coordString)
		local args={locator,coordString}
		self:doCommand("clickAt", args)
	end

	--[[
		Function: doubleClickAt
		Doubleclicks on a link, button, checkbox or radio button. If the action causes a new page to load (like a link usually does), call waitForPageToLoad.

		Parameters:
			locator - String an element locator
			coordString - String specifies the x,y position (i.e. - 10,20) of the mouse event relative to the element returned by the locator.
	]]
	function self:doubleClickAt(locator, coordString)
		local args={locator,coordString}
		self:doCommand("doubleClickAt", args)
	end

	--[[
		Function: contextMenuAt
		Simulates opening the context menu for the specified element (as might happen if the user "right-clicked" on the element).

		Parameters:
			locator - String an element locator
			coordString - String specifies the x,y position (i.e. - 10,20) of the mouse event relative to the element returned by the locator.ng
	]]
	function self:contextMenuAt(locator, coordString)
		local args={locator,coordString}
		self:doCommand("contextMenuAt", args)
	end

	--[[
		Function: fireEvent
		Explicitly simulate an event, to trigger the corresponding "onevent" handler.

		Parameters:
			locator - String an element locator
			eventName - String the event name, e.g. "focus" or "blur"
	]]
	function self:fireEvent(locator, eventName)
		local args={locator,eventName}
		self:doCommand("fireEvent", args)
	end

	--[[
		Function:focus
		Explicitly simulate an event, to trigger the corresponding "onevent" handler.

		Parameters:
			locator - String an element locator
	]]
	function self:focus(locator)
		local args={locator}
		self:doCommand("focus", args)
	end

	--[[
		Function: keyPress
		Simulates a user pressing and releasing a key.

		Parameters:
			locator - String an element locator
			keySequence - String Either be a string("\" followed by the numeric keycode of the key to be pressed, normally the ASCII value of that key), or a single  character. For example: "w", "\119".
	]]
	function self:keyPress(locator, keySequence)
		local args={locator,keySequence}
		self:doCommand("keyPress", args)
	end

	--[[
		Function:keyDown
		Simulates a user pressing a key (without releasing it yet).

		Parameters:
			locator - String an element locator
			keySequence -    Either be a string("\" followed by the numeric keycode of the key to be pressed, normally the ASCII value of that key), or a single character. For example: "w", "\119".
	]]
	function self:keyDown(locator, keySequence)
		local args={locator,keySequence}
		self:doCommand("keyDown", args)
	end

	--[[
		Function: kepUp
		Simulates a user releasing a key.

		Parameters:
			locator - String an element locator
		    keySequence - Either be a string("\" followed by the numeric keycode  of the key to be pressed, normally the ASCII value of that key), or a single  character. For example: "w", "\119".
	]]
	function self:keyUp(locator, keySequence)
		local args={locator,keySequence}
		self:doCommand("keyUp", args)
	end

	--[[
		Function: keyDownNative
		Simulates a user pressing a key (without releasing it yet) by sending a native operating system keystroke.
		This function uses the java.awt.Robot class to send a keystroke-- this more accurately simulates typing
		a key on the keyboard.  It does not honor settings from the shiftKeyDown, controlKeyDown, altKeyDown and
		metaKeyDown commands, and does not target any particular HTML element.  To send a keystroke to a particular
		element, focus on the element first before running this command.

		Parameters:
			keycode - String  an integer keycode number corresponding to a java.awt.event.KeyEvent-- note that Java keycodes are NOT the same thing as JavaScript keycodes!
	]]
	function self:keyDownNative(keycode)
		local args={keycode}
		self:doCommand("keyDownNative", args)
	end

	--[[
		Function: keyUpNative
		Simulates a user releasing a key by sending a native operating system keystroke.
		This function uses the java.awt.Robot class to send a keystroke-- this more accurately simulates typing
		a key on the keyboard.  It does not honor settings from the shiftKeyDown, controlKeyDown, altKeyDown and
		metaKeyDown commands, and does not target any particular HTML element.  To send a keystroke to a particular
		element, focus on the element first before running this command.

		Parameters:
			keycode - String an integer keycode number corresponding to a java.awt.event.KeyEvent-- note that Java keycodes are NOT the same thing as JavaScript keycodes!
	]]
	function self:keyUpNative(keycode)
		local args={keycode}
		self:doCommand("keyUpNative", args)
	end

	--[[
		Function: keyPressNative
		Simulates a user pressing and releasing a key by sending a native operating system keystroke.
		This function uses the java.awt.Robot class to send a keystroke-- this more accurately simulates typing
		a key on the keyboard.  It does not honor settings from the shiftKeyDown, controlKeyDown, altKeyDown and
		metaKeyDown commands, and does not target any particular HTML element.  To send a keystroke to a particular
		element, focus on the element first before running this command.

		Parameters:
			keycode - String an integer keycode number corresponding to a java.awt.event.KeyEvent-- note that Java keycodes are NOT the same thing as JavaScript keycodes!
	]]
	function self:keyPressNative(keycode)
		local args={keycode}
		self:doCommand("keyPressNative", args)
	end

	--[[
		Function:addScript
		Loads script content into a new script tag in the Selenium document. This
		differs from the runScript command in that runScript adds the script tag
		to the document of the AUT, not the Selenium document. The following
		entities in the script content are replaced by the characters they
		represent: &lt-- &gt-- amp--  the corresponding remove command is removeScript.

		Parameters:
			scriptContent - String the Javascript content of the script to add
			scriptTagId - String *optional* the id of the new script tag. If specified, and an element with this id alread exists, this operation will fail.
	]]
	function self:addScript(scriptContent, scriptTagId)
		local args={scriptContent,scriptTagId}
		self:doCommand("addScript", args)
	end

	--[[
		Function:removeScript
		Removes a script tag from the Selenium document identified by the given
		id. Does nothing if the referenced tag doesn't exist.

		Parameters:
			 scriptTagId - String the id of the script element to remove.
	]]
	function self:removeScript(scriptTagId)
		local args={scriptTagId}
		self:doCommand("removeScript", args)
	end

	--[[
		Function: rollup
		Executes a command rollup, which is a series of commands with a unique
		name, and optionally arguments that control the generation of the set of
		commands. If any one of the rolled-up commands fails, the rollup is
		considered to have failed. Rollups may also contain nested rollups.

		Parameters:
		 	rollupName - String the name of the rollup command
			kwargs - String keyword arguments string that influences how the rollup expands into commands
	]]
	function self:rollup(rollupName, kwargs)
		local args={rollupName,kwargs}
		self:doCommand("rollup", args)
	end

	--[[
		Function: addLocationStrategy
		Defines a new function for Selenium to locate elements on the page.
		For example,
		if you define the strategy "foo", and someone runs click("foo=blah"), we'll
		run your function, passing you the string "blah", and click on the element
		that your function
		returns, or throw an "Element not found" error if your function returns null.
		We'll pass three arguments to your function:

		- locator the string the user passed in
		- inWindow the currently selected window
		- inDocument the currently selected document

		The function must return null if the element can't be found.

		Parameters:
			strategyName - String the name of the strategy to define this should use only letters [a-zA-Z] with no spaces or other punctuation.
			functionDefinition - String a string defining the body of a function in JavaScript. For example: *return inDocument.getElementById(locator)--*
	]]
	function self:addLocationStrategy(strategyName, functionDefinition)
		local args={strategyName,functionDefinition}
		self:doCommand("rollup", args)
	end

	--[[
		Function: ignoreAttributesWithoutValue
		Specifies whether Selenium will ignore xpath attributes that have no
		value, i.e. are the empty string, when using the non-native xpath
		evaluation engine. You'd want to do this for performance reasons in IE.
		However, this could break certain xpaths, for example an xpath that looks
		for an attribute whose value is NOT the empty string.
		The hope is that such xpaths are relatively rare, but the user should
		have the option of using them. Note that this only influences xpath
		evaluation when using the ajaxslt engine (i.e. not "javascript-xpath").

		Parameters:
			ignore - Boolean, true means we'll ignore attributes without value at the expense of xpath "correctness"-- false means                        we'll sacrifice speed for correctness.
	]]
	function self:ignoreAttributesWithoutValue(ignore)
		local args={ignore}
		self:doCommand("ignoreAttributesWithoutValue", args)
	end

	--[[
		Function: isOrdered
		Check if these two elements have same parent and are ordered siblings in the DOM. Two same elements will not be considered ordered.

		Parameters:
			locator1 - String an element locator pointing to the first element
			locator2 - String an element locator pointing to the second element

		Returns:
			boolean true if element1 is the previous sibling of element2, false otherwise
	]]
	function self:isOrdered(locator1, locator2)
		local args={locator1,locator2}
		return self:getBoolean("isOrdered", args)
	end

	--[[
		Function: mouseDown
		Simulates a user pressing the right mouse button (without releasing it yet) at the specified location.

		Parameters:
			locator - String an element locator
	]]
	function self:mouseDown(locator)
		local args={locator}
		self:doCommand("mouseDown", args)
	end

	--[[
		Function: mosueDownRight
		Simulates a user pressing the right mouse button (without releasing it yet) on the specified element.

		Parameters:
			locator - String an element locator
	]]
	function self:mouseDownRight(locator)
		local args={locator}
		self:doCommand("mouseDownRight", args)
	end


	--[[
		Function: mouseDownAt
		Simulates a user pressing the left mouse button (without releasing it yet) at the specified location.

		Parameters:
			locator - String an element locator
			coordString - String specifies the x,y position (i.e. - 10,20) of the mouse event relative to the element returned by the locator.
	]]
	function self:mouseDownAt(locator, coordString)
		local args={locator,coordString}
		self:doCommand("mouseDownAt", args)
	end

	--[[
		Function: mouseDownRightAt
		Simulates a user pressing the right mouse button (without releasing it yet) at the specified location.

		Parameters:
			locator - String an element locator
			coordString - String specifies the x,y position (i.e. - 10,20) of the mouse event relative to the element returned by the locator.
	]]
	function self:mouseDownRightAt(locator, coordString)
		local args={locator,coordString}
		self:doCommand("mouseDownRightAt", args)
	end

	--[[
		Function: mouseUp
		Simulates the event that occurs when the user releases the mouse button (i.e., stops
		holding the button down) on the specified element.

		Parameters:
			locator - String an element locator
	]]
	function self:mouseUp(locator)
		local args={locator}
		self:doCommand("mouseUp", args)
	end

	--[[
		Function: mouseUpRight
		Simulates the event that occurs when the user releases the right mouse button (i.e., stops
		holding the button down) on the specified element.

		Parameters:
			locator - String an element locator
	]]
	function self:mouseUpRight(locator)
		local args={locator}
		self:doCommand("mouseUpRight", args)
	end

	--[[
		Function: mouseUpAt
		Simulates the event that occurs when the user releases the mouse button (i.e., stops
		holding the button down) at the specified location.

		Parameters:
			locator - String an element locator
			coordString - String specifies the x,y position (i.e. - 10,20) of the mouse event relative to the element returned by the locator.
	]]
	function self:mouseUpAt(locator, coordString)
		local args={locator,coordString}
		self:doCommand("mouseUpAt", args)
	end

	--[[
		Function: mouseUpRightAt
		Simulates the event that occurs when the user releases the right mouse button (i.e., stops
		holding the button down) at the specified location.

		Parameters:
			locator - String an element locator
			coordString - String specifies the x,y position (i.e. - 10,20) of the mouse event relative to the element returned by the locator.
	]]
	function self:mouseUpRightAt(locator, coordString)
		local args={locator,coordString}
		self:doCommand("mouseUpRightAt", args)
	end

	--[[
		Function: mouseMove
		Simulates a user pressing the mouse button (without releasing it yet) on the specified element.

		Parameters:
			locator - String an element locator
	]]
	function self:mouseMove(locator)
		local args={locator}
		self:doCommand("mouseMove", args)
	end

	--[[
		Function: mouseMoveAt
		Simulates a user pressing the mouse button (without releasing it yet) on the specified element.

		Parameters:
			locator - String an element locator
			coordString - String specifies the x,y position (i.e. - 10,20) of the mouse event relative to the element returned by the locator.
	]]
	function self:mouseMoveAt(locator, coordString)
		local args={locator,coordString}
		self:doCommand("mouseMoveAt", args)
	end

	--[[
		Function: mouseOver
		Simulates a user hovering a mouse over the specified element.

		Parameters:
			locator - String an element locator
	]]
	function self:mouseOver(locator)
		local args={locator}
		self:doCommand("mouseOver", args)
	end

	--[[
		Function: mouseOut
		Simulates a user moving the mouse pointer away from the specified element.

		Parameters:
			locator - String an element locator
	]]
	function self:mouseOut(locator)
		local args={locator}
		self:doCommand("mouseOut", args)
	end

	--[[
		Function: type
		Sets the value of an input field, as though you d it in.
		Can also be used to set the value of combo boxes, check boxes, etc. In these cases,
		value should be the value of the option selected, not the visible text.

		Parameters:
			locator - String an element locator
			value - String the value to type
	]]
	function self:type(locator, value)
		local args={locator,value}
		self:doCommand("type", args)
	end

	--[[
		Function: typeKeys
		Simulates keystroke events on the specified element, as though you typed the value key-by-key.
		This is a convenience method for calling keyDown, keyUp, keyPress for every character in the specified string--
		this is useful for dynamic UI widgets (like auto-completing combo boxes) that require explicit key events.
		Unlike the simple "type" command, which forces the specified value into the page directly, this command
		may or may not have any visible effect, even in cases where typing keys would normally have a visible effect.
		For example, if you use "typeKeys" on a form element, you may or may not see the results of what you typed in the field.
		In some cases, you may need to use the simple "type" command to set the value of the field and then the "typeKeys" command to
		send the keystroke events corresponding to what you just typed.

		Parameters:
			locator - String an element locator
			value - String the value to type
	]]
	function self:typeKeys(locator, value)
		local args={locator,value}
		self:doCommand("typeKeys", args)
	end

	--[[
		Function: setSpeed
		Set execution speed (i.e., set the millisecond length of a delay which will follow each selenium operation).  By default, there is no such delay, i.e.,
		the delay is 0 milliseconds.

		Parameters:
			value - String the number of milliseconds to pause after operation
	]]
	function self:setSpeed(value)
		local args={value}
		self:doCommand("setSpeed", args)
	end

	--[[
		Function: getSpeed
		Get execution speed (i.e., get the millisecond length of the delay following each selenium operation).  By default, there is no such delay, i.e.,
		the delay is 0 milliseconds.

		See Also:
			<setSpeed>.

		Returns:
			string the execution speed in milliseconds.
	]]
	function self:getSpeed()
		return self:getString("getSpeed", false)
	end

	--[[
		Function: check
		Check a toggle-button (checkbox/radio)

		Parameters:
			locator - String an element locator
	]]
	function self:check(locator)
		local args={locator}
		self:doCommand("check", args)
	end

	--[[
		Function: uncheck
		Uncheck a toggle-button (checkbox/radio)

		Parameters:
		locator - String an element locator
	]]

	function self:uncheck(locator)
		local args={locator}
		self:doCommand("uncheck", args)
	end

	--[[
		Function: select
		Select an option from a drop-down using an option locator.
		Option locators provide different ways of specifying options of an HTML
		Select element (e.g. for selecting a specific option, or for asserting
		that the selected option satisfies a specification). There are several forms of Select Option Locator.
		-*label =labelPattern*:

		matches options based on their labels, i.e. the visible text. (This is the default.)
		- *label = regexp:^[Oo]ther*
		- *value = valuePattern*:

		matches options based on their values.
		- *value = other*
		- *id = id*:

		matches options based on their ids.
		- *id=option1*
		- *index = index*:

		matches an option based on its index (offset from zero).
		- *index=2*

		If no option locator prefix is provided, the default behaviour is to match on <b>label</b>.

		Parameters:
			SelectlLocator - String an element locator identifying a drop-down menu
			optionLocator - String an option locator (a label by default)
	]]
	function self:select(selectLocator, optionLocator)
		local args={selectLocator,optionLocator}
		self:doCommand("select", args)
	end

	--[[
		Function:addSelection
		Add a selection to the set of selected options in a multi-select element using an option locator.

		Parameters:
			locator - String an element locator identifying a multi-select box
			optionLocator - String an option locator (a label by default)
	]]
	function self:addSelection(locator, optionLocator)
		local args={locator,optionLocator}
		self:doCommand("addSelection", args)
	end

	--[[
		Function: removeSelection
		Remove a selection from the set of selected options in a multi-select element using an option locator.

		Parameters:
			locator - String an element locator identifying a multi-select box
			optionLocator - String an option locator (a label by default)
	]]
	function self:removeSelection(locator, optionLocator)
		local args={locator,optionLocator}
		self:doCommand("removeSelection", args)
	end

	--[[
		Function: removeAllSelections
		Unselects all of the selected options in a multi-select element.

		Parameters:
			locator - String an element locator identifying a multi-select box
	]]
	function self:removeAllSelections(locator)
		local args={locator}
		self:doCommand("removeAllSelections", args)
	end

	--[[
		Function: submit
		Submit the specified form. This is particularly useful for forms without submit buttons, e.g. single-input "Search" forms.

		Parameters:
			formLocator - String an element locator for the form you want to submit
	]]
	function self:submit(formLocator)
		local args={formLocator}
		self:doCommand("submit", args)
	end

	--[[
		Function: openWindow
		Opens a popup window (if a window with that ID isn't already open).
		After opening the window, you'll need to select it using the selectWindow command.
		This command can also be a useful workaround for bug SEL-339.  In some cases, Selenium will be unable to intercept a call to window.open (if the call occurs during or before the "onLoad" event, for example).
		In those cases, you can force Selenium to notice the open window's name by using the Selenium openWindow command, using
		an empty (blank) url, like this: *openWindow("", "myFunnyWindow").*

		Parameters:
			url - String the URL to open, which can be blank
			windowID - String the JavaScript window ID of the window to select
	]]
	function self:openWindow(Url, windowID)
		local args={Url},windowID
		self:doCommand("openWindow", args)
	end

	--[[
		Function: selectWindow
		Selects a popup window using a window locator-- once a popup window has been selected, all
		commands go to that window. To select the main window again, use null
		as the target. Window locators provide different ways of specifying the window object:
		by title, by internal JavaScript *"name,"* or by JavaScript variable.
		- *title = My Special Window*:

		Finds the window using the text that appears in the title bar.  Be careful--
		two windows can share the same title.  If that happens, this locator will
		just pick one.
		- *name = myWindow*:

		Finds the window using its internal JavaScript "name" property.  This is the second
		parameter "windowName" passed to the JavaScript method window.open(url, windowName, windowFeatures, replaceFlag)
		(which Selenium intercepts).
		- var = variableName:

		Some pop-up windows are unnamed (anonymous), but are associated with a JavaScript variable name in the current
		application window, e.g. *"window.foo = window.open(url)--"*.  In those cases, you can open the window using *"var=foo"*
		If no window locator prefix is provided, we'll try to guess what you mean like this:
		*1)* if windowID is null, (or the string "null" then it is assumed the user is referring to the original window instantiated by the browser).
		*2)* if the value of the "windowID" parameter is a JavaScript variable name in the current application window, then it is assumed
		that this variable contains the return value from a call to the JavaScript window.open() method.
		*3)* Otherwise, selenium looks in a hash it maintains that maps string names to window "names".
		*4)* If that fails, we'll try looping over all of the known windows to try to find the appropriate "title".
		Since "title" is not necessarily unique, this may have unexpected behavior.
		If you're having trouble figuring out the name of a window that you want to manipulate, look at the Selenium log messages
		which identify the names of windows created via window.open (and therefore intercepted by Selenium).  You will see messages
		like the following for each window as it is opened:
		*debug: window.open call intercepted-- window ID (which you can use with selectWindow()) is "myNewWindow"*
		In some cases, Selenium will be unable to intercept a call to window.open (if the call occurs during or before the "onLoad" event, for example).
		(This is bug SEL-339.)  In those cases, you can force Selenium to notice the open window's name by using the Selenium openWindow command, using
		an empty (blank) url, like this: *openWindow("", "myFunnyWindow")*.

		Parameters:
			windowID - String the JavaScript window ID of the window to select
	]]
	function self:selectWindow(windowID)
		local args={windowID}
		self:doCommand("selectWindow", args)
	end

	--[[
		Function: selectPopUp
		Simplifies the process of selecting a popup window (and does not offer
		functionality beyond what *selectWindow()* already provides).
		If *window* is either not specified, or specified as
		"null", the first non-top window is selected. The top window is the one
		that would be selected by *selectWindow()* without providing a
		*windowID* . This should not be used when more than one popup window is in play.
		Otherwise, the window will be looked up considering
		*windowID* as the following in order:
		*1)* the "name" of the window, as specified to *window.open()*
		*2)* a javascript variable which is a reference to a window
		*3)* the title of the window. This is the same ordered lookup performed by *selectWindow*.

		Parameters:
			windowID - String an identifier for the popup window, which can take on a number of different meanings
	]]
	function self:selectPopUp(windowID)
		local args={windowID}
		self:doCommand("selectPopUp", args)
	end

	--[[
		Function: deselectPopUp
		Selects the main window. functionally equivalent to using
		*selectWindow()* and specifying no value for *windowID*.
	]]
	function self:deselectPopUp()
		self:doCommand("deselectPopUp", false)
	end

	--[[
		Function: selectFrame
		Selects a frame within the current window.  (You may invoke this command
		multiple times to select nested frames.)  To select the parent frame, use
		"relative=parent" as a locator-- to select the top frame, use "relative=top".
		You can also select a frame by its 0-based index number-- select the first frame with
		"index=0", or the third frame with "index=2".
		You may also use a DOM expression to identify the frame you want directly,
		like this: *dom=frames["main"].frames["subframe"]*

		Parameters:
			locator - String an element locator identifying a frame or iframe
	]]
	function self:selectFrame(locator)
		local args={locator}
		self:doCommand("selectFrame", args)
	end

	--[[
		Function: getWhetherThisFrameMatchFrameExpression
		Determine whether current/locator identify the frame containing this running code.
		This is useful in proxy injection mode, where this code runs in every
		Browser frame and window, and sometimes the Selenium server needs to identify
		the "current" frame.  In this case, when the test calls selectFrame, this()
		routine is called for each frame to figure out which one has been selected.
		The selected frame will return true, while all others will return false.

		Parameters
			currentFrameString - String starting frame
			target - String New frame (which might be relative to the current one)

		Returns:
			boolean true if the New frame is this code--s window
	]]
	function self:getWhetherThisFrameMatchFrameExpression(currentFrameString, target)
		local args={currentFrameString,target}
		return self:getBoolean("getWhetherThisFrameMatchFrameExpression", args)
	end

	--[[
		Function: getWhetherThisWindowMatchWindowExpression
		Determine whether currentWindowString plus target identify the window containing this running code.
		This is useful in proxy injection mode, where this code runs in every
		browser frame and window, and sometimes the Selenium server needs to identify
		the "current" window.  In this case, when the test calls selectWindow, this()
		routine is called for each window to figure out which one has been selected.
		The selected window will return true, while all others will return false.

		Parameters:
			currentWindowString - String starting window
			target - String New window (which might be relative to the current one, e.g., "_parent")

		Returns:
			boolean true if the New window is this code--s window
	]]
	function self:getWhetherThisWindowMatchWindowExpression(currentWindowString, target)
		local args={currentWindowString,target}
		return self:getBoolean("getWhetherThisWindowMatchWindowExpression", args)
	end

	--[[
		Function: waitForPopUp
		Waits for a popup window to appear and load up.

		Parameters:
		windowID - String the JavaScript window "name" of the window that will appear (not the text of the title bar) If unspecified, or specified as "null", this command will                 wait for the first non-top window to appear (don't rely                 on this if you are working with multiple popups                 simultaneously).
		timeout - String a timeout in milliseconds, after which the action will return with an error.If this value is not specified, the default Selenium                timeout will be used. See the setTimeout() command.
	]]
	function self:waitForPopUp(windowID, Timeout)
		local args={windowID,Timeout}
		self:doCommand("waitForPopUp", args)
	end

	--[[
		Function: chooseCancelOnNextConfirmation
		By default, Selenium's overridden window.confirm() function will
		return true, as if the user had manually clicked OK-- after running
		this command, the next call to confirm() will return false, as if
		the user had clicked Cancel.  Selenium will then resume using the
		default behavior for future confirmations, automatically returning
		true (OK) unless/until you explicitly call this command for each confirmation.
		Take note - every time a confirmation comes up, you must
		consume it with a corresponding getConfirmation, or else
		the next selenium operation will fail.
	]]
	function self:chooseCancelOnNextConfirmation()
		self:doCommand("chooseCancelOnNextConfirmation", false)
	end

	--[[
		Function: chooseOkOnNextConfirmation
		Undo the effect of calling chooseCancelOnNextConfirmation.  Note
		that Selenium's overridden window.confirm() function will normally automatically
		return true, as if the user had manually clicked OK, so you shouldn't
		need to use this command unless for some reason you need to change
		your mind prior to the next confirmation.  After any confirmation, Selenium will resume using the
		default behavior for future confirmations, automatically returning
		true (OK) unless/until you explicitly call chooseCancelOnNextConfirmation for each
		confirmation.
		Take note - every time a confirmation comes up, you must
		consume it with a corresponding getConfirmation, or else
		the next selenium operation will fail.
	]]
	function self:chooseOkOnNextConfirmation()
		self:doCommand("chooseOkOnNextConfirmation", false)
	end

	--[[
		Function: answerOnNextPrompt
		Instructs Selenium to return the specified answer string in response to
		the next JavaScript prompt [window.prompt()].

		Parameters:
			answer - String the answer to give in response to the prompt pop-up
	]]
	function self:answerOnNextPrompt(answer)
		local args={answer}
		self:doCommand("answerOnNextPrompt", args)
	end

	--[[
		Function: close
		Simulates the user clicking the "close" button in the titlebar of a popup window or tab.
	]]
	function self:close()
		self:doCommand("close", false)
	end

	--[[
		Function: isAlertPresent
		Has an alert occurred?
		This function never throws an exception

		Returns:
			boolean true if there is an alert
	]]
	function self:isAlertPresent()
		return self:getBoolean("isAlertPresent", false)
	end

	--[[
		Function: isPromptPresent
		Has a prompt occurred?
		This function never throws an exception

		Returns:
			boolean true if there is a pending p
	]]
	function self:isPromptPresent()
		return self:getBoolean("isPromptPresent", false)
	end

	--[[
		Function:isConfirmationPresent
		Has confirm() been called?
		his function never throws an exception

		Returns:
			boolean true if there is a pending confirmation
	]]
	function self:isConfirmationPresent()
		return self:getBoolean("isConfirmationPresent", false)
	end

	--[[
		Function: isChecked
		Gets whether a toggle-button (checkbox/radio) is checked.  Fails if the specified element doesn't exist or isn't a toggle-button.

		Parameters:
			locator - String an element locator pointing to a checkbox or radio button

		Returns:
			boolean true if the checkbox is checked, false otherwise
	]]
	function self:isChecked(locator)
		local args={locator}
		return self:getBoolean("isChecked", args)
	end

	--[[
		Function: getTable
		Gets the text from a cell of a table. The cellAddress syntax
		tableLocator.row.column, where row and column start at 0.

		Parameters:
			tableCellAddress - String a cell address, e.g. "foo.1.4"

		Returns:
			string the text from the specified cell
	]]
	function self:getTable(tableCellAddress)
		local args={tableCellAddress}
		return self:getString("getTable", args)
	end

	--[[
		Function: getSelectedLabels
		Gets all option labels (visible text) for selected options in the specified select or multi-select element.

		Parameters:
			selectLocator - String an element locator identifying a drop-down menu

		Returns:
			array an array of all selected option labels in the specified select drop-down
	]]
	function self:getSelectedLabels(selectLocator)
		local args={selectLocator}
		return self:getStringArray("getSelectedLabels", args)
	end

	--[[
		Function: getSelectedLabel
		Gets option label (visible text) for selected option in the specified select element.

		Parameters:
			selectLocator - String an element locator identifying a drop-down menu

		Returns:
			string the selected option label in the specified select drop-down
	]]
	function self:getSelectedLabel(selectLocator)
		local args={selectLocator}
		return self:getString("getSelectedLabel", args)
	end

	--[[
		Function: getSelectedValue
		Gets all option values (value attributes) for selected options in the specified select or multi-select element.

		Parameters:
			selectLocator - String an element locator identifying a drop-down menu

		returns
			array an array of all selected option values in the specified select drop-down
	]]
	function self:getSelectedValue(selectLocator)
		local args={selectLocator}
		return self:getStringArray("getSelectedValue", args)
	end

	--[[
		Function: getSelectedIndexes
		Gets all option indexes (option number, starting at 0) for selected options in the specified select or multi-select element.
		selectLocator an element locator identifying a drop-down menu
		@return array an array of all selected option indexes in the specified select drop-down
	]]
	function self:getSelectedIndexes(selectLocator)
		local args={selectLocator}
		return self:getStringArray("getSelectedIndexes", args)
	end

	--[[
		Function: getSelectedIndex
		Gets option index (option number, starting at 0) for selected option in the specified select element.

		Parameters:
		selectLocator - String an element locator identifying a drop-down menu

		Returns:
			string the selected option index in the specified select drop-down
	]]
	function self:getSelectedIndex(selectLocator)
		local args={selectLocator}
		return self:getString("getSelectedIndex", args)
	end

	--[[
		Function: getSelectedIds
		Gets all option element IDs for selected options in the specified select or multi-select element.
		selectLocator an element locator identifying a drop-down menu
		@return array an array of all selected option IDs in the specified select drop-down
	]]
	function self:getSelectedIds(selectLocator)
		local args={selectLocator}
		return self:getStringArray("getSelectedIds", args)
	end

	--[[
		Function: getSelectedId
		Gets option element ID for selected option in the specified select element.

		Parameters:
			selectLocator - String an element locator identifying a drop-down menu

		Returns:
			string the selected option ID in the specified select drop-down
	]]
	function self:getSelectedId(selectLocator)
		local args={selectLocator}
		return self:getString("getSelectedId", args)
	end

	--[[
		Function: isSomethingSelected
		Determines whether some option in a drop-down menu is selected.

		Parameters:
			selectLocator - String an element locator identifying a drop-down menu

		Returns:
			boolean true if some option has been selected, false otherwise
	]]
	function self:isSomethingSelected(selectLocator)
		local args={selectLocator}
		return self:getBoolean("isSomethingSelected", args)
	end

	--[[
		Function: getAttribute
		Gets the value of an element attribute. The value of the attribute may
		differ across browsers (this is the case for the "style" attribute, for example).

		Parameters:
			attributeLocator - String an element locator followed by an @ sign and then the name of the attribute, e.g. "foo@bar"

		Returns:
			string the value of the specified attribute
	]]
	function self:getAttribute(attributeLocator)
		local args={attributeLocator}
		return self:getString("getAttribute", args)
	end

	--[[
		Function:isVisible
		Determines if the specified element is visible. An
		element can be rendered invisible by setting the CSS "visibility"
		property to "hidden", or the "display" property to "none", either for the
		element itself or one if its ancestors.  This method will fail if the element is not present.

		Parameters:
			locator - String an element locator

		Returns:
			boolean true if the specified element is visible, false otherwise
	]]
	function self:isVisible(locator)
		local args={locator}
		return self:getBoolean("isVisible", args)
	end

	--[[
		Function: getAlert
		Retrieves the message of a JavaScript alert generated during the previous action, or fail if there were no alerts.
		Getting an alert has the same effect as manually clicking OK. If an
		alert is generated but you do not consume it with getAlert, the next Selenium action will fail.
		Under Selenium, JavaScript alerts will NOT pop up a visible alert dialog.
		Selenium does NOT support JavaScript alerts that are generated in a
		page's onload() event handler. In this case a visible dialog WILL be
		generated and Selenium will hang until someone manually clicks OK.

		Returns:
			string The message of the most recent JavaScript alert
	]]
	function self:getAlert()
		return self:getString("getAlert", false)
	end

	--[[
		Function: getEval
		Gets the result of evaluating the specified JavaScript snippet.  The snippet may
		have multiple lines, but only the result of the last line will be returned.
		Note that, by default, the snippet will run in the context of the "selenium"
		object itself, so *this* will refer to the Selenium object.  Use *window* to
		refer to the window of your application, e.g. *window.document.getElementById('foo')*
		If you need to use
		a locator to refer to a single element in your application page, you can
		use *this.browserbot.findElement("id=foo")* where "id=foo" is your locator.

		Parameters:
			script - String the JavaScript snippet to run

		Returns:
			string the results of evaluating the snippet
	]]
	function self:getEval(script)
		local args={script}
		return self:getString("getEval", args)
	end

	--[[
		Function: getConfirmation
		Retrieves the message of a JavaScript confirmation dialog generated during the previous action.
		By default, the confirm function will return true, having the same effect
		as manually clicking OK. This can be changed by prior execution of the
		chooseCancelOnNextConfirmation command.
		If an confirmation is generated but you do not consume it with getConfirmation,
		the next Selenium action will fail.
		*NOTE*: under Selenium, JavaScript confirmations will NOT pop up a visible dialog.
		*NOTE*: Selenium does NOT support JavaScript confirmations that are
		generated in a page's onload() event handler. In this case a visible
		dialog WILL be generated and Selenium will hang until you manually click OK.

		Returns
			string the message of the most recent JavaScript confirmation dialog
	]]
	function self:getConfirmation()
		return self:getString("getConfirmation", false)
	end

	--[[
		Function:getPrompt
		Retrieves the message of a JavaScript question prompt dialog generated during the previous action.
		Successful handling of the prompt requires prior execution of the
		answerOnNextPrompt command. If a prompt is generated but you
		do not get/verify it, the next Selenium action will fail.
		*NOTE*: under Selenium, JavaScript prompts will NOT pop up a visible dialog.
		*NOTE*: Selenium does NOT support JavaScript prompts that are generated in a
		page's onload() event handler. In this case a visible dialog WILL be
		generated and Selenium will hang until someone manually clicks OK.

		Returns:
			string the message of the most recent JavaScript question prompt
	]]
	function self:getPrompt()
		return self:getString("getPrompt", false)
	end

	--[[
		Function:getLocation
		Gets the absolute URL of the current page.

		Returns:
			string the absolute URL of the current page
	]]
	function self:getLocation()
		return self:getString("getLocation", false)
	end

	--[[
		Function: getBodyText
		Gets the entire text of the page.

		Returns:
			string the entire text of the page
	]]
	function self:getBodyText()
		return self:getString("getBodyText", false)
	end

	--[[
		Function: metaKeyDown
		Press the meta key and hold it down until doMetaUp() is called or a new page is loaded.
	]]
	function self:metaKeyDown()
		self:doCommand("metaKeyDown", false)
	end

	--[[
		Function: metaKeyUp
		Release the meta key.
	]]
	function self:metaKeyUp()
		self:doCommand("metaKeyUp", false)
	end

	--[[
		Function: shiftKeyDown
		Press the shift key and hold it down until doShiftUp() is called or a new page is loaded.
	]]
	function self:shiftKeyDown()
		self:doCommand("shiftKeyDown", false)
	end

	--[[
		Function: shiftKeyUp
		Release the shift key.
	]]
	function self:shiftKeyUp()
		self:doCommand("shiftKeyUp", false)
	end

	--[[
		Function: altKeyDown
		Press the alt key and hold it down until doAltUp() is called or a new page is loaded.
	]]
	function self:altKeyDown()
		self:doCommand("altKeyDown", false)
	end

	--[[
		Function: altKeyUp
		Release the alt key.
	]]
	function self:altKeyUp()
		self:doCommand("altKeyUp", false)
	end

	--[[
		Function: controlKeyDown
		Press the control key and hold it down until doControlUp() is called or a new page is loaded.
	]]
	function self:controlKeyDown()
		self:doCommand("controlKeyDown", false)
	end

	--[[
		Function: controlKeyUp
		Release the control key.
	]]
	function self:controlKeyUp()
		self:doCommand("controlKeyUp", false)
	end

	--[[
		Function: waitForFrameToLoad
		Waits for a new frame to load.
		Selenium constantly keeps track of new pages and frames loading,
		and sets a "newPageLoaded" flag when it first notices a page load.

		See Also:
			<_waitForPageToLoad>

		Parameters:
			frameAddress - String FrameAddress from the server side
			timeout - String timeout in milliseconds, after which this command will return with an error
	]]
	function self:waitForFrameToLoad(frameAddress,Timeout)
		local args={frameAddress,Timeout}
		self:doCommand("waitForFrameToLoad", args)
	end

	--[[
		Function: waitForPageToLoad
		Waits for a new page to load.
		You can use this command instead of the "AndWait" suffixes, "clickAndWait", "selectAndWait", "typeAndWait" etc.
		(which are only available in the JS API).
		Selenium constantly keeps track of new pages loading, and sets a "newPageLoaded"
		flag when it first notices a page load.  Running any other Selenium command after
		turns the flag to false.  Hence, if you want to wait for a page to load, you must
		wait immediately after a Selenium command that caused a page-load.
		timeout a timeout in milliseconds, after which this command will return with an error
	]]
	function self:waitForPageToLoad(timeout)
		local args={timeout}
		self:doCommand("waitForPageToLoad", args)
	end

	--[[
		Function: windowMaximize
		Resize currently selected window to take up the entire screen
	]]
	function self:windowMaximize()
		self:doCommand("windowMaximize", false)
	end

	--[[
		Function: windowFocus
		Gives focus to the currently selected window
	]]
	function self:windowFocus()
		self:doCommand("windowFocus", false)
	end

	--[[
		Function: dragAndDropToObject
		Drags an element and drops it on another element

		Parameters:
			locatorOfObjectToBeDragged - String an element to be dragged
			locatorOfDragDestinationObject - String an element whose location (i.e., whose center-most pixel) will be the point where locatorOfObjectToBeDragged  is dropped
	]]
	function self:dragAndDropToObject(locatorOfObjectToBeDragged, locatorOfDragDestinationObject)
		local args={locatorOfObjectToBeDragged,locatorOfDragDestinationObject}
		self:doCommand("dragAndDropToObject", args)
	end

	--[[
		Function: dragAndDrop
		Drags an element a certain distance and then drops it

		Parameters:
			locator - String an element locator
			movementsString - String offset in pixels from the current location to which the element should be moved, e.g., "+70,-300"
	]]
	function self:dragAndDrop(locator, movementsString)
		local args={locator,movementsString}
		self:doCommand("dragAndDrop", args)
	end

	--[[
		Function: getMouseSpeed
		returns the number of pixels between "mousemove" events during dragAndDrop commands (default=10).

		Returns:
			nuumber - the number of pixels between "mousemove" events during dragAndDrop commands (default=10)
	]]
	function self:getMouseSpeed()
		return _getNumber("getMouseSpeed", false)
	end

	--[[
		Function: setMouseSpeed
		Configure the number of pixels between "mousemove" events during dragAndDrop commands (default=10).
		Setting this value to 0 means that we'll send a "mousemove" event to every single pixel
		in between the start location and the end location-- that can be very slow, and may
		cause some browsers to force the JavaScript to timeout.
		If the mouse speed is greater than the distance between the two dragged objects, we'll
		just send one "mousemove" at the start location and then one final one at the end location.

		Parameters:
			pixels - String the number of pixels between "mousemove" events
	]]
	function self:setMouseSpeed(pixels)
		local args={pixels}
		self:doCommand("setMouseSpeed", args)
	end

	--[[
		Function: getHtmlSource
		returns the entire HTML source between the opening and closing "html" tags.

		Returns:
			string the entire HTML source
	]]
	function self:getHtmlSource()
		return self:getString("getHtmlSource", false)
	end

	--[[
		Function: setCursorPosition
		Moves the text cursor to the specified position in the given input element or textarea.
		This method will fail if the specified element isn't an input element or textarea.

		Parameters:
			locator - String  an element locator pointing to an input element or textarea
			position - String the numerical position of the cursor in the field-- position should be 0 to move the position to the beginning of the field.  You can also set the cursor to -1 to move it to the end of the field.
	]]
	function self:setCursorPosition(locator, position)
		local args={locatorposition}
		self:doCommand("setCursorPosition", args)
	end

	--[[
		Function: getElementIndex
		Get the relative index of an element to its parent (starting from 0). The comment node and empty text node
		will be ignored.
		locator an element locator pointing to an element
		@return number of relative index of the element to its parent (starting from 0)
	]]
	function self:getElementIndex(locator)
		local args={locator}
		return _getNumber("getElementIndex", args)
	end

	--[[
		Function: getElementPositionLeft
		Retrieves the horizontal position of an element

		Parameters:
			locator an element locator pointing to an element OR an element itself

		Returns:
			number of pixels from the edge of the frame.
	]]
	function self:getElementPositionLeft(locator)
		local args={locator}
		return _getNumber("getElementPositionLeft", args)
	end

	--[[
		Function: getElementPositionTop
		Retrieves the vertical position of an element

		Parameters:
			locator - String  an element locator pointing to an element OR an element itself

		Returns:
			number of pixels from the edge of the frame.
	]]
	function self:getElementPositionTop(locator)
		local args={locator}
		return _getNumber("getElementPositionTop", args)
	end

	--[[
		Function: getElementWidth
		Retrieves the width of an element

		Parameters:
			locator an element locator pointing to an element

		Returns:
			number width of an element in pixels
	]]
	function self:getElementWidth(locator)
		local args={locator}
		return _getNumber("getElementWidth", args)
	end

	--[[
		Function: getElementHeight
		Retrieves the height of an element

		Parameters:
			locator - String an element locator pointing to an element

		Returns:
			number height of an element in pixels
	]]
	function self:getElementHeight(locator)
		local args={locator}
		return _getNumber("getElementHeight", args)
	end

	--[[
		Function: getCursorPosition
		Retrieves the text cursor position in the given input element or textarea-- beware, this may not work perfectly on all browsers.
		Specifically, if the cursor/selection has been cleared by JavaScript, this command will tend to
		return the position of the last location of the cursor, even though the cursor is now gone from the page.  This is filed as SEL-243.
		This method will fail if the specified element isn't an input element or textarea, or there is no cursor in the element.

		Parameters:
			locator - String an element locator pointing to an input element or textarea

		Returns:
			number the numerical position of the cursor in the field
	]]
	function self:getCursorPosition(locator)
		local args={locator}
		return _getNumber("getCursorPosition", args)
	end

	--[[
		Function:getExpression
		returns the specified expression.
		This is useful because of JavaScript preprocessing.
		It is used to generate commands like assertExpression and waitForExpression.

		Parameters:
			expression - String the value to return

		Returns:
			string the value passed in
	]]
	function self:getExpression(expression)
		local args={expression}
		return self:getString("getExpression", args)
	end

	--[[
		Function: getXpathCount
		returns the number of nodes that match the specified xpath, eg. "//table" would give
		the number of tables.

		Parameters:
			xpath - String the xpath expression to evaluate. do NOT wrap this expression in a 'count()' function-- we will do that for you.

		Returns:
			number the number of nodes that match the specified xpath
	]]
	function self:getXpathCount(xpath)
		local args={xpath}
		return _getNumber("getXpathCount", args)
	end

	--[[
		Function: useXpathLibrary
		Allows choice of one of the available libraries.

		Parameters:
			libraryName - String name of the desired library Only the following three can be chosen.

		-"ajaxslt" - Google's library
		-"javascript-xpath" - Cybozu Labs' faster library
		-"default" - The default library.  Currently the default library is "ajaxslt"

		-If libraryName isn't one of these three, then  no change will be made.

		Returns:
			number
	]]
	function self:useXpathLibrary(libraryName)
		local args={libraryName}
		return _getNumber("useXpathLibrary", args)
	end

	--[[
		Function: assignId
		Temporarily sets the "id" attribute of the specified element, so you can locate it in the future
		using its ID rather than a slow/complicated XPath.  This ID will disappear once the page is reloaded.

		Parameters:
			locator - String an element locator pointing to an element
			identifier - String a string to be used as the ID of the specified element

		Returns:
			number
	]]
	function self:assignId(locator, identifier)
		local args={locator,identifier}
		return _getNumber("assignId", args)
	end

	--[[
		Function: allowNativeXpath
		Specifies whether Selenium should use the native in-browser implementation
		of XPath (if any native version is available)-- if you pass "false" to
		this function, we will always use our pure-JavaScript xpath library.
		Using the pure-JS xpath library can improve the consistency of xpath
		element locators between different browser vendors, but the pure-JS
		version is much slower than the native implementations.

		Parameters:
			allow -  boolean, true means we'll prefer to use native XPath-- false means we'll only use JS XPath
	]]
	function self:allowNativeXpath(allow)
		local args={allow}
		self:doCommand("allowNativeXpath", args)
	end

	--[[
		Function:waitForCondition
		Runs the specified JavaScript snippet repeatedly until it evaluates to "true".
		The snippet may have multiple lines, but only the result of the last line
		will be considered.
		Note that, by default, the snippet will be run in the runner's test window, not in the window
		of your application.  To get the window of your application, you can use
		the JavaScript snippet *selenium.browserbot.getCurrentWindow()*, and then
		run your JavaScript in there

		Parameters:
			script - String the JavaScript snippet to run
			timeout - String a timeout in milliseconds, after which this command will return with an error
	]]
	function self:waitForCondition(script, Timeout)
		local args={script,Timeout}
		self:doCommand("waitForCondition", args)
	end

	--[[
		Function: getAllWindowTitles
			returns the titles of all windows that the browser knows about in an array.

		Returns:
			Array of titles of all windows that the browser knows about.
	]]
	function self:getAllWindowTitles()
		return self:getStringArray("getAllWindowTitles", false)
	end

	--[[
		Function: getAllWindowNames
		returns the names of all windows that the browser knows about in an array.

		Returns:
			array Array of names of all windows that the browser knows about.
	]]
	function self:getAllWindowNames()
		return self:getStringArray("getAllWindowNames", false)
	end

	--[[
		Function: getAllWindowIds
		returns the IDs of all windows that the browser knows about in an array.

		Returns:
			array Array of identifiers of all windows that the browser knows about.
	]]
	function self:getAllWindowIds()
		return self:getStringArray("getAllWindowIds", false)
	end

	--[[
		Function: getAllFields
		returns the IDs of all input fields on the page.
		If a given field has no ID, it will appear as "" in this array.

		Returns:
			array the IDs of all field on the page
	]]
	function self:getAllFields()
		return self:getStringArray("getAllFields", false)
	end

	--[[
		Function:getAttributeFromAllWindows
		returns an array of JavaScript property values from all known windows having one.

		Parameters:
			attributeName -String name of an attribute on the windows

		Returns:
			array the set of values of this attribute from all known windows.
	]]
	function self:getAttributeFromAllWindows(attributeName)
		local args={attributeName}
		return self:getStringArray("getAttributeFromAllWindows", false)
	end

	--[[
		Function: getAllLinks
		returns the IDs of all links on the page.
		If a given link has no ID, it will appear as "" in this array.

		Returns:
			array the IDs of all links on the page
	]]
	function self:getAllLinks()
		return self:getStringArray("getAllLinks", false)
	end

	--[[
		Function: getAllButtons
		returns the IDs of all buttons on the page.
		If a given button has no ID, it will appear as "" in this array.

		Returns:
			array the IDs of all buttons on the page
	]]
	function self:getAllButtons()
		return self:getStringArray("getAllButtons", false)
	end

	--[[
		Function: setTimeout
		Specifies the amount of time that Selenium will wait for actions to complete.
		Actions that require waiting include "open" and the "waitFor*" actions.
		The default timeout is 30 seconds.

		Parameters:
			timeout a timeout in milliseconds, after which the action will return with an error
	]]
	function self:setTimeout(Timeout)
		local args={Timeout}
		self:doCommand("setTimeout", args)
	end

	--[[
		Function: goBack
		Simulates the user clicking the "back" button on their browser.
	]]
	function self:goBack()
		self:doCommand("goBack", false)
	end

	--[[
		Function: highlight
		riefly changes the backgroundColor of the specified element yellow.  Useful for debugging.

		Parameters:
			locator - String an element locator
	]]
	function self:highlight(locator)
		local args={locator}
		self:doCommand("highlight", args)
	end

	--[[
		Function: refresh
		Simulates the user clicking the "Refresh" button on their browser.
	]]
	function self:refresh()
		self:doCommand("refresh", false)
	end

	--[[
		Function: isEditable
		Determines whether the specified input element is editable, ie hasn't been disabled.
		This method will fail if the specified element isn't an input element.

		Parameters:
			locator - String an element locator

		Returns:
			boolean true if the input element is editable, false otherwise
	]]
	function self:isEditable(locator)
		local args={locator}
		return self:getBoolean("isEditable", args)
	end

	--[[
		Function: isTextPresent
		Verifies that the specified text pattern appears somewhere on the rendered page shown to the user.

		Parameters:
			pattern - String a pattern to match with the text of the page

		Returns:
			boolean true if the pattern matches the text, false otherwise
	]]
	function self:isTextPresent(pattern)
		local args={pattern}
		return self:getBoolean("isTextPresent", args)
	end

	--[[
		Function: isElementPresent
		Verifies that the specified element is somewhere on the page.

		Parameters:
			locator - String an element locator

		Returns:
			boolean true if the element is present, false otherwise
	]]
	function self:isElementPresent(locator)
		local args={locator}
		return self:getBoolean("isElementPresent", args)
	end

	--[[
		Function: setBrowserLogLevel
		Sets the threshold for browser-side logging messages-- log messages beneath this threshold will be discarded.
		Valid logLevel strings are: "debug", "info", "warn", "error" or "off".
		To see the browser logs, you need to either show the log window in GUI mode, or enable browser-side logging in Selenium RC.

		Parameters:
			logLevel - String one of the following: "debug", "info", "warn", "error" or "off"
	]]
	function self:setBrowserLogLevel(logLevel)
		local args={logLevel}
		return self:doCommand("setBrowserLogLevel", args)
	end

	--[[
		Function: setContext
		Writes a message to the status bar and adds a note to the browser-side log.

		Parameters:
			context - String the message to be sent to the browser
	]]
	function self:setContext(context)
		local args={context}
		self:doCommand("setBrowserLogLevel", args)
	end

	--[[
		Function: retrieveLastRemoteControlLogs
		Retrieve the last messages logged on a specific remote control. Useful for error reports, especially
		when running multiple remote controls in a distributed environment. The maximum number of log messages
		that can be retrieve is configured on remote control startup.

		Returns:
			string The last N log messages as a multi-line string.
	]]
	function self:retrieveLastRemoteControlLogs()
		return self:getString("retrieveLastRemoteControlLogs", false)
	end

	--[[
		Function: shutDownSeleniumServer
		Kills the running Selenium Server and all browser sessions.  After you run this command, you will no longer be able to send
		commands to the server-- you can't remotely start the server once it has been stopped.  Normally
		you should prefer to run the "stop" command, which terminates the current browser session, rather than
		shutting down the entire server.
	]]
	function self:shutDownSeleniumServer()
		self:doCommand("shutDownSeleniumServer", false)
	end

   return self
end

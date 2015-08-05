# Lua Selenium Driver

A port from [sourceforga][source].

## Overview

Lua Selenium Driver is a Selenium 1 (Selenium RC) client library that provide
a programming interface (API), i.e., a set of functions, which run Selenium
commands. Within each interface, there is a programming function that supports
each Selenese command.

## How to run code in examples

* Install [Selenium standalone jar]: http://goo.gl/yLJLZg

* Install [chromedriver]: http://chromedriver.storage.googleapis.com/index.html?path=2.16/

* Start selenium server
```java -jar selenium-server-standalone-2.47.1.jar -Dwebdriver.chrome.driver=chromedriver```
somewhere else

* Go to example directory 

* Run example ```lua googleSearchTest.lua```

[source]: http://luaselenium.sourceforge.net/index.html

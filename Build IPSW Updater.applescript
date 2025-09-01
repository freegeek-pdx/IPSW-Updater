--
-- Created by Pico Mitchell (of Free Geek)
--
-- https://ipsw.app
-- https://github.com/freegeek-pdx/IPSW-Updater
--
-- MIT License
--
-- Copyright (c) 2022 Free Geek
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--

use AppleScript version "2.7"
use scripting additions
use framework "Foundation"

set bundleIdentifierPrefix to "org.freegeek."

set pathToMeInfo to (info for (path to me))

try
	set infoPlistPath to ((POSIX path of (path to me)) & "Contents/Info.plist")
	((infoPlistPath as POSIX file) as alias)
	
	set AppleScript's text item delimiters to "-"
	set correctBundleIdentifier to bundleIdentifierPrefix & ((words of (name of me)) as text)
	try
		set currentBundleIdentifier to ((do shell script "/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' " & (quoted form of infoPlistPath)) as text)
		if (currentBundleIdentifier is not equal to correctBundleIdentifier) then error "INCORRECT Bundle Identifier"
	on error
		do shell script "plutil -replace CFBundleIdentifier -string " & (quoted form of correctBundleIdentifier) & " " & (quoted form of infoPlistPath)
		
		try
			set currentCopyright to ((do shell script "/usr/libexec/PlistBuddy -c 'Print :NSHumanReadableCopyright' " & (quoted form of infoPlistPath)) as text)
			if (currentCopyright does not contain "Twemoji") then error "INCORRECT Copyright"
		on error
			do shell script "plutil -replace NSHumanReadableCopyright -string " & (quoted form of ("Copyright © " & (year of (current date)) & " Free Geek
Designed and Developed by Pico Mitchell")) & " " & (quoted form of infoPlistPath)
		end try
		
		try
			set minSystemVersion to ((do shell script "/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' " & (quoted form of infoPlistPath)) as text)
			if (minSystemVersion is not equal to "10.13") then error "INCORRECT Minimum System Version"
		on error
			do shell script "plutil -remove LSMinimumSystemVersionByArchitecture " & (quoted form of infoPlistPath) & "; plutil -replace LSMinimumSystemVersion -string '10.13' " & (quoted form of infoPlistPath)
		end try
		
		try
			set prohibitMultipleInstances to ((do shell script "/usr/libexec/PlistBuddy -c 'Print :LSMultipleInstancesProhibited' " & (quoted form of infoPlistPath)) as number)
			if (prohibitMultipleInstances is equal to 0) then error "INCORRECT Multiple Instances Prohibited"
		on error
			do shell script "plutil -replace LSMultipleInstancesProhibited -bool true " & (quoted form of infoPlistPath)
		end try
		
		try
			set allowMixedLocalizations to ((do shell script "/usr/libexec/PlistBuddy -c 'Print :CFBundleAllowMixedLocalizations' " & (quoted form of infoPlistPath)) as number)
			if (allowMixedLocalizations is equal to 1) then error "INCORRECT Localization"
		on error
			do shell script "plutil -replace CFBundleAllowMixedLocalizations -bool false " & (quoted form of infoPlistPath) & "; plutil -replace CFBundleDevelopmentRegion -string 'en_US' " & (quoted form of infoPlistPath)
		end try
		
		try
			set currentAppleEventsUsageDescription to ((do shell script "/usr/libexec/PlistBuddy -c 'Print :NSAppleEventsUsageDescription' " & (quoted form of infoPlistPath)) as text)
			if (currentAppleEventsUsageDescription does not contain (name of me)) then error "INCORRECT AppleEvents Usage Description"
		on error
			do shell script "plutil -replace NSAppleEventsUsageDescription -string " & (quoted form of ("You MUST click the “OK” button for “" & (name of me) & "” to be able to function.")) & " " & (quoted form of infoPlistPath)
		end try
		
		try
			set currentVersion to ((do shell script "/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' " & (quoted form of infoPlistPath)) as text)
			if (currentVersion is equal to "1.0") then error "INCORRECT Version"
		on error
			set shortCreationDateString to (short date string of (creation date of pathToMeInfo))
			set AppleScript's text item delimiters to "/"
			set correctVersion to ((text item 3 of shortCreationDateString) & "." & (text item 1 of shortCreationDateString) & "." & (text item 2 of shortCreationDateString))
			do shell script "plutil -remove CFBundleVersion " & (quoted form of infoPlistPath) & "; plutil -replace CFBundleShortVersionString -string " & (quoted form of correctVersion) & " " & (quoted form of infoPlistPath)
		end try
		
		-- The "main.scpt" must NOT be writable to prevent the code signature from being invalidated: https://developer.apple.com/library/archive/releasenotes/AppleScript/RN-AppleScript/RN-10_8/RN-10_8.html#//apple_ref/doc/uid/TP40000982-CH108-SW8
		do shell script "osascript -e 'delay 0.5' -e 'repeat while (application \"" & (POSIX path of (path to me)) & "\" is running)' -e 'delay 0.5' -e 'end repeat' -e 'try' -e 'do shell script \"chmod a-w \\\"" & ((POSIX path of (path to me)) & "Contents/Resources/Scripts/main.scpt") & "\\\"\"' -e 'do shell script \"codesign -fs \\\"Developer ID Application\\\" --strict \\\"" & (POSIX path of (path to me)) & "\\\"\"' -e 'on error codeSignError' -e 'activate' -e 'display alert \"Code Sign Error\" message codeSignError' -e 'end try' -e 'do shell script \"open -na \\\"" & (POSIX path of (path to me)) & "\\\"\"' > /dev/null 2>&1 &"
		quit
		delay 10
	end try
end try

set builderFileName to (displayed name of pathToMeInfo)
if (builderFileName contains ".") then -- "displayed name" could still contain extension that we need to remove if Finder settings are set to include them.
	set builderFileNameExtension to ("." & (name extension of pathToMeInfo))
	set AppleScript's text item delimiters to builderFileNameExtension
	set builderFileName to ((first text item of builderFileName) as text)
end if

set AppleScript's text item delimiters to "Build "
set projectName to ((last text item of builderFileName) as text)

set AppleScript's text item delimiters to "-"
set projectNameForBundleID to ((words of projectName) as text)

set projectFolderPath to (POSIX path of (((path to me) as text) & "::")) -- https://apple.stackexchange.com/a/302397

set appBuildPath to projectFolderPath & "Build/" & projectName & ".app"

repeat
	waitUntilAwakeAndUnlocked()
	activate
	set buildAlertReply to display alert builderFileName & "?" buttons {"Launch", "Quit", "Build"} cancel button 2 default button 3
	delay 0.2 -- Delay a moment to allow the prompt to close.
	
	try
		if (button returned of buildAlertReply is "Build") then
			repeat while (application appBuildPath is running)
				activate
				try
					do shell script "afplay /System/Library/Sounds/Basso.aiff > /dev/null 2>&1 &"
				on error
					beep
				end try
				display alert "You must Quit " & projectName & " to Build." buttons {"Cancel", "Try Again"} cancel button 1 default button 2
			end repeat
			
			try -- IPSW Updater should never have any TCC permissions, but clear them just in case to always reproduce any un-intented prompts for a new build
				do shell script ("tccutil reset All " & (quoted form of (bundleIdentifierPrefix & projectNameForBundleID)))
			end try
			
			do shell script ("rm -rf " & (quoted form of appBuildPath))
			
			try
				(((projectFolderPath & "Build") as POSIX file) as alias)
			on error
				try
					do shell script ("mkdir -p " & (quoted form of (projectFolderPath & "Build")))
				end try
			end try
			
			try
				(((projectFolderPath & projectName & " Resources") as POSIX file) as alias)
			on error
				try
					do shell script ("mkdir -p " & (quoted form of (projectFolderPath & projectName & " Resources")))
				end try
			end try
			
			-- Since JXA cannot be compiled as Run-Only like regular AppleScript can and I wanted to be able to distribute the applet in a way that the source could not be edited.
			-- To do this, I'm using Google Closure Compiler to minify the JXA source code, and then compressing that minified source with gzip and then base64 encoding that compressed data.
			-- The resuling base64 encoded string of the gzipped and minified source code is stored within a JXA wrapper script and decoded and decompressed
			-- back into the minified source code when the applet is launched and the minified source code is then run via "eval()".
			-- This is nothing crazy that couldn't be reversed by someone who wanted to to be able to retrieve the raw minified source code,
			-- but that doesn't really matter since this project with the un-minified source code all released as open source anyways.
			-- The purpose of the is more the make the distributed applet not easily editable rather than protecting the source code from being retrieved.
			
			set jxaSourcePath to (projectFolderPath & projectName & ".jxa")
			
			set appVersion to (do shell script "awk -F \"'\" '($1 == \"const appVersion = \") { print $(NF-1); exit }' " & (quoted form of jxaSourcePath))
			if (appVersion is equal to "") then error "FAILED TO GET APP VERSION"
			
			-- Make sure Google Closure Compiler is installed, and check that it's the latest version and prompt if an update is available.
			-- https://developers.google.com/closure/compiler/ & https://search.maven.org/artifact/com.google.javascript/closure-compiler & https://mvnrepository.com/artifact/com.google.javascript/closure-compiler & https://github.com/google/closure-compiler
			set newestInstalledGoogleClosureCompilerPath to (do shell script ("ls -t " & (quoted form of projectFolderPath) & "closure-compiler*.jar | head -1"))
			set installedGoogleClosureCompileVersion to (do shell script ("java -jar " & (quoted form of newestInstalledGoogleClosureCompilerPath) & " --version | awk -F ': ' '($1 == \"Version\") { print $NF; exit }'"))
			if (installedGoogleClosureCompileVersion is equal to "") then
				open location "https://maven-badges.sml.io/maven-central/com.google.javascript/closure-compiler"
				error "MINIFY JXA ERROR (GOOGLE CLOSURE COMPILER NOT FOUND)"
			end if
			
			set latestGoogleClosureCompileVersion to (do shell script "curl -m 5 --retry 2 -sfw '%{redirect_url}' -o /dev/null 'https://maven-badges.sml.io/maven-central/com.google.javascript/closure-compiler' | awk -F '/' '{ print $7; exit }'")
			if (latestGoogleClosureCompileVersion does not start with "v2") then
				beep
			else if (installedGoogleClosureCompileVersion is not equal to latestGoogleClosureCompileVersion) then
				set didChooseDownloadLatestGoogleClosureCompiler to false
				try
					waitUntilAwakeAndUnlocked()
					activate
					display alert "Newer Google Closure Compiler Available" message ("Google Closure Compiler version " & latestGoogleClosureCompileVersion & " is now available!

Google Closure Compiler version " & installedGoogleClosureCompileVersion & " is currently installed.") buttons {("Continue Build with Google Closure Compiler " & installedGoogleClosureCompileVersion), ("Download Google Closure Compiler " & latestGoogleClosureCompileVersion)} cancel button 1 default button 2
					set didChooseDownloadLatestGoogleClosureCompiler to true
					open location "https://maven-badges.sml.io/maven-central/com.google.javascript/closure-compiler"
				end try
				
				if (didChooseDownloadLatestGoogleClosureCompiler) then
					error number -128 -- Simulate user canceled if chose to download latest Google Closure Compiler version.
				end if
			end if
			
			-- GOOGLE CLOSURE COMPILER OPTION NOTES:
			-- The following compilation/minification results in about 95 KB space savings of the JXA source code (about 180 KB down to about 85 KB).
			-- DO NOT SET "--compilation_level 'ADVANCED'" which would result in about 10 KB more space savings, but breaks lots of code because it renames properties which need to NOT be renamed when they come from and are written to JSON files, which SIMPLE compilation (the default setting) does not do.
			-- Set "--language_in 'ECMASCRIPT_2018'" so that it will error if any JavaScript features are used that may not be supported on macOS 10.13 High Sierra (which I found to support ES2018 and NOT ES2019 by manually checking for newer language features).
			-- Set "--assume_function_wrapper" so that top level global names are also renamed (not just names within functions) to save space since those names are never referenced from the main wrapper script (this results in about 16 KB extra space savings vs not using this option).
			-- Set "--formatting 'SINGLE_QUOTES'" only because I prefer defaulting to single quoted strings, but it's not really necessary and shouldn't make a difference to the code either way.
			-- NOTE: Even though Google Closure Compiler will rename variables and functions, there should be no conflicts with the variable names in the main wrapper script since the code will be run via "eval()" which appears to be its own block scope and none of the variables or function are called outside of "eval()" after it runs.
			set jxaMinifiedSource to (do shell script ("java -jar " & (quoted form of newestInstalledGoogleClosureCompilerPath) & " --language_in 'ECMASCRIPT_2018' --language_out 'ECMASCRIPT_2018' --assume_function_wrapper --formatting 'SINGLE_QUOTES' --js " & (quoted form of jxaSourcePath)))
			set jxaMinifiedSourceLength to (length of jxaMinifiedSource)
			if (jxaMinifiedSourceLength is equal to 0) then error "MINIFY JXA ERROR (GOOGLE CLOSURE COMPILER FAILED)"
			
			-- GZIP THE MINIFIED GOOGLE CLOSURE COMPILER OUTPUT TO SAVE EVEN MORE SPACE:
			-- As stated in the FAQ, the way Google Closure Compiler minifies code is actually done with the intention of the result being gzipping: https://github.com/google/closure-compiler/wiki/FAQ#closure-compiler-inlined-all-my-strings-which-made-my-code-size-bigger-why-did-it-do-that
			-- Gzipping gets the size all the way down to about 25 KB, and then base64 encoding the gzipped data brings it back up to about 30 KB, but still a massive savings over not gzipping.
			set jxaObfuscatedSource to (do shell script ("printf '%s' " & (quoted form of jxaMinifiedSource) & " | gzip -9 | base64"))
			if (jxaObfuscatedSource is equal to "") then error "GZIP/BASE64 FAILED"
			
			set initialSourceComments to (do shell script ("awk '($1 == \"//\") { print } ($0 == \"\") { exit }' " & (quoted form of jxaSourcePath)))
			if (initialSourceComments is equal to "") then
				error "FAILED TO GET INITIAL SOURCE COMMENTS"
			else
				set initialSourceComments to (initialSourceComments & linefeed & linefeed)
			end if
			
			do shell script "osacompile -l 'JavaScript' -o " & (quoted form of appBuildPath) & " -e " & (quoted form of (initialSourceComments & ¬
				"'use strict';" & ¬
				"ObjC.import('AppKit');" & ¬
				"const a=Application.currentApplication();" & ¬
				"a.includeStandardAdditions=true;" & ¬
				"let s='Failed to Load Source';" & ¬
				"try{" & ¬
				"const ab=$.NSBundle.mainBundle;" & ¬
				"const ap=ab.bundlePath.js;" & ¬
				"if(ap.endsWith('.app')){" & ¬
				"const zt=$.NSTask.alloc.init;" & ¬
				"zt.executableURL=$.NSURL.fileURLWithPath('/usr/bin/zcat');" & ¬
				"zt.standardInput=$.NSPipe.pipe;" & ¬
				"const ztI=zt.standardInput.fileHandleForWriting;" & ¬
				"ztI.writeData($.NSData.alloc.initWithBase64EncodedStringOptions('" & jxaObfuscatedSource & "',$.NSDataBase64DecodingIgnoreUnknownCharacters));" & ¬
				"ztI.closeFile;" & ¬
				"zt.standardOutput=$.NSPipe.pipe;" & ¬
				"zt.launchAndReturnError($());" & ¬
				"const ztO=zt.standardOutput.fileHandleForReading;" & ¬
				"s=$.NSString.alloc.initWithDataEncoding((ztO.respondsToSelector('readDataToEndOfFileAndReturnError:')?ztO.readDataToEndOfFileAndReturnError($()):ztO.readDataToEndOfFile),$.NSUTF8StringEncoding).js;" & ¬
				"if(!s)throw new Error('Source Decode/Decompress Error');" & ¬
				"if(s.length!=" & jxaMinifiedSourceLength & ")throw new Error(`Invalid Decoded/Decompressed Source (${s.length} ≠ " & jxaMinifiedSourceLength & ")`);" & ¬
				"eval(s);" & ¬
				"}else a.doShellScript('/usr/bin/open -nb " & bundleIdentifierPrefix & projectNameForBundleID & "')" & ¬
				"}catch(e){" & ¬
				"if(e.errorNumber!==-128){" & ¬
				"delay(0.5);" & ¬
				"a.activate();" & ¬
				"try{" & ¬
				"a.displayAlert(`" & projectName & ": ${((!s)?'Source Not Decoded/Decompressed':((s.length==" & jxaMinifiedSourceLength & ")?'Runtime Error':s.substring(0,100)))}`,{message:`${e}\\n\\n${JSON.stringify(e,Object.getOwnPropertyNames(e))}`,as:'critical',buttons:['Quit','Re-Download “" & projectName & "”'],cancelButton:1,defaultButton:2});" & ¬
				"a.doShellScript('/usr/bin/open https://ipsw.app/download/')" & ¬
				"}catch(e){}}}"))
			
			set quotedBuiltAppInfoPlistPath to (quoted form of (appBuildPath & "/Contents/Info.plist"))
			-- The "main.scpt" for normal AppleScript applets must NOT be writable to prevent the code signature from being invalidated: https://developer.apple.com/library/archive/releasenotes/AppleScript/RN-AppleScript/RN-10_8/RN-10_8.html#//apple_ref/doc/uid/TP40000982-CH108-SW8
			-- I don't think that applies to JXA applets since they do not write back properties to the script file, but still doesn't hurt to set it as not writable.
			do shell script ("
chmod a-w " & (quoted form of (appBuildPath & "/Contents/Resources/Scripts/main.scpt")) & "

plutil -replace CFBundleIdentifier -string " & (quoted form of (bundleIdentifierPrefix & projectNameForBundleID)) & " " & quotedBuiltAppInfoPlistPath & "
plutil -replace CFBundleShortVersionString -string " & (quoted form of appVersion) & " " & quotedBuiltAppInfoPlistPath & "

plutil -remove LSMinimumSystemVersionByArchitecture " & quotedBuiltAppInfoPlistPath & "
plutil -replace LSMinimumSystemVersion -string '10.13' " & quotedBuiltAppInfoPlistPath & "

plutil -replace LSMultipleInstancesProhibited -bool true " & quotedBuiltAppInfoPlistPath & "

plutil -replace NSHumanReadableCopyright -string " & (quoted form of ("Copyright © " & (year of (current date)) & " Free Geek
Designed and Developed by Pico Mitchell")) & " " & quotedBuiltAppInfoPlistPath & "

# Force English to be able to remove menu items by their English titles (and no text within the app is localized anyways).
plutil -replace CFBundleDevelopmentRegion -string 'en_US' " & quotedBuiltAppInfoPlistPath & "
plutil -replace  CFBundleAllowMixedLocalizations -bool false " & quotedBuiltAppInfoPlistPath & "

plutil -remove NSHomeKitUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSAppleMusicUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSCalendarsUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSSiriUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSCameraUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSMicrophoneUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSAppleEventsUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSRemindersUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSContactsUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSPhotoLibraryUsageDescription " & quotedBuiltAppInfoPlistPath & "
plutil -remove NSSystemAdministrationUsageDescription " & quotedBuiltAppInfoPlistPath & "

mv " & (quoted form of (appBuildPath & "/Contents/MacOS/applet")) & " " & (quoted form of (appBuildPath & "/Contents/MacOS/" & projectName)) & "
plutil -replace CFBundleExecutable -string " & (quoted form of projectName) & " " & quotedBuiltAppInfoPlistPath & "

mv " & (quoted form of (appBuildPath & "/Contents/Resources/applet.rsrc")) & " " & (quoted form of (appBuildPath & "/Contents/Resources/" & projectName & ".rsrc")) & "

rm -f " & (quoted form of (appBuildPath & "/Contents/Resources/applet.icns")) & "
plutil -replace CFBundleIconFile -string " & (quoted form of projectName) & " " & quotedBuiltAppInfoPlistPath & "
plutil -replace CFBundleIconName -string " & (quoted form of projectName) & " " & quotedBuiltAppInfoPlistPath & "

ditto " & (quoted form of (projectFolderPath & projectName & " Resources/")) & " " & (quoted form of (appBuildPath & "/Contents/Resources/")) & "
rm -f " & (quoted form of (appBuildPath & "/Contents/Resources/.DS_Store")) & "

# Any xattrs MUST be cleared for 'codesign' to not error (this MUST be done BEFORE code signing the following 'Launch IPSW Updater' script since signing shell scripts stores the code signature in the xattrs, and those specific xattrs do not prevent code signing of the app itself).
xattr -crs " & (quoted form of appBuildPath) & "

touch " & (quoted form of appBuildPath) & "

# The following 'Launch IPSW Updater' script is created and SIGNED so that it can be used for the LaunchAgent that can be created by the 'IPSW Updater' app,
# and it MUST be signed so that the 'AssociatedBundleIdentifier' key can be used in macOS 13 Ventura so that the LaunchAgent is properly displayed as being for the IPSW Updater app.
# This is because the executable in the LaunchAgent MUST have a Code Signing Team ID that matches the Team ID of the app Bundle ID specified in the 'AssociatedBundleIdentifiers' key (as described in https://developer.apple.com/documentation/servicemanagement/updating_helper_executables_from_earlier_versions_of_macos?language=objc#4065210).
# We DO NOT want to have the LaunchAgent just run the 'IPSW Updater' app binary directly because if the app is launched that way via the LaunchAgent and then the LaunchAgent is removed during that execution the app will be terminated immediately when 'launchctl bootout' is run.
# That issue has always been avoided by using the '/usr/bin/open' binary to launch the app instead. But using '/usr/bin/open' directly in the LaunchAgent on macOS 13 Ventura makes it show as just running 'open' from an unidentified developer in the new Login Items list, which may seem suspicious or confusing.
# Making this simple SIGNED script that just runs '/usr/bin/open' and then using the 'AssociatedBundleIdentifiers' allows the LaunchAgent to be properly displayed as being for the 'IPSW Updater' app.
# When on macOS 12 Monterey and older, the 'AssociatedBundleIdentifiers' will just be ignored and the 'Launch IPSW Updater' will function the same as if we directly specified '/usr/bin/open' with the path to the app in the LaunchAgent.
# Search for 'AssociatedBundleIdentifiers' in the 'IPSW Updater.jxa' script to see the LaunchAgent creation code.
echo '#!/bin/sh
/usr/bin/open -na \"${0%/Contents/*}\"' > " & (quoted form of (appBuildPath & "/Contents/Resources/Launch " & projectName)) & "
chmod +x " & (quoted form of (appBuildPath & "/Contents/Resources/Launch " & projectName)) & "
codesign -s 'Developer ID Application' --identifier " & (quoted form of (bundleIdentifierPrefix & "Launch-" & projectNameForBundleID)) & " --strict " & (quoted form of (appBuildPath & "/Contents/Resources/Launch " & projectName)))
			
			try
				do shell script ("codesign -fs 'Developer ID Application' --strict " & (quoted form of appBuildPath)) -- Code signing will be re-done (with hardened runtime) if notarization is done below, but always run "codesign" here in case NOT notarizing during testing so the app can properly launch and validate the code signature.
				
				if (appVersion does not end with "-0") then
					repeat while (application appBuildPath is running)
						delay 0.5
					end repeat
					
					try
						waitUntilAwakeAndUnlocked()
						activate
						display alert ("Notarize " & projectName & " version " & appVersion & "?") buttons {"No", "Yes"} cancel button 1 default button 2
						delay 0.2 -- Delay a moment to allow the prompt to close.
						
						try
							set AppleScript's text item delimiters to ""
							set appZipName to (((words of projectName) as text) & "-v")
							set AppleScript's text item delimiters to {".", "-"}
							if ((count of (every text item of appVersion)) is equal to 4) then
								set appZipName to (appZipName & ((text item 1 of appVersion) as text))
								if ((length of ((text item 2 of appVersion) as text)) < 2) then
									set appZipName to (appZipName & "0" & ((text item 2 of appVersion) as text))
								else
									set appZipName to (appZipName & ((text item 2 of appVersion) as text))
								end if
								if ((length of ((text item 3 of appVersion) as text)) < 2) then
									set appZipName to (appZipName & "0" & ((text item 3 of appVersion) as text))
								else
									set appZipName to (appZipName & ((text item 3 of appVersion) as text))
								end if
								set appZipName to (appZipName & ((text item 4 of appVersion) as text))
							else
								set appZipName to (appZipName & appVersion)
							end if
							
							set appZipPathForNotarization to (projectFolderPath & "Build/" & appZipName & "-NOTARIZATION-SUBMISSION.zip")
							set appZipPath to (projectFolderPath & "Build/" & appZipName & ".zip")
							
							-- Setting up "notarytool": https://scriptingosx.com/2021/07/notarize-a-command-line-tool-with-notarytool/ & https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
							
							-- NOTE: Every command is chained with "&&" so that if anything errors, it all stops and all combined output from every command will be included in the error message.
							-- Also, the output of "spctl -avv" is checked for "source=Notarized Developer ID" since a signed but unnotarized app could pass the initial assessment (but stapling should have failed before getting the that check anyways).
							-- And notarization is also verified with "codesign": https://developer.apple.com/forums/thread/128683?answerId=404727022#404727022 & https://developer.apple.com/forums/thread/130560
							-- Information about using "--deep" and "--strict" options during "codesign" verification:
							-- https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/resolving_common_notarization_issues#3087735
							-- https://developer.apple.com/library/archive/technotes/tn2206/_index.html#//apple_ref/doc/uid/DTS40007919-CH1-TNTAG211
							-- https://developer.apple.com/library/archive/technotes/tn2206/_index.html#//apple_ref/doc/uid/DTS40007919-CH1-TNTAG404
							-- The "--deep" option is DEPRECATED in macOS 13 Ventura for SIGNING but I don't think it's deprecated for VERIFYING since verification is where it was always really intended to be used (as explained in the note in the last link in the list above).
							
							set notarizationOutput to (do shell script ("rm -f " & (quoted form of appZipPathForNotarization) & " " & (quoted form of appZipPath) & " &&
echo 'Code Signing App...' &&
codesign -fs 'Developer ID Application' -o runtime --strict " & (quoted form of appBuildPath) & " 2>&1 &&
echo '
Zipping App for Notarization...' &&
ditto -ckvV --keepParent " & (quoted form of appBuildPath) & " " & (quoted form of appZipPathForNotarization) & " 2>&1 &&
echo '
Notarizing App...' &&
xcrun notarytool submit " & (quoted form of appZipPathForNotarization) & " --keychain-profile 'notarytool App Specific Password' --wait 2>&1 &&
rm -f " & (quoted form of appZipPathForNotarization) & " &&
echo '
Stapling Notarization Ticket to App...' &&
xcrun stapler staple " & (quoted form of appBuildPath) & " 2>&1 &&
echo '
Assessing Notarized App...' &&
spctl_assess_output=\"$(spctl -avv " & (quoted form of appBuildPath) & " 2>&1; true)\" && # Never exit because of spctl error to always show the output and notarization will be checked explicitly below.
echo \"${spctl_assess_output}\" &&
codesign -vv --deep --strict -R '=notarized' --check-notarization " & (quoted form of appBuildPath) & " 2>&1 &&
echo \"${spctl_assess_output}\" | grep -qxF 'source=Notarized Developer ID' &&
echo '
Zipping Notarized App...' &&
ditto -ckvV --keepParent --sequesterRsrc --zlibCompressionLevel 9 " & (quoted form of appBuildPath) & " " & (quoted form of appZipPath) & " 2>&1") without altering line endings) -- VERY IMPORTANT to NOT alter line endings so that "awk" can read each line (which needs "\n" instead of "\r").
							
							try
								set notarizationSubmissionID to (do shell script ("echo " & (quoted form of notarizationOutput) & " | awk '($1 == \"id:\") { print $NF; exit }'"))
								if (notarizationSubmissionID is not equal to "") then
									set notarizationOutput to (notarizationOutput & "

Notarization Log:
" & (do shell script ("xcrun notarytool log " & notarizationSubmissionID & " --keychain-profile 'notarytool App Specific Password' 2>&1")))
								end if
							end try
							
							set appZipChecksum to "UNKNOWN"
							try
								set appZipChecksum to (last word of (do shell script "openssl dgst -sha512 " & (quoted form of appZipPath)))
								set the clipboard to appZipChecksum
							end try
							
							waitUntilAwakeAndUnlocked()
							activate
							try
								do shell script "afplay /System/Library/Sounds/Glass.aiff > /dev/null 2>&1 &"
							on error
								beep
							end try
							set notarizationSuccessfulReply to choose from list (paragraphs of notarizationOutput) with prompt ("Successfully Notarized & Zipped " & projectName & " version " & appVersion & "!

Copied SHA512 Checksum of Zipped File to Clipboard:
" & appZipChecksum & "

Notarization Output:") cancel button name "Quit" OK button name "Continue" with title (name of me) with empty selection allowed without multiple selections allowed
							
							if (notarizationSuccessfulReply is false) then
								quit
								delay 10
							end if
							
							try
								do shell script ("open -R " & (quoted form of appZipPath))
							end try
						on error notarizationError number notarizationErrorCode
							set notarizationLog to ""
							try
								set notarizationSubmissionID to (do shell script ("echo " & (quoted form of notarizationError) & " | awk '($1 == \"id:\") { print $NF; exit }'"))
								if (notarizationSubmissionID is not equal to "") then
									set notarizationLog to ("

Notarization Log:
" & (do shell script ("xcrun notarytool log " & notarizationSubmissionID & " --keychain-profile 'notarytool App Specific Password' 2>&1")))
								end if
							end try
							
							waitUntilAwakeAndUnlocked()
							activate
							try
								do shell script "afplay /System/Library/Sounds/Basso.aiff > /dev/null 2>&1 &"
							on error
								beep
							end try
							set notarizationErrorReply to choose from list (paragraphs of (notarizationError & notarizationLog)) with prompt (projectName & " Notarization Error " & notarizationErrorCode & "

Notarization Error:") cancel button name "Quit" OK button name "Continue" with title (name of me) with empty selection allowed without multiple selections allowed
							
							if (notarizationErrorReply is false) then
								quit
								delay 10
							end if
						end try
					end try
				end if
			on error codeSignError number codeSignErrorCode
				waitUntilAwakeAndUnlocked()
				activate
				try
					do shell script "afplay /System/Library/Sounds/Basso.aiff > /dev/null 2>&1 &"
				on error
					beep
				end try
				display alert (projectName & " Code Sign Error " & codeSignErrorCode) message codeSignError
			end try
		end if
		
		try
			do shell script "open -na " & (quoted form of appBuildPath)
		on error
			try
				do shell script "open -na " & (quoted form of ("/Applications/" & projectName & ".app"))
			end try
		end try
	on error buildErrorMessage number buildErrorNumber
		if (buildErrorNumber is not equal to -128) then
			waitUntilAwakeAndUnlocked()
			activate
			try
				do shell script "afplay /System/Library/Sounds/Basso.aiff > /dev/null 2>&1 &"
			on error
				beep
			end try
			display alert (button returned of buildAlertReply) & " Error" message buildErrorMessage
		end if
	end try
end repeat

on waitUntilAwakeAndUnlocked()
	repeat -- dialogs timeout when screen is asleep or locked (just in case)
		set isAwake to true
		try
			set isAwake to ((run script "ObjC.import('CoreGraphics'); $.CGDisplayIsActive($.CGMainDisplayID())" in "JavaScript") is equal to 1)
		end try
		
		set isUnlocked to true
		try
			set isUnlocked to ((do shell script ("bash -c " & (quoted form of "/usr/libexec/PlistBuddy -c 'Print :IOConsoleUsers:0:CGSSessionScreenIsLocked' /dev/stdin <<< \"$(ioreg -ac IORegistryEntry -k IOConsoleUsers -d 1)\""))) is not equal to "true")
		end try
		
		if (isAwake and isUnlocked) then
			exit repeat
		else
			delay 1
		end if
	end repeat
end waitUntilAwakeAndUnlocked

:: Set working dir
cd %~dp0 & cd ..

:user_configuration

:: Path to Flex SDK
set FLEX_SDK=D:\SDK\Air290

:validation
if not exist "%FLEX_SDK%\bin" goto flexsdk
goto succeed

:flexsdk
echo.
echo ERROR: incorrect path to Flex SDK in 'bat\SetupSDK.bat'
echo.
echo Looking for: %FLEX_SDK%\bin
echo.
if %PAUSE_ERRORS%==1 pause
exit

:succeed
set PATH=%FLEX_SDK%\bin;%PATH%

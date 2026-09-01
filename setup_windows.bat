@echo off
REM CLAWN PRIME - Windows Setup Script

echo ===================================
echo   CLAWN PRIME - Windows Setup
echo ===================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo Flutter not found.
    echo Please install Flutter from: https://docs.flutter.dev/get-started/install/windows
    echo Then add Flutter to your PATH.
    pause
    exit /b 1
)

REM Check Flutter version
echo Checking Flutter...
flutter doctor

REM Install project dependencies
echo.
echo Installing project dependencies...
flutter pub get

REM Create .env if it doesn't exist
if not exist ".env" (
    echo.
    echo Creating .env file...
    copy .env.example .env
    echo Please edit .env and add your Gemini API key
    echo Get one at: https://aistudio.google.com/apikey
)

echo.
echo ===================================
echo   Setup Complete!
echo ===================================
echo.
echo To run the app:
echo   flutter run -d windows
echo.
echo To build for production:
echo   flutter build windows --release
echo.
echo Don't forget to:
echo   1. Edit .env and add your API key
echo.
pause

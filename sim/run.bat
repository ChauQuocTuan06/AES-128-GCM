@echo off
REM ==============================================================================
REM Quick batch launcher for QuestaSim on Windows
REM Usage:
REM   run.bat       -> Runs in GUI mode
REM   run.bat c     -> Runs in Command-line/batch mode
REM   run.bat lint  -> Runs static lint check
REM   run.bat clean -> Cleans simulation files
REM ==============================================================================

if "%1"=="clean" goto clean
if "%1"=="lint"  goto lint
if "%1"=="c"     goto batch
if "%1"=="batch" goto batch

:gui
echo Starting QuestaSim in GUI mode...
vsim -gui -do "do ../scripts/run.do"
goto end

:batch
echo Starting QuestaSim in Batch mode...
vsim -c -do "do ../scripts/run.do; quit -f"
goto end

:lint
echo Running QuestaSim Lint Check...
vsim -c -do "do ../scripts/lint.do; quit -f"
echo Checking with Python Linter as well...
python ../scripts/check_lint.py ../rtl/aes_128_gcm_all.sv
goto end

:clean
echo Cleaning simulation files...
if exist work rmdir /s /q work
if exist transcript del /f /q transcript
if exist *.wlf del /f /q *.wlf
if exist *.log del /f /q *.log
if exist modelsim.ini del /f /q modelsim.ini
echo Clean complete.
goto end

:end

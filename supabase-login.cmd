@echo off
cd /d %~dp0
call supabase-local.cmd login %*

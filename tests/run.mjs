import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const runtime = process.argv[2];
const { LuauState } = await import(runtime ? pathToFileURL(path.resolve(runtime)).href : 'luau-web');
const state = await LuauState.createAsync({print: console.log});
try {
  let count = 0;
  function compile(dir) {
    for (const entry of fs.readdirSync(dir, {withFileTypes:true})) {
      const file = path.join(dir, entry.name);
      if (entry.isDirectory()) compile(file);
      else if (file.endsWith('.luau')) { state.loadstring(fs.readFileSync(file,'utf8'),file,true); count++; }
    }
  }
  compile('src');
  compile('tests');
  console.log('Luau syntax: '+count+' files passed');
  const module = fs.readFileSync('src/server/SessionStore.luau','utf8');
  const spec = fs.readFileSync('tests/SessionStore.spec.luau','utf8').replace('local SessionStore = require(game.ServerScriptService.Server.SessionStore)', 'local SessionStore = (function()\n'+module+'\nend)()');
  await state.loadstring(spec,'SessionStore.spec',true)();
  const layout=fs.readFileSync('src/shared/LabelLayout.luau','utf8');
  const layoutSpec=fs.readFileSync('tests/LabelLayout.spec.luau','utf8').replace(/local Layout\s*=\s*require\(game\.ReplicatedStorage\.Shared\.LabelLayout\)/, 'local Layout=(function()\n'+layout+'\nend)()');
  await state.loadstring(layoutSpec,'LabelLayout.spec',true)();
  const configSource=fs.readFileSync('src/shared/Config.luau','utf8');
  const formulaSource=fs.readFileSync('src/shared/Formulas.luau','utf8').replace('local Config = require(script.Parent.Config)','');
  const economySpec=fs.readFileSync('tests/Economy.spec.luau','utf8');
  await state.loadstring('local Color3={fromRGB=function() return {} end}\nlocal Config=(function()\n'+configSource+'\nend)()\nlocal Formulas=(function()\n'+formulaSource+'\nend)()\n'+economySpec,'Economy.spec',true)();
  const main = fs.readFileSync('src/server/Main.server.luau','utf8');
  const gates = main.slice(main.indexOf('local function playable'), main.indexOf('local prestigeEvent ='));
  const saves = main.slice(main.indexOf('local function copy'), main.indexOf('local function tutorial'));
  const request = main.slice(main.indexOf('local function requestPrestige'),main.indexOf('-- EFECTOS'));
  const confirmation = main.slice(main.indexOf('prestigeEvent.OnServerEvent:Connect'),main.indexOf('-- GERENTES', main.indexOf('prestigeEvent.OnServerEvent:Connect')));
  await state.loadstring(`
local playerStates={}
local closing=false
${gates}
local player={}
local MINER_COUNT,MAX_PRESTIGE_LEVEL=6,25
local function tell() end
local function getMoney() return {Value=1000} end
local function prestigeCost() return 500 end
local function formatNumber(n) return tostring(n) end
local game={}
local seq=0
function game:GetService() return {GenerateGUID=function() seq+=1 return "token-"..seq end} end
local sent
local prestigeEvent={OnServerEvent={}}
function prestigeEvent:FireClient(_,token,cost) sent={token,cost} end
function prestigeEvent.OnServerEvent:Connect(fn) self.callback=fn end
local rebirths=0
local function doPrestige() rebirths+=1 end
${request}
${confirmation}
playerStates[player]={ready=true,plot={},pr=0,sh={}}
for i=1,MINER_COUNT do playerStates[player].sh[i]={h=false} end
requestPrestige(player)
assert(sent==nil,"missing miners cannot open confirmation")
for i=1,MINER_COUNT do playerStates[player].sh[i]={h=true} end
requestPrestige(player)
assert(sent and sent[2]==500,"eligible player sees cost")
local answer=prestigeEvent.OnServerEvent.callback
answer(player,"forged",true)
assert(rebirths==0 and playerStates[player].confirm,"forged reply is rejected")
answer(player,sent[1],false)
assert(rebirths==0 and not playerStates[player].confirm,"cancel does not reset progress")
requestPrestige(player)
playerStates[player].confirm.expires=-1
answer(player,sent[1],true)
assert(rebirths==0,"expired reply is rejected")
requestPrestige(player)
answer(player,sent[1],true)
answer(player,sent[1],true)
assert(rebirths==1,"valid reply is consumed once")
print("prestigeEvent confirmation: all regression checks passed")
`,'prestigeEvent.spec',true)();
  await state.loadstring(`
local playerStates={}
local closing=false
${gates}
local player={attributes={}}
function player:SetAttribute(k,v) self.attributes[k]=v end
function player:Kick() self.kicked=true end
local calls=0
local action=guarded(function(_,amount) calls+=amount end)
action(player,1)
assert(calls==0,"no state is blocked")
playerStates[player]={ready=false}
action(player,1)
assert(calls==0,"loading is blocked")
playerStates[player].ready=true
action(player,2)
assert(calls==2,"ready player can act")
playerStates[player].leaving=true
action(player,1)
assert(calls==2,"leaving is blocked")
playerStates[player].leaving=false
closing=true
action(player,1)
assert(calls==2,"shutdown is blocked")
closing=false
local MINER_COUNT=1
local Config={BALANCE_VERSION=1}
local Players={}
player.Parent=Players
local money={Value=100}
local function getMoney() return money end
local writes=0
local shouldFail=false
local DataService={}
function DataService.save(_,snapshot,token,release)
writes+=1
assert(token=="owner")
assert(snapshot.sk.pico==1,"snapshot starts with current state")
playerStates[player].sk.pico=9
assert(snapshot.sk.pico==1,"snapshot is isolated from live changes")
return not shouldFail
end
${saves}
local function fixture()
return {loaded=true,ready=true,session="owner",sh={{h=true,l=1}},sk={pico=1},mg={},eq={},star={},slots=3,ro=0,coll=false,dep=0,dl=0,pr=0,qn=0,tot=0}
end
playerStates[player]=fixture()
playerStates[player].loaded=false
save(player)
assert(writes==0,"failed load never saves")
playerStates[player]=fixture()
save(player,true)
assert(writes==1 and playerStates[player].released,"final save releases once")
save(player,true)
assert(writes==1,"shutdown and removal cannot double save released state")
playerStates[player]=fixture()
shouldFail=true
save(player)
assert(not playerStates[player].ready and player.kicked and player.attributes.SaveStatus=="error","failed save disables gameplay")
print("Lifecycle: all regression checks passed")
`,'Lifecycle.spec',true)();
} finally { state.destroy(); }

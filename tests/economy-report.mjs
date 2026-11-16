import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const {LuauState}=await import(pathToFileURL(path.resolve(process.argv[2])).href);
const state=await LuauState.createAsync({print:console.log});
try {
 const baseline=process.argv.includes('--baseline');
 const read=(file)=>baseline?execFileSync('git',['show','HEAD:'+file],{encoding:'utf8'}):fs.readFileSync(file,'utf8');
 const config=read('src/shared/Config.luau');
 const formulas=read('src/shared/Formulas.luau').replace('local Config = require(script.Parent.Config)','');
 const interval=Number(process.argv.find(a=>a.startsWith('--collect='))?.split('=')[1]||10);
 const simulation=fs.readFileSync('tests/EconomySimulation.luau','utf8');
 const code='local Color3={fromRGB=function() return {} end}\nlocal Config=(function()\n'+config+'\nend)()\nlocal Formulas=(function()\n'+formulas+'\nend)()\nlocal collectEvery='+interval+'\n'+simulation;
 await state.loadstring(code,'EconomySimulation',true)();
}finally{state.destroy();}

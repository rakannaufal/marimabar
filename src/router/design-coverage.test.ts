import { describe, expect, it, vi } from 'vitest'
vi.mock('vue-router',async(importOriginal)=>{
 const original=await importOriginal<typeof import('vue-router')>()
 return {...original,createWebHistory:original.createMemoryHistory}
})
import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { resolve } from 'node:path'
import router from './index'

interface Mapping { route:string; view:string }
const root=resolve(import.meta.dirname,'../..')
const mapping=JSON.parse(readFileSync(resolve(root,'design-coverage.json'),'utf8')) as Record<string,Mapping>
const originals=readdirSync(resolve(root,'design'),{withFileTypes:true})
  .filter(dir=>dir.isDirectory()&&existsSync(resolve(root,'design',dir.name,'code.html')))
  .map(dir=>dir.name).sort()

describe('original design inventory',()=>{
 it('maps every HTML original exactly once',()=>{
  expect(Object.keys(mapping).sort()).toEqual(originals)
 })
 it('has a Vue view and route for each original',()=>{
  for(const [name,entry] of Object.entries(mapping)){
   expect(existsSync(resolve(root,'src/views',`${entry.view}.vue`)),name).toBe(true)
   const path=entry.route.split('?')[0]
   const matched=router.resolve(path).matched.at(-1)
   expect(matched,name).toBeDefined()
   expect(matched?.path,name).not.toBe('/:pathMatch(.*)*')
  }
 })
})

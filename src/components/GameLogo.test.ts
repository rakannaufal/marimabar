import { describe, expect, it } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from '@vue/server-renderer'
import GameLogo from './GameLogo.vue'

const render = (slug: string, name: string) => renderToString(createSSRApp(GameLogo, { slug, name }))

describe('GameLogo', () => {
  it.each([
    ['mlbb', 'mobilelegends.png'],
    ['free-fire', 'freefire.png'],
    ['pubg-mobile', 'pubgmobile.png'],
    ['valorant', 'valorant.png'],
  ])('renders the local asset for %s', async (slug, file) => {
    const html = await render(slug, 'Game')
    expect(html).toContain(`/logo/${file}`)
    expect(html).toContain('alt=""')
  })

  it('falls back to an initial for games without an asset', async () => {
    const html = await render('new-game', 'New Game')
    expect(html).toContain('>N</span>')
    expect(html).not.toContain('<img')
  })
})

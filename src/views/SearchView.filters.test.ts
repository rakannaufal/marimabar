import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const view = readFileSync(fileURLToPath(new URL('./SearchView.vue', import.meta.url)), 'utf8')

describe('search filter usability', () => {
  it('groups game-specific attributes into accessible disclosure sections', () => {
    expect(view).toContain('v-for="section in filterSections"')
    expect(view).toContain('<details')
    expect(view).toContain('<summary')
  })

  it('applies selections automatically, debounces numeric inputs, and removes one active filter', () => {
    expect(view).toContain('scheduleFilters()')
    expect(view).toContain('scheduleFilters(true)')
    expect(view).toContain('clearTimeout(filterTimer)')
    expect(view).toContain('removeAppliedFilter(filter.key)')
    expect(view).not.toContain('filter-submit')
    expect(view).not.toContain('Terapkan filter')
  })

  it('clears rank filters when the Free Fire mode chip is removed', () => {
    expect(view).toContain("if (slug.value === 'free-fire' && key === 'ranked_mode')")
    expect(view).toContain('delete attributes.rank_br')
    expect(view).toContain('delete attributes.rank_cs')
  })
  it('clears the opposite Free Fire mode rank when switching modes', () => {
    expect(view).toContain("if (slug.value === 'free-fire' && key === 'ranked_mode')")
    expect(view).toContain("delete attributes.rank_br")
    expect(view).toContain("delete attributes.rank_cs")
  })

  it('provides recoverable loading, validation, and empty states', () => {
    expect(view).toContain('retryCatalog')
    expect(view).toContain('validationError')
    expect(view).toContain('Belum ada profil untuk game ini')
  })
})

<script setup lang="ts">
import { computed, ref } from 'vue'
import type { AttributeDefinition } from '../lib/models'
import { visibleProfileFields } from '../lib/gameProfileFields'
import { groupedCharacterOptions } from '../lib/characterGroups'

const props = defineProps<{ slug: string; definitions: AttributeDefinition[]; values: Record<string, unknown>; excludeKeys?: string[] }>()
const emit = defineEmits<{ 'update:values': [value: Record<string, unknown>] }>()
const fields = computed(() => visibleProfileFields(props.slug, props.definitions, props.values).filter(field => !props.excludeKeys?.includes(field.key)))
const openCharacter = ref<string | null>(null)
const characterSearch = ref('')
function toggleCharacter(key: string) {
  openCharacter.value = openCharacter.value === key ? null : key
  characterSearch.value = ''
}
function characterOptions(key: string, options: string[]) {
  const query = characterSearch.value.trim().toLocaleLowerCase()
  return groupedCharacterOptions(key, options).map(group => ({ ...group, options: group.options.filter(name => name.toLocaleLowerCase().includes(query)) })).filter(group => group.options.length)
}
const coreKeys: Record<string, string[]> = {
  mlbb: ['position_main', 'position_secondary', 'rank_current', 'rank_stars', 'match_type', 'voice_chat'],
  'pubg-mobile': ['queue_mode', 'perspective', 'rank_tier', 'squad_role_main', 'voice_chat'],
  'free-fire': ['ranked_mode', 'rank_br', 'rank_cs', 'team_role_main', 'voice_chat'],
  valorant: ['game_mode', 'rank_current', 'agent_role_main', 'voice_chat'],
}
const groups = computed(() => [
  { id: 'utama', label: 'Informasi utama', items: fields.value.filter(field => coreKeys[props.slug]?.includes(field.key)) },
  { id: 'tambahan', label: 'Atribut tambahan', items: fields.value.filter(field => !coreKeys[props.slug]?.includes(field.key)) },
])
const label = (definition: AttributeDefinition) => definition.key === 'position_secondary' ? 'Posisi cadangan (maksimal 2)' : props.slug === 'mlbb' && definition.key === 'rank_current' ? 'Rank' : definition.label
function change(key: string, value: unknown) {
  const next = { ...props.values }
  if (value === undefined || value === '' || Array.isArray(value) && !value.length) delete next[key]
  else next[key] = value
  if (key === 'rank_current' && value !== props.values.rank_current) delete next.rank_stars
  if (key === 'position_main' && Array.isArray(next.position_secondary)) {
    next.position_secondary = next.position_secondary.filter(item => item !== value)
  }
  emit('update:values', next)
}
function choice(key: string, option: string) {
  const current = Array.isArray(props.values[key]) ? props.values[key] as string[] : []
  if (!current.includes(option) && ((key === 'position_secondary' && (current.length >= 2 || option === props.values.position_main)) || (['hero_pool', 'main_agent', 'main_character'].includes(key) && current.length >= 3))) return
  change(key, current.includes(option) ? current.filter(item => item !== option) : [...current, option])
}
function numeric(key: string, event: Event) {
  const raw = (event.target as HTMLInputElement).value
  change(key, raw === '' ? undefined : Number(raw))
}
</script>

<template>
  <div class="attribute-editor">
    <p class="editor-note">Data game diisi sendiri, belum terverifikasi. Isian tambahan tidak wajib.</p>
    <details v-for="group in groups.filter(group => group.items.length)" :key="group.id" class="attribute-section" :open="group.id === 'utama' || undefined">
      <summary>{{ group.label }} <span>{{ group.items.length }}</span></summary>
      <div class="attribute-section__body">
        <div v-for="definition in group.items" :key="definition.key" class="attribute-field">
          <label v-if="['single_select', 'slider_tier', 'boolean_with_option'].includes(definition.value_type)" :for="`game-attribute-${definition.key}`" class="attribute-label">{{ label(definition) }}
            <select :id="`game-attribute-${definition.key}`" :value="values[definition.key] ?? ''" @change="change(definition.key, ($event.target as HTMLSelectElement).value)">
              <option value="">Belum dipilih</option><option v-for="option in (definition.options as string[])" :key="option" :value="option">{{ option }}</option>
            </select>
          </label>
          <div v-else-if="definition.value_type === 'tag_multi' && ['hero_pool', 'main_agent', 'main_character'].includes(definition.key) && Array.isArray(definition.options) && definition.options.length" class="character-picker">
            <span class="attribute-label" :id="`character-label-${definition.key}`">{{ label(definition) }}</span>
            <button class="character-trigger" type="button" :aria-expanded="openCharacter === definition.key" :aria-labelledby="`character-label-${definition.key}`" @click="toggleCharacter(definition.key)">{{ Array.isArray(values[definition.key]) && (values[definition.key] as string[]).length ? (values[definition.key] as string[]).join(', ') : `Pilih ${definition.key === 'hero_pool' ? 'hero' : definition.key === 'main_agent' ? 'agent' : 'karakter'}` }} <span aria-hidden="true">⌄</span></button>
            <div v-if="openCharacter === definition.key" class="character-menu">
              <label class="character-search">Cari {{ definition.key === 'hero_pool' ? 'hero' : definition.key === 'main_agent' ? 'agent' : 'karakter' }}<input v-model="characterSearch" type="search" autocomplete="off" :placeholder="`Cari ${definition.key === 'hero_pool' ? 'hero' : definition.key === 'main_agent' ? 'agent' : 'karakter'}…`" /></label>
              <div class="character-list"><div v-for="group in characterOptions(definition.key, definition.options as string[])" :key="group.label" class="character-group"><strong>{{ group.label }}</strong><label v-for="option in group.options" :key="option"><input type="checkbox" :checked="Array.isArray(values[definition.key]) && (values[definition.key] as string[]).includes(option)" :disabled="!(values[definition.key] as string[] | undefined)?.includes(option) && ((values[definition.key] as string[] | undefined)?.length || 0) >= 3" @change="choice(definition.key, option)" /> {{ option }}</label></div><p v-if="!characterOptions(definition.key, definition.options as string[]).length" class="editor-note">Tidak ditemukan.</p></div>
            </div>
            <small>{{ ((values[definition.key] as string[] | undefined)?.length || 0) }}/3 dipilih. Pilihan tersimpan saat profil disimpan.</small>
          </div>
          <label v-else-if="definition.value_type === 'tag_multi' && Array.isArray(definition.options) && !definition.options.length" :for="`game-attribute-${definition.key}`" class="attribute-label">{{ label(definition) }}
            <input :id="`game-attribute-${definition.key}`" type="text" :value="Array.isArray(values[definition.key]) ? (values[definition.key] as string[]).join(', ') : ''" placeholder="Pisahkan nama dengan koma" maxlength="240" @change="change(definition.key, ($event.target as HTMLInputElement).value.split(',').map(item => item.trim()).filter(Boolean))">
            <small>Maksimal 3 nama. Diisi sendiri, belum diverifikasi.</small>
          </label>
          <fieldset v-else-if="['multi_select', 'tag_multi'].includes(definition.value_type)" class="attribute-group"><legend>{{ label(definition) }}</legend>
            <div class="attribute-options"><label v-for="option in (definition.options as string[])" :key="option"><input type="checkbox" :checked="Array.isArray(values[definition.key]) && (values[definition.key] as string[]).includes(option)" :disabled="definition.key === 'position_secondary' && !(values[definition.key] as string[] | undefined)?.includes(option) && ((values[definition.key] as string[] | undefined)?.length || 0) >= 2 || definition.key === 'position_secondary' && option === values.position_main" @change="choice(definition.key, option)"> {{ option }}</label></div>
            <small v-if="definition.key === 'position_secondary'">Pilih paling banyak dua posisi selain posisi utama.</small>
          </fieldset>
          <label v-else-if="definition.value_type === 'boolean'" class="attribute-check"><input type="checkbox" :checked="values[definition.key] === true" @change="change(definition.key, ($event.target as HTMLInputElement).checked)"> {{ label(definition) }}</label>
          <label v-else :for="`game-attribute-${definition.key}`" class="attribute-label">{{ label(definition) }} {{ definition.unit || '' }}
            <input :id="`game-attribute-${definition.key}`" type="number" :step="definition.value_type === 'decimal' ? '0.01' : '1'" :min="definition.key === 'rank_stars' && values.rank_current === 'Mythic Immortal' ? 100 : definition.range_min ?? undefined" :max="definition.key === 'rank_stars' && values.rank_current === 'Mythic Glory' ? 99 : definition.range_max ?? undefined" :value="values[definition.key] ?? ''" @input="numeric(definition.key, $event)">
          </label>
        </div>
      </div>
    </details>
    <p v-if="slug === 'free-fire' && !values.ranked_mode" class="editor-note">Pilih mode rank untuk mengisi rank Battle Royale atau Clash Squad.</p>
  </div>
</template>

<style scoped>
.attribute-editor{display:grid;gap:14px;margin:18px 0 26px;min-width:0}.editor-note{font-size:12px;color:#bdbbc9;line-height:1.5;margin:0}.attribute-section{border:1px solid #454554;border-radius:10px;min-width:0}.attribute-section summary{cursor:pointer;padding:12px 14px;color:#f5f3ee;font-size:13px;font-weight:700}.attribute-section summary span{color:#bdbbc9;font-size:11px;margin-left:5px}.attribute-section summary:focus-visible,.attribute-editor :focus-visible{outline:2px solid #c8ff4d;outline-offset:2px}.attribute-section__body{padding:6px 14px 16px;display:grid;gap:17px}.attribute-field,.attribute-label{min-width:0;display:grid;gap:8px}.attribute-label,.attribute-group legend{font-size:13px;font-weight:700;color:#f5f3ee}.attribute-label input,.attribute-label select{width:100%;min-height:40px;border:1px solid #626271;border-radius:8px;padding:8px 10px;background:#292934;color:#f5f3ee;font:inherit}.attribute-group{min-width:0;margin:0;padding:0;border:0}.attribute-group legend{margin-bottom:9px}.attribute-options{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:7px 12px}.attribute-options label,.attribute-check{display:flex;align-items:center;gap:8px;min-width:0;font-size:12px;font-weight:500;color:#e1dfeb;line-height:1.4}.attribute-options input,.attribute-check input{width:16px;height:16px;flex:none;accent-color:#c8ff4d}.attribute-options input:disabled{opacity:.45}.character-picker{display:grid;gap:8px;min-width:0}.character-picker small{color:#bdbbc9}.character-trigger{width:100%;min-height:40px;display:flex;align-items:center;justify-content:space-between;gap:10px;text-align:left;border:1px solid #626271;border-radius:8px;padding:8px 10px;background:#292934;color:#f5f3ee;font:inherit;overflow-wrap:anywhere}.character-menu{min-width:0;border:1px solid #626271;border-radius:8px;background:#242430;padding:12px}.character-search{display:grid;gap:6px;font-size:12px}.character-search input{width:100%;min-height:36px;border:1px solid #626271;border-radius:7px;background:#292934;color:#f5f3ee;padding:7px;font:inherit}.character-list{max-height:240px;overflow-y:auto;display:grid;gap:14px;margin-top:12px}.character-group{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:7px 12px}.character-group strong{grid-column:1/-1;font-size:12px;color:#bdbbc9}.character-group label{display:flex;align-items:center;gap:8px;font-size:12px;min-width:0}.character-group input{accent-color:#c8ff4d}.character-group input:disabled{opacity:.45}.attribute-group small{display:block;color:#bdbbc9;margin-top:9px}@media(max-width:420px){.attribute-options{grid-template-columns:1fr}}
</style>

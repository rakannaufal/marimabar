<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ slug: string; name: string }>()
const assets: Record<string, string> = {
  mlbb: 'mobilelegends.png',
  'free-fire': 'freefire.png',
  'pubg-mobile': 'pubgmobile.png',
  valorant: 'valorant.png',
}
const src = computed(() => assets[props.slug] ? `/logo/${assets[props.slug]}` : '')
</script>

<template>
  <span class="game-logo" aria-hidden="true"><img v-if="src" :src="src" alt="" /><span v-else>{{ name.charAt(0).toUpperCase() }}</span></span>
</template>

<style scoped>
.game-logo{display:inline-grid;place-items:center;flex:none;width:100%;height:100%;overflow:hidden;border-radius:inherit}
.game-logo img{display:block;width:100%;height:100%;object-fit:contain}
</style>

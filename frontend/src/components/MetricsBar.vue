<script setup lang="ts">
const props = defineProps<{
  timeMs?: number | null
  method?: string
  threads?: number
  note?: string
}>()

function fmtMs(v?: number | null) {
  if (v == null) return '—'
  if (v >= 1000) return (v / 1000).toFixed(2) + ' s'
  return v.toFixed(1) + ' ms'
}
</script>

<template>
  <div class="bar">
    <span class="badge"><strong>Método:</strong> {{ method ?? '—' }}</span>
    <span class="badge"><strong>Hilos:</strong> {{ threads ?? '—' }}</span>
    <span class="badge"><strong>Tiempo:</strong> {{ fmtMs(timeMs) }}</span>
    <span v-if="note" class="note">{{ note }}</span>
  </div>
</template>

<style scoped>
.bar {
  display: flex;
  gap: .5rem;
  flex-wrap: wrap;
  align-items: center;
}
.badge {
  background: #0b0b0b;
  border: 1px solid #222;
  color: #ddd;
  padding: .3rem .6rem;
  border-radius: 999px;
  font-size: .9rem;
}
.note { color: #8aa; margin-left: .5rem; }
</style>

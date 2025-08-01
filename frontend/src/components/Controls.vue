<script setup lang="ts">
import { computed } from 'vue'

type Method = 'oryg' | 'tstile' | '3D'

const props = defineProps<{
  method: Method
  threads: number
  tileSize?: number // opcional (por si luego lo usas)
}>()

const emit = defineEmits<{
  (e: 'update:method', v: Method): void
  (e: 'update:threads', v: number): void
  (e: 'update:tileSize', v: number): void
}>()

const threadLabel = computed(() => `${props.threads} hilo${props.threads === 1 ? '' : 's'}`)
</script>

<template>
  <div class="controls">
    <label class="field">
      <span>Método</span>
      <select
        :value="props.method"
        @change="emit('update:method', ($event.target as HTMLSelectElement).value as Method)"
      >
        <option value="oryg">Serial (oryg)</option>
        <option value="tstile">Tiling 2D (tstile)</option>
        <option value="3D">Tiling 3D (3D)</option>
      </select>
    </label>

    <label class="field">
      <span>Hilos: <strong>{{ threadLabel }}</strong></span>
      <input
        type="range"
        min="1"
        max="32"
        :value="props.threads"
        @input="emit('update:threads', parseInt(($event.target as HTMLInputElement).value))"
      />
    </label>

    <label v-if="props.tileSize !== undefined" class="field">
      <span>Tile</span>
      <input
        type="number"
        min="8"
        step="8"
        :value="props.tileSize"
        @input="emit('update:tileSize', parseInt(($event.target as HTMLInputElement).value))"
      />
    </label>
  </div>
</template>

<style scoped>
.controls {
  display: flex;
  gap: 1rem;
  align-items: center;
  flex-wrap: wrap;
}
.field {
  display: grid;
  gap: .25rem;
}
select, input[type="number"] {
  background: #0b0b0b; color: #ddd;
  border: 1px solid #222; border-radius: 8px;
  padding: .35rem .5rem;
}
input[type="range"] { width: 200px; }
</style>

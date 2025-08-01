<script setup lang="ts">
import { ref } from 'vue'

const emit = defineEmits<{
  (e: 'submit', seq: string): void
}>()

const text = ref<string>('>demo\nAUGGCUAGCUAGCUAGCUA\n')

function cleanFasta(raw: string): string {
  return raw
    .split(/\r?\n/)
    .filter((l) => l.trim() && !l.startsWith('>'))
    .join('')
    .toUpperCase()
    .replace(/[^ACGUTN]/g, '') // deja solo bases válidas (U en RNA)
}

function onUse() {
  const seq = cleanFasta(text.value)
  emit('submit', seq)
}

async function onFile(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  const raw = await file.text()
  text.value = raw
  const seq = cleanFasta(raw)
  emit('submit', seq)
}
</script>

<template>
  <div class="upload">
    <div class="row">
      <input type="file" accept=".fa,.fasta,.txt" @change="onFile" />
      <button class="btn" @click="onUse">Usar texto</button>
    </div>
    <textarea v-model="text" rows="6" class="fasta" placeholder="Pega aquí tu FASTA…"></textarea>
  </div>
</template>

<style scoped>
.upload { display: grid; gap: .5rem; }
.row { display: flex; gap: .5rem; align-items: center; flex-wrap: wrap; }
.fasta {
  width: 100%;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  background: #0b0b0b; color: #ddd;
  border: 1px solid #222; border-radius: 8px;
  padding: .5rem;
}
.btn {
  padding: .4rem .8rem; border-radius: 8px;
  border: 1px solid #333; background: #1a56db; color: #fff;
  cursor: pointer;
}
.btn:hover { filter: brightness(1.05); }
</style>

<script setup lang="ts">
import { ref } from 'vue'
import { fold, fetchResult } from './api/client'
import type { Method } from './types'

import UploadFASTA from './components/UploadFASTA.vue'
import Controls from './components/Controls.vue'
import HeatmapPanel from './components/HeatmapPanel.vue'
import MetricsBar from './components/MetricsBar.vue'

const seq = ref<string>('>demo\nAUGGCUAGCUAGCUAGCUA\n')
const method = ref<Method>('3D')
const threads = ref<number>(4)

// Escala del heatmap: 'seq' | 'div0' | 'log' | 'p98'
const scale = ref<'seq'|'div0'|'log'|'p98'>('seq')

const S = ref<number[][] | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)
const timeMs = ref<number | null>(null)
const note = ref<string>('')

// Comparativa
const Sserial = ref<number[][] | null>(null)
const Tserial = ref<number | null>(null)
const speedup = ref<number | null>(null)

// Hover de celda
const hoverInfo = ref<{i:number,j:number,v:number|null}|null>(null)

function cleanBody(s: string) {
  return s.split('\n').filter(l => !l.startsWith('>')).join('').trim().toUpperCase()
}

async function onRun() {
  loading.value = true
  error.value = null
  note.value = ''
  S.value = null
  timeMs.value = null
  Sserial.value = null
  Tserial.value = null
  speedup.value = null
  hoverInfo.value = null
  try {
    const bodySeq = cleanBody(seq.value)
    if (!bodySeq || bodySeq.length < 10) {
      throw new Error('Secuencia vacía o demasiado corta (mínimo 10 nt).')
    }

    const res = await fold(bodySeq, method.value, threads.value)
    timeMs.value = res?.meta?.time_ms ?? null

    const data = await fetchResult(res.job_id) // { S: number[][] }
    S.value = data.S

    const allZero = S.value?.every(row => row.every(v => v === 0)) ?? false
    if (allZero) {
      note.value = 'La matriz S contiene solo ceros. Prueba con una secuencia con estructura (p. ej., un tRNA) o cambia el método.'
    }
  } catch (e: any) {
    error.value = e?.message ?? String(e)
  } finally {
    loading.value = false
  }
}

async function onCompare() {
  loading.value = true
  error.value = null
  note.value = ''
  S.value = null
  timeMs.value = null
  Sserial.value = null
  Tserial.value = null
  speedup.value = null
  hoverInfo.value = null
  try {
    const bodySeq = cleanBody(seq.value)
    if (!bodySeq || bodySeq.length < 10) {
      throw new Error('Secuencia vacía o demasiado corta (mínimo 10 nt).')
    }

    // 1) Serial (oryg @ 1 hilo)
    const r1 = await fold(bodySeq, 'oryg', 1)
    const d1 = await fetchResult(r1.job_id)
    Sserial.value = d1.S
    Tserial.value = r1?.meta?.time_ms ?? null

    // 2) Método seleccionado
    const r2 = await fold(bodySeq, method.value, threads.value)
    const d2 = await fetchResult(r2.job_id)
    S.value = d2.S
    timeMs.value = r2?.meta?.time_ms ?? null

    // 3) Speed-up
    speedup.value = (Tserial.value && timeMs.value) ? +(Tserial.value / timeMs.value).toFixed(2) : null
  } catch (e: any) {
    error.value = e?.message ?? String(e)
  } finally {
    loading.value = false
  }
}

// ----- Exportaciones -----
function matrixToCSV(M: number[][]): string {
  return M.map(r => r.join(',')).join('\n')
}
function downloadCSVCurrent() {
  if (!S.value) return
  const csv = matrixToCSV(S.value)
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const n = S.value.length
  const fname = `S_matrix_${method.value}_${n}x${n}.csv`
  const a = document.createElement('a')
  a.href = url; a.download = fname; document.body.appendChild(a); a.click(); a.remove()
  URL.revokeObjectURL(url)
}
function downloadJSONCurrent() {
  if (!S.value) return
  const n = S.value.length
  const blob = new Blob([JSON.stringify({ S: S.value })], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url; a.download = `S_matrix_${method.value}_${n}x${n}.json`
  document.body.appendChild(a); a.click(); a.remove()
  URL.revokeObjectURL(url)
}
// (opcional) abrir CSV en nueva pestaña
function openCSVInNewTab() {
  if (!S.value) return
  const csv = matrixToCSV(S.value)
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  window.open(url, '_blank')
  setTimeout(() => URL.revokeObjectURL(url), 10000)
}

// Presets rápidos
function onPreset(e: Event) {
  const v = (e.target as HTMLSelectElement).value
  if (v === 'tRNA') {
    seq.value = '>tRNA_demo\nGCGGAUUUAGCUCAGUUGGGAGAGCGCCAGACUGAAGAUCUGGAGGUCCUGUGUUCGAUCCACAGAAUUCGCACCA\n'
  } else if (v === '5S') {
    seq.value = '>5S_demo\nGGGCCATGGGCGCGGTTGGTGTGTGAGCGCTGATAGCTCAGGCTGGTATGGCCGAGTCCGATAGTGGCAGG\n'
  } else if (v === 'short') {
    seq.value = '>short_demo\nAUGGCUAGCUAGCUAGCUA\n'
  }
}
</script>

<template>
  <main class="container">
    <header class="header">
      <h1>Nussinov Visor (serial · 2D · 3D)</h1>
      <p class="subtitle">Ejecuta el algoritmo y visualiza la matriz S</p>
    </header>

    <section class="panel">
      <h2>Secuencia</h2>
      <select class="preset" @change="onPreset">
        <option value="">— Datasets demo —</option>
        <option value="tRNA">tRNA (estructura clara)</option>
        <option value="5S">5S rRNA (corto)</option>
        <option value="short">Demo corta</option>
      </select>
      <UploadFASTA @submit="(s:string)=> (seq = s)" />
      <textarea v-model="seq" rows="5" class="fasta"></textarea>
    </section>

    <section class="panel">
      <h2>Parámetros</h2>
      <Controls
        :method="method"
        :threads="threads"
        @update:method="(m:string)=> (method = m as Method)"
        @update:threads="(t:number)=> (threads = t)"
      />
      <div class="row">
        <button class="run" :disabled="loading" @click="onRun">
          {{ loading ? 'Corriendo…' : 'Ejecutar' }}
        </button>
        <button class="run" :disabled="loading" @click="onCompare">
          {{ loading ? 'Comparando…' : 'Comparar vs serial' }}
        </button>
        <label class="scale-label">
          Escala:
          <select v-model="scale" class="scale">
            <option value="seq">Secuencial 0→alto</option>
            <option value="div0">Centrada en 0 (divergente)</option>
            <option value="log">Logarítmica</option>
            <option value="p98">Percentil 2–98 (grises)</option>
          </select>
        </label>
      </div>
      <p v-if="error" class="error">{{ error }}</p>
    </section>

    <section class="panel">
      <h2>Resultados</h2>
      <MetricsBar :timeMs="timeMs" :method="method" :threads="threads" :note="note" />
      <p v-if="speedup" class="hint">Speed-up vs serial: <strong>{{ speedup }}×</strong></p>

      <div class="row" style="margin-top:.5rem;">
        <button class="run" :disabled="!S" @click="downloadCSVCurrent">Descargar matriz (CSV)</button>
        <button class="run" :disabled="!S" @click="downloadJSONCurrent">Descargar JSON</button>
        <button class="run" :disabled="!S" @click="openCSVInNewTab">Ver CSV en nueva pestaña</button>
      </div>
    </section>

    <section class="panel">
      <h2>Matriz S</h2>
      <HeatmapPanel
        :S="S ?? undefined"
        :hideLower="true"
        :scale="scale"
        @hover="(p)=> hoverInfo = p"
      />
      <p class="hint" v-if="hoverInfo && S">
        i={{ hoverInfo.i }}, j={{ hoverInfo.j }}, S[i,j]={{ hoverInfo.v }}
      </p>
      <p v-if="!S && !loading" class="hint">Ejecuta para ver el heatmap.</p>
    </section>

    <section class="panel grid2" v-if="Sserial || S">
      <div>
        <h3>Serial (oryg)</h3>
        <MetricsBar :timeMs="Tserial" method="oryg" :threads="1" />
        <HeatmapPanel :S="Sserial ?? undefined" :hideLower="true" :scale="scale" />
      </div>
      <div>
        <h3>{{ method.toUpperCase() }}</h3>
        <MetricsBar :timeMs="timeMs" :method="method" :threads="threads" />
        <HeatmapPanel :S="S ?? undefined" :hideLower="true" :scale="scale" />
      </div>
    </section>
  </main>
</template>

<style scoped>
.container {
  max-width: 1100px;
  margin: 0 auto;
  padding: 1rem;
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
}
.header { margin-bottom: .5rem; }
.subtitle { color: #666; margin: 0; }
.panel {
  background: #111;
  border: 1px solid #222;
  border-radius: 10px;
  padding: 1rem;
}
.row { display: flex; gap: .5rem; align-items: center; flex-wrap: wrap; }
.preset, .scale {
  background:#0b0b0b;color:#ddd;border:1px solid #222;border-radius:8px;
  padding:.35rem .5rem;
}
.preset { margin-bottom:.5rem; }
.scale-label { display:flex; align-items:center; gap:.4rem; margin-left:.5rem; }
.fasta {
  width: 100%;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  background: #0b0b0b;
  color: #ddd;
  border: 1px solid #222;
  border-radius: 8px;
  padding: .5rem;
  margin-top: .5rem;
}
.run {
  margin-top: .5rem;
  padding: .5rem .9rem;
  border-radius: 8px;
  border: 1px solid #333;
  background: #1a56db;
  color: #fff;
  cursor: pointer;
}
.run:disabled { opacity: .6; cursor: default; }
.error { color: #ff6b6b; margin-top: .5rem; white-space: pre-wrap; }
.hint { color: #888; font-size: .9rem; }
h2 { margin: 0 0 .5rem 0; font-size: 1.05rem; }
.grid2 { display:grid; grid-template-columns: 1fr 1fr; gap:1rem; }
@media (max-width: 900px){ .grid2 { grid-template-columns: 1fr; } }
</style>

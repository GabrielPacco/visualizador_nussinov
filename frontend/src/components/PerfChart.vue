<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'

type Sample = { t_ms: number; cpu_proc: number; cpu_sys: number; rss_mb: number }
const props = defineProps<{ samples?: Sample[] }>()

const canvas = ref<HTMLCanvasElement|null>(null)

function draw() {
  const c = canvas.value
  const data = props.samples ?? []
  if (!c || data.length === 0) { if (c) { const ctx=c.getContext('2d')!; ctx.clearRect(0,0,c.width,c.height) } ; return }
  const W = c.width = c.clientWidth
  const H = c.height = c.clientHeight
  const ctx = c.getContext('2d')!

  const tMin = data[0].t_ms
  const tMax = data[data.length-1].t_ms || 1
  const cpuMax = 100
  const memMax = Math.max(...data.map(d=>d.rss_mb), 1)

  function x(t:number){ return ((t - tMin)/(tMax - tMin||1)) * (W-40) + 30 }
  function yCPU(v:number){ return H - 20 - (v/cpuMax)*(H-40) }
  function yMEM(v:number){ return H - 20 - (v/memMax)*(H-40) }

  // fondo
  ctx.fillStyle = '#0b0b0b'; ctx.fillRect(0,0,W,H)
  ctx.strokeStyle = '#222'; ctx.lineWidth = 1
  ctx.beginPath(); ctx.moveTo(30,10); ctx.lineTo(30,H-20); ctx.lineTo(W-10,H-20); ctx.stroke()

  // CPU sistema (línea)
  ctx.strokeStyle = '#6aa0ff'
  ctx.beginPath()
  data.forEach((d,i)=>{ const X=x(d.t_ms), Y=yCPU(d.cpu_sys); i?ctx.lineTo(X,Y):ctx.moveTo(X,Y) })
  ctx.stroke()

  // CPU proceso (línea)
  ctx.strokeStyle = '#ffa74d'
  ctx.beginPath()
  data.forEach((d,i)=>{ const X=x(d.t_ms), Y=yCPU(d.cpu_proc); i?ctx.lineTo(X,Y):ctx.moveTo(X,Y) })
  ctx.stroke()

  // Memoria (línea secundaria)
  ctx.strokeStyle = '#7ddc8c'
  ctx.beginPath()
  data.forEach((d,i)=>{ const X=x(d.t_ms), Y=yMEM(d.rss_mb); i?ctx.lineTo(X,Y):ctx.moveTo(X,Y) })
  ctx.stroke()

  // leyenda
  ctx.fillStyle='#ccc'
  ctx.font='12px system-ui'
  ctx.fillText('CPU sistema (%)', 40, 16)
  ctx.fillStyle='#ffa74d'; ctx.fillText('CPU proceso (%)', 160, 16)
  ctx.fillStyle='#7ddc8c'; ctx.fillText('RAM (MB)', 290, 16)
}

onMounted(draw)
watch(()=>props.samples, draw, {deep:true})
</script>

<template>
  <div class="wrap">
    <canvas ref="canvas"></canvas>
  </div>
</template>

<style scoped>
.wrap { width:100%; height:180px; border:1px solid #222; border-radius:8px; background:#0b0b0b; }
canvas { width:100%; height:100%; display:block; }
</style>

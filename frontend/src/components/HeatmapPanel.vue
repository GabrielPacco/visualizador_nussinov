<script setup lang="ts">
import { onMounted, ref, watch } from "vue";

const props = defineProps<{
  S?: number[][];
  hideLower?: boolean;     // oculta triángulo inferior
  scale?: "seq" | "div0" | "log" | "p98"; // modo de color
}>();

const emit = defineEmits<{
  (e: 'hover', payload: { i: number, j: number, v: number | null }): void
}>()

const canvas = ref<HTMLCanvasElement | null>(null);

function percentile(arr: number[], p: number) {
  if (!arr.length) return 0;
  const a = [...arr].sort((x, y) => x - y);
  const i = Math.min(a.length - 1, Math.max(0, Math.floor((p / 100) * (a.length - 1))));
  return a[i];
}

function toGray(t: number) {
  // t en [0,1]
  const g = Math.max(0, Math.min(255, Math.floor(t * 255)));
  return [g, g, g] as const;
}

// Mapa de color divergente centrado en 0: azul (neg) → blanco → rojo (pos)
function divergingColor(norm: number) {
  // norm en [-1, 1]; -1 = azul, 0 = blanco, 1 = rojo
  const t = (norm + 1) / 2; // [0,1]
  let r, g, b;
  if (norm >= 0) {
    // blanco→rojo
    r = 255;
    g = Math.round(255 * (1 - t));
    b = Math.round(255 * (1 - t));
  } else {
    // azul→blanco
    b = 255;
    g = Math.round(255 * t);
    r = Math.round(255 * t);
  }
  return [r, g, b] as const;
}

function draw() {
  if (!canvas.value || !props.S || !props.S.length) return;

  const S = props.S;
  const n = S.length;
  const ctx = canvas.value.getContext("2d")!;
  canvas.value.width = n;
  canvas.value.height = n;

  // Aplana y filtra NaN/Inf
  const flat: number[] = [];
  for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
    const v = S[y]?.[x];
    if (Number.isFinite(v)) flat.push(v as number);
  }
  if (!flat.length) return;

  // Percentiles para recorte de outliers
  let p2 = percentile(flat, 2);
  let p98 = percentile(flat, 98);
  if (p98 <= p2) { p2 = Math.min(...flat); p98 = Math.max(...flat) || p2 + 1; }
  const mode = props.scale ?? "seq";

  const img = ctx.createImageData(n, n);
  let k = 0;

  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      if (props.hideLower && y > x) { img.data[k + 3] = 0; k += 4; continue; }
      let v = S[y]?.[x] ?? 0;

      let r = 0, g = 0, b = 0;

      if (mode === "div0") {
        // Divergente centrada en 0: usa maxAbs simétrica
        const maxAbs = Math.max(Math.abs(p2), Math.abs(p98), 1e-9);
        if (v >  maxAbs) v =  maxAbs;
        if (v < -maxAbs) v = -maxAbs;
        const norm = v / maxAbs; // [-1,1]
        [r, g, b] = divergingColor(norm);
      } else if (mode === "log") {
        // Log1p aplicado a valores no negativos; si hay negativos, clípalos a 0
        const v0 = Math.max(0, v);
        const hi = Math.max(1e-9, Math.max(0, p98));
        const t = Math.log1p(v0) / Math.log1p(hi); // [0,1]
        [r, g, b] = toGray(t);
      } else if (mode === "p98") {
        // Grises con recorte 2–98
        if (v < p2) v = p2;
        if (v > p98) v = p98;
        const t = (v - p2) / (p98 - p2 || 1); // [0,1]
        [r, g, b] = toGray(t);
      } else {
        // "seq" por defecto: escala secuencial 0→alto, usando percentiles
        // Asegura base 0
        const lo = Math.min(0, p2);
        const hi = Math.max(p98, lo + 1);
        if (v < lo) v = lo;
        if (v > hi) v = hi;
        const t = (v - lo) / (hi - lo || 1);
        [r, g, b] = [Math.floor(255 * t), 0, 0]; // negro→rojo
      }

      img.data[k++] = r;
      img.data[k++] = g;
      img.data[k++] = b;
      img.data[k++] = 255;
    }
  }
  ctx.putImageData(img, 0, 0);
}

function handleMove(ev: MouseEvent) {
  if (!canvas.value || !props.S || !props.S.length) return
  const rect = canvas.value.getBoundingClientRect()
  const x = ev.clientX - rect.left
  const y = ev.clientY - rect.top
  const n = props.S.length
  const i = Math.floor((y / rect.height) * n)
  const j = Math.floor((x / rect.width)  * n)
  const v = (i>=0 && i<n && j>=0 && j<n) ? (props.S[i]?.[j] ?? null) : null
  // si ocultamos triángulo inferior, ignora valores invisibles
  if (props.hideLower && i > j) {
    emit('hover', { i, j, v: null })
  } else {
    emit('hover', { i, j, v: (typeof v === 'number' ? v : null) })
  }
}

onMounted(draw);
watch(() => props.S, draw, { deep: true });
watch(() => props.scale, draw);
</script>

<template>
  <div class="wrap">
    <canvas ref="canvas" @mousemove="handleMove"></canvas>
  </div>
</template>

<style scoped>
.wrap {
  width: 100%;
  aspect-ratio: 1/1;
  border: 1px solid #222;
  border-radius: 8px;
  overflow: hidden;
  background: #0b0b0b;
}
canvas {
  width: 100%;
  height: 100%;
  image-rendering: pixelated;
  display: block;
}
</style>

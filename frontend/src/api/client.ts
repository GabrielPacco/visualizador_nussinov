const base = import.meta.env.VITE_API_BASE ?? "http://localhost:8000/api/v1";

export async function fold(sequence: string, method: string, threads: number) {
  const r = await fetch(`${base}/fold`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ sequence, method, threads })
  });
  if (!r.ok) throw new Error(await r.text());
  return r.json(); // { job_id, meta, ... }
}

export async function fetchResult(jobId: string) {
  const r = await fetch(`${base}/result/${jobId}`);
  if (!r.ok) throw new Error(await r.text());
  return r.json(); // { S: number[][] }
}

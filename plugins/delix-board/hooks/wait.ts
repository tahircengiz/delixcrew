// Long runs the session waits on: a Bash command matching a wait pattern, or a
// delix:* subagent. A foreground call is followed through its `next`; a
// background one through its output file and the task notification.

import { atom, read, update } from 'claude-code'
import type { EngineInterface } from 'claude-code'

import type { Run, RunStatus } from '../types'
import { formatDuration, notificationStatus, runProgress } from './parse'

// The board's values; the same atoms in each file that reads them, as the module scan requires.
const runsAtom = atom({ plugin: 'delix-board', key: 'runs' } as const, [], { shape: 'runs-1' })
const nowAtom = atom({ plugin: 'delix-board', key: 'now' } as const, 0)

type History = Record<string, { durationMs: number; suites: number; checks: number }>

const HISTORY_KEY = 'history-1'
const SILENT_MS = 15 * 60_000
const KEEP = 20

export async function expected($: EngineInterface, label: string) {
  const history = ((await $.store.get(HISTORY_KEY).catch(() => undefined)) ?? {}) as History
  const h = history[label]
  return { expectedMs: h?.durationMs ?? null, expectedSuites: h?.suites || null, expectedChecks: h?.checks || null }
}

export async function startRun($: EngineInterface, run: Run) {
  await update($, runsAtom, list => [run, ...list.filter(r => r.id !== run.id)].slice(0, KEEP))
  await update($, nowAtom, () => run.startedAt)
  await statusLine($)
}

export async function patchRun($: EngineInterface, id: string, patch: Partial<Run>) {
  await update($, runsAtom, list => list.map(r => (r.id === id ? { ...r, ...patch } : r)))
}

/** Closes a run: its final counts, a toast, the history a later run's estimate reads. */
export async function finishRun($: EngineInterface, id: string, status: RunStatus, output: string | null) {
  const list = await read($, runsAtom)
  const run = list.find(r => r.id === id)
  if (!run || run.status !== 'running') return
  const endedAt = await $.clock.now()
  const progress = output === null ? null : runProgress(output)
  const counts = progress ?? { suites: run.suites, pass: run.pass, fail: run.fail, tail: run.tail }
  const final: RunStatus = status === 'passed' && counts.fail > 0 ? 'failed' : status
  await patchRun($, id, { ...counts, endedAt, status: final })
  const took = formatDuration(endedAt - run.startedAt)
  const tally = counts.pass + counts.fail > 0 ? `${counts.pass} GEÇTİ / ${counts.fail} KALDI · ` : ''
  const head = final === 'passed' ? `${run.label} bitti` : final === 'silent' ? `${run.label} sessiz` : `${run.label} başarısız`
  $.ui.toast(`delix · ${head}: ${tally}${took}`)
  if (final === 'passed' && run.kind === 'bash') {
    const history = ((await $.store.get(HISTORY_KEY).catch(() => undefined)) ?? {}) as History
    history[run.label] = { durationMs: endedAt - run.startedAt, suites: counts.suites, checks: counts.pass + counts.fail }
    await $.store.set(HISTORY_KEY, history).catch(() => undefined)
  }
  await statusLine($)
}

/** The status line while something runs; cleared when nothing does. */
export async function statusLine($: EngineInterface) {
  const list = await read($, runsAtom)
  const running = list.filter(r => r.status === 'running')
  const first = running[0]
  if (!first) {
    $.ui.status(undefined)
    return
  }
  const t = await $.clock.now()
  const m = Math.floor((t - first.startedAt) / 60_000)
  const s = Math.floor(((t - first.startedAt) % 60_000) / 1000)
  const checks = first.pass + first.fail
  const count = checks > 0 ? ` · ${checks}${first.expectedChecks ? `/${first.expectedChecks}` : ''}` : ''
  const more = running.length > 1 ? ` · +${running.length - 1}` : ''
  $.ui.status(`delix · ${first.label} ${m}:${String(s).padStart(2, '0')}${count}${more}`)
}

/** One poll: background output files grow, agents end, silence is marked. */
export async function pollRuns($: EngineInterface) {
  const list = await read($, runsAtom)
  const running = list.filter(r => r.status === 'running')
  if (running.length === 0) return
  const t = await $.clock.now()
  await update($, nowAtom, () => t)
  let agents: { id: string; status: string }[] | null = null
  for (const run of running) {
    if (run.kind === 'agent' && run.isBackground && run.agentId) {
      agents ??= await $.agent.list().catch(() => [])
      const agent = agents.find(a => a.id === run.agentId)
      if (!agent || ['completed', 'failed', 'killed'].includes(agent.status)) {
        await finishRun($, run.id, agent?.status === 'completed' || !agent ? 'passed' : 'failed', null)
      }
      continue
    }
    if (!run.isBackground || !run.outputPath) continue
    const stat = await $.fs.stat(run.outputPath).catch(() => undefined)
    if (stat && stat.size !== run.outputSize) {
      const text = await $.fs.read(run.outputPath).catch(() => undefined)
      if (typeof text === 'string') {
        await patchRun($, run.id, { ...runProgress(text), outputSize: stat.size, lastGrowthAt: t })
      }
    } else if (t - run.lastGrowthAt > SILENT_MS) {
      await finishRun($, run.id, 'silent', null)
    }
  }
  await statusLine($)
}

/** A row the session appends: the task notification of a background run ends it. */
export async function onAppended($: EngineInterface, originKind: string, content: unknown) {
  const list = await read($, runsAtom)
  const waiting = list.filter(r => r.status === 'running' && r.isBackground && r.taskId)
  if (waiting.length === 0) return
  const text = JSON.stringify(content)
  if (originKind !== 'task-notification' && !text.includes('task-notification')) return
  for (const run of waiting) {
    const status = notificationStatus(text, run.taskId ?? '')
    if (status === null) continue
    const output = run.outputPath ? await $.fs.read(run.outputPath).catch(() => undefined) : undefined
    await finishRun($, run.id, status === 'completed' ? 'passed' : 'failed', typeof output === 'string' ? output : null)
  }
}

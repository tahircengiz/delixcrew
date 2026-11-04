// delix-board: a live board for delix beside the chat. Read-only: it reads the
// project's docs/delix files and follows the session's long runs; it never
// changes a tool call. Starts when someone can see it: the REPL, or a surface
// attaching (the desktop app runs over the SDK); a plain `claude -p` run starts nothing.

import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Run, View } from '../types'
import { findTop, newCache, readSnapshot } from './data'
import { makeKit } from './gfx'
import { backgroundOutputPath, matchCommand } from './parse'
import { band, pane, PANE, VIEWS, type Ctx } from './views'
import { expected, finishRun, onAppended, patchRun, pollRuns, startRun } from './wait'

// The board's values; the same atoms in each file that reads them, as the module scan requires.
const snapshotAtom = atom({ plugin: 'delix-board', key: 'snapshot' } as const, null, { shape: 'snapshot-4' })
const runsAtom = atom({ plugin: 'delix-board', key: 'runs' } as const, [], { shape: 'runs-1' })
const viewAtom = atom({ plugin: 'delix-board', key: 'view' } as const, 'pano')
const selectedAtom = atom({ plugin: 'delix-board', key: 'selected' } as const, null)
const nowAtom = atom({ plugin: 'delix-board', key: 'now' } as const, 0)

const ARG_VIEWS: Record<string, View> = { pano: 'pano', bekleme: 'bekleme', kart: 'kart', olcum: 'olcum', 'ölçüm': 'olcum' }

type Runtime = { isActive: boolean; top: string | null; isRefreshing: boolean; cache: ReturnType<typeof newCache>; extra: string[] }

const rt: Runtime = { isActive: false, top: null, isRefreshing: false, cache: newCache(), extra: [] }

async function refresh($: EngineInterface) {
  if (rt.top === null || rt.isRefreshing) return
  rt.isRefreshing = true
  try {
    const next = await readSnapshot($, rt.top, rt.cache, await $.clock.now())
    const prev = await read($, snapshotAtom)
    if (JSON.stringify(prev) !== JSON.stringify(next)) await update($, snapshotAtom, () => next)
  } catch (error) {
    $.ui.log(`delix-board: refresh failed: ${String(error)}`, { to: 'debug' })
  } finally {
    rt.isRefreshing = false
  }
}

function openPane($: EngineInterface) {
  return $.ui.open({ id: PANE, title: 'delix' })
}

/** Starts the board once: the session's checkout, refresh and run timers, the pane in a delix project. */
async function activate($: EngineInterface, cwd: string) {
  if (rt.isActive) return
  rt.isActive = true
  rt.top = await findTop($, cwd)
  await refresh($)
  $.clock.every(4000, () => refresh($))
  $.clock.every(2000, () => pollRuns($).catch(() => undefined))
  if ((await read($, snapshotAtom))?.isDelix) void openPane($)
}

async function context($: EngineInterface, k: Ctx['k']): Promise<Ctx> {
  return {
    k,
    snap: await read($, snapshotAtom),
    runs: await read($, runsAtom),
    view: await read($, viewAtom),
    selected: await read($, selectedAtom),
    now: await read($, nowAtom),
  }
}

export const register: Register = (on, options) => {
  rt.isActive = false
  rt.extra = String(options.extraPatterns ?? '')
    .split(',')
    .map(s => s.trim())
    .filter(Boolean)

  on('session.start', async ($, e, next) => {
    const started = await next(e)
    await $.command.register({
      name: 'delix-board',
      description: 'Open the delix board pane (pano, bekleme, kart <Tnnn>, olcum)',
    })
    if (e.isInteractive || (await $.session.surfaces()).length > 0) await activate($, e.cwd)
    return started
  })

  on('session.attach', async ($, e, next) => {
    const attached = await next(e)
    await activate($, await $.session.cwd())
    return attached
  }).catch(($, e, next) => next(e))

  on('command.run', { command: 'delix-board' }, async ($, e) => {
    const [arg, card] = e.args.trim().toLowerCase().split(/\s+/)
    const chosen = arg ? ARG_VIEWS[arg] : undefined
    if (chosen) await update($, viewAtom, () => chosen)
    if (card && /^t\d{3}$/.test(card)) await update($, selectedAtom, () => card.toUpperCase())
    await refresh($)
    const opened = await openPane($)
    return {
      text: opened.isPlaced
        ? `delix panosu açıldı (${VIEWS.find(v => v.id === (chosen ?? 'pano'))?.label ?? 'Pano'}).`
        : 'delix panosu bu yüzeyde açılamadı.',
    }
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    if (!rt.isActive) return next(e)
    const label = matchCommand(e.command, rt.extra)
    if (label === null) return next(e)
    let id: string | null = null
    try {
      const startedAt = await $.clock.now()
      id = e.tool_use_id ?? `run-${startedAt}`
      const run: Run = {
        id,
        kind: 'bash',
        label,
        command: e.command,
        startedAt,
        endedAt: null,
        status: 'running',
        isBackground: e.run_in_background === true,
        taskId: null,
        agentId: null,
        outputPath: null,
        outputSize: 0,
        lastGrowthAt: startedAt,
        suites: 0,
        pass: 0,
        fail: 0,
        tail: [],
        ...(await expected($, label)),
      }
      await startRun($, run)
    } catch {
      id = null
    }
    const ran = await next(e)
    if (id === null) return ran
    try {
      if (ran.deny !== undefined) {
        await update($, runsAtom, list => list.filter(r => r.id !== id))
      } else if (ran.isError !== true && ran.result.backgroundTaskId) {
        await patchRun($, id, {
          isBackground: true,
          taskId: ran.result.backgroundTaskId,
          outputPath: backgroundOutputPath(ran.text ?? '') ?? ran.result.backgroundOutputPath ?? null,
        })
      } else {
        const output = ran.isError === true ? (ran.text ?? '') : `${ran.result.stdout}\n${ran.result.stderr}`
        await finishRun($, id, ran.isError === true ? 'failed' : 'passed', output)
      }
    } catch (error) {
      $.ui.log(`delix-board: run bookkeeping failed: ${String(error)}`, { to: 'debug' })
    }
    return ran
  }).catch(($, e, next) => next(e))

  on('tool.call', { tool: 'Agent' }, async ($, e, next) => {
    const type = e.subagent_type ?? ''
    if (!rt.isActive || !type.startsWith('delixcrew:')) return next(e)
    let id: string | null = null
    try {
      const startedAt = await $.clock.now()
      id = e.tool_use_id ?? `agent-${startedAt}`
      await startRun($, {
        id,
        kind: 'agent',
        label: type,
        command: e.description,
        startedAt,
        endedAt: null,
        status: 'running',
        isBackground: false,
        taskId: null,
        agentId: null,
        outputPath: null,
        outputSize: 0,
        lastGrowthAt: startedAt,
        suites: 0,
        pass: 0,
        fail: 0,
        tail: [],
        expectedMs: null,
        expectedSuites: null,
        expectedChecks: null,
      })
    } catch {
      id = null
    }
    const ran = await next(e)
    if (id === null) return ran
    try {
      if (ran.deny !== undefined) {
        await update($, runsAtom, list => list.filter(r => r.id !== id))
      } else if (ran.isError !== true && 'status' in ran.result && ran.result.status === 'async_launched') {
        await patchRun($, id, { isBackground: true, agentId: ran.result.agentId })
      } else {
        await finishRun($, id, ran.isError === true ? 'failed' : 'passed', null)
      }
    } catch (error) {
      $.ui.log(`delix-board: agent bookkeeping failed: ${String(error)}`, { to: 'debug' })
    }
    return ran
  }).catch(($, e, next) => next(e))

  on('session.append', async ($, e, next) => {
    if (rt.isActive) await onAppended($, e.origin.kind, e.message.content).catch(() => undefined)
    return next(e)
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'Pane', requestId: 'delix-board' }, async ($, e) => {
    const k = makeKit($, e, e.props.bodyColumns)
    return pane($, await context($, k))
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (!rt.isActive || e.props.hasSurvey) return next(e)
    const k = makeKit($, e, e.props.bodyColumns)
    const tree = band(await context($, k), () => openPane($))
    return tree ?? next(e)
  })
}

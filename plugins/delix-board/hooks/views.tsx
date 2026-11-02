// The four views of the pane (Pano, Bekleme, Kart, Ölçüm), the band above the
// prompt and the empty state. Every view reads the same on every surface:
// numbers are written beside each graphic, which `gfx` draws per surface.

import { atom, update } from 'claude-code'
import type { EngineInterface, RenderElement } from 'claude-code'

import type { Card, Run, Snapshot, View } from '../types'
import { ACCENT, BAD, GOOD, MERGE, MUTED, STATUS_COLORS, WARN, severityTone, statusColor, verdictTone, type IconName, type Kit } from './gfx'
import { DEFAULT_PATTERNS, clock, cut, formatDuration, plain, usd } from './parse'

// The board's values; the same atoms in each file that reads them, as the module scan requires.
const viewAtom = atom({ plugin: 'delix-board', key: 'view' } as const, 'pano')
const selectedAtom = atom({ plugin: 'delix-board', key: 'selected' } as const, null)

export const PANE = 'delix-board'

export const VIEWS: { id: View; label: string }[] = [
  { id: 'pano', label: 'Pano' },
  { id: 'bekleme', label: 'Bekleme' },
  { id: 'kart', label: 'Kart' },
  { id: 'olcum', label: 'Ölçüm' },
]

const STATUS_LABEL: Record<string, string> = {
  open: 'açık',
  in_progress: 'sürüyor',
  in_review: 'incelemede',
  fixing: 'düzeltiliyor',
  accepted: 'kabul',
  rejected: 'red',
  escalated: 'yükseltildi',
}

const GATE: Record<string, { icon: IconName; color: string; label: string }> = {
  lock: { icon: 'lock', color: WARN, label: 'Tier 3 onayı' },
  merge: { icon: 'merge', color: MERGE, label: 'merge' },
  escalated: { icon: 'alert', color: BAD, label: 'yükseltildi' },
  needs_context: { icon: 'alert', color: WARN, label: 'bağlam istiyor' },
  blocked: { icon: 'alert', color: BAD, label: 'tıkandı' },
}

const shortTime = (iso: string | null) => (iso ? iso.replace('T', ' ').replace(/:\d{2}(\.\d+)?([+-]\d{2}:\d{2}|Z)?$/, '') : '-')

export type Ctx = {
  k: Kit
  snap: Snapshot | null
  runs: Run[]
  view: View
  selected: string | null
  now: number
}

function header($: EngineInterface, { k, snap, view }: Ctx): RenderElement {
  const { Box, Text, Button } = k
  return (
    <Box flexDirection="column" marginBottom={1}>
      <Box flexDirection="row" gap={1} alignItems="center">
        {k.icon('board', ACCENT)}
        <Text weight="semibold">delix</Text>
        <Text dimColor>{cut(snap?.project ?? '', Math.max(8, k.cols - 30))}</Text>
        {snap?.updated ? <Text dimColor size="caption">STATE {shortTime(snap.updated)}</Text> : null}
      </Box>
      <Box flexDirection="row" gap={1} flexWrap="wrap">
        {VIEWS.map((v, i) => (
          <Button
            key={`tab-${v.id}`}
            label={v.label}
            hotkey={String(i + 1)}
            variant={v.id === view ? 'primary' : 'secondary'}
            onPress={() => update($, viewAtom, () => v.id)}
          />
        ))}
      </Box>
    </Box>
  )
}

export function emptyState(k: Kit, root: string): RenderElement {
  const { Box, Text } = k
  return (
    <Box flexDirection="column" gap={1} paddingY={1}>
      <Box flexDirection="row" gap={1} alignItems="center">
        {k.icon('board', MUTED)}
        <Text weight="semibold">Bu klasör bir delix projesi değil</Text>
      </Box>
      <Text dimColor>{cut(`docs/delix/STATE.json bulunamadı: ${root}`, k.cols)}</Text>
      <Text>Başlamak için sohbette /delix:start ve isteğini yaz; kartlar /delix:dispatch ile gelir.</Text>
      <Text dimColor>Bekleme sekmesi delix projesi dışında da uzun koşuları izler.</Text>
    </Box>
  )
}

function statusDot(k: Kit, status: string): RenderElement {
  return k.icon('dot', statusColor(status))
}

function gateChips(k: Kit, gates: string[]): RenderElement {
  const { Box, Text } = k
  return (
    <Box flexDirection="row" gap={1}>
      {gates.map(g => {
        const gate = GATE[g] ?? { icon: 'alert' as IconName, color: WARN, label: g }
        return (
          <Box flexDirection="row" gap={0}>
            {k.icon(gate.icon, gate.color)}
            <Text color={gate.color}> {gate.label}</Text>
          </Box>
        )
      })}
    </Box>
  )
}

function cardRow($: EngineInterface, { k }: Ctx, c: Card): RenderElement {
  const { Box, Text, Button } = k
  const isWide = k.cols >= 60
  const meta = isWide ? `${c.role} · T${c.tier ?? '?'} · tur ${c.rounds ?? '-'} · ${usd(c.costUsd)}` : `T${c.tier ?? '?'}`
  const titleRoom = Math.max(6, k.cols - meta.length - 14 - c.gates.length * 12)
  return (
    <Box flexDirection="row" gap={1} alignItems="center">
      {statusDot(k, c.status)}
      <Button
        key={`card-${c.id}`}
        plain
        onPress={async () => {
          await update($, selectedAtom, () => c.id)
          await update($, viewAtom, () => 'kart')
        }}
      >
        {c.id} <Text dimColor>{cut(c.title || STATUS_LABEL[c.status] || c.status, titleRoom)}</Text>
      </Button>
      <Text dimColor size="caption">{meta}</Text>
      {c.gates.length > 0 ? gateChips(k, c.gates) : null}
    </Box>
  )
}

function pano($: EngineInterface, ctx: Ctx, snap: Snapshot): RenderElement {
  const { k } = ctx
  const { Box, Text } = k
  const counts: Record<string, number> = {}
  for (const c of snap.cards) counts[c.status] = (counts[c.status] ?? 0) + 1
  const cost = snap.cards.reduce((a, c) => a + (c.costUsd ?? 0), 0)
  const unmeasured = snap.cards.filter(c => c.costUsd === null).length
  const rounds = snap.cards.reduce((a, c) => a + (c.rounds ?? 0), 0)
  const order = Object.keys(STATUS_COLORS)
  const parts = Object.entries(counts)
    .sort(([a], [b]) => order.indexOf(a) - order.indexOf(b))
    .map(([status, value]) => ({ status, value, color: statusColor(status) }))
  const pending = snap.cards.filter(c => c.gates.length > 0)
  const byWave = new Map<string, Card[]>()
  const groupOf = (c: Card) => (c.isArchived ? 'archived' : String(c.wave))
  for (const c of snap.cards) byWave.set(groupOf(c), [...(byWave.get(groupOf(c)) ?? []), c])
  const titleOf = (g: string) => {
    if (g === 'archived') return `Önceki spec${snap.previous ? ` · ${snap.previous}` : ''}`
    const note = snap.waves.find(x => String(x.wave) === g)?.note ?? ''
    return `${g === 'null' ? 'Wave yok' : `Wave ${g}`}${note ? ` · ${note}` : ''}`
  }
  return (
    <Box flexDirection="column" gap={1}>
      <Box flexDirection="column">
        <Text>
          <Text weight="semibold">{snap.cards.length} kart</Text>
          <Text dimColor>
            {' '}· tur {rounds} · {usd(cost)}{unmeasured > 0 ? ` (+${unmeasured} ölçülmedi)` : ''} · worktree {snap.worktreeCount}
            {snap.size ? ` · boy ${snap.size}` : ''}
          </Text>
        </Text>
        {k.stack('mix', Math.min(48, Math.max(10, k.cols - 4)), parts)}
        <Box flexDirection="row" gap={2} flexWrap="wrap">
          {parts.map(p => (
            <Box flexDirection="row" gap={0}>
              {statusDot(k, p.status)}
              <Text dimColor size="caption"> {STATUS_LABEL[p.status] ?? p.status} {p.value}</Text>
            </Box>
          ))}
        </Box>
      </Box>

      <Box flexDirection="column" borderStyle="round" borderColor={pending.length ? 'warning' : 'subtle'} paddingX={1}>
        <Box flexDirection="row" gap={1} alignItems="center">
          {k.icon(pending.length ? 'lock' : 'check', pending.length ? WARN : GOOD)}
          <Text weight="semibold">Bekleyen kapılar</Text>
          <Text dimColor>{pending.length}</Text>
        </Box>
        {pending.length === 0 ? <Text dimColor>Bekleyen kapı yok; kapılar sohbette açılır.</Text> : null}
        {pending.map(c => (
          <Box flexDirection="row" gap={1}>
            <Text weight="semibold">{c.id}</Text>
            {gateChips(k, c.gates)}
          </Box>
        ))}
        {snap.envOwner ? <Text color="warning">Test ortamı kilitli: {snap.envOwner}</Text> : null}
      </Box>

      {[...byWave.entries()].map(([w, cards]) => (
        <Box flexDirection="column">
          <Text dimColor size="caption">{cut(titleOf(w), Math.max(10, k.cols - 2))}</Text>
          {cards.map(c => cardRow($, ctx, c))}
        </Box>
      ))}

      {snap.verifications.length > 0 ? (
        <Box flexDirection="column">
          <Box flexDirection="row" gap={1} alignItems="center">
            {k.icon('flask', ACCENT)}
            <Text weight="semibold">Doğrulamalar (kartsız)</Text>
          </Box>
          {snap.verifications.map(v => (
            <Text>
              <Text>{cut(v.name, 18)}</Text>
              <Text dimColor> {v.date} · </Text>
              <Text color={verdictTone(v.verdict)}>{plain(v.verdict)}</Text>
              <Text dimColor> · {usd(v.costUsd)}</Text>
            </Text>
          ))}
        </Box>
      ) : null}
    </Box>
  )
}

function runBlock(ctx: Ctx, run: Run): RenderElement {
  const { k, now } = ctx
  const { Box, Text } = k
  const elapsed = (run.endedAt ?? Math.max(now, run.startedAt)) - run.startedAt
  const ratio = run.expectedMs ? Math.min(1, elapsed / run.expectedMs) : null
  const left = run.expectedMs ? run.expectedMs - elapsed : null
  const checks = run.pass + run.fail
  return (
    <Box flexDirection="column" borderStyle="round" borderColor="suggestion" paddingX={1}>
      <Box flexDirection="row" gap={1} alignItems="center">
        {k.icon(run.kind === 'agent' ? 'users' : 'timer', ACCENT)}
        <Text weight="semibold">{run.label}</Text>
        <Text tabular>{clock(elapsed)}</Text>
        <Text dimColor size="caption">{run.isBackground ? 'arka plan' : 'ön plan'}</Text>
      </Box>
      <Text dimColor mono>{cut(run.command, Math.max(10, k.cols - 4))}</Text>
      {run.expectedMs ? (
        <Box flexDirection="row" gap={1} alignItems="center">
          {k.bar(`bar-${run.id}`, Math.min(40, Math.max(10, k.cols - 24)), ratio, ACCENT)}
          <Text dimColor size="caption">{left !== null && left > 0 ? `≈ ${formatDuration(left)} kaldı` : 'beklenen süre aşıldı'}</Text>
        </Box>
      ) : (
        <Text dimColor size="caption">İlk koşu: beklenen süre yok, yalnız sayaç.</Text>
      )}
      {run.kind === 'bash' ? (
        <Text>
          <Text dimColor>takım </Text>
          <Text tabular>{run.suites}{run.expectedSuites ? `/${run.expectedSuites}` : ''}</Text>
          <Text dimColor> · kontrol </Text>
          <Text tabular>{checks}{run.expectedChecks ? `/${run.expectedChecks}` : ''}</Text>
          <Text dimColor> · </Text>
          <Text color="success">{run.pass} GEÇTİ</Text>
          <Text dimColor> / </Text>
          <Text color={run.fail > 0 ? 'error' : 'subtle'}>{run.fail} KALDI</Text>
        </Text>
      ) : null}
      {run.tail.length > 0 ? (
        <Box flexDirection="column" marginTop={1}>
          {run.tail.map(line => (
            <Text dimColor mono wrap="truncate-end">{cut(line, Math.max(10, k.cols - 4))}</Text>
          ))}
        </Box>
      ) : run.isBackground ? null : (
        <Text dimColor size="caption">Ön plan komutu ara çıktı vermez; son satırlar bitince gelir.</Text>
      )}
    </Box>
  )
}

function bekleme(ctx: Ctx): RenderElement {
  const { k, runs } = ctx
  const { Box, Text } = k
  const running = runs.filter(r => r.status === 'running')
  const done = runs.filter(r => r.status !== 'running').slice(0, 5)
  return (
    <Box flexDirection="column" gap={1}>
      {running.length === 0 ? (
        <Box flexDirection="column">
          <Box flexDirection="row" gap={1} alignItems="center">
            {k.icon('check', GOOD)}
            <Text weight="semibold">Bekleyen koşu yok</Text>
          </Box>
          <Text dimColor>İzlenen komutlar: {DEFAULT_PATTERNS.map(p => p.label).join(', ')}; ve delix:* inceleyici alt ajanları.</Text>
        </Box>
      ) : (
        running.map(r => runBlock(ctx, r))
      )}
      {done.length > 0 ? (
        <Box flexDirection="column">
          <Text weight="semibold">Son koşular</Text>
          {done.map(r => {
            const ok = r.status === 'passed'
            const checks = r.pass + r.fail
            return (
              <Box flexDirection="row" gap={1} alignItems="center">
                {k.icon(ok ? 'check' : r.status === 'silent' ? 'alert' : 'x', ok ? GOOD : r.status === 'silent' ? WARN : BAD)}
                <Text>{r.label}</Text>
                <Text dimColor tabular>{formatDuration((r.endedAt ?? r.startedAt) - r.startedAt)}</Text>
                {checks > 0 ? (
                  <Text>
                    <Text color="success">{r.pass}</Text>
                    <Text dimColor>/</Text>
                    <Text color={r.fail > 0 ? 'error' : 'subtle'}>{r.fail}</Text>
                  </Text>
                ) : null}
                <Text dimColor size="caption">{r.status === 'silent' ? 'sessiz' : ok ? 'bitti' : 'başarısız'}</Text>
              </Box>
            )
          })}
        </Box>
      ) : null}
    </Box>
  )
}

function kart($: EngineInterface, ctx: Ctx, snap: Snapshot): RenderElement {
  const { k, selected } = ctx
  const { Box, Text, Button } = k
  const cards = snap.cards
  const fallback = cards.find(c => c.gates.length > 0) ?? cards[cards.length - 1]
  const c = cards.find(x => x.id === selected) ?? fallback
  if (!c) return <Text dimColor>Kart yok. Kartlar /delix:dispatch ile gelir.</Text>
  const i = cards.indexOf(c)
  const go = (to: Card | undefined) => () => (to ? update($, selectedAtom, () => to.id) : undefined)
  const w = Math.max(10, k.cols - 4)
  return (
    <Box flexDirection="column" gap={1}>
      <Box flexDirection="row" gap={1}>
        <Button key="card-prev" label="‹ Önceki" onPress={go(cards[i - 1])} />
        <Button key="card-next" label="Sonraki ›" onPress={go(cards[i + 1])} />
        <Text dimColor size="caption">{i + 1}/{cards.length}</Text>
      </Box>
      <Box flexDirection="column">
        <Box flexDirection="row" gap={1} alignItems="center">
          {statusDot(k, c.status)}
          <Text weight="semibold">{c.id}</Text>
          <Text>{cut(c.title, Math.max(8, k.cols - 10))}</Text>
        </Box>
        <Text dimColor>
          {c.role} · Tier {c.tier ?? '?'} · wave {c.wave ?? '-'} · <Text color={statusColor(c.status)}>{STATUS_LABEL[c.status] ?? c.status}</Text> · tur {c.rounds ?? '-'} · {usd(c.costUsd)}
        </Text>
        {c.pr ? <Text dimColor>{cut(`PR: ${c.pr}`, w)}</Text> : null}
        {c.approved ? <Text dimColor>{cut(`onay: ${c.approved}`, w)}</Text> : null}
        {c.gates.length > 0 ? gateChips(k, c.gates) : null}
      </Box>

      <Box flexDirection="row" gap={2} flexWrap="wrap">
        <Text>
          <Text dimColor>qa </Text>
          <Text color={verdictTone(c.qa)}>{cut(c.qa ?? 'yok', 40)}</Text>
        </Text>
        <Text>
          <Text dimColor>security </Text>
          <Text color={verdictTone(c.security)}>{cut(c.security ?? 'yok', Math.max(20, k.cols - 20))}</Text>
        </Text>
      </Box>

      <Box flexDirection="column">
        <Box flexDirection="row" gap={1} alignItems="center">
          {k.icon('file', ACCENT)}
          <Text weight="semibold">Files</Text>
          <Text dimColor>{c.files.length}</Text>
        </Box>
        {c.files.length === 0 ? <Text dimColor>Kartta Files listesi yok.</Text> : null}
        {c.files.map(f => (
          <Text>
            <Text color={/create|oluştur/i.test(f.kind) ? 'success' : /test/i.test(f.kind) ? 'suggestion' : 'warning'}>{f.kind.padEnd(7)}</Text>
            <Text mono>{cut(f.path, Math.max(8, k.cols - 12))}</Text>
          </Text>
        ))}
      </Box>

      <Box flexDirection="column">
        <Box flexDirection="row" gap={1} alignItems="center">
          {k.icon('flask', ACCENT)}
          <Text weight="semibold">Rapor ve test</Text>
        </Box>
        {c.worktree ? (
          <Text dimColor>{cut(`worktree ${c.worktree}${c.branch ? ` · ${c.branch}` : ''}`, w)}</Text>
        ) : (
          <Text dimColor>Açık worktree yok (kart merge edilmiş ya da başlamamış).</Text>
        )}
        {c.report ? (
          <Text>
            <Text color={verdictTone(c.report.status)}>{c.report.status ?? 'durum yok'}</Text>
            <Text dimColor> · {cut(c.report.summary, Math.max(8, k.cols - 24))}</Text>
          </Text>
        ) : null}
        {c.test ? (
          <Box flexDirection="column">
            <Text>
              <Text color="success">{c.test.pass} GEÇTİ</Text>
              <Text dimColor> / </Text>
              <Text color={c.test.fail > 0 ? 'error' : 'subtle'}>{c.test.fail} KALDI</Text>
            </Text>
            {c.test.tail.slice(-6).map(line => (
              <Text dimColor mono>{cut(line, w)}</Text>
            ))}
          </Box>
        ) : c.worktree ? (
          <Text dimColor>.delix/test-result.txt yok.</Text>
        ) : null}
      </Box>

      <Box flexDirection="column">
        <Box flexDirection="row" gap={1} alignItems="center">
          {k.icon('users', ACCENT)}
          <Text weight="semibold">Tur geçmişi</Text>
          <Text dimColor>{c.reviewRounds.length}</Text>
        </Box>
        {c.reviewRounds.length === 0 ? <Text dimColor>Kartta inceleme bulgusu yazılmamış.</Text> : null}
        {c.reviewRounds.map(r => (
          <Box flexDirection="column">
            <Text>{cut(r.title, w)}</Text>
            {r.findings.map(f => (
              <Text>
                <Text color={severityTone(f.severity)}>  {f.severity === 'high' ? '▲' : f.severity === 'medium' ? '◆' : '·'} </Text>
                <Text dimColor>{cut(f.text, Math.max(8, k.cols - 8))}</Text>
              </Text>
            ))}
          </Box>
        ))}
      </Box>
    </Box>
  )
}

type Series = { key: string; title: string; unit: (n: number) => string; color: string; values: (number | null)[]; note?: string }

function olcum(ctx: Ctx, snap: Snapshot): RenderElement {
  const { k } = ctx
  const { Box, Text } = k
  const cards = snap.cards
  const series: Series[] = [
    { key: 'cost', title: 'Maliyet', unit: n => `$${n.toFixed(2)}`, color: ACCENT, values: cards.map(c => c.costUsd) },
    { key: 'rounds', title: 'Tur', unit: n => String(n), color: WARN, values: cards.map(c => c.rounds) },
    { key: 'time', title: 'Süre', unit: n => `${n} dk`, color: MERGE, values: cards.map(c => c.durationMin), note: 'metrics.md tablolarından' },
    { key: 'gates', title: 'Kapı', unit: n => String(n), color: GOOD, values: cards.map(c => c.gateCount), note: 'türetilmiş: kart onayı + Tier 3 onayı + merge' },
  ]
  const barCells = Math.max(6, Math.min(30, k.cols - 26))
  return (
    <Box flexDirection="column" gap={1}>
      {series.map(s => {
        const known = s.values.filter((v): v is number => v !== null)
        const max = Math.max(0, ...known)
        const total = known.reduce((a, b) => a + b, 0)
        return (
          <Box flexDirection="column">
            <Box flexDirection="row" gap={1} alignItems="center">
              {k.icon('chart', s.color)}
              <Text weight="semibold">{s.title}</Text>
              {k.spark(`spark-${s.key}`, s.values, s.color)}
            </Box>
            <Text dimColor size="caption">
              toplam {s.unit(Math.round(total * 100) / 100)} · ort. {known.length ? s.unit(Math.round((total / known.length) * 10) / 10) : '-'} · ölçülen {known.length}/{s.values.length}
            </Text>
            {s.note ? <Text dimColor size="caption">{s.note}</Text> : null}
            {cards.map((c, i) => {
              const v = s.values[i] ?? null
              return (
                <Box flexDirection="row" gap={1} alignItems="center">
                  <Text tabular>{c.id}</Text>
                  {k.bar(`${s.key}-${c.id}`, barCells, v === null ? null : max > 0 ? v / max : 0, s.color)}
                  <Text dimColor={v === null} tabular>{v === null ? 'ölçülmedi' : s.unit(v)}</Text>
                </Box>
              )
            })}
          </Box>
        )
      })}
      {snap.verifications.length > 0 ? (
        <Box flexDirection="column">
          <Text weight="semibold">Doğrulama maliyeti</Text>
          {snap.verifications.map(v => (
            <Box flexDirection="row" gap={1} alignItems="center">
              <Text>{cut(v.name, 16).padEnd(16)}</Text>
              {k.bar(`ver-${v.name}`, barCells, v.costUsd === null ? null : v.costUsd / Math.max(...snap.verifications.map(x => x.costUsd ?? 0), 0.01), ACCENT)}
              <Text dimColor={v.costUsd === null}>{usd(v.costUsd)}</Text>
            </Box>
          ))}
        </Box>
      ) : null}
    </Box>
  )
}

export function pane($: EngineInterface, ctx: Ctx): RenderElement {
  const { k, snap, view } = ctx
  const { Box } = k
  const body =
    view === 'bekleme'
      ? bekleme(ctx)
      : snap === null || !snap.isDelix
        ? emptyState(k, snap?.root ?? '')
        : view === 'kart'
          ? kart($, ctx, snap)
          : view === 'olcum'
            ? olcum(ctx, snap)
            : pano($, ctx, snap)
  return (
    <Box flexDirection="column">
      {header($, ctx)}
      {body}
    </Box>
  )
}

/** The band: a running wait first, else the pending gates, else nothing (null). */
export function band(ctx: Ctx, openPane: () => unknown): RenderElement | null {
  const { k, snap, runs, now } = ctx
  const { Box, Text, Button } = k
  const run = runs.find(r => r.status === 'running')
  const pending = snap?.isDelix ? snap.cards.filter(c => c.gates.length > 0) : []
  if (!run && pending.length === 0) return null
  const open = <Button key="band-open" label="Pano" onPress={openPane} />
  if (run) {
    const elapsed = Math.max(now, run.startedAt) - run.startedAt
    const checks = run.pass + run.fail
    return (
      <Box flexDirection="row" gap={1} alignItems="center">
        {k.icon(run.kind === 'agent' ? 'users' : 'timer', ACCENT)}
        <Text weight="semibold">{run.label}</Text>
        <Text tabular>{clock(elapsed)}</Text>
        {run.expectedMs ? k.bar('band-bar', 12, Math.min(1, elapsed / run.expectedMs), ACCENT) : null}
        {checks > 0 ? (
          <Text>
            <Text color="success">{run.pass}</Text>
            <Text dimColor>/</Text>
            <Text color={run.fail > 0 ? 'error' : 'subtle'}>{run.fail}</Text>
            {run.expectedChecks ? <Text dimColor> ({checks}/{run.expectedChecks})</Text> : null}
          </Text>
        ) : null}
        {open}
      </Box>
    )
  }
  return (
    <Box flexDirection="row" gap={1} alignItems="center">
      {k.icon('lock', WARN)}
      <Text>
        <Text weight="semibold">{pending.length} kapı bekliyor: </Text>
        <Text dimColor>{cut(pending.map(c => `${c.id} ${c.gates.map(g => GATE[g]?.label ?? g).join('+')}`).join(' · '), Math.max(10, k.cols - 30))}</Text>
      </Text>
      {open}
    </Box>
  )
}

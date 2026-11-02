// The drawing layer: palette, icons, bars and sparklines. Desktop, VS Code and
// mobile draw them as Svg; the terminal, which has no Svg, as one Raster of
// block characters, and icons as single-width geometric glyphs.

import type {
  BoxProps,
  ButtonProps,
  Color,
  ElementConstructor,
  EngineInterface,
  RasterProps,
  RenderElement,
  RenderInput,
  SvgProps,
  TextProps,
} from 'claude-code'

export type Kit = {
  surface: string
  isTerminal: boolean
  cols: number
  Box: ElementConstructor<BoxProps>
  Text: ElementConstructor<TextProps>
  Button: ElementConstructor<ButtonProps>
  icon: (name: IconName, color: string, key?: string) => RenderElement
  bar: (key: string, cells: number, ratio: number | null, color: string) => RenderElement
  stack: (key: string, cells: number, parts: { value: number; color: string }[]) => RenderElement
  spark: (key: string, values: (number | null)[], color: string) => RenderElement
}

export const STATUS_COLORS: Record<string, string> = {
  open: '#8B949E',
  in_progress: '#3B82F6',
  in_review: '#8B5CF6',
  fixing: '#F59E0B',
  accepted: '#22C55E',
  rejected: '#EF4444',
  escalated: '#F97316',
}
export const ACCENT = '#3B82F6'
export const TRACK = '#4B5563'
export const MUTED = '#8B949E'
export const GOOD = '#22C55E'
export const BAD = '#EF4444'
export const WARN = '#F59E0B'
export const MERGE = '#8B5CF6'

export const statusColor = (status: string) => STATUS_COLORS[status] ?? MUTED

/** A theme key for text that names a verdict, so light and dark themes both read it. */
export function verdictTone(verdict: string | null): Color {
  const v = (verdict ?? '').toUpperCase()
  if (/FIX|DÜZELT|REJECT|BLOCK|KALDI|FAIL/.test(v)) return 'error'
  if (/HUMAN_APPROVAL|NEEDS|WITH_NOTES|ÇEKİNCE|CONCERN|🔐/.test(v)) return 'warning'
  if (/ACCEPT|CLEAN|KABUL|TEMİZ|PASS|DONE/.test(v)) return 'success'
  return 'subtle'
}

export const severityTone = (s: string | null): Color => (s === 'high' ? 'error' : s === 'medium' ? 'warning' : s === 'low' ? 'suggestion' : 'subtle')

export type IconName = 'lock' | 'merge' | 'timer' | 'check' | 'x' | 'alert' | 'users' | 'file' | 'flask' | 'dot' | 'chart' | 'board' | 'card'

// 24×24 stroke paths, drawn in the style of an outline icon set.
const PATHS: Record<IconName, string> = {
  lock: '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
  merge: '<circle cx="6" cy="18" r="2.5"/><circle cx="6" cy="6" r="2.5"/><circle cx="18" cy="14" r="2.5"/><path d="M6 8.5v7"/><path d="M6 8.5c0 4 4 5.5 9.5 5.5"/>',
  timer: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2"/><path d="M10 2h4"/>',
  check: '<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>',
  x: '<circle cx="12" cy="12" r="9"/><path d="m9 9 6 6"/><path d="m15 9-6 6"/>',
  alert: '<path d="M12 3 2 20h20L12 3z"/><path d="M12 10v4"/><path d="M12 17h.01"/>',
  users: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7"/><path d="M18 14a6.5 6.5 0 0 1 3.5 6"/>',
  file: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/>',
  flask: '<path d="M9 3h6"/><path d="M10 3v6L4.5 19a1.5 1.5 0 0 0 1.3 2h12.4a1.5 1.5 0 0 0 1.3-2L14 9V3"/><path d="M7 15h10"/>',
  dot: '<circle cx="12" cy="12" r="6" fill="currentColor"/>',
  chart: '<path d="M4 20V10"/><path d="M10 20V4"/><path d="M16 20v-7"/><path d="M22 20H2"/>',
  board: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M9 4v16"/><path d="M15 4v16"/>',
  card: '<rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8"/><path d="M8 12h8"/><path d="M8 16h5"/>',
}

const GLYPHS: Record<IconName, string> = {
  lock: '◈',
  merge: '⑂',
  timer: '◷',
  check: '✓',
  x: '✕',
  alert: '▲',
  users: '◎',
  file: '▤',
  flask: '◬',
  dot: '●',
  chart: '▥',
  board: '▦',
  card: '▭',
}

const svgIcon = (name: IconName, color: string) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="${color}" color="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${PATHS[name]}</svg>`

const B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function base64(bytes: Uint8Array): string {
  let out = ''
  for (let i = 0; i < bytes.length; i += 3) {
    const a = bytes[i] ?? 0
    const b = bytes[i + 1] ?? 0
    const c = bytes[i + 2] ?? 0
    const n = (a << 16) | (b << 8) | c
    out += B64[(n >> 18) & 63]! + B64[(n >> 12) & 63]!
    out += i + 1 < bytes.length ? B64[(n >> 6) & 63]! : '='
    out += i + 2 < bytes.length ? B64[n & 63]! : '='
  }
  return out
}

const DEFAULT = 0x01000000
const rgb = (hex: string) => Number.parseInt(hex.replace('#', ''), 16) & 0xffffff

/** Raster cells from `[char, foreground]` pairs on the terminal's own background. */
function cells(list: [string, string | null][]): string {
  const words = new Uint32Array(list.length * 3)
  list.forEach(([ch, fg], i) => {
    words[i * 3] = ch.codePointAt(0) ?? 0x20
    words[i * 3 + 1] = fg === null ? DEFAULT : rgb(fg)
    words[i * 3 + 2] = DEFAULT
  })
  return base64(new Uint8Array(words.buffer))
}

const EIGHTHS = ['', '▏', '▎', '▍', '▌', '▋', '▊', '▉']
const SPARKS = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█']
const PX = 7

type AnyTable = {
  Box: ElementConstructor<BoxProps>
  Text: ElementConstructor<TextProps>
  Button: ElementConstructor<ButtonProps>
  Svg?: ElementConstructor<SvgProps>
  Raster?: ElementConstructor<RasterProps>
}

export function makeKit($: EngineInterface, e: RenderInput, cols: number): Kit {
  const t = $.ui.resolve(e) as unknown as AnyTable
  // A table is completed with every element name (a missing one draws a fragment), so the surface decides.
  const isTerminal = e.surface === 'terminal'
  const { Box, Text, Button } = t
  const Svg = isTerminal ? undefined : t.Svg
  const Raster = isTerminal ? t.Raster : undefined

  const raster = (key: string, list: [string, string | null][]) =>
    Raster ? <Raster key={key} columns={Math.max(1, list.length)} rows={1} cells={cells(list.length ? list : [[' ', null]])} /> : <Text> </Text>

  const icon = (name: IconName, color: string, key?: string): RenderElement =>
    Svg ? <Svg source={svgIcon(name, color)} alt={name} width={14} height={14} /> : <Text color={color}>{GLYPHS[name]}</Text>

  const bar = (key: string, n: number, ratio: number | null, color: string): RenderElement => {
    const w = Math.max(1, Math.floor(n))
    if (Svg) {
      const px = w * PX
      const fill = ratio === null ? '' : `<rect x="0" y="0" height="8" rx="2" width="${Math.max(ratio > 0 ? 2 : 0, Math.round(px * Math.min(1, ratio)))}" fill="${color}"/>`
      const track = ratio === null
        ? `<rect x="0.5" y="0.5" height="7" width="${px - 1}" rx="2" fill="none" stroke="${TRACK}" stroke-dasharray="3 2"/>`
        : `<rect x="0" y="0" height="8" width="${px}" rx="2" fill="${TRACK}" fill-opacity="0.35"/>`
      return <Svg source={`<svg xmlns="http://www.w3.org/2000/svg" width="${px}" height="8" viewBox="0 0 ${px} 8">${track}${fill}</svg>`} alt={ratio === null ? 'not measured' : `${Math.round(ratio * 100)}%`} width={px} height={8} />
    }
    if (ratio === null) return raster(key, Array.from({ length: w }, () => ['╌', TRACK] as [string, string]))
    const eighths = Math.round(Math.min(1, Math.max(0, ratio)) * w * 8)
    const list: [string, string | null][] = []
    for (let i = 0; i < w; i++) {
      const left = eighths - i * 8
      if (left >= 8) list.push(['█', color])
      else if (left > 0) list.push([EIGHTHS[left] ?? '▏', color])
      else list.push(['░', TRACK])
    }
    return raster(key, list)
  }

  const stack = (key: string, n: number, parts: { value: number; color: string }[]): RenderElement => {
    const w = Math.max(1, Math.floor(n))
    const total = parts.reduce((a, p) => a + p.value, 0)
    if (total <= 0) return bar(key, w, 0, TRACK)
    if (Svg) {
      const px = w * PX
      let x = 0
      const rects = parts
        .filter(p => p.value > 0)
        .map(p => {
          const width = (p.value / total) * px
          const r = `<rect x="${x.toFixed(1)}" y="0" width="${Math.max(1, width - 1).toFixed(1)}" height="10" rx="2" fill="${p.color}"/>`
          x += width
          return r
        })
        .join('')
      return <Svg source={`<svg xmlns="http://www.w3.org/2000/svg" width="${px}" height="10" viewBox="0 0 ${px} 10">${rects}</svg>`} alt="status mix" width={px} height={10} />
    }
    const list: [string, string | null][] = []
    let used = 0
    parts.forEach((p, i) => {
      const share = i === parts.length - 1 ? w - used : Math.round((p.value / total) * w)
      for (let k = 0; k < share && used < w; k++, used++) list.push(['█', p.color])
    })
    while (list.length < w) list.push(['░', TRACK])
    return raster(key, list)
  }

  const spark = (key: string, values: (number | null)[], color: string): RenderElement => {
    const known = values.filter((v): v is number => v !== null)
    const max = Math.max(0, ...known)
    if (Svg) {
      const step = 9
      const px = Math.max(step, values.length * step)
      const bars = values
        .map((v, i) => {
          if (v === null) return `<rect x="${i * step + 1}" y="15" width="6" height="1" fill="${TRACK}"/>`
          const h = max > 0 ? Math.max(1.5, (v / max) * 16) : 1.5
          return `<rect x="${i * step + 1}" y="${(16 - h).toFixed(1)}" width="6" height="${h.toFixed(1)}" rx="1" fill="${color}"/>`
        })
        .join('')
      return <Svg source={`<svg xmlns="http://www.w3.org/2000/svg" width="${px}" height="16" viewBox="0 0 ${px} 16">${bars}</svg>`} alt="sparkline" width={px} height={16} />
    }
    return raster(
      key,
      values.map(v => (v === null ? ['·', TRACK] : [SPARKS[max > 0 ? Math.min(7, Math.round((v / max) * 7)) : 0] ?? '▁', color])),
    )
  }

  return { surface: e.surface, isTerminal, cols, Box, Text, Button, icon, bar, stack, spark }
}

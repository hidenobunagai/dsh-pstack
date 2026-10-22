#!/usr/bin/env node
// Validate this repo's skills against the Agent Skills spec and the DSH loader's expectations.
//
// Checks:
//   - <dir>/SKILL.md exists and the directory name matches the `name` field
//   - frontmatter is YAML and closes with `---`
//   - `description` is present, non-empty, and within the 1024-character cap
//   - the body is non-empty
//   - every `**skill-name**` reference resolves to a skill in this repo or a known external one
//   - every relative link to another skill's file resolves
//
// Usage: node scripts/check-skills.mjs [--verbose]
import { readdir, readFile, stat } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const skillsRoot = path.join(repoRoot, 'skills')
const verbose = process.argv.includes('--verbose')

// Skills that live outside this repo and that a ported skill may legitimately name.
const externalSkills = new Set([
  'web-verify',
  'web-demo-video',
  'readme-demo',
  'memory',
  'typescript-standards',
  'python-standards',
])

const problems = []
const warnings = []

function parseFrontmatter(text, file) {
  if (!text.startsWith('---\n')) {
    problems.push(`${file}: does not start with a --- frontmatter block`)
    return null
  }
  const end = text.indexOf('\n---\n', 4)
  if (end === -1) {
    problems.push(`${file}: frontmatter block is not closed`)
    return null
  }
  const raw = text.slice(4, end)
  const body = text.slice(end + 5)
  const fields = {}
  for (const line of raw.split('\n')) {
    const match = line.match(/^([a-zA-Z][\w-]*):\s*(.*)$/)
    if (!match) continue
    let value = match[2].trim()
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1)
    }
    fields[match[1]] = value
  }
  return { fields, body }
}

const dirs = (await readdir(skillsRoot, { withFileTypes: true }))
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort()

const known = new Set(dirs)
const skills = new Map()

for (const name of dirs) {
  const file = path.join(skillsRoot, name, 'SKILL.md')
  if (!existsSync(file)) {
    problems.push(`${name}: missing SKILL.md`)
    continue
  }
  const text = await readFile(file, 'utf8')
  const parsed = parseFrontmatter(text, name)
  if (!parsed) continue
  const { fields, body } = parsed

  if (!fields.name) problems.push(`${name}: frontmatter has no name`)
  else if (fields.name !== name) problems.push(`${name}: name "${fields.name}" != directory name`)

  if (!fields.description) problems.push(`${name}: frontmatter has no description`)
  else if (fields.description.length > 1024)
    problems.push(`${name}: description is ${fields.description.length} chars, cap is 1024`)

  if (body.trim().length === 0) problems.push(`${name}: body is empty`)

  skills.set(name, { file, text, body })
}

// Every **name** or `name` mention that looks like a skill reference must resolve.
for (const [name, { file, text }] of skills) {
  const dir = path.dirname(file)

  for (const match of text.matchAll(/\*\*([a-z][a-z0-9-]{2,})\*\*/g)) {
    const ref = match[1]
    if (known.has(ref) || externalSkills.has(ref)) continue
    // Bare names in prose that are not skills are common; only flag ones shaped like a skill id.
    if (!/^principle-|^(how|why|swarm|arena|architect|interrogate|reflect|unslop|no-comments|technical-writing|poteto-mode|benchmark-checklist|show-me-your-work)$/.test(ref)) {
      if (verbose) warnings.push(`${name}: **${ref}** is not a skill (ignored)`)
      continue
    }
    problems.push(`${name}: references **${ref}** but no skills/${ref}/ exists`)
  }

  for (const match of text.matchAll(/\]\(([^)]+\.md)\)/g)) {
    const target = match[1]
    if (target.startsWith('http')) continue
    const resolved = path.resolve(dir, target)
    if (!existsSync(resolved)) problems.push(`${name}: link ${target} does not resolve`)
  }

  for (const match of text.matchAll(/`(references\/[\w./-]+\.md)`/g)) {
    const resolved = path.resolve(dir, match[1])
    if (!existsSync(resolved)) problems.push(`${name}: reference ${match[1]} does not resolve`)
  }
}

for (const warning of warnings) console.warn(`warn  ${warning}`)
for (const problem of problems) console.error(`error ${problem}`)

if (problems.length > 0) {
  console.error(`\n${problems.length} problem(s) across ${skills.size} skill(s)`)
  process.exit(1)
}

console.log(`ok: ${skills.size} skill(s) validated`)

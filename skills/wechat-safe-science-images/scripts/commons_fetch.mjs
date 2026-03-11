#!/usr/bin/env node
/**
 * Fetch images from Wikimedia Commons with strict license filtering.
 * Output: downloaded images + image-manifest.json
 *
 * License allowlist (by extmetadata.LicenseShortName):
 * - CC0
 * - Public domain
 * - CC BY
 * - CC BY-SA
 */

import fs from 'node:fs';
import path from 'node:path';

function arg(name, def = undefined) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx >= 0) return process.argv[idx + 1] ?? def;
  return def;
}
function flag(name) {
  return process.argv.includes(`--${name}`);
}

const query = arg('query');
const outDir = arg('out', './imgs');
const limit = Number(arg('limit', '6'));
const minWidth = Number(arg('min-width', '800'));

if (!query) {
  console.error('Missing --query');
  process.exit(1);
}

const API = 'https://commons.wikimedia.org/w/api.php';
const ua = 'openclaw-wechat-safe-science-images/1.0';

const allow = new Set([
  'CC0',
  'Public domain',
  'CC BY',
  'CC BY-SA',
  'CC BY 4.0',
  'CC BY-SA 4.0',
  'CC BY 3.0',
  'CC BY-SA 3.0',
]);

async function api(params) {
  const url = new URL(API);
  for (const [k, v] of Object.entries({ format: 'json', origin: '*', ...params })) {
    url.searchParams.set(k, String(v));
  }
  const res = await fetch(url, { headers: { 'User-Agent': ua } });
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json();
}

function safeName(name) {
  return name.replace(/^File:/, '')
    .replace(/[\\/:*?"<>|]/g, '_')
    .replace(/\s+/g, ' ')
    .trim();
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  // 1) search file titles
  const s = await api({
    action: 'query',
    list: 'search',
    srsearch: `${query} filetype:bitmap`,
    srnamespace: 6,
    srlimit: String(Math.max(limit * 5, 25)),
  });

  const titles = (s?.query?.search ?? []).map(x => x.title).filter(Boolean);
  if (!titles.length) {
    console.error('No results');
    process.exit(2);
  }

  // 2) get imageinfo + extmetadata
  const info = await api({
    action: 'query',
    prop: 'imageinfo',
    titles: titles.join('|'),
    iiprop: 'url|size|extmetadata',
  });

  const pages = Object.values(info?.query?.pages ?? {});

  const candidates = [];
  for (const p of pages) {
    const ii = p?.imageinfo?.[0];
    if (!ii?.url) continue;
    if ((ii.width ?? 0) < minWidth) continue;

    const m = ii.extmetadata ?? {};
    const licenseShort = (m.LicenseShortName?.value ?? '').replace(/<[^>]+>/g, '').trim();
    const licenseUrl = (m.LicenseUrl?.value ?? '').replace(/<[^>]+>/g, '').trim();
    const artist = (m.Artist?.value ?? '').replace(/<[^>]+>/g, '').trim();
    const credit = (m.Credit?.value ?? '').replace(/<[^>]+>/g, '').trim();

    // hard deny obvious bad signals
    const lower = (licenseShort || '').toLowerCase();
    if (!licenseShort) continue;
    if (lower.includes('noncommercial') || lower.includes('nc')) continue;
    if (lower.includes('noderivatives') || lower.includes('nd')) continue;
    if (lower.includes('all rights reserved') || lower.includes('copyright')) continue;

    // allowlist check (best-effort)
    const ok = allow.has(licenseShort) || lower.startsWith('cc by') || lower.startsWith('cc by-sa') || lower.includes('public domain');
    if (!ok) continue;

    candidates.push({
      title: p.title,
      pageid: p.pageid,
      file_page_url: `https://commons.wikimedia.org/wiki/${encodeURIComponent(p.title.replace(/ /g, '_'))}`,
      original_url: ii.url,
      width: ii.width,
      height: ii.height,
      mime: ii.mime,
      license_short_name: licenseShort,
      license_url: licenseUrl,
      artist,
      credit,
    });
  }

  const chosen = candidates.slice(0, limit);
  if (!chosen.length) {
    console.error('No candidates passed license/size filters. Try a different query.');
    process.exit(3);
  }

  // 3) download
  const manifest = [];
  for (const c of chosen) {
    const urlObj = new URL(c.original_url);
    const ext = path.extname(urlObj.pathname) || (c.mime?.includes('png') ? '.png' : '.jpg');
    const base = safeName(c.title);
    const filename = `${base}`.replace(/\.(png|jpg|jpeg|gif|webp|svg)$/i, '') + ext;
    const outPath = path.join(outDir, filename);

    const res = await fetch(c.original_url, { headers: { 'User-Agent': ua } });
    if (!res.ok) continue;
    const buf = Buffer.from(await res.arrayBuffer());
    fs.writeFileSync(outPath, buf);

    manifest.push({
      filename,
      local_path: outPath,
      file_title: c.title,
      file_page_url: c.file_page_url,
      original_url: c.original_url,
      width: c.width,
      height: c.height,
      mime: c.mime,
      license_short_name: c.license_short_name,
      license_url: c.license_url,
      artist: c.artist,
      credit: c.credit,
      retrieved_at: new Date().toISOString(),
    });
  }

  const manifestPath = path.join(outDir, 'image-manifest.json');
  fs.writeFileSync(manifestPath, JSON.stringify({ query, generated_at: new Date().toISOString(), images: manifest }, null, 2));

  console.log(JSON.stringify({ ok: true, outDir, manifest: manifestPath, count: manifest.length }, null, 2));
}

main().catch((e) => {
  console.error('ERROR', e?.stack || String(e));
  process.exit(1);
});

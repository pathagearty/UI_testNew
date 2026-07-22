#!/usr/bin/env python3
"""Build the standalone interactive HTML walkthrough without third-party packages."""
from __future__ import annotations
import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "FOUNDRY_ENTERPRISE_HARNESS_WALKTHROUGH.md"
OUTPUT = ROOT / "foundry-enterprise-harness-walkthrough.html"


def slugify(value: str) -> str:
    value = re.sub(r"<[^>]+>", "", value)
    value = re.sub(r"[^a-zA-Z0-9]+", "-", value).strip("-").lower()
    return value or "section"


def inline(value: str) -> str:
    # Preserve code spans while escaping all source HTML.
    stash: list[str] = []
    def keep_code(match: re.Match[str]) -> str:
        stash.append(f"<code>{html.escape(match.group(1))}</code>")
        return f"@@CODE{len(stash)-1}@@"
    value = re.sub(r"`([^`]+)`", keep_code, value)
    value = html.escape(value, quote=False)
    def keep_link(match: re.Match[str]) -> str:
        label, href = match.group(1), match.group(2)
        if href.startswith(("http://", "https://")):
            return f'<a href="{href}" target="_blank" rel="noopener">{label}</a>'
        return f'<a href="{href}">{label}</a>'
    value = re.sub(
        r"\[([^\]]+)\]\(((?:https?://[^)]+)|(?:[A-Za-z0-9_.\-/]+(?:#[A-Za-z0-9_.:-]+)?)|(?:#[A-Za-z0-9_.:-]+))\)",
        keep_link,
        value,
    )
    value = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", value)
    value = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", value)
    for i, token in enumerate(stash):
        value = value.replace(f"@@CODE{i}@@", token)
    return value


def is_table_separator(line: str) -> bool:
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", c) for c in cells)


def render_markdown(text: str) -> tuple[str, list[tuple[str, str]]]:
    lines = text.splitlines()
    out: list[str] = []
    toc: list[tuple[str, str]] = []
    used_ids: dict[str, int] = {}
    checklist_num = 0
    i = 0
    list_type: str | None = None
    paragraph: list[str] = []

    def close_list() -> None:
        nonlocal list_type
        if list_type:
            out.append(f"</{list_type}>")
            list_type = None

    def flush_paragraph() -> None:
        nonlocal paragraph
        if paragraph:
            out.append(f"<p>{inline(' '.join(x.strip() for x in paragraph))}</p>")
            paragraph = []

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if stripped.startswith("```"):
            flush_paragraph(); close_list()
            language = stripped[3:].strip()
            i += 1
            code_lines: list[str] = []
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code_lines.append(lines[i]); i += 1
            out.append(f'<pre data-language="{html.escape(language)}"><code>{html.escape(chr(10).join(code_lines))}</code></pre>')
            i += 1
            continue

        heading = re.match(r"^(#{1,6})\s+(.+)$", stripped)
        if heading:
            flush_paragraph(); close_list()
            level = len(heading.group(1)); title = heading.group(2).strip()
            base = slugify(title); count = used_ids.get(base, 0); used_ids[base] = count + 1
            section_id = base if count == 0 else f"{base}-{count+1}"
            out.append(f'<h{level} id="{section_id}">{inline(title)}<a class="anchor" href="#{section_id}" aria-label="Link to this section">#</a></h{level}>')
            if level <= 2:
                toc.append((section_id, re.sub(r"\*\*|`", "", title)))
            i += 1
            continue

        if stripped == "---":
            flush_paragraph(); close_list(); out.append("<hr>"); i += 1; continue

        if stripped.startswith("> "):
            flush_paragraph(); close_list(); out.append(f"<blockquote>{inline(stripped[2:])}</blockquote>"); i += 1; continue

        # Markdown table.
        if stripped.startswith("|") and i + 1 < len(lines) and is_table_separator(lines[i + 1]):
            flush_paragraph(); close_list()
            headers = [c.strip() for c in stripped.strip("|").split("|")]
            i += 2
            rows: list[list[str]] = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")]); i += 1
            out.append('<div class="table-wrap"><table><thead><tr>' + ''.join(f"<th>{inline(c)}</th>" for c in headers) + "</tr></thead><tbody>")
            for row in rows:
                row += [""] * (len(headers) - len(row))
                out.append("<tr>" + ''.join(f"<td>{inline(c)}</td>" for c in row[:len(headers)]) + "</tr>")
            out.append("</tbody></table></div>")
            continue

        check = re.match(r"^-\s+\[([ xX])\]\s+(.+)$", stripped)
        bullet = re.match(r"^-\s+(.+)$", stripped)
        numbered = re.match(r"^\d+\.\s+(.+)$", stripped)
        if check or bullet or numbered:
            flush_paragraph()
            desired = "ol" if numbered else "ul"
            if list_type != desired:
                close_list(); out.append(f"<{desired}>"); list_type = desired
            if check:
                checklist_num += 1
                key = f"control-{checklist_num:03d}"
                out.append(f'<li class="check-item"><label><input type="checkbox" data-check-key="{key}"><span>{inline(check.group(2))}</span></label></li>')
            else:
                content = numbered.group(1) if numbered else bullet.group(1)
                out.append(f"<li>{inline(content)}</li>")
            i += 1
            continue

        if not stripped:
            flush_paragraph(); close_list(); i += 1; continue

        paragraph.append(stripped); i += 1

    flush_paragraph(); close_list()
    return "\n".join(out), toc


body, toc = render_markdown(SOURCE.read_text(encoding="utf-8"))
toc_html = "\n".join(f'<a href="#{sid}">{html.escape(title)}</a>' for sid, title in toc)

page = f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="description" content="Cross-functional implementation walkthrough for a Microsoft Foundry prior-authorization enterprise assurance harness.">
  <title>Foundry prior-authorization enterprise assurance walkthrough</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="styles.css">
  <style>
    :root{{--walk-accent:#6ee7ff;--walk-success:#6ee7a5}}
    body.walkthrough-page{{background:#f4f7fc;color:#14213d}}
    .walk-shell{{display:grid;grid-template-columns:300px minmax(0,1fr);min-height:100vh}}
    .walk-sidebar{{position:sticky;top:0;height:100vh;overflow:auto;padding:24px;background:linear-gradient(165deg,#07125e,#111d71 62%,#3c2cda);color:#fff}}
    .walk-brand{{font-weight:800;font-size:1.1rem;letter-spacing:-.02em}}
    .walk-brand small{{display:block;margin-top:4px;color:#b9c8ff;font-weight:600;font-size:.72rem;text-transform:uppercase;letter-spacing:.12em}}
    .progress-card{{margin:24px 0 18px;padding:16px;border:1px solid rgba(255,255,255,.2);border-radius:16px;background:rgba(255,255,255,.08)}}
    .progress-line{{height:9px;border-radius:99px;background:rgba(255,255,255,.18);overflow:hidden;margin:10px 0}}
    #walkProgress{{display:block;height:100%;width:0;background:linear-gradient(90deg,#6ee7ff,#6ee7a5);transition:width .2s ease}}
    .progress-meta{{display:flex;justify-content:space-between;font-size:.78rem;color:#d9e3ff}}
    .walk-tools{{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-bottom:18px}}
    .walk-tools button,.walk-tools a{{border:1px solid rgba(255,255,255,.24);border-radius:10px;background:rgba(255,255,255,.09);color:#fff;padding:9px;text-align:center;text-decoration:none;font:inherit;font-size:.76rem;cursor:pointer}}
    .walk-search{{width:100%;padding:10px 12px;border:1px solid rgba(255,255,255,.24);border-radius:10px;background:rgba(255,255,255,.1);color:#fff;font:inherit;margin-bottom:14px}}
    .walk-search::placeholder{{color:#cbd5f7}}
    .walk-nav{{display:flex;flex-direction:column;gap:2px}}
    .walk-nav a{{color:#dbe4ff;text-decoration:none;padding:7px 9px;border-radius:8px;font-size:.76rem;line-height:1.3}}
    .walk-nav a:hover,.walk-nav a:focus-visible{{background:rgba(255,255,255,.12);color:#fff}}
    .walk-main{{min-width:0}}
    .walk-hero{{padding:42px clamp(24px,5vw,72px);background:linear-gradient(135deg,#07125e,#3c2cda);color:#fff}}
    .walk-hero .eyebrow{{color:#8feaff}}
    .walk-hero h1{{font-size:clamp(2rem,4vw,4rem);max-width:980px;margin:10px 0 14px;letter-spacing:-.045em}}
    .walk-hero p{{max-width:880px;color:#dce5ff;font-size:1.02rem;line-height:1.7}}
    .walk-callout{{display:flex;gap:12px;flex-wrap:wrap;margin-top:20px}}
    .walk-chip{{border:1px solid rgba(255,255,255,.23);background:rgba(255,255,255,.09);padding:8px 11px;border-radius:999px;font-size:.76rem}}
    .walk-content{{max-width:1120px;margin:0 auto;padding:38px clamp(20px,4vw,64px) 100px}}
    .walk-content h1{{display:none}}
    .walk-content h2{{margin:58px 0 18px;padding:22px 24px;border-radius:18px;background:linear-gradient(135deg,#07125e,#2820a7);color:#fff;font-size:1.55rem;box-shadow:0 12px 30px rgba(7,18,94,.16)}}
    .walk-content h3{{margin:32px 0 10px;color:#07125e;font-size:1.15rem}}
    .walk-content h4{{margin:24px 0 8px;color:#263363}}
    .anchor{{opacity:0;margin-left:8px;color:inherit;text-decoration:none;font-size:.8em}}
    h2:hover .anchor,h3:hover .anchor,.anchor:focus{{opacity:.6}}
    .walk-content p,.walk-content li{{line-height:1.68}}
    .walk-content blockquote{{margin:22px 0;padding:18px 20px;border-left:4px solid #3c2cda;background:#eef1ff;border-radius:0 14px 14px 0;font-weight:650;color:#151f61}}
    .walk-content pre{{overflow:auto;padding:18px;border-radius:14px;background:#07102f;color:#e6edff;box-shadow:inset 0 0 0 1px rgba(255,255,255,.08)}}
    .walk-content code{{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.9em}}
    .walk-content p code,.walk-content li code,.walk-content td code{{background:#e9edfb;color:#202b74;padding:2px 5px;border-radius:5px}}
    .table-wrap{{overflow:auto;margin:18px 0;border:1px solid #dae1f0;border-radius:14px;background:#fff;box-shadow:0 8px 24px rgba(16,32,83,.06)}}
    .walk-content table{{width:100%;border-collapse:collapse;min-width:680px}}
    .walk-content th{{background:#eef2fb;color:#07125e;text-align:left;font-size:.78rem;text-transform:uppercase;letter-spacing:.04em}}
    .walk-content th,.walk-content td{{padding:12px 14px;border-bottom:1px solid #e6ebf4;vertical-align:top}}
    .walk-content ul,.walk-content ol{{padding-left:25px}}
    .check-item{{list-style:none;margin:8px 0 8px -25px;padding:0}}
    .check-item label{{display:flex;gap:12px;align-items:flex-start;padding:11px 13px;border:1px solid #dce3f1;border-radius:11px;background:#fff;box-shadow:0 3px 12px rgba(16,32,83,.04);cursor:pointer}}
    .check-item input{{flex:0 0 auto;width:19px;height:19px;margin-top:3px;accent-color:#3c2cda}}
    .check-item input:checked+span{{text-decoration:line-through;color:#67718d}}
    .walk-content a{{color:#2c36bf}}
    .no-results{{display:none;padding:20px;border:1px dashed #aeb8d1;border-radius:12px;color:#5d6681}}
    .match-hide{{display:none!important}}
    .walk-footer{{padding:24px;text-align:center;color:#68728d;font-size:.78rem}}
    @media(max-width:960px){{.walk-shell{{display:block}}.walk-sidebar{{position:relative;height:auto}}.walk-nav{{display:none}}.walk-tools{{grid-template-columns:repeat(3,1fr)}}}}
    @media(max-width:600px){{.walk-hero{{padding:30px 20px}}.walk-content{{padding:24px 15px 80px}}.walk-content h2{{margin-top:42px;padding:18px;font-size:1.25rem}}.walk-tools{{grid-template-columns:1fr 1fr}}}}
    @media print{{.walk-sidebar,.walk-tools,.walk-search{{display:none!important}}.walk-shell{{display:block}}.walk-hero{{color:#000;background:#fff;padding:20px 0}}.walk-hero p{{color:#222}}.walk-content{{max-width:none;padding:0}}.walk-content h2{{color:#000;background:#eee;box-shadow:none;break-after:avoid}}.check-item label{{box-shadow:none}}a{{color:#000!important;text-decoration:none}}}}
  </style>
</head>
<body class="walkthrough-page">
<a class="skip-link" href="#main">Skip to walkthrough</a>
<div class="walk-shell">
  <aside class="walk-sidebar" aria-label="Walkthrough controls and sections">
    <div class="walk-brand">Clearway Assurance<small>Foundry build guide</small></div>
    <div class="progress-card" aria-live="polite">
      <strong id="progressLabel">0% complete</strong>
      <div class="progress-line" aria-hidden="true"><span id="walkProgress"></span></div>
      <div class="progress-meta"><span id="progressCount">0 / 0 controls</span><span>saved locally</span></div>
    </div>
    <div class="walk-tools">
      <a href="index.html">Demo</a>
      <a href="foundry-prior-auth-reference-architecture.html">Architecture</a>
      <a href="enterprise-assurance-one-pager.html">One-pager</a>
      <button id="printWalk" type="button">Print</button>
      <button id="resetWalk" type="button">Reset</button>
    </div>
    <label class="sr-only" for="walkSearch">Search walkthrough</label>
    <input id="walkSearch" class="walk-search" type="search" placeholder="Search controls…">
    <nav class="walk-nav" aria-label="Walkthrough sections">{toc_html}</nav>
  </aside>
  <main class="walk-main" id="main">
    <header class="walk-hero">
      <div class="eyebrow">Cross-functional implementation system · Microsoft Foundry specific</div>
      <h1>Build enterprise assurance one verified control at a time.</h1>
      <p>This guide separates what Microsoft Foundry provides from what the application must own. Every phase ends with an artifact, a test, and a stop/go gate. Check a control only after you retain evidence that it works.</p>
      <div class="walk-callout">
        <span class="walk-chip">Synthetic data only</span><span class="walk-chip">No autonomous approval or denial</span><span class="walk-chip">Fail closed</span><span class="walk-chip">Human accountable</span>
      </div>
    </header>
    <article class="walk-content" id="walkContent">{body}<p id="noResults" class="no-results">No sections match that search.</p></article>
    <footer class="walk-footer">Internal implementation guide · public Hexaware-inspired visual treatment · not approved brand collateral or a production-readiness certification.</footer>
  </main>
</div>
<script src="walkthrough.js"></script>
</body>
</html>'''
OUTPUT.write_text(page, encoding="utf-8")
print(f"built {OUTPUT.name}: {len(page)} chars; {len(toc)} TOC links")

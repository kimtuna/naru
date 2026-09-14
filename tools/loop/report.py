#!/usr/bin/env python3
"""대시보드를 굽는다 — docs/index.html.

    python3 tools/loop/report.py

**바깥에서 볼 수 있는 유일한 창이다.** `.loop/` 안의 것들(results.json · spend.txt ·
STOPPED)은 gitignore 라 GitHub 에 안 올라간다. 그래서 이 스크립트가 **값을 페이지에
구워 넣는다** — 페이지는 아무것도 fetch 하지 않는다. 열면 그냥 보인다.

드라이버가 매 바퀴 끝에 부르고 커밋한다. 사람이 직접 불러도 된다.
"""
import html, json, os, re, subprocess, sys
from datetime import datetime

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(ROOT)
REPO = "https://github.com/kimtuna/naru/blob/master"


def read(path, default=""):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return default


def sh(*args):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        return ""


def esc(s):
    return html.escape(str(s), quote=True)


def inline(s):
    """`코드` 와 **굵게** 만 살린다. 일지가 마크다운으로 쓰여 있다."""
    s = html.escape(str(s), quote=False)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    return s


# ── 백로그 ───────────────────────────────────────────────────────────
def backlog():
    phases, cur = [], None
    for ln in read("docs/BACKLOG.md").splitlines():
        m = re.match(r"^## (P\d)\s*[—-]\s*(.*)$", ln)
        if m:
            cur = {"id": m.group(1), "title": m.group(2).strip(), "items": []}
            phases.append(cur)
            continue
        m = re.match(r"^- \[([ x])\] (.*)$", ln)
        if m and cur is not None:
            body = m.group(2)
            desc = body.split("| verify:")[0].strip()
            cur["items"].append({
                "done": m.group(1) == "x",
                "ask": "[ASK]" in desc,
                "desc": desc,
            })
    return phases


# ── 계약 ─────────────────────────────────────────────────────────────
def contract():
    rows, res = [], None
    try:
        res = json.loads(read(".loop/results.json"))
    except Exception:
        pass
    got = {c["id"]: c for c in res["criteria"]} if res else {}
    for ln in read(".loop/criteria.tsv").splitlines():
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        parts = ln.split("\t")
        if len(parts) < 3:
            continue
        cid, what, cmd = parts[0].strip(), parts[1].strip(), parts[2].strip()
        c = got.get(cid)
        rows.append({
            "id": cid, "what": what, "cmd": cmd,
            "ok": c.get("ok") if c else None,
            "evidence": (c.get("evidence") or []) if c else [],
        })
    armed = read(".loop/armed.sha256").strip()[:12]
    tampered = bool(res and res.get("armed_sha256") != res.get("current_sha256"))
    return rows, res, armed, tampered


# ── 일지 ─────────────────────────────────────────────────────────────
FIELDS = ["날짜", "결과", "문제", "원인", "고친 것", "바꾼 결정",
          "잰 값", "남긴 것", "채점", "비용", "커밋"]


def journal():
    text = read("docs/JOURNAL.md")
    text = text.split("\n---\n", 1)[-1]           # 「쓰는 법」 머리말을 버린다
    out = []
    for m in re.finditer(r"^## (.+?)$(.*?)(?=^## |\Z)", text, re.M | re.S):
        title, body = m.group(1).strip(), m.group(2)
        f = {}
        for k in FIELDS:
            # **줄 이름에 공백이 있다** (「고친 것」). `\S+?:` 로 끊으면 다음 줄을 못 만나
            # 절 끝까지 삼킨다 — 첫 판에 실제로 그렇게 뭉쳤다.
            v = re.search(r"^- %s:[ \t]*(.*?)(?=^- [^\n:]{1,12}:|\Z)" % re.escape(k),
                          body, re.M | re.S)
            if v:
                val = " ".join(x.strip() for x in v.group(1).splitlines()).strip()
                if val:
                    f[k] = val
        n = re.match(r"바퀴 (\d+)", title)
        out.append({"title": title, "n": int(n.group(1)) if n else None,
                    "human": n is None, "f": f})
    return out


# ── 렌더 ─────────────────────────────────────────────────────────────
def render():
    phases = backlog()
    rows, res, armed, tampered = contract()
    entries = journal()

    done = sum(1 for p in phases for i in p["items"] if i["done"])
    total = sum(len(p["items"]) for p in phases)
    spend = read(".loop/spend.txt", "0").strip() or "0"
    stopped = read(".loop/STOPPED").strip()
    # **「지금 돌고 있나」는 구운 페이지가 알 수 없다.** 드라이버가 이 스크립트를
    # 부르는 시점엔 드라이버 자신이 살아 있어서 늘 「돌고 있다」로 굳었고,
    # 바로 뒤에 루프가 끝나도 페이지는 영영 그대로였다. 잰 것만 적는다 —
    # **마지막 바퀴가 몇 번이고 어떻게 끝났나.**
    last = next((e for e in entries if not e["human"]), None)

    all_green = res.get("all_green") if res else None
    graded_at = res.get("ts", "") if res else ""

    # 다음 항목
    nxt = next((i for p in phases for i in p["items"] if not i["done"]), None)
    nxt_phase = next((p["id"] for p in phases for i in p["items"]
                      if not i["done"] and i is nxt), "")

    if last:
        lr = last["f"].get("결과", "")
        st_cls = {"초록": "run", "빨강": "halt"}.get(lr, "idle")
        st_txt = f'바퀴 {last["n"]}'
        st_note = f'{lr or "—"} · {last["f"].get("날짜", "")}'
    else:
        st_cls, st_txt, st_note = "idle", "—", "아직 없다"

    P = []
    A = P.append
    A(HEAD)
    A('<body><div class="wrap">')

    # ── 헤더 ──
    A(f'''<header>
  <div class="brand"><span class="logo">🌾</span>
    <div><h1>나루 · Naru</h1>
      <p class="sub">루프 대시보드 — 굽힌 시각 {esc(datetime.now().strftime("%Y-%m-%d %H:%M"))}</p></div>
  </div>
  <nav><a href="{REPO}/docs/">문서</a><a href="https://github.com/kimtuna/naru">GitHub</a></nav>
</header>''')

    # ── 상태 스트립 ──
    green_txt = "—" if all_green is None else ("ALL GREEN" if all_green else "빨강")
    green_cls = "muted" if all_green is None else ("ok" if all_green else "bad")
    A('<section class="strip">')
    A(f'<div class="tile"><span class="k">마지막 바퀴</span>'
      f'<span class="v"><i class="dot {st_cls}"></i>{esc(st_txt)}</span>'
      f'<span class="note">{esc(st_note)}</span></div>')
    A(f'<div class="tile"><span class="k">계약</span>'
      f'<span class="v {green_cls}">{esc(green_txt)}</span>'
      f'<span class="note">{esc(graded_at[:16].replace("T", " "))}</span></div>')
    A(f'<div class="tile"><span class="k">진행</span>'
      f'<span class="v">{done} <small>/ {total}</small></span>'
      f'<span class="note">백로그 항목</span></div>')
    A(f'<div class="tile"><span class="k">누적 비용</span>'
      f'<span class="v">${esc(spend)}</span></div>')
    A('</section>')

    if tampered:
        A('<div class="alert bad"><strong>계약이 무장 뒤에 변조됐다.</strong> '
          '채점자가 <code>exit 77</code> 로 죽는다 — red line 이다.</div>')
    if stopped:
        parts = stopped.splitlines()
        when = parts[0] if parts else ""
        why = " ".join(parts[1:]) or "(사유 없음)"
        A(f'<div class="alert halt"><strong>멈춘 사유</strong> — {inline(why)}'
          f'<span class="note">{esc(when)}</span></div>')
    if nxt:
        tag = '<span class="pill ask">ASK</span>' if nxt["ask"] else \
              f'<span class="pill">{esc(nxt_phase)}</span>'
        A(f'<div class="alert next"><span class="k">다음 항목</span>{tag}{inline(nxt["desc"])}</div>')

    # ── 진행 ──
    A('<h2>진행 — 한 줄 = 한 바퀴</h2>')
    A('<div class="phases">')
    for p in phases:
        d = sum(1 for i in p["items"] if i["done"])
        t = len(p["items"])
        pct = round(d / t * 100) if t else 0
        cls = "full" if d == t and t else ("part" if d else "none")
        A(f'''<details class="phase {cls}"{" open" if 0 < d < t else ""}>
  <summary><span class="pid">{esc(p["id"])}</span>
    <span class="ptitle">{esc(p["title"])}</span>
    <span class="pcount">{d}/{t}</span>
    <span class="bar"><i style="width:{pct}%"></i></span></summary>
  <ul class="items">''')
        for i in p["items"]:
            mk = "done" if i["done"] else ("ask" if i["ask"] else "todo")
            box = "✔" if i["done"] else ("?" if i["ask"] else "")
            A(f'<li class="{mk}"><span class="box">{box}</span>{inline(i["desc"])}</li>')
        A('</ul></details>')
    A('</div>')

    # ── 계약 ──
    A(f'<h2>계약 — 기계가 채점한다 <span class="hash">무장 {esc(armed)}</span></h2>')
    A('<p class="lede">세션에게 「검사를 약하게 하지 마세요」라고 부탁하지 않는다. '
      '<code>criteria.tsv</code> 는 해시로 잠겨 있고, 고치면 채점자가 <code>exit 77</code> 로 죽는다.</p>')
    A('<div class="cards">')
    for r in rows:
        cls = "muted" if r["ok"] is None else ("ok" if r["ok"] else "bad")
        mark = "—" if r["ok"] is None else ("초록" if r["ok"] else "빨강")
        A(f'''<div class="card {cls}">
  <div class="chead"><span class="cid">{esc(r["id"])}</span>
    <span class="cwhat">{inline(r["what"])}</span>
    <span class="cmark">{mark}</span></div>
  <code class="cmd">{esc(r["cmd"])}</code>''')
        if r["evidence"]:
            A('<ul class="ev">' + "".join(f"<li>{esc(e)}</li>" for e in r["evidence"]) + "</ul>")
        A('</div>')
    A('</div>')

    # ── 일지 ──
    A('<h2>바퀴 일지 — 무엇이 막았고, 왜, 그래서 무엇을 바꿨나</h2>')
    A(f'<p class="lede">전체는 <a href="{REPO}/docs/JOURNAL.md">JOURNAL.md</a>. '
      '아래는 그 파일을 그대로 읽어 온 것이다.</p>')
    A('<div class="log">')
    for e in entries:
        f = e["f"]
        res_txt = f.get("결과", "")
        rcls = {"초록": "ok", "빨강": "bad", "멈춤": "halt"}.get(res_txt, "muted")
        badge = "사람" if e["human"] else f'바퀴 {e["n"]}'
        title = re.sub(r"^(바퀴 \d+|사람)\s*·\s*", "", e["title"])
        A(f'''<article class="entry {rcls}">
  <div class="ehead">
    <span class="badge {"human" if e["human"] else ""}">{esc(badge)}</span>
    <h3>{inline(title)}</h3>
    <span class="edate">{esc(f.get("날짜", ""))}</span>
    <span class="eres {rcls}">{esc(res_txt or "—")}</span>
  </div>''')
        if not e["human"] and not any(f.get(k) for k in ("문제", "원인", "고친 것")):
            # 빈 절을 조용히 넘기면 「문제 없는 바퀴」와 구별이 안 된다.
            A('<div class="row prob"><span class="k">일지</span>'
              '<span class="v"><strong>세션이 안 적었다.</strong> '
              '드라이버가 스텁만 찍었다 — 무엇이 막혔는지 남은 게 없다.</span></div>')
        for k, cls in (("문제", "prob"), ("원인", "cause"), ("고친 것", "fix"),
                       ("바꾼 결정", "decide"), ("남긴 것", "left")):
            if f.get(k) and f[k] != "없음":
                A(f'<div class="row {cls}"><span class="k">{esc(k)}</span>'
                  f'<span class="v">{inline(f[k])}</span></div>')
            elif f.get(k) == "없음":
                A(f'<div class="row none"><span class="k">{esc(k)}</span>'
                  f'<span class="v">없음</span></div>')
        if f.get("잰 값"):
            A(f'<div class="row meas"><span class="k">잰 값</span>'
              f'<span class="v">{inline(f["잰 값"])}</span></div>')
        foot = []
        if f.get("채점"):
            foot.append(f'<span class="grade">채점 {inline(f["채점"])}</span>')
        if f.get("비용"):
            foot.append(f'<span>{inline(f["비용"])}</span>')
        if f.get("커밋"):
            foot.append(f'<span>{inline(f["커밋"])}</span>')
        if foot:
            A('<div class="efoot">' + "".join(foot) + "</div>")
        A('</article>')
    A('</div>')

    # ── 문서 ──
    A('<h2>문서 — 누가 언제 읽나</h2>')
    A('<div class="docs">')
    for name, layer, when, why in DOCS:
        A(f'''<a class="doc" href="{REPO}/{name}">
  <span class="dname">{esc(name.split("/")[-1])}</span>
  <span class="dlayer l-{layer[0]}">{esc(layer[1])}</span>
  <span class="dwhen">{esc(when)}</span>
  <span class="dwhy">{inline(why)}</span></a>''')
    A('</div>')

    # ── 커밋 ──
    log = sh("git", "log", "-12", "--format=%h\t%ad\t%s", "--date=short")
    if log:
        A('<h2>최근 커밋</h2><ul class="commits">')
        for ln in log.splitlines():
            h, d, s = (ln.split("\t") + ["", ""])[:3]
            A(f'<li><a href="https://github.com/kimtuna/naru/commit/{esc(h)}">'
              f'<code>{esc(h)}</code></a><span class="cd">{esc(d)}</span>{inline(s)}</li>')
        A('</ul>')

    A('<footer><strong>이 페이지는 스냅샷이다.</strong> '
      '<code>tools/loop/report.py</code> 가 구운 시점의 값이 박혀 있고 '
      '아무것도 fetch 하지 않는다 — <code>.loop/</code> 는 <code>.gitignore</code> 라 '
      '바깥에서 읽을 방법이 없다. 드라이버가 <strong>초록으로 닫힌 바퀴</strong>마다 '굽고 커밋하고 푸시한다 — 빨간 상태는 안 나간다.</footer>')
    A('</div></body></html>')
    return "\n".join(P)


DOCS = [
    ("CLAUDE.md", ("fix", "고정"), "매 바퀴 · 자동 로드",
     "이 기계에서 **무엇을 어떤 명령으로** 돌리는가만. 부풀면 문맥이 오염된다"),
    ("docs/PROMPT.md", ("inj", "주입"), "매 바퀴 · 드라이버가 넣는다",
     "한 바퀴 4단계 · 정지 규칙 6개 · red lines. **세션은 이 파일을 열지 않는다**"),
    ("docs/BACKLOG.md", ("inj", "주입"), "매 바퀴 · 한 줄만",
     "할 일. **한 줄 = 한 바퀴.** 순서는 종속성이지 중요도가 아니다"),
    ("docs/NUMBERS.md", ("cond", "조건부"), "값을 쓸 때 · 그 절만",
     "실측값. **잰 조건을 같이 적는다** — 「passed」는 증거가 아니다"),
    ("docs/GOTCHAS.md", ("cond", "조건부"), "에러가 났을 때만 · grep",
     "엔진·셸의 함정. 조건부라서 **의도적으로 계속 쌓는다**"),
    ("docs/GDD.md", ("cond", "조건부"), "그 영역을 처음 만들 때만",
     "게임 기획서 — 「왜」. **매 바퀴 읽지 않는다.** 세션이 못 고친다"),
    ("docs/JOURNAL.md", ("roll", "사람"), "세션은 안 읽는다",
     "바퀴 일지. **무엇이 막았고 왜 그랬고 그래서 무엇을 바꿨나**"),
]

HEAD = """<!doctype html>
<html lang="ko"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>나루 · 루프 대시보드</title>
<style>
:root{
  --bg:#faf9f7; --panel:#fff; --line:#e6e2db; --ink:#1c1a17; --dim:#6b655c;
  --faint:#948d82; --ok:#2f7d4f; --okbg:#e9f5ee; --bad:#b3402c; --badbg:#fbebe7;
  --halt:#9a6b12; --haltbg:#fbf2df; --accent:#3b6ea5; --code:#f2efe9;
}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){
  --bg:#14130f; --panel:#1c1a16; --line:#2f2c26; --ink:#eae5dc; --dim:#a09889;
  --faint:#7a7266; --ok:#6bbd8a; --okbg:#16281d; --bad:#e08a75; --badbg:#2b1a15;
  --halt:#d6ad5c; --haltbg:#2a2114; --accent:#7fb0e0; --code:#24211b;
}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);
  font:15px/1.65 -apple-system,BlinkMacSystemFont,"Pretendard","Apple SD Gothic Neo",
  "Noto Sans KR",Segoe UI,sans-serif;-webkit-font-smoothing:antialiased}
code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.86em;
  background:var(--code);padding:.1em .38em;border-radius:4px;word-break:break-word}
a{color:var(--accent);text-decoration:none}
a:hover{text-decoration:underline}
.wrap{max-width:1000px;margin:0 auto;padding:32px 20px 80px}
header{display:flex;flex-wrap:wrap;gap:16px;align-items:center;justify-content:space-between;
  padding-bottom:22px;border-bottom:1px solid var(--line);margin-bottom:26px}
.brand{display:flex;gap:14px;align-items:center}
.logo{font-size:34px;line-height:1}
h1{margin:0;font-size:23px;letter-spacing:-.3px}
.sub{margin:2px 0 0;color:var(--faint);font-size:12.5px}
nav{display:flex;gap:8px;flex-wrap:wrap}
nav a{font-size:13px;padding:6px 12px;border:1px solid var(--line);border-radius:999px;color:var(--dim)}
h2{font-size:16.5px;margin:44px 0 6px;letter-spacing:-.2px;display:flex;
  align-items:baseline;gap:10px;flex-wrap:wrap}
.hash{font-size:11px;color:var(--faint);font-family:ui-monospace,monospace;font-weight:400}
.lede{margin:0 0 16px;color:var(--dim);font-size:13.5px}

.strip{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px}
.tile{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:14px 16px}
.tile .k{display:block;font-size:11.5px;color:var(--faint);letter-spacing:.3px}
.tile .v{display:flex;align-items:center;gap:7px;font-size:19px;font-weight:650;margin-top:3px}
.tile .v small{font-size:13px;font-weight:400;color:var(--faint)}
.tile .note{display:block;font-size:11px;color:var(--faint);margin-top:2px}
.ok{color:var(--ok)} .bad{color:var(--bad)} .muted{color:var(--faint)}
.dot{width:9px;height:9px;border-radius:50%;display:inline-block;flex:none}
.dot.run{background:var(--ok);box-shadow:0 0 0 3px var(--okbg)}
.dot.halt{background:var(--halt);box-shadow:0 0 0 3px var(--haltbg)}
.dot.idle{background:var(--faint)}

.alert{margin-top:12px;padding:12px 15px;border-radius:10px;border:1px solid var(--line);
  background:var(--panel);font-size:13.5px;display:flex;gap:10px;align-items:baseline;flex-wrap:wrap}
.alert.bad{border-color:var(--bad);background:var(--badbg)}
.alert.halt{border-color:var(--halt);background:var(--haltbg)}
.alert.next{border-style:dashed}
.alert .k{font-size:11.5px;color:var(--faint);letter-spacing:.3px}
.alert .note{margin-left:auto;font-size:11px;color:var(--faint);font-family:ui-monospace,monospace}
.pill{font-size:11px;font-weight:700;padding:2px 8px;border-radius:999px;
  background:var(--code);color:var(--dim)}
.pill.ask{background:var(--haltbg);color:var(--halt)}

.phases{display:flex;flex-direction:column;gap:8px}
.phase{background:var(--panel);border:1px solid var(--line);border-radius:11px;overflow:hidden}
.phase summary{display:grid;grid-template-columns:34px 1fr auto;gap:10px;align-items:center;
  padding:12px 15px;cursor:pointer;list-style:none}
.phase summary::-webkit-details-marker{display:none}
.pid{font-weight:800;font-size:12.5px;color:var(--faint);font-family:ui-monospace,monospace}
.ptitle{font-size:14px;font-weight:600}
.pcount{font-size:12px;color:var(--faint);font-family:ui-monospace,monospace}
.bar{grid-column:1/-1;height:4px;background:var(--code);border-radius:3px;overflow:hidden}
.bar i{display:block;height:100%;background:var(--ok);border-radius:3px}
.phase.none .bar i{background:var(--faint)}
.items{margin:0;padding:2px 15px 14px 15px;list-style:none;border-top:1px solid var(--line)}
.items li{display:flex;gap:10px;padding:6px 0;font-size:13.5px;color:var(--dim);
  border-bottom:1px dotted var(--line)}
.items li:last-child{border-bottom:0}
.items .box{width:16px;flex:none;text-align:center;font-size:11.5px;color:var(--faint)}
.items li.done{color:var(--ink)}
.items li.done .box{color:var(--ok)}
.items li.ask .box{color:var(--halt);font-weight:800}

.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:10px}
.card{background:var(--panel);border:1px solid var(--line);border-left-width:3px;
  border-radius:10px;padding:12px 14px}
.card.ok{border-left-color:var(--ok)}
.card.bad{border-left-color:var(--bad);background:var(--badbg)}
.card.muted{border-left-color:var(--faint)}
.chead{display:flex;gap:9px;align-items:baseline}
.cid{font-family:ui-monospace,monospace;font-size:11.5px;color:var(--faint);font-weight:700}
.cwhat{flex:1;font-size:13.5px;font-weight:600;line-height:1.45}
.cmark{font-size:11.5px;font-weight:700}
.card.ok .cmark{color:var(--ok)} .card.bad .cmark{color:var(--bad)}
.cmd{display:block;margin:8px 0 0;font-size:11.5px;color:var(--dim);background:transparent;padding:0}
.ev{margin:7px 0 0;padding:7px 0 0 0;list-style:none;border-top:1px dotted var(--line)}
.ev li{font-family:ui-monospace,monospace;font-size:11.5px;color:var(--dim);padding:1px 0}

.log{display:flex;flex-direction:column;gap:12px}
.entry{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:14px 16px}
.entry.bad{border-color:var(--bad)}
.ehead{display:flex;gap:10px;align-items:baseline;flex-wrap:wrap;margin-bottom:10px}
.badge{font-family:ui-monospace,monospace;font-size:11px;font-weight:700;padding:3px 9px;
  border-radius:999px;background:var(--code);color:var(--dim);flex:none}
.badge.human{background:var(--haltbg);color:var(--halt)}
.ehead h3{margin:0;font-size:14.5px;font-weight:650;flex:1;min-width:180px;line-height:1.45}
.edate{font-size:11px;color:var(--faint);font-family:ui-monospace,monospace}
.eres{font-size:11.5px;font-weight:700}
.eres.ok{color:var(--ok)} .eres.bad{color:var(--bad)} .eres.halt{color:var(--halt)}
.row{display:grid;grid-template-columns:64px 1fr;gap:12px;padding:5px 0;font-size:13.5px;
  border-top:1px dotted var(--line)}
.row .k{font-size:11.5px;color:var(--faint);padding-top:3px;letter-spacing:.2px}
.row.prob .k{color:var(--bad)}
.row.fix .k{color:var(--ok)}
.row.decide .k{color:var(--halt)}
.row.none .v{color:var(--faint)}
.row.meas .v{font-family:ui-monospace,monospace;font-size:11.8px;color:var(--dim);line-height:1.7}
.efoot{margin-top:10px;padding-top:9px;border-top:1px solid var(--line);display:flex;
  gap:14px;flex-wrap:wrap;font-size:11px;color:var(--faint);font-family:ui-monospace,monospace}
.efoot .grade{flex:1;min-width:200px}

.docs{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:10px}
.doc{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:12px 14px;
  display:grid;gap:3px;color:inherit}
.doc:hover{border-color:var(--accent);text-decoration:none}
.dname{font-family:ui-monospace,monospace;font-size:13px;font-weight:700;color:var(--accent)}
.dlayer{justify-self:start;font-size:10.5px;font-weight:700;padding:1px 7px;border-radius:999px;
  background:var(--code);color:var(--dim)}
.dlayer.l-f{background:var(--badbg);color:var(--bad)}
.dlayer.l-i{background:var(--okbg);color:var(--ok)}
.dlayer.l-c{background:var(--haltbg);color:var(--halt)}
.dwhen{font-size:11px;color:var(--faint);font-family:ui-monospace,monospace}
.dwhy{font-size:12.5px;color:var(--dim);line-height:1.55;margin-top:2px}

.commits{list-style:none;margin:0;padding:0}
.commits li{display:flex;gap:12px;align-items:baseline;padding:6px 0;font-size:13px;
  border-bottom:1px dotted var(--line);color:var(--dim)}
.commits .cd{font-size:11px;color:var(--faint);font-family:ui-monospace,monospace;flex:none}
footer{margin-top:56px;padding-top:18px;border-top:1px solid var(--line);
  font-size:11.5px;color:var(--faint)}
@media(max-width:560px){
  .wrap{padding:22px 16px 60px}
  .row{grid-template-columns:1fr;gap:1px}
  .phase summary{grid-template-columns:28px 1fr auto}
  .commits li{flex-wrap:wrap;gap:8px}
}
</style></head>"""

if __name__ == "__main__":
    out = render()
    os.makedirs("docs", exist_ok=True)
    open("docs/index.html", "w", encoding="utf-8").write(out)
    open("docs/.nojekyll", "w").close()
    print(f"REPORT docs/index.html {len(out.encode()):,}바이트")

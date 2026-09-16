#!/usr/bin/env python3
"""loop.sh 의 도우미. list.md 파싱 · current.md 생성 · decisions.md 기록 · 대시보드 데이터.

Claude 세션은 이 파일을 쓰지 않는다. loop.sh 만 부른다.
python3 3.9 (macOS 기본) 에서 돌아야 한다.
"""
import datetime
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOOP = os.path.join(ROOT, ".loop")
LIST = os.path.join(ROOT, "list.md")
DECISIONS = os.path.join(ROOT, "decisions.md")
CURRENT = os.path.join(ROOT, "current.md")
DATA = os.path.join(LOOP, "data")  # publish 가 대시보드 워크트리로 복사한다
KST = datetime.timezone(datetime.timedelta(hours=9))

DOC_LIMIT = 150
MARKER = "사람 결정"

GROUP_RE = re.compile(r"^## \[( |x|>)\] (\S+)\s+(.*)$")
STEP_RE = re.compile(r"^- \[( |x)\] (\d+)\.\s+(.*)$")
SUB_RE = re.compile(r"^\s+- (.*)$")
META_RE = re.compile(r"^- (?!\[)(.*)$")


def now():
    return datetime.datetime.now(KST)


def stamp(t=None):
    return (t or now()).strftime("%Y-%m-%d %H:%M:%S KST")


def read(path, default=""):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return default


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, path)


def load_json(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, ValueError):
        return default


def save_json(path, obj):
    write(path, json.dumps(obj, ensure_ascii=False, indent=1))


# ---------------------------------------------------------------- list.md

def parse_list():
    """list.md → 묶음 목록. 각 줄 번호를 기억해서 체크 표시를 제자리에 고친다."""
    lines = read(LIST).split("\n")
    groups, g, step = [], None, None
    for i, line in enumerate(lines):
        m = GROUP_RE.match(line)
        if m:
            g = {"state": m.group(1), "id": m.group(2), "title": m.group(3).strip(),
                 "line": i, "end": i, "meta": [], "steps": []}
            groups.append(g)
            step = None
            continue
        if line.startswith("#"):
            g, step = None, None
            continue
        if g is None:
            continue
        if line.strip():
            g["end"] = i
        m = STEP_RE.match(line)
        if m:
            step = {"done": m.group(1) == "x", "n": int(m.group(2)),
                    "title": m.group(3).strip(), "line": i, "criteria": [], "notes": []}
            g["steps"].append(step)
            continue
        m = SUB_RE.match(line)
        if m and step is not None:
            text = m.group(1).strip()
            if text.startswith("기준:"):
                step["criteria"].append(text[3:].strip())
            else:
                step["notes"].append(text)
            continue
        m = META_RE.match(line)
        if m and step is None:
            g["meta"].append(m.group(1).strip())
    return lines, groups


def find_group(groups, gid):
    for g in groups:
        if g["id"] == gid:
            return g
    raise SystemExit("묶음 없음: " + gid)


def cmd_next(_args):
    _, groups = parse_list()
    for g in groups:
        if g["state"] != " ":
            continue
        todo = [s for s in g["steps"] if not s["done"]]
        out = {"group": g["id"], "title": g["title"], "total": len(g["steps"])}
        if not g["steps"]:
            out["error"] = "단계가 없는 묶음"
        elif todo:
            out.update(step=todo[0]["n"], step_title=todo[0]["title"])
        else:
            out["complete"] = True
        print(json.dumps(out, ensure_ascii=False))
        return
    # 비어 있으면 아무것도 출력하지 않는다 → 목록 완료


def cmd_mark_step(args):
    gid, n = args[0], int(args[1])
    lines, groups = parse_list()
    for s in find_group(groups, gid)["steps"]:
        if s["n"] == n:
            lines[s["line"]] = lines[s["line"]].replace("- [ ]", "- [x]", 1)
    write(LIST, "\n".join(lines))


def cmd_mark_group(args):
    gid, mark = args[0], args[1]
    lines, groups = parse_list()
    g = find_group(groups, gid)
    lines[g["line"]] = "## [%s] %s %s" % (mark, g["id"], g["title"])
    write(LIST, "\n".join(lines))


def group_block(lines, g):
    return "\n".join(lines[g["line"]:g["end"] + 1])


def cmd_current(args):
    """current.md — 구현·QA 세션이 읽는 유일한 할 일 문서."""
    gid, n, attempt, feedback_path = args[0], int(args[1]), int(args[2]), args[3]
    _, groups = parse_list()
    g = find_group(groups, gid)
    step = [s for s in g["steps"] if s["n"] == n][0]
    out = ["# 지금 할 일 — %s %s · %d/%d단계 · 시도 %d"
           % (g["id"], g["title"], n, len(g["steps"]), attempt), ""]
    if g["meta"]:
        out += ["## 묶음 정보"] + ["- " + m for m in g["meta"]] + [""]
    out.append("## 묶음 전체 (위 단계는 이미 통과해 커밋되어 있다)")
    for s in g["steps"]:
        mark = "x" if s["done"] else " "
        here = "  ← 지금" if s["n"] == n else ""
        out.append("- [%s] %d. %s%s" % (mark, s["n"], s["title"], here))
    out += ["", "## 이번 단계: %d. %s" % (n, step["title"])]
    if step["notes"]:
        out += ["- " + x for x in step["notes"]]
    out += ["", "### 수용 기준 (바꾸지 마라)"]
    out += ["- " + c for c in step["criteria"]] or ["- (없음 — 단계 제목을 기준으로 삼는다)"]
    fb = read(feedback_path).strip() if feedback_path != "-" else ""
    if fb:
        out += ["", "## 이전 시도에서 받은 피드백 — 이것부터 해결하라", fb]
    if attempt >= 4:
        out += ["", "## 전략 전환",
                "같은 방법이 %d번 통과하지 못했다. 워킹트리를 마지막 통과 상태로 되돌려 두었다."
                % (attempt - 1),
                "앞의 방법을 반복하지 말고 다른 접근을 골라라. 왜 바꿨는지 report 의 why 에 적어라."]
    write(CURRENT, "\n".join(out) + "\n")


# ---------------------------------------------------------------- decisions.md

def cmd_decide(args):
    gid, reason, n, report_path, branch = args[:5]
    lines, groups = parse_list()
    g = find_group(groups, gid)
    rep = load_json(report_path, {}) if report_path != "-" else {}
    d = rep.get("decision") or {}
    passed = [s for s in g["steps"] if s["done"]]
    step = [s for s in g["steps"] if s["n"] == int(n)]
    out = ["", "## %s %s — %s" % (g["id"], g["title"], stamp()),
           "- 이유: " + reason,
           "- 멈춘 단계: " + ("%d. %s" % (step[0]["n"], step[0]["title"]) if step else n),
           "- 통과해 둔 단계: " + (", ".join(str(s["n"]) for s in passed) or "없음"),
           "- 브랜치: `%s` (통과한 단계와 작업 흔적이 여기 보존됨)" % branch]
    if d.get("question"):
        out += ["", "### 질문", d["question"]]
        if d.get("context"):
            out += ["", d["context"]]
        opts = d.get("options") or []
        if opts:
            out += ["", "### 선택지"]
            for i, o in enumerate(opts, 1):
                if isinstance(o, dict):
                    out.append("%d. **%s** — %s" % (i, o.get("label", ""), o.get("detail", "")))
                else:
                    out.append("%d. %s" % (i, o))
        if d.get("recommend"):
            out += ["", "### 추천", d["recommend"]]
    elif rep.get("problem"):
        out += ["", "### 막힌 내용", rep["problem"]]
    extra = read(args[5]).strip() if len(args) > 5 and args[5] != "-" else ""
    if extra:
        out += ["", "### 마지막 피드백", extra]
    out += ["", "### 묶음 원문", "```", group_block(lines, g), "```",
            "", "- **답:** (여기에 적거나 대화에서 알려 주세요)"]
    text = read(DECISIONS) or "# 결정 대기\n\n루프가 사람 선택이 필요하거나 풀지 못해서 넘긴 묶음.\n"
    write(DECISIONS, text.rstrip("\n") + "\n" + "\n".join(out) + "\n")


# ---------------------------------------------------------------- 문서 길이

def doc_files():
    files = [os.path.join(ROOT, "prompt.md"), os.path.join(ROOT, "qa.md")]
    for base, _, names in os.walk(os.path.join(ROOT, "spec")):
        files += [os.path.join(base, n) for n in names if n.endswith(".md")]
    return [f for f in files if os.path.exists(f)]


def cmd_doccheck(_args):
    """150줄을 넘는 문서마다 정리 묶음을 다음 할 일 앞에 끼워 넣는다."""
    lines, groups = parse_list()
    queued = {g["title"] for g in groups if g["state"] == " "}
    todo = [g for g in groups if g["state"] == " "]
    insert_at = todo[0]["line"] if todo else len(lines)
    new = []
    for f in doc_files():
        rel = os.path.relpath(f, ROOT)
        count = len(read(f).split("\n"))
        title = "문서 정리: " + rel
        if count <= DOC_LIMIT or title in queued:
            continue
        slug = re.sub(r"[^A-Za-z0-9]+", "-", rel).strip("-")
        markers = [l for l in read(f).split("\n") if MARKER in l]
        save_json(os.path.join(LOOP, "tidy", slug + ".json"), {"file": rel, "markers": markers})
        new += ["## [ ] T-%s %s" % (slug, title),
                "- 자동 추가: %s 에 %d줄 (한도 %d)" % (stamp(), count, DOC_LIMIT),
                "- [ ] 1. %s 를 %d줄 이하로 정리" % (rel, DOC_LIMIT),
                "  - 중복·낡은 내용을 지우고 구성을 바꾼다. 필요하면 같은 폴더의 새 파일로 나눈다",
                "  - 기준: %s 가 %d줄 이하" % (rel, DOC_LIMIT),
                "  - 기준: `%s` 표시가 붙은 줄은 하나도 사라지지 않는다 (다른 spec 파일로 옮기는 것은 된다)" % MARKER,
                "  - 기준: 나눴다면 spec/README.md 목록에 반영", ""]
        print(rel)
    if new:
        lines[insert_at:insert_at] = new
        write(LIST, "\n".join(lines))


def cmd_tidygate(args):
    """정리 묶음의 기계 판정. 실패 사유를 출력하고 1 로 끝난다."""
    slug = args[0][2:]
    info = load_json(os.path.join(LOOP, "tidy", slug + ".json"), None)
    if not info:
        return
    bad = []
    count = len(read(os.path.join(ROOT, info["file"])).split("\n"))
    if count > DOC_LIMIT:
        bad.append("%s 가 아직 %d줄" % (info["file"], count))
    spec = "\n".join(read(f) for f in doc_files())
    for m in info["markers"]:
        core = m.strip().lstrip("-*|# ").strip()
        if core and core not in spec:
            bad.append("사람 결정 줄이 사라짐: " + core)
    if bad:
        print("\n".join(bad))
        sys.exit(1)


# ---------------------------------------------------------------- 대시보드

def progress():
    _, groups = parse_list()
    steps = [s for g in groups for s in g["steps"]]
    return {
        "groups_total": len(groups),
        "groups_done": sum(g["state"] == "x" for g in groups),
        "groups_waiting": sum(g["state"] == ">" for g in groups),
        "steps_total": len(steps),
        "steps_done": sum(s["done"] for s in steps),
    }


def kv(args):
    out = {}
    for a in args:
        k, _, v = a.partition("=")
        out[k] = v
    return out


def cmd_status(args):
    """status.json 을 갱신한다. 인자 key=value 는 덮어쓴다."""
    path = os.path.join(DATA, "status.json")
    st = load_json(path, {})
    st.update(kv(args))
    st["updated"] = stamp()
    st["updated_epoch"] = int(now().timestamp())
    st["progress"] = progress()
    save_json(path, st)


def cmd_event(args):
    """events.json 에 기록 한 줄. --report / --qa / --test 는 파일을 읽어 붙인다."""
    ev = {"time": stamp(), "epoch": int(now().timestamp())}
    rest = []
    it = iter(args)
    for a in it:
        if a in ("--report", "--qa", "--test"):
            path = next(it)
            if a == "--test":
                t = read(path).strip()
                if t:
                    ev["test"] = t[-3000:]
            else:
                obj = load_json(path, None)
                if obj is not None:
                    ev[a[2:]] = obj
        else:
            rest.append(a)
    ev.update(kv(rest))
    path = os.path.join(DATA, "events.json")
    events = load_json(path, [])
    events.append(ev)
    save_json(path, events)


# ---------------------------------------------------------------- 토큰 한도

def cmd_reset_epoch(args):
    """한도 메시지에서 재개 시각(epoch)을 뽑는다. 못 뽑으면 30분 뒤."""
    text = read(args[0]) + read(args[1] if len(args) > 1 else "")
    t = now()
    buf = int(os.environ.get("NARU_LIMIT_BUFFER", "120"))
    m = re.search(r"\|(\d{10})\b", text)
    if m:
        print(int(m.group(1)) + buf)
        return
    m = re.search(r"reset[s]?\s*(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*([ap]m)", text, re.I)
    if m:
        h, mi = int(m.group(1)) % 12, int(m.group(2) or 0)
        if m.group(3).lower() == "pm":
            h += 12
        target = t.replace(hour=h, minute=mi, second=0, microsecond=0)
        if target <= t:
            target += datetime.timedelta(days=1)
        print(int(target.timestamp()) + buf)
        return
    print(int(t.timestamp()) + 1800)


def cmd_hhmm(args):
    print(datetime.datetime.fromtimestamp(int(args[0]), KST).strftime("%m-%d %H:%M"))


def cmd_get(args):
    """json 파일에서 키 하나 (없으면 빈 줄)."""
    obj = load_json(args[0], {})
    for k in args[1].split("."):
        obj = obj.get(k, "") if isinstance(obj, dict) else ""
    print(obj if not isinstance(obj, bool) else str(obj).lower())


COMMANDS = {
    "next": cmd_next, "mark-step": cmd_mark_step, "mark-group": cmd_mark_group,
    "current": cmd_current, "decide": cmd_decide, "doccheck": cmd_doccheck,
    "tidygate": cmd_tidygate, "status": cmd_status, "event": cmd_event,
    "reset-epoch": cmd_reset_epoch, "hhmm": cmd_hhmm, "get": cmd_get,
}

if __name__ == "__main__":
    COMMANDS[sys.argv[1]](sys.argv[2:])

# gen_input_ini.py
# Tự động sinh input.ini từ bất kỳ file EA .mq5 nào
# Cách dùng: python gen_input_ini.py <đường_dẫn_EA.mq5>

import re
import sys
import os
import shutil
from pathlib import Path

if sys.stdout and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

DEFAULT_MT5_PROGRAM_PATH = r'C:\Program Files\MetaTrader 5\terminal64.exe'
SCRIPT_DIR = Path(__file__).resolve().parent

# ---- Cấu hình mặc định cho [Tester] ----
DEFAULT_TESTER = {
    "login":               "123456",
    "deposit":             "10000",
    "leverage":            "1:100",
    "model":               "4",
    "executionmode":       "1",
    "optimization":        "1",
    "optimizationcriterion": "6",
    "fromdate":            "0",
    "todate":              "2026.01.01",
    "replacereport":       "1",
    "shutdownterminal":    "1",
    "period":              "H1",
    "symbols":             "EURUSD, GBPUSD, USDJPY",
    "subfix":              "",
}


def find_includes(mq5_text, base_dir):
    """Tìm các file #include cục bộ (không phải thư viện chuẩn <...>)"""
    includes = []
    for m in re.finditer(r'#include\s+"([^"]+)"', mq5_text):
        path = base_dir / m.group(1)
        if path.exists():
            includes.append(path)
    return includes


def collect_source(mq5_path):
    """Gom toàn bộ source code từ file chính + các #include cục bộ"""
    mq5_path = Path(mq5_path)
    base_dir = mq5_path.parent
    visited = set()
    lines = []

    def load(p):
        p = p.resolve()
        if p in visited:
            return
        visited.add(p)
        try:
            text = p.read_text(encoding='utf-8', errors='replace')
        except Exception:
            return
        lines.append(text)
        for inc in find_includes(text, p.parent):
            load(inc)

    load(mq5_path)
    return "\n".join(lines)


def parse_inputs(source):
    """
    Parse các khai báo 'input <type> <name> = <default>;'
    Trả về list dict: {name, type, default, comment}
    """
    pattern = re.compile(
        r'^\s*input\s+'
        r'(\w+)\s+'          # type
        r'(\w+)\s*'          # name
        r'=\s*'
        r'([^;]+?)'          # default value
        r'\s*;'
        r'(?:\s*//\s*(.*))?$',  # optional comment
        re.MULTILINE
    )
    results = []
    for m in pattern.finditer(source):
        typ     = m.group(1).strip()
        name    = m.group(2).strip()
        default = m.group(3).strip().strip('"')
        comment = (m.group(4) or "").strip()
        results.append({"name": name, "type": typ, "default": default, "comment": comment})
    return results


def is_separator(param):
    """Tham số dạng separator (type=string, name bắt đầu bằng _)"""
    return param["name"].startswith("_") or param["type"].lower() == "string" and "===" in param["default"]


def normalize_bool(val):
    """Chuyển true/false MQL5 -> 1/0"""
    if val.lower() == "true":
        return "1"
    if val.lower() == "false":
        return "0"
    return val


def build_tester_input_line(param):
    """
    Sinh dòng [TesterInputs] theo định dạng MT5:
      ParamName=start||start||step||stop||Y   (optimize)
      ParamName=value||value||step||stop||N   (cố định)
    Mặc định: tất cả cố định (N). Người dùng tự đổi Y và điền start/step/stop.
    Format: default||default||step||stop||Y/N
    """
    name    = param["name"]
    typ     = param["type"].lower()
    default = param["default"]

    if typ == "bool":
        default = normalize_bool(default)
    elif typ in ("int", "double"):
        default = default.rstrip("f")

    return f"{name}={default}||{default}||1||{default}||N"


def relative_expert_path(mq5_path):
    r"""
    Tính đường dẫn EA tương đối so với thư mục MQL5
    VD: Experts\AutoTrade\...\EA_Event.ex5
    """
    mq5_path = Path(mq5_path).resolve()
    # Thay đuôi .mq5 -> .ex5
    ex5_path = mq5_path.with_suffix(".ex5")
    # Tìm phần sau 'MQL5\' trong path
    parts = ex5_path.parts
    for i, p in enumerate(parts):
        if p.upper() == "MQL5":
            remaining = parts[i+1:]
            # MT5 tự prepend 'Experts\' vào Expert= nên không được include nó
            if remaining and remaining[0].upper() == "EXPERTS":
                return str(Path(*remaining[1:]))
            return str(Path(*remaining))
    return str(ex5_path)


def detect_mt5_terminals():
    """Tìm tất cả MT5 terminal đang có trong %APPDATA%."""
    base = Path(os.environ.get('APPDATA', '')) / 'MetaQuotes' / 'Terminal'
    candidates = []
    if not base.exists():
        return candidates
    for folder in base.iterdir():
        if not folder.is_dir():
            continue
        if folder.name.lower() in ('common', 'community'):
            continue
        if (folder / 'origin.txt').exists() and (folder / 'MQL5').exists():
            # Đọc tên broker từ origin.txt nếu có
            origin = folder / 'origin.txt'
            try:
                label = origin.read_text(encoding='utf-8', errors='replace').strip().splitlines()[0]
            except Exception:
                label = folder.name
            candidates.append({'hash': folder.name, 'label': label, 'path': folder})
    return candidates


def find_mt5_program(terminal_folder):
    """Tìm đường dẫn terminal64.exe từ origin.txt của terminal."""
    origin = terminal_folder / 'origin.txt'
    try:
        for line in origin.read_text(encoding='utf-8', errors='replace').splitlines():
            p = Path(line.strip())
            if p.name.lower() == 'terminal64.exe' and p.exists():
                return str(p)
    except Exception:
        pass
    if Path(DEFAULT_MT5_PROGRAM_PATH).exists():
        return DEFAULT_MT5_PROGRAM_PATH
    return DEFAULT_MT5_PROGRAM_PATH


def select_mt5_terminal():
    """Hỏi người dùng chọn 1 hoặc nhiều MT5 terminal.
    Trả về list of (hash, mt5_program_path).
    """
    candidates = detect_mt5_terminals()
    if not candidates:
        print('Không tìm thấy MT5 terminal nào. Sẽ để trống — bạn tự điền sau.')
        return [('', DEFAULT_MT5_PROGRAM_PATH)]

    if len(candidates) == 1:
        c = candidates[0]
        print(f'Tìm thấy 1 MT5 terminal: {c["label"]} ({c["hash"]})')
        return [(c['hash'], find_mt5_program(c['path']))]

    print('\nTìm thấy nhiều MT5 terminal:')
    for i, c in enumerate(candidates, 1):
        print(f'  {i}. {c["label"]}')
        print(f'     hash: {c["hash"]}')
    print(f'  0. Dùng tất cả (chạy song song)')

    while True:
        pick = input(f'Chọn terminal (0=tất cả, 1-{len(candidates)}, hoặc nhiều cái VD "1,2"): ').strip()
        if pick == '0':
            return [(c['hash'], find_mt5_program(c['path'])) for c in candidates]
        picks = [p.strip() for p in pick.split(',') if p.strip()]
        selected = []
        valid = True
        for p in picks:
            if p.isdigit() and 1 <= int(p) <= len(candidates):
                c = candidates[int(p) - 1]
                selected.append((c['hash'], find_mt5_program(c['path'])))
            else:
                print(f'Lựa chọn không hợp lệ: {p}')
                valid = False
                break
        if valid and selected:
            return selected


def find_set_file(mq5_path, selected_terminals):
    r"""Tìm file .set của EA trong MQL5\Profiles\Tester\ của các terminal đã chọn."""
    ea_name = Path(mq5_path).stem  # VD: EAMA
    appdata = Path(os.environ.get('APPDATA', ''))
    # Thử tìm trong từng terminal đã chọn
    for hash_val, _ in selected_terminals:
        set_path = appdata / 'MetaQuotes' / 'Terminal' / hash_val / 'MQL5' / 'Profiles' / 'Tester' / f'{ea_name}.set'
        if set_path.exists():
            return set_path
    return None


def read_set_file(set_path):
    """Đọc file .set của MT5 Strategy Tester (không có section header).
    Trả về dict: {param_name: 'value||start||step||stop||Y/N'}
    """
    result = {}
    try:
        raw = Path(set_path).read_bytes()
        # MT5 lưu UTF-16 LE với BOM
        for enc in ('utf-16', 'utf-8-sig', 'utf-8', 'latin-1'):
            try:
                content = raw.decode(enc)
                break
            except Exception:
                continue
        else:
            return result
        for line in content.splitlines():
            line = line.strip().lstrip('\ufeff')  # strip BOM nếu còn sót
            if not line or line.startswith(';') or line.startswith('['):
                continue
            if '=' not in line:
                continue
            idx = line.index('=')
            key = line[:idx].strip()
            val = line[idx+1:].strip()
            if not key:
                continue
            parts = val.split('||')
            if len(parts) == 5:
                flag = 'Y' if parts[4].strip().lower() == 'true' else ('N' if parts[4].strip().lower() == 'false' else parts[4].strip())
                parts[4] = flag
                result[key] = '||'.join(parts)
            else:
                result[key] = val
    except Exception:
        pass
    return result


def generate_input_ini(mq5_path, output_path=None, selected_terminals=None):
    mq5_path = Path(mq5_path).resolve()
    if not mq5_path.exists():
        print(f"Không tìm thấy file: {mq5_path}")
        sys.exit(1)

    # Chọn MT5 terminal(s) trước để biết experts_dir
    if selected_terminals is None:
        selected_terminals = select_mt5_terminal()

    # Copy EA vào root Experts/ nếu chưa ở đó
    if selected_terminals and selected_terminals[0][0]:
        appdata = Path(os.environ.get('APPDATA', ''))
        experts_root = appdata / 'MetaQuotes' / 'Terminal' / selected_terminals[0][0] / 'MQL5' / 'Experts'
        dest = experts_root / mq5_path.name
        if dest.resolve() != mq5_path.resolve():
            experts_root.mkdir(parents=True, exist_ok=True)
            shutil.copy2(str(mq5_path), str(dest))
            print(f"[Copy] {mq5_path.name} → {dest}")
            mq5_path = dest

    print(f"Đang đọc EA: {mq5_path}")
    source = collect_source(mq5_path)
    params = parse_inputs(source)

    if not params:
        print("Không tìm thấy tham số input nào trong EA.")
        sys.exit(1)

    expert_path = relative_expert_path(mq5_path)
    tester = DEFAULT_TESTER.copy()
    tester["expert"] = expert_path

    lines = []

    # [Symbols]
    lines.append("[Symbols]")
    lines.append(f"symbols = {tester['symbols']}")
    lines.append(f"subfix = {tester['subfix']}")
    lines.append("")

    # [Tester]
    lines.append("[Tester]")
    lines.append(f"expert = {tester['expert']}")
    lines.append(f"period = {tester['period']}")
    lines.append(f"login = {tester['login']}")
    lines.append(f"deposit = {tester['deposit']}")
    lines.append(f"leverage = {tester['leverage']}")
    lines.append(f"model = {tester['model']}")
    lines.append(f"executionmode = {tester['executionmode']}")
    lines.append(f"optimization = {tester['optimization']}")
    lines.append(f"optimizationcriterion = {tester['optimizationcriterion']}")
    lines.append(f"fromdate = {tester['fromdate']}")
    lines.append(f"todate = {tester['todate']}")
    lines.append(f"replacereport = {tester['replacereport']}")
    lines.append(f"shutdownterminal = {tester['shutdownterminal']}")
    lines.append("")

    # [MT5] - 1 hoặc nhiều terminal
    lines.append("[MT5]")
    if len(selected_terminals) == 1:
        h, p = selected_terminals[0]
        lines.append(f"terminal_hash = {h}")
        lines.append(f"mt5_program_path = {p}")
    else:
        hashes = ", ".join(h for h, _ in selected_terminals)
        paths  = ", ".join(p for _, p in selected_terminals)
        lines.append(f"terminal_hashes = {hashes}")
        lines.append(f"mt5_program_paths = {paths}")
    lines.append("")

    # Tìm file .set từ MT5
    set_file = find_set_file(mq5_path, selected_terminals)
    set_values = {}
    if set_file:
        set_values = read_set_file(set_file)
        print(f"[.set] Tìm thấy: {set_file} — dùng giá trị từ MT5 Strategy Tester")
    else:
        print("[.set] Không tìm thấy file .set — dùng giá trị mặc định từ source code EA")

    # [TesterInputs]
    lines.append("[TesterInputs]")
    skipped = 0
    for p in params:
        if is_separator(p):
            skipped += 1
            continue
        comment = f"  ; {p['comment']}" if p.get("comment") else ""
        if p['name'] in set_values:
            lines.append(f"{p['name']}={set_values[p['name']]}" + comment)
        else:
            lines.append(build_tester_input_line(p) + comment)

    content = "\n".join(lines) + "\n"

    if output_path is None:
        output_path = SCRIPT_DIR / "input.ini"

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, encoding='utf-8')

    print(f"\nĐã sinh input.ini: {output_path}")
    print(f"  Tổng input params: {len(params) - skipped} (bỏ qua {skipped} separator)")
    print(f"  Expert: {expert_path}")
    print(f"  MT5 terminals: {len(selected_terminals)} cái")
    for h, p in selected_terminals:
        print(f"    - {h} | {p}")
    print()
    print("==== NỘI DUNG input.ini ====")
    print(content)


def search_ea_on_windows(name: str) -> list:
    """Tìm file .mq5 theo tên trên Windows.
    Tìm trong: các MT5 terminal, Desktop, Documents, Downloads, ổ C.
    Trả về list Path đã tìm thấy.
    """
    # Chuẩn hoá tên: bỏ đuôi nếu có để tìm không phân biệt hoa thường
    stem = name.lower()
    if stem.endswith('.mq5'):
        stem = stem[:-4]

    search_roots = []
    appdata = Path(os.environ.get('APPDATA', ''))
    userprofile = Path(os.environ.get('USERPROFILE', ''))

    # 1. Thư mục MQL5 của tất cả MT5 terminal
    base_term = appdata / 'MetaQuotes' / 'Terminal'
    if base_term.exists():
        for folder in base_term.iterdir():
            if folder.is_dir() and folder.name.lower() not in ('common', 'community'):
                mql5 = folder / 'MQL5'
                if mql5.exists():
                    search_roots.append(mql5)

    # 2. Desktop, Documents, Downloads
    for sub in ('Desktop', 'Documents', 'Downloads'):
        p = userprofile / sub
        if p.exists():
            search_roots.append(p)

    found = []
    seen = set()
    for root in search_roots:
        try:
            for path in root.rglob('*.mq5'):
                if path.stem.lower() == stem:
                    resolved = path.resolve()
                    if resolved not in seen:
                        seen.add(resolved)
                        found.append(path)
        except PermissionError:
            pass

    return found


def interactive_mode():
    """Chế độ hội thoại: hỏi tên EA → tìm → copy vào Experts → sinh input.ini."""
    print("=" * 55)
    print("  gen_input_ini — Hỗ trợ sinh input.ini cho MT5 EA")
    print("=" * 55)
    print()

    # ---- Bước 1: Chọn MT5 terminal ----
    candidates = detect_mt5_terminals()
    if not candidates:
        print("Không tìm thấy MT5 terminal nào trên máy. Thoát.")
        sys.exit(1)

    if len(candidates) == 1:
        chosen = candidates[0]
        print(f"MT5 terminal: {chosen['label']}")
    else:
        print("Tìm thấy nhiều MT5 terminal:")
        for i, c in enumerate(candidates, 1):
            print(f"  {i}. {c['label']}")
        while True:
            pick = input(f"Chọn terminal (1-{len(candidates)}): ").strip()
            if pick.isdigit() and 1 <= int(pick) <= len(candidates):
                chosen = candidates[int(pick) - 1]
                break
            print("Lựa chọn không hợp lệ.")

    experts_dir = chosen['path'] / 'MQL5' / 'Experts'

    # ---- Bước 2: Hỏi tên EA ----
    while True:
        raw = input("\nEA của bạn là gì? (nhập tên hoặc kéo thả file .mq5):\n> ").strip().strip('"').strip("'")
        if not raw:
            print("Vui lòng nhập tên EA.")
            continue

        candidate_path = Path(raw)

        # Kéo thả / nhập đường dẫn đầy đủ
        if candidate_path.exists() and candidate_path.suffix.lower() == '.mq5':
            source = candidate_path
        else:
            # Nhập tên → tìm kiếm trên máy
            print(f"Đang tìm '{raw}' trên máy...")
            results = search_ea_on_windows(raw)
            if not results:
                print(f"Không tìm thấy '{raw}.mq5'. Thử nhập lại hoặc kéo thả file vào.")
                continue
            if len(results) == 1:
                source = results[0]
                print(f"Tìm thấy: {source}")
            else:
                print(f"Tìm thấy {len(results)} file:")
                for i, r in enumerate(results, 1):
                    print(f"  {i}. {r}")
                while True:
                    pick = input(f"Chọn file (1-{len(results)}): ").strip()
                    if pick.isdigit() and 1 <= int(pick) <= len(results):
                        source = results[int(pick) - 1]
                        break
                    print("Lựa chọn không hợp lệ.")
        break

    # ---- Bước 3: Copy vào Experts\ ----
    dest = experts_dir / source.name
    if dest.resolve() != source.resolve():
        experts_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(str(source), str(dest))
        print(f"\n[Copy] {source.name} → {dest}")
    else:
        print(f"\nEA đã nằm trong Experts: {dest}")

    # ---- Bước 4: Sinh input.ini ----
    print()
    generate_input_ini(dest, selected_terminals=[(chosen['hash'], find_mt5_program(chosen['path']))])


if __name__ == "__main__":
    if len(sys.argv) < 2:
        interactive_mode()
    else:
        mq5 = sys.argv[1]
        out  = sys.argv[2] if len(sys.argv) > 2 else None
        generate_input_ini(mq5, out)

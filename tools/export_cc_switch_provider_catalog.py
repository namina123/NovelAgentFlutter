from __future__ import annotations

import argparse
import json
from pathlib import Path

from cc_switch_provider_catalog_extractor import export_cc_switch_provider_catalog


def parse_args() -> argparse.Namespace:
    # 中文注释: 这里保持为单一职责命令入口，只处理参数，不承载抽取或落库细节。
    parser = argparse.ArgumentParser(description="从 cc-switch 预设中导出用户端主目录 SQLite。")
    parser.add_argument(
        "--cc-switch-repo",
        dest="cc_switch_repo",
        default="references/cc-switch-main",
        help="cc-switch 仓库路径，默认使用 references/cc-switch-main。",
    )
    parser.add_argument(
        "--skip-json",
        action="store_true",
        help="只生成 SQLite，不生成 JSON 调试产物。",
    )
    parser.add_argument(
        "--output-suffix",
        dest="output_suffix",
        help="为输出文件名追加后缀，避免覆盖现有导出文件。",
    )
    return parser.parse_args()


def main() -> None:
    # 中文注释: 主入口只负责调用导出并打印摘要，方便后续脚本链或人工查看。
    args = parse_args()
    repo_root = Path(__file__).resolve().parent.parent
    cc_switch_repo_path = (repo_root / args.cc_switch_repo).resolve()
    payload = export_cc_switch_provider_catalog(
        repo_root=repo_root,
        cc_switch_repo_path=cc_switch_repo_path,
        write_json=not args.skip_json,
        output_suffix=args.output_suffix,
    )
    print("sqlite_generated=" + payload["_artifacts"]["sqlite_path"])
    if not args.skip_json:
        print("json_generated=" + payload["_artifacts"]["json_path"])
    print("cc_switch_repo_path=" + json.dumps(str(cc_switch_repo_path), ensure_ascii=False))
    print("cc_switch_repo_commit=" + json.dumps(payload["source"].get("repo_commit"), ensure_ascii=False))
    print("library_version=" + json.dumps(payload["source"]["library_version"], ensure_ascii=False))
    print(f"preset_count={len(payload['provider_presets'])}")
    print(f"endpoint_count={len(payload['provider_preset_endpoints'])}")
    print(f"app_binding_count={len(payload['provider_preset_apps'])}")
    print(f"model_count={len(payload['provider_preset_models'])}")
    print("diagnostics=" + json.dumps(payload["diagnostics"], ensure_ascii=False))


if __name__ == "__main__":
    main()

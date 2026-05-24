from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

from litellm_model_matrix_exporter import export_model_matrix, resolve_litellm_repo_path


def parse_args() -> argparse.Namespace:
    # 中文注释: 命令行参数保持尽量少，只暴露真正有用的仓库路径与是否跳过 JSON 调试产物。
    parser = argparse.ArgumentParser(description="导出 LiteLLM 模型映射到 SQLite，并可选保留 JSON 调试产物。")
    parser.add_argument(
        "--litellm-repo",
        dest="litellm_repo",
        help="LiteLLM 上游仓库路径；未提供时会自动尝试 temp/litellm-upstream。",
    )
    parser.add_argument(
        "--skip-json",
        action="store_true",
        help="只生成 SQLite，不生成 JSON 调试文件。",
    )
    parser.add_argument(
        "--output-suffix",
        dest="output_suffix",
        help="为输出文件名追加后缀，避免覆盖当前已有数据库文件。",
    )
    return parser.parse_args()


def main() -> None:
    # 中文注释: 主入口只负责解析参数、调用导出核心并打印摘要，不承载数据拼装细节。
    args = parse_args()
    script_path = Path(__file__).resolve()
    repo_root = script_path.parent.parent
    litellm_repo_path = resolve_litellm_repo_path(repo_root, args.litellm_repo)
    payload = export_model_matrix(
        repo_root=repo_root,
        litellm_repo_path=litellm_repo_path,
        write_json=not args.skip_json,
        output_suffix=args.output_suffix,
    )

    provider_counts = Counter(str(item["provider_id"]) for item in payload["model_variants"])
    print("sqlite_generated=" + payload["_artifacts"]["sqlite_path"])
    if not args.skip_json:
        print("json_generated=" + payload["_artifacts"]["json_path"])
    print("litellm_repo_path=" + json.dumps(str(litellm_repo_path) if litellm_repo_path is not None else None, ensure_ascii=False))
    print("litellm_repo_commit=" + json.dumps(payload["source"].get("repo_commit"), ensure_ascii=False))
    print("library_version=" + json.dumps(payload["source"]["library_version"], ensure_ascii=False))
    print(f"provider_count={len(payload['providers'])}")
    print(f"canonical_model_count={len(payload['canonical_models'])}")
    print(f"model_variant_count={len(payload['model_variants'])}")
    print(f"observed_model_variant_count={len(payload.get('observed_model_variants', []))}")
    print(f"project_provider_snapshot_count={len(payload['project_provider_snapshots'])}")
    print("diagnostics=" + json.dumps(payload["diagnostics"], ensure_ascii=False))
    print("top_providers=" + json.dumps(provider_counts.most_common(10), ensure_ascii=False))
    print("sample_models=" + json.dumps([item["model_id"] for item in payload["model_variants"][:5]], ensure_ascii=False))


if __name__ == "__main__":
    main()

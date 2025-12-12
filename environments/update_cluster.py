# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "copier>=9,<10",
#     "typer>=0.2.0,<1",
# ]
# ///

from typing import Optional
import copier
import typer

def main(
    cluster_path: str = typer.Argument(help="Path to the cluster configuration to update. For example 'global_cave/my-global-cluster"),
    template_version: Optional[str] = typer.Option(None, '--template-version', '-v', help="Update to a specific template version/tag."),
    ask_all: bool = typer.Option(False, "--ask-all", "-a", help="If set, ask for all parameters, including existing ones."),
    dry_run: bool = typer.Option(False, "--dry-run", help="Preview changes without applying them."),
):
    """Update cluster configuration to the latest (or specified) template version."""
    copier.run_recopy(
        cluster_path,
        vcs_ref=template_version,
        skip_answered=not ask_all,
        pretend=dry_run,
    )

if __name__ == "__main__":
    typer.run(main)

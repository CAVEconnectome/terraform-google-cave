# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "copier<=9,<10",
#     "typer>=0.2.0,<1",
# ]
# ///

from typing import Optional
import copier
import typer

TEMPLATE_PATH = "gh://CAVEconnectome/global-template"

def main(
    template_path: Optional[str] = typer.Option(None, '--template-path', '-p', help="Path to the global cluster configuration template."),
    template_version: Optional[str] = typer.Option(None, '--template-version', '-v', help="Tag of the global cluster configuration to add."),
    dry_run: Optional[bool] = typer.Option(False, "--dry-run", help="Run the command without making any changes."),
):
    """Add global cluster configuration to the current project."""
    if template_path is None:
        template_path = TEMPLATE_PATH
    copier.run_copy(
        template_path,
        ".",
        vcs_ref=template_version,
        pretend=dry_run,
    )

if __name__ == "__main__":
    typer.run(main)

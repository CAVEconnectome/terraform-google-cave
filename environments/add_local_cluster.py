# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "copier>=9,<10",
#     "typer>=0.2.0,<1",
#     "PyYAML",
# ]
# ///

from typing import Optional
import pathlib
import copier
import typer
import yaml

TEMPLATE_PATH = "gh://CAVEconnectome/local-template"

def main(
    global_cluster: Optional[str] = typer.Option(None, '--global-cluster', '-g', help="Name of the global cluster configuration to use."),
    template_path: Optional[str] = typer.Option(None, '--template-path', '-p', help="Path to the template to use."),
    template_version: Optional[str] = typer.Option(None, '--template-version', '-v', help="Version of the template to use."),
    dry_run: Optional[bool] = typer.Option(False, "--dry-run", help="Run the command without making any changes."),
):
    """Add local cluster configuration to the current project."""
    data = {}
    if global_cluster:
        path = pathlib.Path(__file__).parent / "global_cave" / global_cluster
        if path.exists():
            global_data = path / '.copier-answers.yml'
            with pathlib.Path(global_data).open("rb") as f:
                data = yaml.safe_load(f)
        else:
            typer.echo(f"Global cluster {global_cluster} configuration file not found at '{path}'")
            raise typer.Exit(code=1)
    if template_path is None:
        template_path = TEMPLATE_PATH
    copier.run_copy(
        template_path,
        ".",
        data=data if global_cluster else None,
        vcs_ref=template_version,
        pretend=dry_run,
        skip_if_exists=True,
    )

if __name__ == "__main__":
    typer.run(main)

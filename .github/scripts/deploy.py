import argparse
import logging
import os
import sys
import traceback

from azure.identity import DefaultAzureCredential
from fabric_cicd import FabricWorkspace, publish_all_items, unpublish_all_orphan_items


ITEM_TYPES = [
    "Lakehouse",
    "Notebook",
    "DataPipeline",
    "Dataflow",
    "Warehouse",
    "SemanticModel",
    "Report",
    "Environment",
    "SparkJobDefinition",
]


class GitHubAnnotationHandler(logging.Handler):
    """Cada ERROR de fabric-cicd se convierte en una anotacion del run de GitHub Actions."""

    def emit(self, record: logging.LogRecord) -> None:
        msg = self.format(record).replace("%", "%25").replace("\r", "").replace("\n", "%0A")
        print(f"::error title=fabric-cicd ({record.name})::{msg[:1500]}", flush=True)


def main() -> None:
    handler = GitHubAnnotationHandler(level=logging.ERROR)
    logging.getLogger().addHandler(handler)
    logging.getLogger("fabric_cicd").addHandler(handler)

    parser = argparse.ArgumentParser(description="Deploy a Fabric layer with fabric-cicd.")
    parser.add_argument("--layer", choices=("bronze", "silver", "gold"), required=True)
    parser.add_argument("--environment", choices=("test", "prod"), required=True)
    parser.add_argument("--project-name", default=os.environ.get("FABRIC_PROJECT_NAME"), required=False)
    args = parser.parse_args()

    if not args.project_name:
        parser.error("--project-name or FABRIC_PROJECT_NAME is required")

    repository_directory = os.path.join("fabric-content", args.layer)
    parameter_file = os.path.join(repository_directory, "parameter.yml")
    workspace_name = f"{args.project_name}-{args.layer}-{args.environment}"
    print(f"::notice title=fabric-cicd::Desplegando {repository_directory} en '{workspace_name}'")

    target = FabricWorkspace(
        workspace_name=workspace_name,
        environment=args.environment,
        repository_directory=repository_directory,
        item_type_in_scope=ITEM_TYPES,
        parameter_file_path=parameter_file,
        token_credential=DefaultAzureCredential(),
    )

    publish_all_items(target)
    unpublish_all_orphan_items(target)
    print(f"Deployment to '{workspace_name}' complete.")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        traceback.print_exc()
        # Anotacion visible en el resumen del run (y legible por la API sin descargar logs).
        msg = f"{type(exc).__name__}: {exc}".replace("%", "%25").replace("\r", "").replace("\n", "%0A")
        print(f"::error title=fabric-cicd::{msg[:1500]}")
        sys.exit(1)

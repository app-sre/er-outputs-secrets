import base64
import hashlib
import json
import logging
import os
from pathlib import Path

from external_resources_io.config import Action, Config
from external_resources_io.input import (
    AppInterfaceProvision,
    parse_model,
    read_input_from_file,
)
from kubernetes import config
from kubernetes.client import CoreV1Api, V1ObjectMeta, V1Secret
from kubernetes.client.exceptions import ApiException
from kubernetes.dynamic.exceptions import NotFoundError, api_exception

OUTPUTS_FILE = "/work/output.json"

logging.basicConfig(level=logging.INFO)


def read_outputs(terraform_output: str) -> dict[str, str]:
    outputs: dict[str, str] = {}
    data = json.loads(terraform_output)
    if "CDKTF" in data:
        # cdktf json
        for k, v in data["CDKTF"].items():
            outputs[k] = base64.b64encode(str(v).encode()).decode()
    else:
        # terraform json
        for k, v in data.items():
            outputs[k] = base64.b64encode(str(v["value"]).encode()).decode()
    return outputs


def get_secret_name(provision: AppInterfaceProvision) -> str:
    secret_key = f"{provision.provision_provider}-{provision.provisioner}-{provision.provider}-{provision.identifier}"
    secret_key_hash = hashlib.shake_128(secret_key.encode("utf-8")).hexdigest(16)
    return f"external-resources-output-{secret_key_hash}"


def get_k8s_client() -> CoreV1Api:
    config.load_incluster_config()
    return CoreV1Api()


def save_outputs(
    k8s_client: CoreV1Api,
    namespace: str,
    secret: V1Secret,
) -> None:
    try:
        k8s_client.read_namespaced_secret(secret.metadata.name, namespace)
        logging.info("Secret already exists: Replacing")
        k8s_client.replace_namespaced_secret(
            secret.metadata.name, namespace, body=secret
        )
    except ApiException as e:
        if isinstance(api_exception(e), NotFoundError):
            logging.info("Secret does not exist: Creating")
            k8s_client.create_namespaced_secret(namespace=namespace, body=secret)
        else:
            raise e


def main() -> None:
    input_data = read_input_from_file()
    provision: AppInterfaceProvision = parse_model(
        AppInterfaceProvision, input_data["provision"]
    )
    namespace = os.environ["NAMESPACE"]
    conf = Config()
    if conf.dry_run:
        logging.info("DRY_RUN does not store any secret")
        return

    match conf.action:
        case Action.DESTROY:
            logging.info("No outputs management on Destroy Action")
        case Action.APPLY:
            output_file = Path(OUTPUTS_FILE)
            if not output_file.exists():
                logging.info(
                    f"No output file found at {OUTPUTS_FILE}, skip output management"
                )
                return
            secret = V1Secret(
                api_version="v1",
                metadata=V1ObjectMeta(
                    name=get_secret_name(provision),
                    annotations=provision.model_dump(exclude={"module_provision_data"}),
                ),
                data=read_outputs(
                    terraform_output=output_file.read_text(encoding="locale")
                ),
            )
            k8s_client = get_k8s_client()
            save_outputs(k8s_client, namespace, secret)


if __name__ == "__main__":
    main()

import os
from collections.abc import Iterator
from unittest.mock import Mock, patch

import pytest
from external_resources_io.input import AppInterfaceProvision
from kubernetes.client import ApiException, V1ObjectMeta, V1Secret

from main import main
from tests.conftest import (
    DEFAULT_EXPECTED_OUTPUTS,
    DEFAULT_EXPECTED_SECRET_NAME,
    DEFAULT_TERRAFORM_OUTPUT,
)


@pytest.fixture
def mock_read_input_from_file() -> Iterator[Mock]:
    with patch("main.read_input_from_file") as m:
        yield m


@pytest.fixture
def mock_logging() -> Iterator[Mock]:
    with patch("main.logging") as m:
        yield m


@pytest.fixture
def mock_path() -> Iterator[Mock]:
    with patch("main.Path") as m:
        yield m


@pytest.fixture
def mock_k8s_config() -> Iterator[Mock]:
    with patch("main.config") as m:
        yield m


@pytest.fixture
def mock_k8s_client() -> Iterator[Mock]:
    with patch("main.CoreV1Api") as m:
        yield m


def test_main_dry_run(
    provision: AppInterfaceProvision,
    mock_read_input_from_file: Mock,
    mock_logging: Mock,
) -> None:
    mock_read_input_from_file.return_value = {"provision": provision}

    with patch.dict(
        os.environ, {"NAMESPACE": "foo", "ACTION": "Apply", "DRY_RUN": "True"}
    ):
        main()

    mock_logging.info.assert_called_once_with("DRY_RUN does not store any secret")


def test_main_destroy(
    provision: AppInterfaceProvision,
    mock_read_input_from_file: Mock,
    mock_logging: Mock,
) -> None:
    mock_read_input_from_file.return_value = {"provision": provision}

    with patch.dict(
        os.environ, {"NAMESPACE": "foo", "ACTION": "Destroy", "DRY_RUN": "False"}
    ):
        main()

    mock_logging.info.assert_called_once_with("No outputs management on Destroy Action")


def test_main_apply_when_secret_not_exist(
    provision: AppInterfaceProvision,
    mock_read_input_from_file: Mock,
    mock_logging: Mock,
    mock_path: Mock,
    mock_k8s_config: Mock,
    mock_k8s_client: Mock,
) -> None:
    expected_secret = V1Secret(
        api_version="v1",
        metadata=V1ObjectMeta(
            name=DEFAULT_EXPECTED_SECRET_NAME,
            annotations=provision.model_dump(exclude={"module_provision_data"}),
        ),
        data=DEFAULT_EXPECTED_OUTPUTS,
    )
    mock_read_input_from_file.return_value = {"provision": provision}
    mock_path.return_value.exists.return_value = True
    mock_path.return_value.read_text.return_value = DEFAULT_TERRAFORM_OUTPUT
    mock_k8s_client.return_value.read_namespaced_secret.side_effect = ApiException(
        status=404
    )

    with patch.dict(
        os.environ, {"NAMESPACE": "foo", "ACTION": "Apply", "DRY_RUN": "False"}
    ):
        main()

    mock_logging.info.assert_called_once_with("Secret does not exist: Creating")
    mock_k8s_client.return_value.create_namespaced_secret.assert_called_once_with(
        namespace="foo",
        body=expected_secret,
    )


def test_main_apply_when_secret_exist(
    provision: AppInterfaceProvision,
    mock_read_input_from_file: Mock,
    mock_logging: Mock,
    mock_path: Mock,
    mock_k8s_config: Mock,
    mock_k8s_client: Mock,
) -> None:
    expected_secret = V1Secret(
        api_version="v1",
        metadata=V1ObjectMeta(
            name=DEFAULT_EXPECTED_SECRET_NAME,
            annotations=provision.model_dump(exclude={"module_provision_data"}),
        ),
        data=DEFAULT_EXPECTED_OUTPUTS,
    )
    mock_read_input_from_file.return_value = {"provision": provision}
    mock_path.return_value.exists.return_value = True
    mock_path.return_value.read_text.return_value = DEFAULT_TERRAFORM_OUTPUT

    with patch.dict(
        os.environ, {"NAMESPACE": "foo", "ACTION": "Apply", "DRY_RUN": "False"}
    ):
        main()

    mock_logging.info.assert_called_once_with("Secret already exists: Replacing")
    mock_k8s_client.return_value.replace_namespaced_secret.assert_called_once_with(
        DEFAULT_EXPECTED_SECRET_NAME,
        "foo",
        body=expected_secret,
    )


def test_main_apply_when_no_output_file(
    provision: AppInterfaceProvision,
    mock_read_input_from_file: Mock,
    mock_logging: Mock,
    mock_path: Mock,
    mock_k8s_config: Mock,
    mock_k8s_client: Mock,
) -> None:
    mock_read_input_from_file.return_value = {"provision": provision}
    mock_path.return_value.exists.return_value = False

    with patch.dict(
        os.environ, {"NAMESPACE": "foo", "ACTION": "Apply", "DRY_RUN": "False"}
    ):
        main()

    mock_logging.info.assert_called_once_with(
        "No output file found at /work/output.json, skip output management"
    )

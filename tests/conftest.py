import sys
from pathlib import Path

import pytest
from external_resources_io.input import AppInterfaceProvision, TerraformProvisionOptions

sys.path.append(str(Path(__file__).parent.parent))


@pytest.fixture
def provision() -> AppInterfaceProvision:
    return AppInterfaceProvision(
        provision_provider="aws",
        provisioner="account",
        provider="s3",
        identifier="my-bucket",
        target_cluster="my-cluster",
        target_namespace="my-namespace",
        target_secret_name="my-secret",
        module_provision_data=TerraformProvisionOptions(
            tf_state_bucket="my-bucket",
            tf_state_region="us-west-2",
            tf_state_dynamodb_table="my-table",
            tf_state_key="my-key",
        ),
    )

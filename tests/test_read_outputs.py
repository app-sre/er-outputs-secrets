import pytest

from main import read_outputs
from tests.conftest import DEFAULT_EXPECTED_OUTPUTS, DEFAULT_TERRAFORM_OUTPUT


@pytest.mark.parametrize(
    "terraform_output, expected_outputs",
    [
        # cdktf json
        (
            '{"CDKTF": {"output1": "output1_value", "output2": 12345}}',
            {"output1": "b3V0cHV0MV92YWx1ZQ==", "output2": "MTIzNDU="},
        ),
        # terraform json
        (
            DEFAULT_TERRAFORM_OUTPUT,
            DEFAULT_EXPECTED_OUTPUTS,
        ),
    ],
)
def test_read_outputs(terraform_output: str, expected_outputs: dict[str, str]) -> None:
    outputs = read_outputs(terraform_output)
    assert outputs == expected_outputs

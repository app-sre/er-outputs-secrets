import pytest

from main import read_outputs


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
            '{"output1": {"value": "output1_value"}, "output2": {"value": 12345}}',
            {"output1": "b3V0cHV0MV92YWx1ZQ==", "output2": "MTIzNDU="},
        ),
    ],
)
def test_read_outputs(terraform_output: str, expected_outputs: dict[str, str]) -> None:
    outputs = read_outputs(terraform_output)
    assert outputs == expected_outputs

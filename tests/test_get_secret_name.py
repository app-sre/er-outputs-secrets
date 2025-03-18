from external_resources_io.input import AppInterfaceProvision
from tests.conftest import DEFAULT_EXPECTED_SECRET_NAME

from main import get_secret_name


def test_get_secret_name(provision: AppInterfaceProvision) -> None:
    assert get_secret_name(provision) == DEFAULT_EXPECTED_SECRET_NAME

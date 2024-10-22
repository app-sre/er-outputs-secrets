from external_resources_io.input import AppInterfaceProvision
from main import get_secret_name


def test_get_secret_name(provision: AppInterfaceProvision) -> None:
    assert (
        get_secret_name(provision)
        == "external-resources-output-6d9eb7ec5e128634012e28f84506de80"
    )

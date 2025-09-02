import os
import pytest
import pytest_html

from Utils.browser_factory import get_webdriver
from config.config_parser import load_config


@pytest.fixture(scope="session")
def config(request):
    cfg = load_config()

    # Read CLI overrides
    browser_name = request.config.getoption("--browser")
    env_name = request.config.getoption("--env")

    # Apply overrides if given
    if browser_name:
        cfg["browserName"] = browser_name

    if env_name:
        # Map environment to correct base URL
        if env_name.lower() == "pie1":
            cfg["baseUrl"] = cfg.get("baseUrl_pie")
        elif env_name.lower() == "stage1":
            cfg["baseUrl"] = cfg.get("baseUrl_stg")
        else:
            print(f"WARNING: Unknown environment '{env_name}', using default baseUrl")
            cfg["baseUrl"] = cfg.get("baseUrl_stg")  # or some safe fallback

    return cfg


"""@pytest.fixture(params=["chrome", "firefox", "edge"])"""


# @pytest.fixture(params=["chrome"])
@pytest.fixture(scope="function")
def browser(config):
    driver = get_webdriver(config)
    yield driver
    driver.quit()


def pytest_addoption(parser):
    parser.addoption("--env", action="store", default="pie1", help="Target environment")
    parser.addoption(
        "--browser", action="store", default="chrome", help="Browser to use"
    )
    parser.addoption("--param1", action="store", default=None, help="Custom parameter")


@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    # Screenshot on failure
    outcome = yield
    rep = outcome.get_result()
    if rep.when == "call" and rep.failed:
        driver = item.funcargs.get("browser")
        if driver:
            file_name = f"screenshots/{item.name}.png"
            driver.save_screenshot(file_name)
            if "pytest_html" in item.config.pluginmanager.list_name_plugin():
                extra = getattr(rep, "extra", [])
                extra.append(pytest_html.extras.image(file_name))
                rep.extra = extra

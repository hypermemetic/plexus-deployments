# Claude Container

Development container for running Claude Code against the Hypermemetic codebase.

## Contents

- **Dockerfile** — Extends `ghcr.io/hypermemetic/claude-container:latest` with Haskell (GHC 9.4.8), Rust tooling, and system deps
- **claude-projects.yml** — Multi-project config for the `claude-container` CLI
- **scripts/** — Host-side helper scripts

## Scripts

### `scripts/start-chromedriver.sh`

Starts ChromeDriver on the host machine so that Docker containers can access it via `host.docker.internal`.

**What it does:**
1. Ensures Google Chrome is installed (auto-installs via Homebrew on macOS)
2. Ensures ChromeDriver is installed (auto-installs via Homebrew on macOS)
3. Kills any existing process on the target port
4. Starts ChromeDriver with open access for container connections

**Usage:**

```bash
# Start on default port 9515
./scripts/start-chromedriver.sh

# Custom port
CHROMEDRIVER_PORT=4444 ./scripts/start-chromedriver.sh
```

**From inside a container**, connect to ChromeDriver at:

```
http://host.docker.internal:9515
```

`host.docker.internal` is a built-in DNS name on Docker Desktop (macOS/Windows). On Linux, add `--add-host=host.docker.internal:host-gateway` to your `docker run` command.

**Example (Python/Selenium):**

```python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

options = Options()
options.add_argument("--headless=new")
driver = webdriver.Remote(
    command_executor="http://host.docker.internal:9515",
    options=options,
)
```

Note: Chrome runs on the host, not in the container. File paths in WebDriver commands (screenshots, downloads) refer to host filesystem paths.

# Bitcoin Signet Wallet

[![GitHub](https://img.shields.io/badge/GitHub-View%20on%20GitHub-blue)](https://github.com/replaid/bitcoin-wallet)

A command-line Bitcoin wallet for the Signet network, built with Ruby and the `bitcoinrb` gem. This wallet allows you to check your balance, send funds, and manage transactions using the mempool.space API.

## Prerequisites

- **Docker**: Ensure Docker and Docker Compose are installed.
  - On macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop).
  - On Linux: Install [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/).
  - Verify with:
    ```bash
    docker --version
    docker compose version
    ```
- **Internet Connection**: Required for initial gem installation and recording VCR cassettes for tests.

## Docker Setup

1. **Clone the Repository**:
   
   ```
   git clone https://github.com/replaid/bitcoin-wallet.git
   cd bitcoin-wallet
   ```
2. **Build the Docker Image:**
   
   ```
   docker compose build
   ```
   
   This builds the `wallet` and `test` services, installing Ruby dependencies in a persisted volume.
3. **Create Data Directory**: The wallet stores key data in the `./data` directory, persisted via a Docker volume.  
   
   ```
   mkdir -p data
   ```

## CLI Usage

Use the `wallet-docker.sh` script for all commands. The equivalent `docker compose` commands are provided for reference. The wrapper script automatically removes containers after execution, preventing orphan container warnings. If there are orphan containers, they can be removed with `docker compose up --remove-orphans`.

### Help

Displays available commands and the wallet address.

**Wrapper command:**

```bash
./wallet-docker.sh help
```

**Docker command:**

```bash
docker compose run --rm wallet help
```

### Install dependencies

Install Ruby gems using Bundler.

**Wrapper command:**

```bash
./wallet-docker.sh bundle
```

**Docker command:**

```bash
docker compose run --rm --entrypoint "bundle" wallet
```

### Run tests

Run the RSpec test suite.

**Wrapper command:**

```bash
./wallet-docker.sh test
```

**Docker command:**

```bash
docker compose run --rm test
```

### Check balance

Displays the current balance and wallet address.

**Wrapper command:**

```bash
./wallet-docker.sh balance
```

**Docker command:**

```bash
docker compose run --rm wallet balance
```

### Send funds

Sends the specified amount (in BTC) to the given Signet address.

**Wrapper command:**

```bash
./wallet-docker.sh send 0.01 tb1q...address
```

**Docker command:**

```bash
docker compose run --rm wallet send 0.01 tb1q...address
```

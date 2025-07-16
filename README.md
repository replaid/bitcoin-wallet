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

### Check balance
```
docker compose run --rm wallet ruby bin/wallet_cli.rb balance
```
    
Displays the current balance and wallet address.


### Send funds

```
docker compose run --rm wallet ruby bin/wallet_cli.rb send 0.01 tb1q...address
```

Sends the specified amount (in BTC) to the given Signet address.

### Help

```
docker compose run --rm wallet ruby bin/wallet_cli.rb help
```

Displays available commands and the wallet address.


## Development

Run tests:

```bash
docker compose run test
```

Install dependencies:

```bash
docker compose run --entrypoint "bundle" wallet
```


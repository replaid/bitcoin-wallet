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
docker compose run --rm wallet balance
```
    
Displays the current balance and wallet address.


### Send funds

```
docker compose run --rm wallet send 0.01 tb1q...address
```

Sends the specified amount (in BTC) to the given Signet address.

### Help

```
docker compose run --rm wallet help
```

Displays available commands and the wallet address.


## Development

Run tests:

```bash
docker compose run wallet rspec
```

or this way:

```bash
docker compose run --entrypoint "bundle exec rspec" wallet
```

Install dependencies:

```bash
docker compose run --entrypoint "bundle" wallet
```

## Additional Notes

* **Dockerfile and docker-compose.yml**: The versions from the previous response (with `BUNDLE_PATH=/app/.bundle` and `bundle-data` volume) are assumed to be in place. If not, ensure they’re updated as provided.  
* **broadcast\_transaction Specs**: The specs from the earlier response (with VCR for the success case and WebMock for error cases) should work fine, as the orphan container issue is unrelated to the Ruby code.  
* **Docker Desktop (macOS)**: Since enabling `docker.sock` access fixed the earlier issue, ensure Docker Desktop remains running and configured correctly.  
* **Gemfile**: Ensure test dependencies (`rspec`, `webmock`, `vcr`) are in your `Gemfile`, as they’re required for the `broadcast_transaction` specs.

If you see any further issues (e.g., test failures, persistent orphans), share the output, and I’ll help debug. Let me know if you need additional tweaks to the `README.md` or other parts of the setup\!
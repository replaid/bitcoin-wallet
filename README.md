# Bitcoin Signet Wallet

[![GitHub](https://img.shields.io/badge/GitHub-View%20on%20GitHub-blue)](https://github.com/replaid/bitcoin-wallet)

## CLI Usage

```bash
# Check balance
docker compose run wallet balance

# Send funds
docker compose run wallet send 0.01 tb1q...address

# Help
docker compose run wallet help
```

## Docker Setup

1. Build the image:
```bash
docker compose build
```

2. Persist wallet data:
```bash
mkdir data
docker compose run -v ./data:/app/data wallet balance
```

## Development

Run tests:
```bash
docker compose run wallet rspec
```

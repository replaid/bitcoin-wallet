# Bitcoin Signet Wallet

## CLI Usage

```bash
# Check balance
docker-compose run wallet balance

# Send funds
docker-compose run wallet send 0.01 tb1q...address

# Help
docker-compose run wallet help
```

## Docker Setup

1. Build the image:
```bash
docker-compose build
```

2. Run commands (see above)

3. Persist wallet data:
```bash
mkdir data
docker-compose run -v ./data:/app/data wallet balance
```

## Development

Run tests:
```bash
docker-compose run wallet rspec
```

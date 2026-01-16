# GitPuller Add-on

A Home Assistant add-on that automatically pulls Git private repositories to HASS local file system using SSH private key

## ⚠️ Disclaimer

**This add-on was created for my personal needs.** Its development, features, and future updates depend solely on my own requirements. 

- No guarantees are made regarding functionality, compatibility, or support
- Use at your own risk
- Feature requests may or may not be implemented based on my personal use case
- The add-on may change or be discontinued at any time without notice

If you choose to use this add-on, you accept these terms and understand that it is provided "as-is" without any warranty.


## Features

- **Automatic Git Pull**: Clones repositories if they don't exist, or pulls latest changes if they do
- **SSH Key Authentication**: Securely authenticate with Git providers using your private SSH key
- **Multiple Repository Support**: Configure and sync multiple repositories simultaneously
- **Universal URL Conversion**: Automatically converts HTTP/HTTPS URLs to SSH format for any Git host
- **Periodic Sync**: Continuously syncs repositories every 10 minutes

## Configuration

| Option | Description |
|--------|-------------|
| `general_private_key` | Your SSH private key for Git authentication |
| `general_key_protocol` | The key protocol (e.g., `rsa`, `ed25519`) |
| `repos` | Array of repository configurations |

### Repository Configuration

Each repository in the `repos` array supports the following options:

| Option | Description |
|--------|-------------|
| `repository` | The Git repository URL (HTTPS or SSH format) |
| `git_branch` | The branch to checkout and sync |
| `destination_dir` | Local directory where the repository will be cloned |
| `git_remote` | The remote name (default: `origin`) |

## Example Configuration

```yaml
general_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  your-private-key-here
  -----END OPENSSH PRIVATE KEY-----
general_key_protocol: ed25519
repos:
  - repository: https://github.com/username/repo.git
    git_branch: main
    destination_dir: /config
    git_remote: origin
```

## How It Works

1. The add-on sets up SSH authentication using your provided private key
2. For each configured repository:
   - HTTP/HTTPS URLs are automatically converted to SSH format
   - If the repository doesn't exist locally, it clones it
   - If the repository exists, it fetches and pulls the latest changes
3. The sync process repeats every 10 minutes

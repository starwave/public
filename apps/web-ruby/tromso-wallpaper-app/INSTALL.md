# Installation Guide - Tromso Wallpaper App (Ruby)

Complete installation instructions for Mac OSX and Ubuntu 22.04.

---

## Table of Contents

- [Mac OSX Installation](#mac-osx-installation)
- [Ubuntu 22.04 Installation](#ubuntu-2204-installation)
- [Quick Start](#quick-start)
- [Troubleshooting](#troubleshooting)

---

## Mac OSX Installation

### Prerequisites

- **Homebrew**: If not installed, run:
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

### Step 1: Install Ruby

```bash
# Install rbenv (Ruby version manager)
brew install rbenv ruby-build

# Initialize rbenv
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

# Install Ruby 3.3
rbenv install 3.3.0
rbenv global 3.3.0

# Verify installation
ruby --version  # Should show ruby 3.3.0 or higher
```

**Alternative: Using Ruby that comes with macOS**
```bash
# macOS includes Ruby, but it's usually outdated
ruby --version  # Check current version

# If version is 3.0+, you can use it
# Otherwise, use rbenv method above
```

### Step 2: Install Bundler

```bash
gem install bundler
bundler --version
```

### Step 3: Clone/Navigate to Project

```bash
cd /Users/starwave/thirdwave_git/shared/ruby/tromso-wallpaper-app
```

### Step 4: Install Dependencies

```bash
# Install all gems
bundle install

# If you get permission errors, try:
bundle install --path vendor/bundle
```

### Step 5: Run the Application

```bash
# Option 1: Using Rake
bundle exec rake server

# Option 2: Using rackup directly
bundle exec rackup -p 3001

# Option 3: With auto-reload (development)
bundle exec rake dev
```

Access the app at: **http://localhost:3001**

### Step 6: Run Tests

```bash
# Run all tests
bundle exec rspec

# Or using Rake
bundle exec rake spec
```

---

## Ubuntu 22.04 Installation

### Step 1: Update System

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### Step 2: Install Ruby and Dependencies

#### Method 1: Using rbenv (Recommended)

```bash
# Install dependencies
sudo apt-get install -y git curl libssl-dev libreadline-dev zlib1g-dev \
  autoconf bison build-essential libyaml-dev libreadline-dev \
  libncurses5-dev libffi-dev libgdbm-dev

# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Add to PATH
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby 3.3
rbenv install 3.3.0
rbenv global 3.3.0

# Verify installation
ruby --version
```

#### Method 2: Using apt (Simpler but older version)

```bash
# Install Ruby from Ubuntu repositories
sudo apt-get install -y ruby-full ruby-bundler

# Verify installation
ruby --version
bundle --version
```

#### Method 3: Using RVM

```bash
# Install GPG keys
gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

# Install RVM
curl -sSL https://get.rvm.io | bash -s stable

# Load RVM
source ~/.rvm/scripts/rvm

# Install Ruby
rvm install 3.3.0
rvm use 3.3.0 --default

# Verify
ruby --version
```

### Step 3: Install Bundler

```bash
gem install bundler
bundler --version
```

### Step 4: Install Build Tools (if not already installed)

```bash
sudo apt-get install -y build-essential patch ruby-dev zlib1g-dev liblzma-dev
```

### Step 5: Navigate to Project

```bash
cd /home/starwave/thirdwave_git/shared/ruby/tromso-wallpaper-app
```

### Step 6: Install Dependencies

```bash
# Install all gems
bundle install

# If you encounter permission errors
bundle install --path vendor/bundle
```

### Step 7: Run the Application

```bash
# Option 1: Using Rake
bundle exec rake server

# Option 2: Using rackup
bundle exec rackup -p 3001

# Option 3: With auto-reload (development)
bundle exec rake dev

# Option 4: Using Puma directly
bundle exec puma -C config/puma.rb
```

Access the app at: **http://localhost:3001**

### Step 8: Run Tests

```bash
bundle exec rspec
```

### Step 9: Setup as a Service (Optional)

Create systemd service:

```bash
sudo nano /etc/systemd/system/tromso-wallpaper-app.service
```

Add the following content:

```ini
[Unit]
Description=Tromso Wallpaper App
After=network.target

[Service]
Type=simple
User=starwave
WorkingDirectory=/home/starwave/thirdwave_git/shared/ruby/tromso-wallpaper-app
Environment="RACK_ENV=production"
Environment="PORT=3001"
ExecStart=/home/starwave/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable tromso-wallpaper-app
sudo systemctl start tromso-wallpaper-app
sudo systemctl status tromso-wallpaper-app
```

---

## Quick Start

### After Installation

```bash
# Navigate to project
cd /path/to/tromso-wallpaper-app

# Install dependencies (first time only)
bundle install

# Run development server with auto-reload
bundle exec rake dev

# Or run production server
RACK_ENV=production bundle exec puma -C config/puma.rb
```

### Common Commands

```bash
# Install dependencies
bundle install

# Update dependencies
bundle update

# Run server
bundle exec rake server

# Run with auto-reload (development)
bundle exec rake dev

# Run tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/app_spec.rb

# Check code style
bundle exec rubocop

# Auto-fix code style issues
bundle exec rubocop -A

# Interactive console
bundle exec pry
```

---

## Environment Configuration

### Create .env file

```bash
cp .env.example .env
```

Edit `.env`:

```bash
# Server Configuration
PORT=3001
RACK_ENV=development

# API Configuration (if needed)
# API_BASE_URL=http://192.168.1.111:8080
```

---

## Troubleshooting

### Mac OSX Issues

#### Issue: "command not found: bundle"

**Solution**:
```bash
gem install bundler
# Or specify path
/usr/local/bin/gem install bundler
```

#### Issue: Permission denied installing gems

**Solution**:
```bash
# Use rbenv (recommended)
brew install rbenv
rbenv install 3.3.0
rbenv global 3.3.0

# Or install to vendor directory
bundle install --path vendor/bundle
```

#### Issue: Native extension build failed

**Solution**:
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install OpenSSL
brew install openssl
```

#### Issue: SSL certificate error

**Solution**:
```bash
# Update certificates
brew install openssl@3
brew upgrade openssl@3
```

### Ubuntu Issues

#### Issue: "Could not find gem"

**Solution**:
```bash
# Update RubyGems
gem update --system

# Install bundler
gem install bundler

# Try installing again
bundle install
```

#### Issue: Native extension build errors

**Solution**:
```bash
# Install build tools
sudo apt-get install -y build-essential patch ruby-dev zlib1g-dev liblzma-dev

# Install additional libraries
sudo apt-get install -y libssl-dev libreadline-dev libffi-dev libgdbm-dev
```

#### Issue: Permission errors

**Solution**:
```bash
# Install to local directory
bundle install --path vendor/bundle

# Or fix gem directory permissions
sudo chown -R $USER:$USER ~/.gem
```

#### Issue: Port already in use

**Solution**:
```bash
# Find process using port 3001
sudo lsof -i :3001

# Kill the process
kill -9 <PID>

# Or use a different port
PORT=3002 bundle exec rake server
```

#### Issue: rbenv: version `3.3.0` not installed

**Solution**:
```bash
# List available versions
rbenv install --list

# Install Ruby 3.3.0
rbenv install 3.3.0

# Set as global version
rbenv global 3.3.0

# Verify
ruby --version
```

---

## Verification

After installation, verify everything works:

```bash
# 1. Check Ruby version
ruby --version  # Should be 3.0 or higher

# 2. Check Bundler
bundle --version

# 3. Check dependencies
bundle check

# 4. Run tests
bundle exec rspec

# 5. Start server
bundle exec rake server

# 6. Test endpoint (in another terminal)
curl http://localhost:3001/health
# Should return: {"status":"ok","timestamp":"..."}
```

---

## Performance Tips

### Mac OSX

```bash
# Use jemalloc for better memory management
brew install jemalloc

# Run with jemalloc
LD_PRELOAD=/usr/local/lib/libjemalloc.dylib bundle exec puma -C config/puma.rb
```

### Ubuntu

```bash
# Install jemalloc
sudo apt-get install -y libjemalloc-dev

# Run with jemalloc
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 bundle exec puma -C config/puma.rb
```

---

## Uninstallation

### Mac OSX

```bash
# Remove project
rm -rf /path/to/tromso-wallpaper-app

# Optionally remove Ruby (if using rbenv)
rbenv uninstall 3.3.0

# Remove rbenv
brew uninstall rbenv
```

### Ubuntu

```bash
# Remove project
rm -rf /path/to/tromso-wallpaper-app

# Stop service (if installed)
sudo systemctl stop tromso-wallpaper-app
sudo systemctl disable tromso-wallpaper-app
sudo rm /etc/systemd/system/tromso-wallpaper-app.service

# Optionally remove Ruby (if using rbenv)
rbenv uninstall 3.3.0

# Remove rbenv
rm -rf ~/.rbenv
```

---

## Next Steps

After installation:

1. Copy frontend files to `public/` directory (React build output)
2. Configure environment variables in `.env`
3. Run tests to ensure everything works
4. Start the development server
5. For production, see [DEPLOYMENT.md](DEPLOYMENT.md)

---

## Support

- **Documentation**: See [README.md](README.md)
- **Deployment**: See [DEPLOYMENT.md](DEPLOYMENT.md)
- **Issues**: Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

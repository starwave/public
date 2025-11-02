# Quick Start Guide - Tromso Wallpaper App (Ruby)

Get up and running in under 5 minutes!

---

## 🚀 One-Command Setup

```bash
./setup.sh
```

That's it! The script will:
- ✅ Check Ruby version
- ✅ Install Bundler
- ✅ Install dependencies
- ✅ Setup environment
- ✅ Create directories
- ✅ Run tests
- ✅ Start server

---

## 📦 Manual Installation

### Mac OSX

```bash
# 1. Install Ruby (if needed)
brew install rbenv
rbenv install 3.3.0
rbenv global 3.3.0

# 2. Install dependencies
bundle install

# 3. Start server
bundle exec rake server
```

### Ubuntu

```bash
# 1. Install Ruby (if needed)
sudo apt-get install ruby-full ruby-bundler

# 2. Install dependencies
bundle install

# 3. Start server
bundle exec rake server
```

Access at: **http://localhost:3001**

---

## 🧪 Test It

```bash
# Run tests
bundle exec rspec

# Test endpoint
curl http://localhost:3001/health
```

---

## 📚 Documentation

### Essential Guides

| Guide | When to Use |
|-------|-------------|
| [README.md](README.md) | Overview and API docs |
| [INSTALL.md](INSTALL.md) | Detailed installation (Mac & Ubuntu) |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Production deployment |
| [COMPARISON.md](COMPARISON.md) | Compare with Node.js version |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | Complete project overview |

---

## 🛠️ Common Commands

```bash
# Development
bundle exec rake dev              # Start with auto-reload
bundle exec rake server           # Start server
bundle exec puma -C config/puma.rb # Start Puma directly

# Testing
bundle exec rspec                 # Run all tests
bundle exec rspec spec/app_spec.rb # Run specific test
bundle exec rake spec             # Run tests via Rake

# Code Quality
bundle exec rubocop               # Check code style
bundle exec rubocop -A            # Auto-fix issues

# Dependencies
bundle install                    # Install gems
bundle update                     # Update gems
bundle check                      # Verify dependencies
```

---

## 🐳 Docker Quick Start

```bash
# Build and run
docker compose -f docker-compose.dev.yml up --build

# Or build manually
docker build -t tromso-app-ruby .
docker run -p 3001:3001 tromso-app-ruby
```

---

## 🔧 Configuration

### Environment Variables (.env)

```bash
PORT=3001
RACK_ENV=development
WEB_CONCURRENCY=2
MAX_THREADS=5
```

### Quick Customization

```ruby
# config/puma.rb
workers 4              # Change worker count
threads 10, 10         # Change thread pool
```

---

## 📊 API Endpoints

### Health Check
```bash
curl http://localhost:3001/health
```

### Theme Library
```bash
curl http://localhost:3001/maramboi?a=g
```

### Wallpaper Request
```bash
curl "http://localhost:3001/ngorongoro?a=tweb&d=1920x1080&t=default2"
```

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
lsof -i :3001
kill -9 <PID>
```

### Bundle Install Fails
```bash
bundle install --path vendor/bundle
```

### Ruby Version Error
```bash
rbenv install 3.3.0
rbenv global 3.3.0
```

---

## 🚀 Production Deployment

### Quick Deploy

```bash
# 1. Install for production
bundle install --deployment --without development test

# 2. Run production server
RACK_ENV=production bundle exec puma -C config/puma.rb
```

### With Systemd

See [DEPLOYMENT.md](DEPLOYMENT.md#systemd-service) for complete setup.

---

## 🎯 Next Steps

1. ✅ **Setup complete** - Server running
2. 📖 **Read API docs** - [README.md](README.md#api-endpoints)
3. 🧪 **Run tests** - `bundle exec rspec`
4. 🚀 **Deploy** - [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 💡 Tips

### Development

```bash
# Auto-reload on file changes
bundle exec rerun -- rackup -p 3001

# Interactive console
bundle exec pry
```

### Performance

```bash
# More workers
WEB_CONCURRENCY=4 bundle exec puma

# More threads
MAX_THREADS=10 bundle exec puma

# With jemalloc (Linux)
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 bundle exec puma
```

### Monitoring

```bash
# Watch logs
tail -f log/puma_access.log

# Check processes
ps aux | grep puma

# Memory usage
ps aux | grep puma | awk '{print $6}'
```

---

## 🆚 Ruby vs Node.js

| Feature | Ruby | Node.js |
|---------|------|---------|
| Setup Time | 2 min | 3 min |
| Lines of Code | Less | More |
| Build Step | No | Yes |
| Memory Usage | 30-50MB | 40-60MB |
| Best For | APIs | Full-stack |

See [COMPARISON.md](COMPARISON.md) for detailed analysis.

---

## 📞 Getting Help

1. **Installation issues** → [INSTALL.md](INSTALL.md#troubleshooting)
2. **Deployment problems** → [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting)
3. **API questions** → [README.md](README.md#api-endpoints)
4. **General info** → [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

---

## ✅ Verification Checklist

After setup, verify:

```bash
# 1. Ruby version
ruby --version        # Should be 3.0+

# 2. Dependencies
bundle check          # Should be satisfied

# 3. Tests
bundle exec rspec     # Should pass

# 4. Server
bundle exec rake server

# 5. Health check (in another terminal)
curl http://localhost:3001/health
# Should return: {"status":"ok",...}
```

---

## 🎉 Success!

Your Tromso Wallpaper App (Ruby) is now running!

**Access**: http://localhost:3001
**Health**: http://localhost:3001/health
**API Docs**: See [README.md](README.md)

Happy coding! 🚀

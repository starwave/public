#!/bin/bash

# Quick setup script for Tromso Wallpaper App (Ruby)
# Works on Mac OSX and Ubuntu

set -e

echo "=========================================="
echo "Tromso Wallpaper App (Ruby) - Setup"
echo "=========================================="
echo ""

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=Linux;;
    Darwin*)    PLATFORM=Mac;;
    *)          PLATFORM="UNKNOWN:${OS}"
esac

echo "Detected platform: ${PLATFORM}"
echo ""

# Check Ruby version
check_ruby() {
    echo "Checking Ruby installation..."
    if command -v ruby &> /dev/null; then
        RUBY_VERSION=$(ruby --version | awk '{print $2}' | cut -d'p' -f1)
        echo "✅ Ruby found: ${RUBY_VERSION}"

        # Check if version is 3.0+
        MAJOR_VERSION=$(echo ${RUBY_VERSION} | cut -d'.' -f1)
        if [ "$MAJOR_VERSION" -lt 3 ]; then
            echo "⚠️  Warning: Ruby ${RUBY_VERSION} is installed, but 3.0+ is recommended"
            echo ""
            echo "To install Ruby 3.3:"
            if [ "$PLATFORM" = "Mac" ]; then
                echo "  brew install rbenv"
                echo "  rbenv install 3.3.0"
                echo "  rbenv global 3.3.0"
            else
                echo "  See INSTALL.md for detailed instructions"
            fi
            echo ""
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        echo "❌ Ruby not found"
        echo ""
        echo "Installation instructions:"
        if [ "$PLATFORM" = "Mac" ]; then
            echo "  brew install rbenv"
            echo "  rbenv install 3.3.0"
            echo "  rbenv global 3.3.0"
        else
            echo "  See INSTALL.md for detailed instructions"
        fi
        exit 1
    fi
    echo ""
}

# Check Bundler
check_bundler() {
    echo "Checking Bundler..."
    if command -v bundle &> /dev/null; then
        BUNDLER_VERSION=$(bundle --version | awk '{print $3}')
        echo "✅ Bundler found: ${BUNDLER_VERSION}"
    else
        echo "❌ Bundler not found"
        echo "Installing Bundler..."
        gem install bundler
        echo "✅ Bundler installed"
    fi
    echo ""
}

# Install dependencies
install_deps() {
    echo "Installing dependencies..."
    bundle install

    if [ $? -eq 0 ]; then
        echo "✅ Dependencies installed successfully"
    else
        echo "❌ Failed to install dependencies"
        echo ""
        echo "Try:"
        echo "  bundle install --path vendor/bundle"
        exit 1
    fi
    echo ""
}

# Setup environment
setup_env() {
    echo "Setting up environment..."
    if [ ! -f .env ]; then
        cp .env.example .env
        echo "✅ Created .env file from .env.example"
        echo "   Edit .env to customize configuration"
    else
        echo "✅ .env file already exists"
    fi
    echo ""
}

# Create directories
create_dirs() {
    echo "Creating directories..."
    mkdir -p log tmp public
    echo "✅ Directories created"
    echo ""
}

# Run tests
run_tests() {
    echo "Running tests..."
    bundle exec rspec

    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ All tests passed"
    else
        echo ""
        echo "⚠️  Some tests failed"
        echo "   Review the output above"
    fi
    echo ""
}

# Main setup
main() {
    check_ruby
    check_bundler
    install_deps
    setup_env
    create_dirs

    echo "=========================================="
    echo "✅ Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Review .env configuration"
    echo "  2. Copy frontend files to public/ directory (if applicable)"
    echo "  3. Start the server:"
    echo ""
    echo "     bundle exec rake server"
    echo ""
    echo "  Access at: http://localhost:3001"
    echo ""
    echo "Other commands:"
    echo "  bundle exec rake dev       # Start with auto-reload"
    echo "  bundle exec rspec          # Run tests"
    echo "  bundle exec rubocop        # Check code style"
    echo ""

    # Ask to run tests
    read -p "Run tests now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_tests
    fi

    # Ask to start server
    read -p "Start development server? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Starting server..."
        echo "Press Ctrl+C to stop"
        echo ""
        bundle exec rake dev
    fi
}

# Run main function
main

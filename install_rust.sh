#!/bin/bash

# Install Rust and required dependencies for PDF OCR
echo "🦀 Installing Rust toolchain for PDF OCR support..."

# Install Rust using rustup
if ! command -v rustup &> /dev/null; then
    echo "📥 Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
else
    echo "✅ Rust is already installed"
fi

# Verify Rust installation
echo "🔍 Verifying Rust installation..."
rustc --version
cargo --version

# Install additional targets that might be needed
echo "🎯 Installing additional Rust targets..."
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin

# Update Rust components
echo "🔄 Updating Rust components..."
rustup update

echo "✅ Rust installation complete!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.cargo/env"
echo "2. Run: dart pub get"
echo "3. Test the PDF OCR functionality"

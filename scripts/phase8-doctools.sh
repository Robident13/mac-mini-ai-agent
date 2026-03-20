#!/bin/bash
set -e

echo "========================================="
echo "Phase 8 — Document Tools (Word & PDF)"
echo "========================================="

# Check Python
if command -v python3 &>/dev/null; then
  echo "[OK] Python3 installed: $(python3 --version)"
else
  echo "[INSTALL] Installing Python via Homebrew..."
  brew install python
fi

# Check pip
if command -v pip3 &>/dev/null; then
  echo "[OK] pip3 available"
else
  echo "[ERROR] pip3 not found. Try: brew install python"
  exit 1
fi

# Install Python document libraries
echo ""
echo "[INSTALL] Installing document libraries..."

PACKAGES=(
  "python-docx"    # Read/write/create Word (.docx) files
  "pypdf"          # Read and extract text from PDFs
  "pdf2docx"       # Convert PDF to Word (preserves layout/tables)
  "docx2pdf"       # Convert Word to PDF
  "reportlab"      # Create new PDFs from scratch
  "pytesseract"    # OCR for scanned/image PDFs
)

for pkg in "${PACKAGES[@]}"; do
  echo "  Installing $pkg..."
  pip3 install "$pkg" --quiet
done

echo "[OK] All Python document libraries installed"

# Install Tesseract OCR engine
echo ""
if command -v tesseract &>/dev/null; then
  echo "[OK] Tesseract OCR already installed: $(tesseract --version 2>&1 | head -1)"
else
  echo "[INSTALL] Installing Tesseract OCR engine..."
  brew install tesseract
fi

# Verify installations
echo ""
echo "[TEST] Verifying installations..."
python3 -c "
libs = {
    'docx': 'python-docx (Word read/write)',
    'pypdf': 'pypdf (PDF read)',
    'pdf2docx': 'pdf2docx (PDF to Word)',
    'docx2pdf': 'docx2pdf (Word to PDF)',
    'reportlab': 'reportlab (PDF create)',
    'pytesseract': 'pytesseract (OCR)',
}
for module, name in libs.items():
    try:
        __import__(module)
        print(f'  [OK] {name}')
    except ImportError:
        print(f'  [FAIL] {name}')
"

echo ""
echo "========================================="
echo "Phase 8 COMPLETE"
echo "========================================="
echo ""
echo "These tools are now available to Aider and Claude Code."
echo "Just ask in natural language:"
echo ""
echo "  \"Read invoice.pdf and extract the total\""
echo "  \"Edit paragraph 3 in report.docx\""
echo "  \"Convert this Word doc to PDF\""
echo "  \"Create a new PDF report with these sections\""
echo "  \"This PDF is a scan — use OCR to read it\""
echo "  \"Summarise all .docx files in this folder\""
echo ""
echo "Libraries installed:"
echo "  python-docx  — Read/write Word files"
echo "  pypdf        — Read PDFs"
echo "  pdf2docx     — PDF to Word conversion"
echo "  docx2pdf     — Word to PDF conversion"
echo "  reportlab    — Create PDFs from scratch"
echo "  pytesseract  — OCR for scanned PDFs"
echo "  tesseract    — OCR engine (system binary)"
echo "========================================="

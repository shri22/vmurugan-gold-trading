#!/bin/bash

# Script to normalize line endings across the repository
# This will fix the CRLF/LF issue between Windows and Mac

echo "🔧 Normalizing line endings..."
echo ""

# Remove the index and force Git to rescan the working directory
echo "Step 1: Removing Git index..."
git rm --cached -r .

echo ""
echo "Step 2: Re-normalizing all files..."
git reset --hard

echo ""
echo "Step 3: Re-adding all files with correct line endings..."
git add --renormalize .

echo ""
echo "✅ Done! Line endings have been normalized."
echo ""
echo "Next steps:"
echo "1. Review the changes: git status"
echo "2. Commit the normalized files: git commit -m 'Normalize line endings'"
echo "3. Push to remote: git push"
echo ""
echo "⚠️  Note: After this, all team members should pull and run:"
echo "   git rm --cached -r ."
echo "   git reset --hard"


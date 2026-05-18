import os
import shutil
import re

BASE = 'lib'

# ── 1. Screen destinations ─────────────────────────────────────────────────────
TRANSACTION_SCREENS_DEST = 'lib/features/transaction/presentation/screens'
WALLET_SCREENS_DEST       = 'lib/features/wallet/presentation/screens'

SCREEN_MAP = {
    'lib/screens/home_screen.dart':                 TRANSACTION_SCREENS_DEST,
    'lib/screens/history_screen.dart':              TRANSACTION_SCREENS_DEST,
    'lib/screens/add_income_screen.dart':           TRANSACTION_SCREENS_DEST,
    'lib/screens/add_expense_screen.dart':          TRANSACTION_SCREENS_DEST,
    'lib/screens/add_adjustment_screen.dart':       TRANSACTION_SCREENS_DEST,
    'lib/screens/transfer_screen.dart':             TRANSACTION_SCREENS_DEST,
    'lib/screens/filtered_transactions_screen.dart':TRANSACTION_SCREENS_DEST,
    'lib/screens/add_transaction_screen.dart':      TRANSACTION_SCREENS_DEST,
    'lib/screens/wallet_management_screen.dart':    WALLET_SCREENS_DEST,
}

os.makedirs(TRANSACTION_SCREENS_DEST, exist_ok=True)
os.makedirs(WALLET_SCREENS_DEST, exist_ok=True)

for src, dest_dir in SCREEN_MAP.items():
    if os.path.exists(src):
        dest = os.path.join(dest_dir, os.path.basename(src))
        shutil.copy2(src, dest)
        print(f'  copied: {src} -> {dest}')
    else:
        print(f'  MISSING (skip): {src}')

# ── 2. Import & class name replacements ────────────────────────────────────────
REPLACEMENTS = [
    # Old model imports → new entity imports
    (
        "package:fin_track/models/transaction_model.dart",
        "package:fin_track/features/transaction/domain/entities/transaction_entity.dart"
    ),
    (
        "package:fin_track/models/wallet_model.dart",
        "package:fin_track/features/wallet/domain/entities/wallet_entity.dart"
    ),
    # Old provider imports → new provider imports
    (
        "package:fin_track/providers/transaction_provider.dart",
        "package:fin_track/features/transaction/presentation/providers/transaction_providers.dart"
    ),
    (
        "package:fin_track/providers/wallet_provider.dart",
        "package:fin_track/features/wallet/presentation/providers/wallet_providers.dart"
    ),
    # Old service import (should not remain, but just in case)
    (
        "package:fin_track/services/firestore_service.dart",
        "// REMOVED: firestore_service — use providers instead"
    ),
    # Screen path updates (for screens that import other screens — rare, but safe to have)
    (
        "package:fin_track/screens/",
        "package:fin_track/features/transaction/presentation/screens/"
    ),
    # Class name renames
    ("TransactionModel", "TransactionEntity"),
    ("WalletModel",      "WalletEntity"),
    # FirestoreService direct references in providers (clean up)
    ("FirestoreService", "// FirestoreService removed"),
]

# Files to update — all dart files under lib/
def find_dart_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        # Skip old screens dir (we will delete it)
        dirnames[:] = [d for d in dirnames if d != '__pycache__']
        for fname in filenames:
            if fname.endswith('.dart'):
                yield os.path.join(dirpath, fname)

updated = []
for filepath in find_dart_files(BASE):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = content
    for old, new in REPLACEMENTS:
        new_content = new_content.replace(old, new)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        updated.append(filepath)
        print(f'  updated: {filepath}')

print(f'\nTotal files updated: {len(updated)}')

# ── 3. Fix wallet_management_screen import (it references main_layout correctly) ─
# The screen was moved to features/wallet/presentation/screens/ but main_layout is still
# in lib/widgets/ — relative imports break, but package imports are fine.
# All imports use `package:fin_track/...` so they're fine as-is.

print('\nAll done! Now check for wallet_management_screen screen import:')
wms = os.path.join(WALLET_SCREENS_DEST, 'wallet_management_screen.dart')
if os.path.exists(wms):
    with open(wms, 'r', encoding='utf-8') as f:
        txt = f.read()
    print('  wallet_management_screen references main_layout:', 'main_layout' in txt)

# Removed Images Fix

## Problem

Umunhum was showing deleted/removed images in search results because:

1. Prado marked images as "removed" in database but didn't delete vectors from Qdrant
2. Umunhum searched Qdrant directly without checking database status
3. Removed images appeared in results, showing "Image Not Available" errors

## Solution (3-Part Fix)

### 1. Scanner Now Deletes Vectors (Prado)

**File**: `prado/scanner.py:147-159`

When files are deleted and marked as "removed", Prado now:

- Looks up the pid in database
- Deletes the vector from Qdrant
- Then marks as removed in database

**Effect**: Future deleted files won't appear in search results

### 2. Status Stored in Qdrant Payload (Prado)

**File**: `prado/scanner.py:251`

New vectors now include `status: "done"` in Qdrant payload.

**Effect**: Enables filtering at query time

### 3. Umunhum Filters Removed Images (Umunhum)

**File**: `umunhum/server/services/qdrant.js:27-34`

Search now includes filter:

```javascript
filter: {
  should: [
    { key: "status", match: { value: "done" } }, // New vectors
    { is_empty: { key: "status" } }, // Old vectors
  ];
}
```

**Effect**: Removed images excluded from search results

### 4. Cleanup Script for Existing Removed Images (One-Time)

**File**: `prado/cleanup_removed.py`

Run once to clean up existing removed images:

```bash
cd /home/starwave/thirdwave_git/shared/python/prado
python3 cleanup_removed.py
```

**Effect**: Deletes Qdrant vectors for all currently removed images

## Deployment

### 1. Deploy Prado fixes:

```bash
# On Prado machine (11.11.11.11)
cd /home/starwave/thirdwave_git/shared/python/prado
sudo systemctl restart prado
```

### 2. Run cleanup script (one-time):

```bash
cd /home/starwave/thirdwave_git/shared/python/prado
source venv/bin/activate
python3 cleanup_removed.py
```

### 3. Deploy Umunhum fixes:

```bash
# On Umunhum machine (11.11.11.12)
cd /home/starwave/thirdwave_git/shared/nodejs/umunhum
# Restart server (npm run dev will auto-reload)
```

## Verification

After deployment:

1. **Delete a file** from PRADOROOT
2. **Run a scan**: The file should be marked as removed AND vector deleted
3. **Search for similar images**: The deleted file should NOT appear
4. **Check logs**: Should see "Deleted vector for removed image: ..."

## Notes

- Old vectors (before this fix) don't have status field → included by default
- Filter uses `should` (OR logic) to include both old and new vectors
- Searches now request `topK * 2` results to ensure enough after filtering
- Cleanup script is idempotent (safe to run multiple times)
- Status in database is still source of truth, Qdrant payload is a cache

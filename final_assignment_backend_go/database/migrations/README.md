# Database Migrations

This directory contains database migration scripts for the Traffic Management System.

## Migration Tool

We use [golang-migrate](https://github.com/golang-migrate/migrate) for database migrations.

### Installation

```bash
# Windows (Scoop)
scoop install migrate

# Mac (Homebrew)
brew install golang-migrate

# Or download binary
# https://github.com/golang-migrate/migrate/releases
```

### Usage

#### Apply Migrations (Up)

```bash
# Apply all pending migrations
migrate -path database/migrations -database "mysql://user:password@tcp(localhost:3306)/traffic_db" up

# Apply specific number of migrations
migrate -path database/migrations -database "mysql://user:password@tcp(localhost:3306)/traffic_db" up 1
```

#### Rollback Migrations (Down)

```bash
# Rollback last migration
migrate -path database/migrations -database "mysql://user:password@tcp(localhost:3306)/traffic_db" down 1

# Rollback all migrations
migrate -path database/migrations -database "mysql://user:password@tcp(localhost:3306)/traffic_db" down
```

#### Check Migration Status

```bash
migrate -path database/migrations -database "mysql://user:password@tcp(localhost:3306)/traffic_db" version
```

#### Force Version (if migration fails)

```bash
# Force set version (use with caution!)
migrate -path database/migrations -database "mysql://user:password@tcp(localhost:3306)/traffic_db" force <version>
```

## Migrations

### 000001: Account Driver Link

**Purpose**: Connect driver_information with sys_user authentication system

**Changes**:
- Add `auth_user_id` to `driver_information` table
- Add `driver_id` to business tables (vehicle, fine, payment, appeal)
- Create foreign key constraints
- Create performance indexes

**Files**:
- `000001_account_driver_link.up.sql`
- `000001_account_driver_link.down.sql`

### 000002: Payment Version

**Purpose**: Add optimistic locking to payment records

**Changes**:
- Add `version` column to `payment_record`
- Create index for version queries

**Usage**:
```go
// Update with version check
UPDATE payment_record 
SET amount = ?, status = ?, version = version + 1 
WHERE payment_id = ? AND version = ?
```

**Files**:
- `000002_payment_version.up.sql`
- `000002_payment_version.down.sql`

### 000003: Request History Defaults

**Purpose**: Add default values to sys_request_history for better data quality

**Changes**:
- Set default values for `request_method`, `request_url`, `business_type`
- Update existing NULL values

**Files**:
- `000003_request_history_defaults.up.sql`
- `000003_request_history_defaults.down.sql`

## Best Practices

### Before Running Migrations

1. **Backup Database**
   ```bash
   mysqldump -u user -p traffic_db > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Test on Staging**
   - Always test migrations on staging environment first
   - Verify data integrity after migration

3. **Check Current Version**
   ```bash
   migrate -path database/migrations -database "..." version
   ```

### Migration Guidelines

1. **Naming Convention**: `<version>_<description>.up.sql` and `<version>_<description>.down.sql`
2. **Idempotency**: Use `IF NOT EXISTS` / `IF EXISTS` where possible
3. **Backwards Compatibility**: Ensure applications can work during migration
4. **Small Steps**: Break large migrations into smaller, reversible steps
5. **Data Migration**: Separate schema changes from data changes when possible

### Creating New Migrations

```bash
# Create new migration files
migrate create -ext sql -dir database/migrations -seq <migration_name>
```

Example:
```bash
migrate create -ext sql -dir database/migrations -seq add_user_status
# Creates:
# - 000004_add_user_status.up.sql
# - 000004_add_user_status.down.sql
```

## Production Deployment

### Step 1: Backup

```bash
# Full backup
mysqldump -u user -p --single-transaction --routines --triggers traffic_db > backup.sql

# Verify backup
mysql -u user -p test_db < backup.sql
```

### Step 2: Apply Migrations

```bash
# Dry run (check what will be applied)
migrate -path database/migrations -database "..." version

# Apply migrations
migrate -path database/migrations -database "..." up

# Verify
migrate -path database/migrations -database "..." version
```

### Step 3: Verify Data

```sql
-- Check driver-auth links
SELECT COUNT(*) FROM driver_information WHERE auth_user_id IS NOT NULL;

-- Check payment versions
SELECT COUNT(*) FROM payment_record WHERE version >= 0;

-- Check request history defaults
SELECT COUNT(*) FROM sys_request_history WHERE request_method = 'UNKNOWN';
```

### Rollback Plan

If migration fails:

```bash
# Rollback last migration
migrate -path database/migrations -database "..." down 1

# Restore from backup (if needed)
mysql -u user -p traffic_db < backup.sql
```

## Troubleshooting

### Migration Stuck

```bash
# Check dirty state
migrate -path database/migrations -database "..." version

# If dirty, force version (after manual fix)
migrate -path database/migrations -database "..." force <version>
```

### Foreign Key Errors

- Check that referenced tables/columns exist
- Verify data integrity before adding constraints
- Use `ON DELETE SET NULL` for optional relationships

### Performance Issues

- Run migrations during low-traffic periods
- Monitor query execution time
- Consider using `ALGORITHM=INPLACE` for large tables (MySQL 5.6+)

## CI/CD Integration

### Automated Migrations

```yaml
# .github/workflows/deploy.yml
- name: Run Database Migrations
  run: |
    migrate -path database/migrations \
            -database "${{ secrets.DATABASE_URL }}" \
            up
```

### Validation

```bash
# Validate migration files
migrate -path database/migrations -database "..." validate

# Test migrations on CI
migrate -path database/migrations -database "test_db_url" up
migrate -path database/migrations -database "test_db_url" down
```

---

**⚠️ Important**: Always backup your database before running migrations in production!

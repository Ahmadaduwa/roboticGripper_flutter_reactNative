# Database Schema Documentation

## Mock Database (Backend)

### Table: `teachingpatterns`

| Column | Type | PK | FK | Nullable |
|--------|------|----|----|----------|
| id | INTEGER | ✓ |  | ✗ |
| name | VARCHAR |  |  | ✗ |
| created_at | DATETIME |  |  | ✗ |

### Table: `patternsteps`

| Column | Type | PK | FK | Nullable |
|--------|------|----|----|----------|
| id | INTEGER | ✓ |  | ✗ |
| pattern_id | INTEGER |  | ✓ | ✓ |
| sequence_order | INTEGER |  |  | ✗ |
| action_type | VARCHAR |  |  | ✗ |
| j1 | FLOAT |  |  | ✗ |
| j2 | FLOAT |  |  | ✗ |
| j3 | FLOAT |  |  | ✗ |
| j4 | FLOAT |  |  | ✗ |
| j5 | FLOAT |  |  | ✗ |
| j6 | FLOAT |  |  | ✗ |
| gripper_angle | INTEGER |  |  | ✗ |
| wait_time | FLOAT |  |  | ✗ |

**Foreign Keys:**
- `pattern_id` → `teachingpatterns.id`

### Table: `runhistory`

| Column | Type | PK | FK | Nullable |
|--------|------|----|----|----------|
| id | INTEGER | ✓ |  | ✗ |
| filename | VARCHAR |  |  | ✗ |
| pattern_id | INTEGER |  |  | ✗ |
| pattern_name | VARCHAR |  |  | ✗ |
| cycle_target | INTEGER |  |  | ✗ |
| cycle_completed | INTEGER |  |  | ✗ |
| max_force | FLOAT |  |  | ✗ |
| status | VARCHAR |  |  | ✗ |
| created_at | DATETIME |  |  | ✗ |


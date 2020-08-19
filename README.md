# MySQL Autocomplete Search

This is a simple and efficient implementation of autocomplete. The main idea is from [prefixy/prefixy]([https://github.com/prefixy/prefixy](https://github.com/prefixy/prefixy)) It shows suggestions sorted by scores and it also supports multitenancy.

An example of autocomplete is Google search field:

![Google autocomplete](images/google_autocomplete.gif)

## Requirements

+ MySQL 5+

## Installation

Import `initialize.sql` into your database. You can also import `seed.sql` for demo data.

## Database schema

### Table `apps`

| Key_name | Column_name | Non_unique | Index_type  |
|----------|-------------|------------|-------------|
| PRIMARY  | id          |          0 | BTREE       |
| app_key  | app_key     |          0 | BTREE       |

#### Indexes:

| Non_unique | Key_name | Column_name | Index_type |
|------------|----------|-------------|------------|
|          0 | PRIMARY  | id          | BTREE      |
|          0 | app_key  | app_key     | BTREE      |

### Table `prefixes`

| Field  | Type         | Null | Key | Default | Extra          |
|--------|--------------|------|-----|---------|----------------|
| id     | int(11)      | NO   | PRI | NULL    | auto_increment |
| app_id | int(11)      | NO   | MUL | NULL    |                |
| prefix | varchar(255) | NO   | MUL | NULL    |                |


#### Indexes

| Key_name      | Column_name         | Non_unique | Index_type |
|---------------|---------------------|------------|------------|
| PRIMARY       | id                  |          0 | BTREE      |
| app_id-prefix | app_id, prefix      |          0 | BTREE      |
| prefix        | prefix              |          1 | BTREE      |

### Table `completions`

| Field      | Type         | Null | Key | Default | Extra          |
|------------|--------------|------|-----|---------|----------------|
| id         | int(11)      | NO   | PRI | NULL    | auto_increment |
| prefix_id  | int(11)      | NO   | MUL | NULL    |                |
| completion | varchar(255) | NO   |     | NULL    |                |
| rank       | int(11)      | NO   |     | NULL    |                |

#### Indexes

| Key_name             | Column_name             | Non_unique | Index_type |
|----------------------|-------------------------|------------|------------|
| PRIMARY              | id                      |          0 | BTREE      |
| prefix_id-completion | prefix_id, completion   |          0 | BTREE      |
| prefix_id            | prefix_id               |          1 | BTREE      |

## Usage

### Inserting a new completion

Use `InsertCompletion(app_id, completion_text, max_prefixes, bucket_size_limit)`. Example:

```sql
CALL InsertCompletion(1, 'nima', 15, 15);
```

**Time complexity:** O((max_prefixes × log(table_prefixes_count)) + log(table_completions_count))

### Get completions of a prefix

Use `GetCompletions(app_id, prefix_text)`. Example:

```sql
CALL GetCompletions(1, 'n');
```
**Time complexity:** O(log(table_prefixes_count × table_completions_count))

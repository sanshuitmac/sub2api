-- 为 API Key 增加独立并发限制与“首次使用后开始计时”开关

ALTER TABLE api_keys
ADD COLUMN IF NOT EXISTS concurrency INTEGER;

ALTER TABLE api_keys
ADD COLUMN IF NOT EXISTS expiry_starts_on_first_use BOOLEAN NOT NULL DEFAULT FALSE;

-- 回填历史数据：按用户并发初始化 key 并发，避免升级后行为突变。
UPDATE api_keys k
SET concurrency = GREATEST(COALESCE(u.concurrency, 1), 1)
FROM users u
WHERE k.user_id = u.id
  AND (k.concurrency IS NULL OR k.concurrency <= 0);

-- 安全兜底（极端脏数据场景）
UPDATE api_keys
SET concurrency = 1
WHERE concurrency IS NULL OR concurrency <= 0;

ALTER TABLE api_keys
ALTER COLUMN concurrency SET NOT NULL;

ALTER TABLE api_keys
ALTER COLUMN concurrency SET DEFAULT 1;

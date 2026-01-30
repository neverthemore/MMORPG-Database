-- Создание базы данных для MMORPG
CREATE DATABASE mmorpg_db;


-- Таблица игроков (пользователей)
CREATE TABLE players (
    player_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_username CHECK (username ~ '^[a-zA-Z0-9_]{3,50}$'),
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Таблица рас персонажей
CREATE TABLE races (
    race_id SERIAL PRIMARY KEY,
    race_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    base_health INTEGER NOT NULL DEFAULT 100,
    base_mana INTEGER NOT NULL DEFAULT 50,
    base_strength INTEGER NOT NULL DEFAULT 10,
    base_agility INTEGER NOT NULL DEFAULT 10,
    base_intellect INTEGER NOT NULL DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_stats CHECK (
        base_health > 0 AND base_mana >= 0 AND
        base_strength > 0 AND base_agility > 0 AND base_intellect > 0
    ),
    CONSTRAINT unique_race_stats UNIQUE(base_health, base_mana, base_strength, base_agility, base_intellect)
);

-- Таблица классов персонажей
CREATE TABLE classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    primary_attribute VARCHAR(20) NOT NULL,
    can_use_magic BOOLEAN DEFAULT FALSE,
    armor_type VARCHAR(20) NOT NULL,
    weapon_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_primary_attribute CHECK (
        primary_attribute IN ('strength', 'agility', 'intellect')
    ),
    CONSTRAINT valid_armor_type CHECK (
        armor_type IN ('cloth', 'leather', 'mail', 'plate')
    )
);

-- Таблица персонажей
CREATE TABLE characters (
    character_id SERIAL PRIMARY KEY,
    player_id INTEGER NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
    character_name VARCHAR(50) UNIQUE NOT NULL,
    race_id INTEGER NOT NULL REFERENCES races(race_id),
    class_id INTEGER NOT NULL REFERENCES classes(class_id),
    level INTEGER NOT NULL DEFAULT 1,
    experience INTEGER NOT NULL DEFAULT 0,
    health INTEGER NOT NULL DEFAULT 100,
    mana INTEGER NOT NULL DEFAULT 50,
    strength INTEGER NOT NULL DEFAULT 10,
    agility INTEGER NOT NULL DEFAULT 10,
    intellect INTEGER NOT NULL DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    CONSTRAINT valid_level CHECK (level BETWEEN 1 AND 100),
    CONSTRAINT valid_experience CHECK (experience >= 0),
    CONSTRAINT positive_stats_char CHECK (
        health > 0 AND mana >= 0 AND
        strength > 0 AND agility > 0 AND intellect > 0
    ),
    CONSTRAINT valid_character_name CHECK (
        character_name ~ '^[a-zA-Z][a-zA-Z0-9_-]{2,49}$' AND
        length(character_name) BETWEEN 3 AND 50
    )
);

-- Таблица гильдий
CREATE TABLE guilds (
    guild_id SERIAL PRIMARY KEY,
    guild_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    leader_id INTEGER NOT NULL REFERENCES characters(character_id),
    member_limit INTEGER DEFAULT 100,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_member_limit CHECK (member_limit BETWEEN 5 AND 1000)
);

-- Таблица членства в гильдиях
CREATE TABLE guild_memberships (
    membership_id SERIAL PRIMARY KEY,
    guild_id INTEGER NOT NULL REFERENCES guilds(guild_id) ON DELETE CASCADE,
    character_id INTEGER NOT NULL REFERENCES characters(character_id) ON DELETE CASCADE,
    rank VARCHAR(20) NOT NULL DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(guild_id, character_id),
    CONSTRAINT valid_rank CHECK (rank IN ('leader', 'officer', 'veteran', 'member', 'recruit'))
);

-- Таблица типов предметов
CREATE TABLE item_types (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(20) NOT NULL,
    can_be_equipped BOOLEAN DEFAULT FALSE,
    stack_limit INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_category CHECK (
        category IN ('weapon', 'armor', 'consumable', 'material', 'quest', 'misc')
    ),
    CONSTRAINT positive_stack_limit CHECK (stack_limit > 0)
);

-- Таблица предметов
CREATE TABLE items (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    type_id INTEGER NOT NULL REFERENCES item_types(type_id),
    description TEXT,
    required_level INTEGER DEFAULT 1,
    sell_price INTEGER,
    buy_price INTEGER,
    rarity VARCHAR(20) NOT NULL DEFAULT 'common',
    durability INTEGER,
    max_durability INTEGER,
    is_soulbound BOOLEAN DEFAULT FALSE,
    is_tradable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_required_level CHECK (required_level >= 0),
    CONSTRAINT valid_prices CHECK (
        (sell_price IS NULL OR sell_price >= 0) AND
        (buy_price IS NULL OR buy_price >= 0)
    ),
    CONSTRAINT valid_rarity CHECK (
        rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')
    ),
    CONSTRAINT valid_durability CHECK (
        (durability IS NULL AND max_durability IS NULL) OR
        (durability BETWEEN 0 AND max_durability AND max_durability > 0)
    )
);

-- Таблица характеристик предметов
CREATE TABLE item_stats (
    item_stat_id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES items(item_id) ON DELETE CASCADE,
    stat_type VARCHAR(30) NOT NULL,
    stat_value INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(item_id, stat_type),
    CONSTRAINT valid_stat_type CHECK (
        stat_type IN (
            'strength', 'agility', 'intellect', 'stamina',
            'attack_power', 'spell_power', 'crit_chance',
            'haste', 'armor', 'health', 'mana', 'health_regen', 'mana_regen'
        )
    )
);

-- Таблица инвентаря
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    character_id INTEGER NOT NULL REFERENCES characters(character_id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES items(item_id),
    slot INTEGER,
    quantity INTEGER NOT NULL DEFAULT 1,
    equipped BOOLEAN DEFAULT FALSE,
    acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_slot CHECK (slot BETWEEN 0 AND 100),
    CONSTRAINT valid_quantity CHECK (quantity > 0),
    CONSTRAINT no_equipped_non_equippable CHECK (
        NOT (equipped = TRUE AND slot IS NULL)
    )
);

-- Таблица зон (игровых локаций)
CREATE TABLE zones (
    zone_id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    level_range_low INTEGER NOT NULL DEFAULT 1,
    level_range_high INTEGER NOT NULL DEFAULT 100,
    zone_type VARCHAR(20) NOT NULL,
    is_safe BOOLEAN DEFAULT FALSE,
    parent_zone_id INTEGER REFERENCES zones(zone_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_level_range CHECK (
        level_range_low <= level_range_high AND
        level_range_low >= 1 AND level_range_high <= 100
    ),
    CONSTRAINT valid_zone_type CHECK (
        zone_type IN ('starting', 'normal', 'dungeon', 'raid', 'capital', 'pvp', 'arena')
    )
);

-- Таблица местоположения персонажей
CREATE TABLE character_locations (
    character_id INTEGER PRIMARY KEY REFERENCES characters(character_id) ON DELETE CASCADE,
    zone_id INTEGER NOT NULL REFERENCES zones(zone_id),
    x_coordinate DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    y_coordinate DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    z_coordinate DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_coordinates CHECK (
        x_coordinate BETWEEN -10000.0 AND 10000.0 AND
        y_coordinate BETWEEN -10000.0 AND 10000.0 AND
        z_coordinate BETWEEN -1000.0 AND 1000.0
    )
);

-- Таблица навыков
CREATE TABLE skills (
    skill_id SERIAL PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL,
    description TEXT,
    required_class_id INTEGER REFERENCES classes(class_id),
    required_level INTEGER NOT NULL DEFAULT 1,
    mana_cost INTEGER DEFAULT 0,
    cooldown_seconds INTEGER DEFAULT 0,
    skill_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_required_level CHECK (required_level >= 0),
    CONSTRAINT non_negative_mana_cost CHECK (mana_cost >= 0),
    CONSTRAINT non_negative_cooldown CHECK (cooldown_seconds >= 0),
    CONSTRAINT valid_skill_type CHECK (
        skill_type IN ('active', 'passive', 'toggle', 'aura')
    )
);

-- Таблица навыков персонажей
CREATE TABLE character_skills (
    character_skill_id SERIAL PRIMARY KEY,
    character_id INTEGER NOT NULL REFERENCES characters(character_id) ON DELETE CASCADE,
    skill_id INTEGER NOT NULL REFERENCES skills(skill_id),
    skill_level INTEGER NOT NULL DEFAULT 1,
    learned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(character_id, skill_id),
    CONSTRAINT valid_skill_level CHECK (skill_level BETWEEN 1 AND 100)
);

-- Таблица квестов
CREATE TABLE quests (
    quest_id SERIAL PRIMARY KEY,
    quest_name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    quest_giver VARCHAR(100),
    required_level INTEGER NOT NULL DEFAULT 1,
    required_quest_id INTEGER REFERENCES quests(quest_id),
    zone_id INTEGER REFERENCES zones(zone_id),
    experience_reward INTEGER NOT NULL DEFAULT 0,
    gold_reward INTEGER NOT NULL DEFAULT 0,
    repeatable BOOLEAN DEFAULT FALSE,
    max_repeats INTEGER DEFAULT 1,
    quest_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_required_level CHECK (required_level >= 0),
    CONSTRAINT non_negative_rewards CHECK (
        experience_reward >= 0 AND gold_reward >= 0
    ),
    CONSTRAINT valid_max_repeats CHECK (max_repeats >= 1),
    CONSTRAINT valid_quest_type CHECK (
        quest_type IN ('main', 'side', 'daily', 'weekly', 'event')
    )
);

-- Таблица прогресса квестов
CREATE TABLE quest_progress (
    progress_id SERIAL PRIMARY KEY,
    character_id INTEGER NOT NULL REFERENCES characters(character_id) ON DELETE CASCADE,
    quest_id INTEGER NOT NULL REFERENCES quests(quest_id),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    progress_data JSONB,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    times_completed INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_status CHECK (
        status IN ('available', 'active', 'completed', 'failed', 'abandoned')
    ),
    CONSTRAINT valid_times_completed CHECK (times_completed >= 0)
);

-- Таблица монстров (NPC врагов)
CREATE TABLE monsters (
    monster_id SERIAL PRIMARY KEY,
    monster_name VARCHAR(100) NOT NULL,
    level INTEGER NOT NULL DEFAULT 1,
    health INTEGER NOT NULL,
    zone_id INTEGER NOT NULL REFERENCES zones(zone_id),
    respawn_time_seconds INTEGER DEFAULT 60,
    experience_given INTEGER NOT NULL DEFAULT 0,
    gold_min INTEGER NOT NULL DEFAULT 0,
    gold_max INTEGER NOT NULL DEFAULT 0,
    ai_type VARCHAR(20) DEFAULT 'passive',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_level CHECK (level BETWEEN 1 AND 100),
    CONSTRAINT positive_health CHECK (health > 0),
    CONSTRAINT valid_respawn_time CHECK (respawn_time_seconds >= 0),
    CONSTRAINT non_negative_experience CHECK (experience_given >= 0),
    CONSTRAINT valid_gold_range CHECK (gold_min <= gold_max AND gold_min >= 0),
    CONSTRAINT valid_ai_type CHECK (
        ai_type IN ('passive', 'aggressive', 'defensive', 'boss', 'elite')
    )
);

-- Таблица дропа с монстров
CREATE TABLE monster_loot (
    loot_id SERIAL PRIMARY KEY,
    monster_id INTEGER NOT NULL REFERENCES monsters(monster_id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES items(item_id),
    drop_chance DECIMAL(5, 4) NOT NULL,
    min_quantity INTEGER NOT NULL DEFAULT 1,
    max_quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_drop_chance CHECK (drop_chance BETWEEN 0.0000 AND 1.0000),
    CONSTRAINT valid_quantity_range CHECK (
        min_quantity <= max_quantity AND min_quantity >= 1
    ),
    UNIQUE(monster_id, item_id)
);

-- Таблица боевых действий
CREATE TABLE combats (
    combat_id SERIAL PRIMARY KEY,
    attacker_id INTEGER NOT NULL REFERENCES characters(character_id),
    target_id INTEGER NOT NULL,
    target_type VARCHAR(10) NOT NULL,
    damage_dealt INTEGER NOT NULL,
    damage_type VARCHAR(20) NOT NULL,
    critical_hit BOOLEAN DEFAULT FALSE,
    combat_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    zone_id INTEGER REFERENCES zones(zone_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_target_type CHECK (target_type IN ('character', 'monster')),
    CONSTRAINT positive_damage CHECK (damage_dealt >= 0),
    CONSTRAINT valid_damage_type CHECK (
        damage_type IN ('physical', 'magical', 'fire', 'frost', 'shadow', 'holy', 'nature')
    )
);

-- Создание частичного уникального индекса для инвентаря
CREATE UNIQUE INDEX idx_inventory_unique_slot 
ON inventory(character_id, slot) 
WHERE slot IS NOT NULL;

-- Частичный уникальный индекс для квестов
CREATE UNIQUE INDEX idx_quest_progress_unique_active 
ON quest_progress(character_id, quest_id) 
WHERE status IN ('active', 'available');

-- Индексы для улучшения производительности
CREATE INDEX idx_characters_player_id ON characters(player_id);
CREATE INDEX idx_characters_level ON characters(level);
CREATE INDEX idx_characters_name ON characters(character_name);
CREATE INDEX idx_characters_race_class ON characters(race_id, class_id);

CREATE INDEX idx_inventory_character_id ON inventory(character_id);
CREATE INDEX idx_inventory_item_id ON inventory(item_id);
CREATE INDEX idx_inventory_equipped ON inventory(character_id) WHERE equipped = TRUE;

CREATE INDEX idx_character_locations_zone_id ON character_locations(zone_id);

CREATE INDEX idx_quest_progress_character_id ON quest_progress(character_id);
CREATE INDEX idx_quest_progress_status ON quest_progress(status);
CREATE INDEX idx_quests_name ON quests(quest_name);
CREATE INDEX idx_quests_zone ON quests(zone_id);
CREATE INDEX idx_quests_type ON quests(quest_type);

CREATE INDEX idx_combats_attacker_id ON combats(attacker_id);
CREATE INDEX idx_combats_target ON combats(target_id, target_type);
CREATE INDEX idx_combats_combat_time ON combats(combat_time);

CREATE INDEX idx_guild_memberships_character_id ON guild_memberships(character_id);
CREATE INDEX idx_guild_memberships_guild ON guild_memberships(guild_id);
CREATE INDEX idx_guilds_leader ON guilds(leader_id);

CREATE INDEX idx_character_skills_character_id ON character_skills(character_id);
CREATE INDEX idx_character_skills_skill ON character_skills(skill_id);

CREATE INDEX idx_items_name ON items(item_name);
CREATE INDEX idx_items_rarity ON items(rarity);
CREATE INDEX idx_items_type ON items(type_id);
CREATE INDEX idx_items_level ON items(required_level);

CREATE INDEX idx_monsters_name ON monsters(monster_name);
CREATE INDEX idx_monsters_zone ON monsters(zone_id);
CREATE INDEX idx_monsters_level ON monsters(level);

CREATE INDEX idx_skills_name ON skills(skill_name);
CREATE INDEX idx_skills_class ON skills(required_class_id);

CREATE INDEX idx_item_stats_item ON item_stats(item_id);
CREATE INDEX idx_item_stats_type ON item_stats(stat_type);

-- Комментарии к таблицам
COMMENT ON TABLE players IS 'Аккаунты игроков';
COMMENT ON TABLE characters IS 'Игровые персонажи';
COMMENT ON TABLE races IS 'Доступные расы для персонажей';
COMMENT ON TABLE classes IS 'Классы персонажей';
COMMENT ON TABLE guilds IS 'Игровые гильдии';
COMMENT ON TABLE items IS 'Игровые предметы';
COMMENT ON TABLE zones IS 'Игровые зоны и локации';
COMMENT ON TABLE quests IS 'Игровые квесты';
COMMENT ON TABLE monsters IS 'Монстры и NPC враги';
COMMENT ON TABLE skills IS 'Навыки и умения персонажей';
COMMENT ON TABLE combats IS 'Лог боевых действий';

-- Функция для обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создание триггеров для обновления updated_at
CREATE TRIGGER update_players_updated_at BEFORE UPDATE ON players
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_characters_updated_at BEFORE UPDATE ON characters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guilds_updated_at BEFORE UPDATE ON guilds
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_items_updated_at BEFORE UPDATE ON items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quests_updated_at BEFORE UPDATE ON quests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Триггер для проверки уровня персонажа при получении предмета
CREATE OR REPLACE FUNCTION check_item_level_requirement()
RETURNS TRIGGER AS $$
DECLARE
    item_level_required INTEGER;
    character_level INTEGER;
BEGIN
    SELECT required_level INTO item_level_required
    FROM items WHERE item_id = NEW.item_id;
    
    -- Если у предмета нет ограничения по уровню, пропускаем проверку
    IF item_level_required IS NULL THEN
        RETURN NEW;
    END IF;
    
    SELECT level INTO character_level
    FROM characters WHERE character_id = NEW.character_id;
    
    IF item_level_required > character_level THEN
        RAISE EXCEPTION 'Персонаж уровня % не может использовать предмет, требующий уровень %',
            character_level, item_level_required;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_item_level
BEFORE INSERT OR UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION check_item_level_requirement();

-- Триггер для проверки, что лидер гильдии является членом гильдии
CREATE OR REPLACE FUNCTION check_guild_leader_membership()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, есть ли лидер в составе гильдии
    IF NOT EXISTS (
        SELECT 1 FROM guild_memberships 
        WHERE guild_id = NEW.guild_id 
        AND character_id = NEW.leader_id
        AND rank = 'leader'
    ) THEN
        -- Автоматически добавляем лидера в гильдию
        INSERT INTO guild_memberships (guild_id, character_id, rank)
        VALUES (NEW.guild_id, NEW.leader_id, 'leader')
        ON CONFLICT (guild_id, character_id) 
        DO UPDATE SET rank = 'leader';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_guild_leader_membership
AFTER INSERT OR UPDATE OF leader_id ON guilds
FOR EACH ROW
EXECUTE FUNCTION check_guild_leader_membership();

-- Триггер для обновления времени последней игры персонажа
CREATE OR REPLACE FUNCTION update_character_last_played()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_played = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_last_played
BEFORE UPDATE ON characters
FOR EACH ROW
EXECUTE FUNCTION update_character_last_played();

-- Представление для статистики персонажей
CREATE VIEW character_stats AS
SELECT 
    c.character_id,
    c.character_name,
    p.username,
    r.race_name,
    cl.class_name,
    c.level,
    c.experience,
    c.health as current_health,
    c.mana as current_mana,
    c.strength + r.base_strength + COALESCE(SUM(is.stat_value) FILTER (WHERE is.stat_type = 'strength'), 0) as total_strength,
    c.agility + r.base_agility + COALESCE(SUM(is.stat_value) FILTER (WHERE is.stat_type = 'agility'), 0) as total_agility,
    c.intellect + r.base_intellect + COALESCE(SUM(is.stat_value) FILTER (WHERE is.stat_type = 'intellect'), 0) as total_intellect,
    (c.health + COALESCE(SUM(is.stat_value) FILTER (WHERE is.stat_type = 'health'), 0)) as max_health,
    (c.mana + COALESCE(SUM(is.stat_value) FILTER (WHERE is.stat_type = 'mana'), 0)) as max_mana,
    COALESCE(g.guild_name, 'Без гильдии') as guild_name,
    gm.rank as guild_rank,
    z.zone_name,
    (SELECT COUNT(*) FROM character_skills cs WHERE cs.character_id = c.character_id) as skills_learned,
    (SELECT COUNT(*) FROM quest_progress qp WHERE qp.character_id = c.character_id AND qp.status = 'completed') as quests_completed,
    (SELECT COUNT(*) FROM combats co WHERE co.attacker_id = c.character_id) as combats_participated
FROM characters c
JOIN players p ON c.player_id = p.player_id
JOIN races r ON c.race_id = r.race_id
JOIN classes cl ON c.class_id = cl.class_id
LEFT JOIN character_locations cloc ON c.character_id = cloc.character_id
LEFT JOIN zones z ON cloc.zone_id = z.zone_id
LEFT JOIN guild_memberships gm ON c.character_id = gm.character_id
LEFT JOIN guilds g ON gm.guild_id = g.guild_id
LEFT JOIN inventory inv ON c.character_id = inv.character_id AND inv.equipped = TRUE
LEFT JOIN item_stats is ON inv.item_id = is.item_id
WHERE c.is_deleted = FALSE
GROUP BY c.character_id, p.username, r.race_name, cl.class_name, 
         g.guild_name, gm.rank, z.zone_name, c.health, c.mana;

-- Представление для статистики гильдий
CREATE VIEW guild_stats AS
SELECT
    g.guild_id,
    g.guild_name,
    c.character_name as leader_name,
    COUNT(gm.character_id) as member_count,
    AVG(ch.level) as average_level,
    MAX(ch.level) as highest_level,
    g.created_at,
    STRING_AGG(DISTINCT cl.class_name, ', ') as class_distribution
FROM guilds g
JOIN characters c ON g.leader_id = c.character_id
JOIN guild_memberships gm ON g.guild_id = gm.guild_id
JOIN characters ch ON gm.character_id = ch.character_id
JOIN classes cl ON ch.class_id = cl.class_id
GROUP BY g.guild_id, g.guild_name, c.character_name, g.created_at;

-- Представление для экономики игры
CREATE VIEW economy_stats AS
SELECT
    COUNT(DISTINCT i.item_id) as total_items,
    COUNT(DISTINCT it.type_id) as item_types,
    SUM(i.buy_price) FILTER (WHERE i.buy_price IS NOT NULL) as total_buy_value,
    SUM(i.sell_price) FILTER (WHERE i.sell_price IS NOT NULL) as total_sell_value,
    AVG(i.buy_price) FILTER (WHERE i.buy_price IS NOT NULL) as avg_buy_price,
    AVG(i.sell_price) FILTER (WHERE i.sell_price IS NOT NULL) as avg_sell_price,
    COUNT(*) FILTER (WHERE i.rarity = 'legendary') as legendary_items,
    COUNT(*) FILTER (WHERE i.rarity = 'epic') as epic_items,
    COUNT(*) FILTER (WHERE i.rarity = 'rare') as rare_items
FROM items i
JOIN item_types it ON i.type_id = it.type_id;

-- Функция для расчета опыта до следующего уровня
CREATE OR REPLACE FUNCTION experience_to_next_level(current_level INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN current_level * 100 * (current_level + 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Функция для расчета максимального здоровья персонажа
CREATE OR REPLACE FUNCTION calculate_max_health(
    base_health INTEGER,
    level INTEGER,
    stamina INTEGER
)
RETURNS INTEGER AS $$
BEGIN
    RETURN base_health + (level * 10) + (stamina * 5);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Таблица для аудита важных действий
CREATE TABLE audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    old_data JSONB,
    new_data JSONB,
    user_id INTEGER REFERENCES players(player_id),
    ip_address INET,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_action CHECK (action IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- Индекс для аудита
CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_action_time ON audit_log(action_time);
CREATE INDEX idx_audit_log_user ON audit_log(user_id);
